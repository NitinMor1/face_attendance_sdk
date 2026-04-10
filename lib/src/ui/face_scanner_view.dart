import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../engines/detector_interface.dart';
import '../engines/recognizer_interface.dart';
import '../models/face_data.dart';
import '../utils/image_utils.dart';
import 'face_painter.dart';
import 'utils/web_utils_stub.dart'
    if (dart.library.js_interop) 'utils/web_utils_impl.dart';

import '../models/dialog_options.dart';
import 'widgets/recognition_dialog.dart';

class FaceScannerView extends StatefulWidget {
  final FaceDetectorInterface detector;
  final FaceRecognizerInterface? recognizer;
  final List<FaceProfile> profiles;
  final bool enableDefaultDialog;
  final bool captureOnlyFace;
  final RecognitionDialogOptions dialogOptions;
  final Function(FaceData face, Uint8List faceImage)? onFaceDetected;
  final Function(FaceProfile profile, Uint8List faceImage)? onFaceRecognized;

  const FaceScannerView({
    super.key,
    required this.detector,
    this.recognizer,
    this.profiles = const [],
    this.enableDefaultDialog = false,
    this.captureOnlyFace = false,
    this.dialogOptions = const RecognitionDialogOptions(),
    this.onFaceDetected,
    this.onFaceRecognized,
  });

  @override
  State<FaceScannerView> createState() => _FaceScannerViewState();
}

class _FaceScannerViewState extends State<FaceScannerView> {
  CameraController? _controller;
  List<FaceData> _faces = [];
  bool _isProcessing = false;
  bool _isDialogShowing = false;
  Timer? _webDetectionTimer;
  ValueNotifier<String?>? _currentNameNotifier;

  void _showBuiltInDialog(FaceData face, Uint8List faceImage) {
    if (!widget.enableDefaultDialog || _isDialogShowing) return;
    _isDialogShowing = true;
    
    // Fix: Initialize with the current face label if already recognized
    _currentNameNotifier = ValueNotifier<String?>(face.label);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder<String?>(
        valueListenable: _currentNameNotifier!,
        builder: (context, name, _) => RecognitionDialog(
          faceImage: faceImage,
          name: name,
          options: widget.dialogOptions,
          onConfirm: () => Navigator.of(context).pop(),
        ),
      ),
    ).then((_) {
      _lastDialogDismissTime = DateTime.now();
      _isDialogShowing = false;
      _currentNameNotifier?.dispose();
      _currentNameNotifier = null;
    });

    // Auto close unconditionally after the duration
    Future.delayed(widget.dialogOptions.displayDuration, () {
      if (_isDialogShowing && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  DateTime? _lastDialogDismissTime;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.high, // Increased for better cropping quality
      enableAudio: false,
      imageFormatGroup: kIsWeb ? null : ImageFormatGroup.nv21,
    );

    try {
      await _controller!.initialize();
      if (kIsWeb) {
        _webDetectionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          _processCameraImage(null);
        });
      } else {
        _controller!.startImageStream(_processCameraImage);
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
    }
  }

  void _processCameraImage(CameraImage? image) async {
    if (_isProcessing || _isDialogShowing) return;

    // Cooldown: Don't show another dialog for 3 seconds after dismissing one
    if (_lastDialogDismissTime != null && 
        DateTime.now().difference(_lastDialogDismissTime!) < const Duration(seconds: 3)) {
      return;
    }

    _isProcessing = true;

    try {
      List<FaceData> faces;
      if (kIsWeb) {
        faces = await detectWebFaces(widget.detector);
      } else if (image != null) {
        faces = await widget.detector.detectFromImage(
          image,
          _controller!.description.sensorOrientation,
        );
      } else {
        faces = [];
      }

      // SINGLE FACE ENFORCEMENT: Only handle the first (primary) face
      if (faces.length > 1) {
        faces = [faces.first];
      }

      if (faces.isNotEmpty) {
          for (var i = 0; i < faces.length; i++) {
            Uint8List? faceImage;
            
            // CROP LOGIC: Use cropBox on Web or ImageUtils on Mobile
            if (widget.captureOnlyFace) {
               if (kIsWeb) {
                faceImage = await captureWebFrame(cropBox: faces[i].boundingBox);
              } else if (image != null) {
                faceImage = ImageUtils.cropFace(
                  image, 
                  faces[i].boundingBox, 
                  _controller!.description.sensorOrientation,
                );
              }
            } else {
               if (kIsWeb) {
                faceImage = await captureWebFrame();
              } else if (image != null) {
                faceImage = Uint8List.fromList(ImageUtils.convertedImageToBytes(image));
              }
            }

            if (widget.recognizer != null && (image != null || kIsWeb)) {
              final embedding = await widget.recognizer!.extractEmbedding(image, faces[i]);
              final match = await widget.recognizer!.matchFace(embedding, widget.profiles);
              
              if (match != null) {
                faces[i] = faces[i].copyWith(
                  embedding: embedding,
                  label: match.name,
                  status: RecognitionStatus.recognized,
                );
                
                _currentNameNotifier?.value = match.name;

                if (faceImage != null) {
                  widget.onFaceRecognized?.call(match, faceImage);
                }
              } else {
                faces[i] = faces[i].copyWith(
                  embedding: embedding, 
                  status: RecognitionStatus.notRecognized,
                );
              }
            }

            // TRIGGER CALLBACKS AFTER EMBEDDING IS READY
            if (faceImage != null) {
              widget.onFaceDetected?.call(faces[i], faceImage);
              _showBuiltInDialog(faces[i], faceImage);
            }
          }
        }

        if (mounted) {
          setState(() {
            _faces = faces;
          });
        }
      } catch (e) {
        debugPrint('Error processing image: $e');
      } finally {
        _isProcessing = false;
      }
    }

    @override
    void dispose() {
      _webDetectionTimer?.cancel();
      _controller?.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      if (_controller == null || !_controller!.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }

      final previewSize = _controller!.value.previewSize;
      if (previewSize == null) {
        return const Center(child: CircularProgressIndicator());
      }

      // PRECISION ALIGNMENT & FULL-LENGTH VIEW:
      // We use FittedBox + BoxFit.cover to make the camera fill the container
      // while keeping the AspectRatio + CustomPaint stack scaled as a single unit.
      // This ensures the face boxes stay perfectly aligned even when cropped/zoomed.
      return ClipRRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: kIsWeb ? previewSize.width : previewSize.height,
            height: kIsWeb ? previewSize.height : previewSize.width,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                CustomPaint(
                  painter: FacePainter(
                    faces: _faces,
                    imageSize: previewSize,
                    rotation: _controller!.description.sensorOrientation,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }


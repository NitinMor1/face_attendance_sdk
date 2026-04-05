import 'dart:async';
import 'dart:typed_data';
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
import 'widgets/attendance_dialog.dart';

class FaceScannerView extends StatefulWidget {
  final FaceDetectorInterface detector;
  final FaceRecognizerInterface? recognizer;
  final List<FaceProfile> profiles;
  final bool enableDefaultDialog;
  final AttendanceDialogOptions dialogOptions;
  final Function(FaceData face, Uint8List faceImage)? onFaceDetected;
  final Function(FaceProfile profile, Uint8List faceImage)? onFaceRecognized;

  const FaceScannerView({
    Key? key,
    required this.detector,
    this.recognizer,
    this.profiles = const [],
    this.enableDefaultDialog = false,
    this.dialogOptions = const AttendanceDialogOptions(),
    this.onFaceDetected,
    this.onFaceRecognized,
  }) : super(key: key);

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
    _currentNameNotifier = ValueNotifier<String?>(null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder<String?>(
        valueListenable: _currentNameNotifier!,
        builder: (context, name, _) => AttendanceDialog(
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
      ResolutionPreset.medium,
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
      print('Camera initialization failed: $e');
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

        if (faces.isNotEmpty) {
          for (var i = 0; i < faces.length; i++) {
            Uint8List? faceImage;
            if (kIsWeb) {
              faceImage = await captureWebFrame();
            } else if (image != null) {
              faceImage = ImageUtils.cropFace(
                image, 
                faces[i].boundingBox, 
                _controller!.description.sensorOrientation,
              );
            }

            if (widget.recognizer != null && (image != null || kIsWeb)) {
              final embedding = await widget.recognizer!.extractEmbedding(image, faces[i]);
              final match = await widget.recognizer!.matchFace(embedding, widget.profiles);
              
              if (match != null) {
                faces[i] = faces[i].copyWith(
                  embedding: embedding,
                  label: match.name,
                  status: AttendanceStatus.recognized,
                );
                
                _currentNameNotifier?.value = match.name;

                if (faceImage != null) {
                  widget.onFaceRecognized?.call(match, faceImage);
                }
              } else {
                faces[i] = faces[i].copyWith(
                  embedding: embedding, // STORE embedding for enrollment
                  status: AttendanceStatus.notRecognized,
                );
              }
            }

            // TRIGGER CALLBACKS AFTER EMBEDDING IS READY
            if (faceImage != null) {
              debugPrint('Face detected and captured (embedding ready), triggering callback');
              widget.onFaceDetected?.call(faces[i], faceImage);
              _showBuiltInDialog(faces[i], faceImage);
            } else {
              debugPrint('Face detected but capture failed');
            }
          }
        }

        if (mounted) {
          setState(() {
            _faces = faces;
          });
        }
      } catch (e) {
        print('Error processing image: $e');
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

      return Stack(
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
      );
    }
  }


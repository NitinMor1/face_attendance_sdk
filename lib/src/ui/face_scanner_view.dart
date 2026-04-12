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
import '../models/guidance_options.dart';
import 'widgets/recognition_dialog.dart';

class FaceScannerView extends StatefulWidget {
  final FaceDetectorInterface detector;
  final FaceRecognizerInterface? recognizer;
  final List<FaceProfile> profiles;
  final bool enableDefaultDialog;
  final bool captureOnlyFace;
  final double cropPadding;
  final RecognitionDialogOptions dialogOptions;
  final FaceGuidanceOptions guidanceOptions;
  final Function(FaceData face, Uint8List faceImage)? onFaceDetected;
  final Function(FaceProfile profile, Uint8List faceImage)? onFaceRecognized;

  const FaceScannerView({
    super.key,
    required this.detector,
    this.recognizer,
    this.profiles = const [],
    this.enableDefaultDialog = false,
    this.captureOnlyFace = false,
    this.cropPadding = 0.0,
    this.dialogOptions = const RecognitionDialogOptions(),
    this.guidanceOptions = const FaceGuidanceOptions(),
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
  String? _activeGuidance;
  bool _isRecognitionBusy = false;
  DateTime? _lastRecognitionTime;

  void _showBuiltInDialog(FaceData face, Uint8List faceImage) {
    if (!mounted || !widget.enableDefaultDialog || _isDialogShowing) return;
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
      if (!mounted || _isProcessing || _isDialogShowing) return;

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

        // Adaptive Logic: If a face is found, we keep tracking it on every frame.
        // But we only run RECOGNITION (heavy stuff) every 500ms-1s to avoid lag.
        bool shouldRunRecognition = widget.recognizer != null && 
                                   !_isRecognitionBusy && 
                                   (_lastRecognitionTime == null || 
                                    DateTime.now().difference(_lastRecognitionTime!) > const Duration(milliseconds: 700));

        // 1. LIGHTING CHECK (Dynamic Lighting Guidance)
        if (widget.guidanceOptions.enabled && !kIsWeb && image != null) {
          final brightness = _calculateAverageBrightness(image);
          if (brightness < widget.guidanceOptions.brightnessThreshold) {
            if (mounted) setState(() => _activeGuidance = widget.guidanceOptions.poorLightingMessage);
            _isProcessing = false;
            return;
          }
        }

        // 2. FACE DETECTION & RECOGNITION
        if (faces.isNotEmpty) {
          if (faces.length > 1) {
            faces = [faces.first];
          }
          
          final mainFace = faces.first;

          // Guidance Logic for visible face
          if (widget.guidanceOptions.enabled) {
            _updateGuidance(mainFace, image);
          } else {
            _activeGuidance = null;
          }

          if (shouldRunRecognition && (image != null || kIsWeb)) {
             _isRecognitionBusy = true;
             _lastRecognitionTime = DateTime.now();

             _runRecognitionAsync(image, mainFace);
          }
          
          if (mounted) {
            setState(() {
              _faces = faces;
            });
          }
        } else {
          // NO FACE DETECTED: Reset status and show guidance
          if (widget.guidanceOptions.enabled) {
            if (mounted) setState(() => _activeGuidance = widget.guidanceOptions.noFaceMessage);
          } else {
            if (mounted) setState(() => _activeGuidance = null);
          }
          if (mounted) setState(() => _faces = []);
        }
      } catch (e) {
        debugPrint('Error processing image: $e');
      } finally {
        _isProcessing = false;
      }
    }

    double _calculateAverageBrightness(CameraImage image) {
      if (image.planes.isEmpty) return 100.0;
      final Uint8List bytes = image.planes[0].bytes;
      int total = 0;
      // Sampling every 10th pixel for performance
      for (int i = 0; i < bytes.length; i += 10) {
        total += bytes[i];
      }
      return total / (bytes.length / 10);
    }

    void _runRecognitionAsync(CameraImage? image, FaceData face) async {
       try {
          Uint8List? faceImage;
          if (widget.captureOnlyFace) {
            if (kIsWeb) {
              faceImage = await captureWebFrame(cropBox: face.boundingBox);
            } else if (image != null) {
              faceImage = ImageUtils.cropFace(
                image, 
                face.boundingBox, 
                _controller!.description.sensorOrientation,
                paddingFactor: widget.cropPadding,
              );
            }
          } else {
            if (kIsWeb) {
              faceImage = await captureWebFrame();
            } else if (image != null) {
              faceImage = Uint8List.fromList(ImageUtils.convertedImageToBytes(image));
            }
          }

          final embedding = await widget.recognizer!.extractEmbedding(
            image, 
            face, 
            rotation: _controller!.description.sensorOrientation,
            flipHorizontal: _controller!.description.lensDirection == CameraLensDirection.front,
          );
          final match = await widget.recognizer!.matchFace(embedding, widget.profiles);
          
          FaceData updatedFace = face.copyWith(embedding: embedding);
          
          if (match != null) {
            updatedFace = updatedFace.copyWith(
              label: match.name,
              status: RecognitionStatus.recognized,
            );
            _currentNameNotifier?.value = match.name;
            if (faceImage != null) widget.onFaceRecognized?.call(match, faceImage);
          } else {
            updatedFace = updatedFace.copyWith(status: RecognitionStatus.notRecognized);
          }

          if (faceImage != null) {
            widget.onFaceDetected?.call(updatedFace, faceImage);
            _showBuiltInDialog(updatedFace, faceImage);
          }

          if (mounted) {
            setState(() {
              _faces = [updatedFace];
            });
          }
       } finally {
         _isRecognitionBusy = false;
       }
    }

    void _updateGuidance(FaceData face, CameraImage? image) {
      String? message;
      final options = widget.guidanceOptions;

      // Centering Check
      if (image != null) {
         final centerX = face.boundingBox.center.dx;
         final centerY = face.boundingBox.center.dy;
         final imgW = image.width.toDouble();
         final imgH = image.height.toDouble();

         if (centerX < imgW * 0.1 || centerX > imgW * 0.9 || centerY < imgH * 0.1 || centerY > imgH * 0.9) {
           message = 'Center your face in the frame';
         }
      }

      if (message == null && face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
        if (face.leftEyeOpenProbability! < 0.35 || 
            face.rightEyeOpenProbability! < 0.35) {
          message = options.openEyesMessage;
        }
      }

      if (message == null && face.headEulerAngleY != null) {
        if (face.headEulerAngleY! < -options.rotationThreshold) {
          message = options.turnRightMessage;
        } else if (face.headEulerAngleY! > options.rotationThreshold) {
          message = options.turnLeftMessage;
        }
      }

      if (message == null && face.boundingBox.width < 100) {
        message = options.moveCloserMessage;
      }

      // If no warning but face is detected, show 'Stay still'
      message ??= options.stayStillMessage;

      if (_activeGuidance != message) {
        if (mounted) setState(() => _activeGuidance = message);
      }
    }

    @override
    void dispose() {
      _stopAllProcessing();
      super.dispose();
    }

    Future<void> _stopAllProcessing() async {
      _webDetectionTimer?.cancel();
      _webDetectionTimer = null;
      
      if (_controller != null) {
        if (_controller!.value.isStreamingImages) {
          try {
            await _controller!.stopImageStream();
          } catch (e) {
            debugPrint('Error stopping stream: $e');
          }
        }
        await _controller?.dispose();
        _controller = null;
      }
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera Layer (FittedBox)
            FittedBox(
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
            
            // Logical UI Layer (Standard logical pixels)
            if (_activeGuidance != null)
              _buildGuidanceOverlay(),
            
            if (_faces.isNotEmpty)
              _buildRecognitionStatusCard(_faces.first),
          ],
        ),
      );
    }

    Widget _buildRecognitionStatusCard(FaceData face) {
      final isRecognized = face.status == RecognitionStatus.recognized;
      final isSearching = face.status == RecognitionStatus.processing || face.embedding == null;
      final isUnknown = face.status == RecognitionStatus.notRecognized;

      Color color;
      IconData icon;
      String title;
      String subtitle;

      if (isRecognized) {
        color = Colors.indigo;
        icon = Icons.verified;
        title = face.label ?? 'Recognized';
        final conf = face.confidence != null ? '${(face.confidence! * 100).toInt()}%' : 'High';
        subtitle = 'Identity Verified ($conf)';
      } else if (isUnknown) {
        color = Colors.redAccent;
        icon = Icons.error_outline;
        title = 'Unknown Face';
        subtitle = 'Not in registry';
      } else if (isSearching) {
        color = Colors.blueGrey;
        icon = Icons.search;
        title = 'Searching...';
        subtitle = 'Analyzing Biometrics';
      } else {
        color = Colors.blueGrey;
        icon = Icons.radar;
        title = 'Face Detected';
        subtitle = 'Scanning...';
      }

      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 60),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, letterSpacing: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildGuidanceOverlay() {
      if (widget.guidanceOptions.guidanceBuilder != null) {
        return widget.guidanceOptions.guidanceBuilder!(context, _activeGuidance!);
      }

      return Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            _activeGuidance!,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      );
    }
  }


import 'dart:async';
import 'dart:js_interop';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import '../../models/face_data.dart';
import '../detector_interface.dart';
import 'mediapipe_interop.dart';
import 'package:web/web.dart' as web;

class WebDetector implements FaceDetectorInterface {
  FaceDetector? _detector;

  @override
  Future<void> initialize() async {
    try {
      print('Initializing Web Face Detector...');
      
      final vision = await FilesetResolver.forVisionTasks(
        'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.3/wasm'.toJS,
      ).toDart.timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('MediaPipe FilesetResolver timeout');
      });

      _detector = await FaceDetector.createFromOptions(
        vision,
        FaceDetectorOptions(
          baseOptions: BaseOptions(
            modelAssetPath: 'https://storage.googleapis.com/mediapipe-models/face_detector/blaze_face_short_range/float16/1/blaze_face_short_range.tflite'.toJS,
            delegate: 'GPU'.toJS,
          ),
          runningMode: 'IMAGE'.toJS as dynamic,
          minDetectionConfidence: 0.5,
        ),
      ).toDart.timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('MediaPipe FaceDetector creation timeout');
      });

      print('Web Face Detector initialized via MediaPipe');
    } catch (e) {
      print('Failed to initialize Web Face Detector: $e');
    }
  }

  @override
  Future<List<FaceData>> detectFromImage(CameraImage image, int rotation) async {
    // Note: On Web, FaceScannerView should pass the video element instead of CameraImage bytes
    // For now, this is a placeholder as the real detection happens via detectForVideo
    return [];
  }

  /// Web specific detection using a Video Element
  Future<List<FaceData>> detectFromVideo(web.HTMLVideoElement video) async {
    if (_detector == null) return [];

    final result = _detector!.detect(video as dynamic);
    final detections = result.detections.toDart;

    return detections.map((d) {
      final box = d.boundingBox!;
      return FaceData(
        boundingBox: Rect.fromLTWH(box.originX, box.originY, box.width, box.height),
        confidence: d.categories.toDart.isNotEmpty ? d.categories.toDart[0].score : 0.0,
      );
    }).toList();
  }

  @override
  Future<void> dispose() async {
    _detector?.close();
  }
}

FaceDetectorInterface createDetector() => WebDetector();

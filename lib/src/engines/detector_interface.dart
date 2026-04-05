import 'package:camera/camera.dart';
import '../models/face_data.dart';
import 'detector_stub.dart'
    if (dart.library.io) 'mobile/ml_kit_detector.dart'
    if (dart.library.html) 'web/web_detector.dart';

/// Abstract interface for a face detection engine.
abstract class FaceDetectorInterface {
  /// Default factory to create the platform-specific detector.
  factory FaceDetectorInterface() => createDetector();

  /// Initializes the detector.
  Future<void> initialize();

  /// Processes a single camera frame to detect faces.
  Future<List<FaceData>> detectFromImage(CameraImage image, int rotation);

  /// Releases resources.
  Future<void> dispose();
}

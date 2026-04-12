import 'package:camera/camera.dart';
import '../models/face_data.dart';
import 'recognizer_stub.dart' 
    if (dart.library.io) 'mobile/tflite_recognizer.dart'
    if (dart.library.html) 'web/web_recognizer.dart';

/// Abstract interface for a face recognition engine.
abstract class FaceRecognizerInterface {
  /// Default factory to create the platform-specific recognizer.
  factory FaceRecognizerInterface() => createRecognizer();

  /// Initializes the recognizer (e.g., loading the TFLite model).
  Future<void> initialize();

  /// Returns true if the engine is ready for inference.
  bool get isReady;

  /// Returns the error message if initialization failed.
  String? get initializationError;

  /// Extracts an embedding (vector) from a cropped face image.
  /// [rotation] specifies the camera frame rotation.
  /// [flipHorizontal] should be true for front-facing cameras to correct mirroring.
  Future<List<double>> extractEmbedding(CameraImage? image, FaceData face, {int rotation = 0, bool flipHorizontal = false});

  /// Matches a FaceData against a list of known profiles.
  Future<FaceProfile?> matchFace(List<double> embedding, List<FaceProfile> profiles, {double threshold = 0.52});

  /// Releases resources.
  Future<void> dispose();
}

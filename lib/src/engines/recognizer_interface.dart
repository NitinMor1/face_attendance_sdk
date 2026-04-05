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

  /// Extracts an embedding (vector) from a cropped face image.
  Future<List<double>> extractEmbedding(CameraImage? image, FaceData face);

  /// Matches a FaceData against a list of known profiles.
  Future<FaceProfile?> matchFace(List<double> embedding, List<FaceProfile> profiles, {double threshold = 0.6});

  /// Releases resources.
  Future<void> dispose();
}

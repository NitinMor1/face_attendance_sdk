import '../../models/face_data.dart';
import '../recognizer_interface.dart';
import 'package:camera/camera.dart';

class WebRecognizer implements FaceRecognizerInterface {
  @override
  Future<void> initialize() async {
    // Web face recognition is not yet implemented (requires JS-Interop)
  }

  @override
  bool get isReady => true; // Web uses mock for now

  @override
  String? get initializationError => null;

  @override
  Future<List<double>> extractEmbedding(CameraImage? image, FaceData face, {int rotation = 0, bool flipHorizontal = false}) async {
    // MediaPipe FaceDetector on web doesn't provide embeddings.
    // For the demo/live project, we generate a mock embedding based on face location
    // to allow the enrollment and recognition flow to function.
    // In a production app, you would use face-api.js or tfjs here.
    return List.generate(128, (i) => (face.boundingBox.left + i) % 1.0);
  }

  @override
  Future<FaceProfile?> matchFace(List<double> embedding, List<FaceProfile> profiles, {double threshold = 0.6}) async {
    return null;
  }

  @override
  Future<void> dispose() async {}
}

FaceRecognizerInterface createRecognizer() => WebRecognizer();

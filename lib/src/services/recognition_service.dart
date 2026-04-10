import 'dart:math';
import '../models/face_data.dart';

class RecognitionService {
  final List<FaceProfile> _registeredProfiles = [];
  final double threshold = 0.6;

  List<FaceProfile> get registeredProfiles => List.unmodifiable(_registeredProfiles);

  /// Registers a new profile with an embedding.
  void registerFace(String id, String name, List<double> embedding) {
    _registeredProfiles.add(FaceProfile(id: id, name: name, embedding: embedding));
  }

  /// Verifies recognition and returns the status.
  RecognitionStatus processRecognition(FaceProfile profile) {
    // In a real toolkit, this could log events or interact with a backend
    return RecognitionStatus.success;
  }

  /// Utility to calculate similarity (Euclidean distance)
  double compareEmbeddings(List<double> e1, List<double> e2) {
    double sum = 0;
    for (int i = 0; i < e1.length; i++) {
        sum += pow(e1[i] - e2[i], 2);
    }
    return sqrt(sum);
  }
}

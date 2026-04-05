import 'dart:math';
import '../models/face_data.dart';

class AttendanceService {
  final List<FaceProfile> _registeredProfiles = [];
  final double threshold = 0.6;

  List<FaceProfile> get registeredProfiles => List.unmodifiable(_registeredProfiles);

  /// Registers a new profile with an embedding.
  void registerFace(String id, String name, List<double> embedding) {
    _registeredProfiles.add(FaceProfile(id: id, name: name, embedding: embedding));
  }

  /// Verifies attendance and returns the result.
  AttendanceStatus processAttendance(FaceProfile profile, bool isCheckingIn) {
    // In a real app, this would update a database or call an API
    return isCheckingIn ? AttendanceStatus.checkinSuccessful : AttendanceStatus.checkoutSuccessful;
  }

  /// Utility to calculate similarity
  double compareEmbeddings(List<double> e1, List<double> e2) {
    double sum = 0;
    for (int i = 0; i < e1.length; i++) {
        sum += pow(e1[i] - e2[i], 2);
    }
    return sqrt(sum);
  }
}

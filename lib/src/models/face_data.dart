import 'dart:ui';

/// Represents the status of a face in the attendance system.
enum AttendanceStatus {
  unknown,
  processing,
  recognized,
  notRecognized,
  checkoutSuccessful,
  checkinSuccessful,
}

/// Represents a detected face landmark (e.g., eye, nose, mouth).
class FaceLandmark {
  final String type;
  final Offset position;

  FaceLandmark({required this.type, required this.position});
}

/// Data structure for a detected face.
class FaceData {
  final Rect boundingBox;
  final double? confidence;
  final String? label;
  final List<double>? embedding;
  final AttendanceStatus status;
  final Map<String, FaceLandmark> landmarks;

  FaceData({
    required this.boundingBox,
    this.confidence,
    this.label,
    this.embedding,
    this.status = AttendanceStatus.unknown,
    this.landmarks = const {},
  });

  FaceData copyWith({
    Rect? boundingBox,
    double? confidence,
    String? label,
    List<double>? embedding,
    AttendanceStatus? status,
    Map<String, FaceLandmark>? landmarks,
  }) {
    return FaceData(
      boundingBox: boundingBox ?? this.boundingBox,
      confidence: confidence ?? this.confidence,
      label: label ?? this.label,
      embedding: embedding ?? this.embedding,
      status: status ?? this.status,
      landmarks: landmarks ?? this.landmarks,
    );
  }
}

/// Represents a stored user profile for matching.
class FaceProfile {
  final String id;
  final String name;
  final List<double> embedding;

  FaceProfile({
    required this.id,
    required this.name,
    required this.embedding,
  });
}

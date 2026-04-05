import 'dart:async';
import 'dart:typed_data';
import 'package:face_attendance_sdk/face_attendance_sdk.dart';

/// Stub for finding the video element and detecting faces.
Future<List<FaceData>> detectWebFaces(FaceDetectorInterface detector) async {
  return [];
}

/// Stub for capturing a frame on the web.
Future<Uint8List?> captureWebFrame() async {
  return null;
}

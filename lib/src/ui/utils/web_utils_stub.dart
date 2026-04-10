import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';
import 'package:face_recognition_kit/face_recognition_kit.dart';

/// Stub for finding the video element and detecting faces.
Future<List<FaceData>> detectWebFaces(FaceDetectorInterface detector) async {
  return [];
}

/// Stub for capturing a frame on the web.
Future<Uint8List?> captureWebFrame({Rect? cropBox}) async {
  return null;
}

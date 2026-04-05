import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:face_attendance_sdk/face_attendance_sdk.dart';
import 'package:face_attendance_sdk/src/engines/web/web_detector.dart';
import 'package:web/web.dart' as web;
import 'dart:convert';
/// Actual web implementation of finding the video element and detecting faces.
Future<List<FaceData>> detectWebFaces(FaceDetectorInterface detector) async {
  final videoElement = web.document.querySelector('video') as web.HTMLVideoElement?;
  if (videoElement != null && detector is WebDetector) {
    return await detector.detectFromVideo(videoElement);
  }
  return [];
}

/// Captures a frame from the active video element and returns it as a Uint8List (JPEG).
Future<Uint8List?> captureWebFrame() async {
  try {
    final video = web.document.querySelector('video') as web.HTMLVideoElement?;
    if (video == null) return null;

    final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    
    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    ctx.drawImage(video, 0, 0);
    
    // Convert to JPEG
    final dataUrl = canvas.toDataURL('image/jpeg', 0.8.toJS);
    final base64 = dataUrl.split(',')[1];
    
    return base64Decode(base64);
  } catch (e) {
    print('Web frame capture failed: $e');
    return null;
  }
}

import 'dart:async';
import 'dart:ui';
import 'dart:js_interop';
import 'package:face_recognition_kit/face_recognition_kit.dart';
import 'package:face_recognition_kit/src/engines/web/web_detector.dart';
import 'package:web/web.dart' as web;
import 'dart:convert';
import 'package:flutter/foundation.dart';
/// Actual web implementation of finding the video element and detecting faces.
Future<List<FaceData>> detectWebFaces(FaceDetectorInterface detector) async {
  final videoElement = web.document.querySelector('video') as web.HTMLVideoElement?;
  if (videoElement != null && detector is WebDetector) {
    return await detector.detectFromVideo(videoElement);
  }
  return [];
}

/// Captures a frame from the active video element and returns it as a Uint8List (JPEG).
/// If [cropBox] is provided, performs a crop on the hardware-accelerated canvas.
Future<Uint8List?> captureWebFrame({Rect? cropBox}) async {
  try {
    final video = web.document.querySelector('video') as web.HTMLVideoElement?;
    if (video == null) return null;

    final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
    
    // Default to full video resolution if no crop is provided
    double sx = 0, sy = 0, sw = video.videoWidth.toDouble(), sh = video.videoHeight.toDouble();
    double dx = 0, dy = 0, dw = sw, dh = sh;

    if (cropBox != null) {
      // Add a 20% margin around the face for better recognition/display
      const margin = 0.2;
      final mw = cropBox.width * margin;
      final mh = cropBox.height * margin;

      sx = (cropBox.left - mw).clamp(0, video.videoWidth.toDouble());
      sy = (cropBox.top - mh).clamp(0, video.videoHeight.toDouble());
      sw = (cropBox.width + (mw * 2)).clamp(0, video.videoWidth.toDouble() - sx);
      sh = (cropBox.height + (mh * 2)).clamp(0, video.videoHeight.toDouble() - sy);
      
      dw = sw;
      dh = sh;
    }

    canvas.width = dw.toInt();
    canvas.height = dh.toInt();
    
    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    
    // JS drawImage with 9 arguments: (image, sx, sy, sw, sh, dx, dy, dw, dh)
    ctx.drawImage(video, sx, sy, sw, sh, dx, dy, dw, dh);
    
    // Convert to JPEG
    final dataUrl = canvas.toDataURL('image/jpeg', 0.85.toJS);
    final base64 = dataUrl.split(',')[1];
    
    return base64Decode(base64);
  } catch (e) {
    debugPrint('Web frame capture/crop failed: $e');
    return null;
  }
}

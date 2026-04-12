import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/face_data.dart';

class FacePainter extends CustomPainter {
  final List<FaceData> faces;
  final Size imageSize;
  final int rotation;

  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / (kIsWeb ? imageSize.width : imageSize.height);
    final double scaleY = size.height / (kIsWeb ? imageSize.height : imageSize.width);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final landmarkPaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.fill;

    for (final face in faces) {
      final rect = _transformRect(face.boundingBox, size, scaleX, scaleY);
      
      // Select color based on status
      if (face.status == RecognitionStatus.recognized) {
        paint.color = Colors.blueAccent;
      } else if (face.status == RecognitionStatus.notRecognized) {
        paint.color = Colors.redAccent;
      } else {
        paint.color = Colors.greenAccent;
      }

      // Draw full box
      canvas.drawRect(rect, paint);

      // Draw Landmarks (Eyes, Nose, Mouth)
      for (final landmark in face.landmarks.values) {
        final pos = _transformPoint(landmark.position, size, scaleX, scaleY);
        canvas.drawCircle(pos, 3, landmarkPaint);
      }
    }
  }


  Offset _transformPoint(Offset point, Size size, double scaleX, double scaleY) {
    if (kIsWeb) {
      // Mirroring fix: Web front camera is mirrored by default
      return Offset(
        size.width - (point.dx * scaleX),
        point.dy * scaleY,
      );
    }
    return Offset(
      size.width - (point.dx * scaleX),
      point.dy * scaleY,
    );
  }


  Rect _transformRect(Rect rect, Size size, double scaleX, double scaleY) {
    if (kIsWeb) {
      // Mirroring fix: Web front camera is mirrored by default
      return Rect.fromLTRB(
        size.width - (rect.right * scaleX),
        rect.top * scaleY,
        size.width - (rect.left * scaleX),
        rect.bottom * scaleY,
      );
    }
    // Mobile mirroring/rotation logic
    return Rect.fromLTRB(
      size.width - (rect.right * scaleX),
      rect.top * scaleY,
      size.width - (rect.left * scaleX),
      rect.bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces;
  }
}

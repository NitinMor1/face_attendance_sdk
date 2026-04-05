import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'dart:ui';

class ImageUtils {
  /// Crops a face from a [CameraImage] based on the provided [boundingBox].
  static Uint8List? cropFace(CameraImage image, Rect boundingBox, int rotation) {
    try {
      img.Image? convertedImage;
      
      if (image.format.group == ImageFormatGroup.yuv420 || image.format.group == ImageFormatGroup.nv21) {
        convertedImage = _convertYUV420ToImage(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        convertedImage = _convertBGRA8888ToImage(image);
      }

      if (convertedImage == null) {
        debugPrint('Image conversion failed');
        return null;
      }

      // Rotate the image to match what ML Kit saw (Portrait)
      if (rotation == 90) {
        convertedImage = img.copyRotate(convertedImage, angle: 90);
      } else if (rotation == 270) {
        convertedImage = img.copyRotate(convertedImage, angle: 270);
      } else if (rotation == 180) {
        convertedImage = img.copyRotate(convertedImage, angle: 180);
      }
      
      final x = boundingBox.left.toInt().clamp(0, convertedImage.width);
      final y = boundingBox.top.toInt().clamp(0, convertedImage.height);
      final width = boundingBox.width.toInt().clamp(0, convertedImage.width - x);
      final height = boundingBox.height.toInt().clamp(0, convertedImage.height - y);

      if (width <= 0 || height <= 0) {
        debugPrint('Invalid crop dimensions: $width x $height');
        return null;
      }

      final cropped = img.copyCrop(convertedImage, x: x, y: y, width: width, height: height);
      return Uint8List.fromList(img.encodeJpg(cropped));
    } catch (e) {
      debugPrint('Error cropping face: $e');
      return null;
    }
  }

  static img.Image _convertYUV420ToImage(CameraImage image) {
    final width = image.width;
    final height = image.height;
    
    // Check if we have packed YUV (NV21/NV12) or separate planes
    if (image.planes.length == 1) {
      final bytes = image.planes[0].bytes;
      final img.Image result = img.Image(width: width, height: height);
      
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * width + x;
          final int uvIndex = width * height + (y ~/ 2) * width + (x & ~1);
          
          final int yp = bytes[yIndex];
          // NV21 is V, U, V, U...
          final int vp = bytes[uvIndex];
          final int up = bytes[uvIndex + 1];

          _setPixel(result, x, y, yp, up, vp);
        }
      }
      return result;
    } else {
      // Standard 3-plane YUV420
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      final img.Image result = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * yPlane.bytesPerRow + x;
          final int uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uPlane.bytesPerPixel!;

          final int yp = yPlane.bytes[yIndex];
          final int up = uPlane.bytes[uvIndex];
          final int vp = vPlane.bytes[uvIndex];

          _setPixel(result, x, y, yp, up, vp);
        }
      }
      return result;
    }
  }

  static void _setPixel(img.Image result, int x, int y, int yp, int up, int vp) {
    int r = (yp + 1.402 * (vp - 128)).toInt();
    int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128)).toInt();
    int b = (yp + 1.772 * (up - 128)).toInt();
    result.setPixelRgb(x, y, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
  }

  static img.Image _convertBGRA8888ToImage(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }
}

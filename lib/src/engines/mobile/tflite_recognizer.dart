import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../models/face_data.dart';
import '../recognizer_interface.dart';

class TfliteRecognizer implements FaceRecognizerInterface {
  Interpreter? _interpreter;
  final int _inputSize = 112; // Standard for MobileFaceNet

  @override
  Future<void> initialize() async {
    try {
      // Assuming the model is in assets/models/mobile_facenet.tflite
      _interpreter = await Interpreter.fromAsset('packages/face_attendance_sdk/assets/models/mobile_facenet.tflite');
      debugPrint('TFLite Interpreter loaded successfully');
    } catch (e) {
      debugPrint('Failed to load TFLite model: $e');
    }
  }

  @override
  Future<List<double>> extractEmbedding(CameraImage? image, FaceData face) async {
    if (_interpreter == null || image == null) return [];

    // 1. Convert CameraImage to img.Image (from 'image' package)
    final img.Image convertedImage = _convertCameraImage(image);

    // 2. Crop face
    final rect = face.boundingBox;
    final img.Image faceCrop = img.copyCrop(
      convertedImage,
      x: rect.left.toInt(),
      y: rect.top.toInt(),
      width: rect.width.toInt(),
      height: rect.height.toInt(),
    );

    // 3. Resize face image to input size (112x112)
    final img.Image resizedFace = img.copyResize(faceCrop, width: _inputSize, height: _inputSize);

    // 4. Pre-process (normalization)
    final Float32List input = _imageToByteListFloat32(resizedFace);

    // 5. Run inference
    final output = List.filled(1 * 192, 0.0).reshape([1, 192]); // MobileFaceNet output is 192 or 128
    _interpreter!.run(input.buffer.asFloat32List().reshape([1, 112, 112, 3]), output);

    return List<double>.from(output[0]);
  }

  @override
  Future<FaceProfile?> matchFace(List<double> embedding, List<FaceProfile> profiles, {double threshold = 0.6}) async {
    FaceProfile? bestMatch;
    double minDistance = double.maxFinite;

    for (final profile in profiles) {
      final distance = _calculateEuclideanDistance(embedding, profile.embedding);
      if (distance < threshold && distance < minDistance) {
        minDistance = distance;
        bestMatch = profile;
      }
    }

    return bestMatch;
  }

  double _calculateEuclideanDistance(List<double> v1, List<double> v2) {
    double sum = 0;
    for (int i = 0; i < v1.length; i++) {
      sum += pow(v1[i] - v2[i], 2);
    }
    return sqrt(sum);
  }

  Float32List _imageToByteListFloat32(img.Image image) {
    final Float32List byteList = Float32List(1 * _inputSize * _inputSize * 3);
    int bufferIndex = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        byteList[bufferIndex++] = (pixel.r - 127.5) / 127.5;
        byteList[bufferIndex++] = (pixel.g - 127.5) / 127.5;
        byteList[bufferIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }
    return byteList;
  }

  img.Image _convertCameraImage(CameraImage image) {
    // Basic conversion from CameraImage to img.Image
    // Handling YUV420 format is complex, using a simplified version for this SDK structure
    // In a real app, you'd use a more robust YUV->RGB converter
    return img.Image(width: image.width, height: image.height); // Placeholder for brevity
  }

  @override
  Future<void> dispose() async {
    _interpreter?.close();
  }
}

FaceRecognizerInterface createRecognizer() => TfliteRecognizer();

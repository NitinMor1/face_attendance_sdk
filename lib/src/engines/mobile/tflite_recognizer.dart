import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../models/face_data.dart';
import '../../utils/image_utils.dart';
import '../recognizer_interface.dart';

class TfliteRecognizer implements FaceRecognizerInterface {
  Interpreter? _interpreter;
  final int _inputSize = 112; // Standard for MobileFaceNet
  bool _isReady = false;
  String? _initError;

  @override
  bool get isReady => _isReady;

  @override
  String? get initializationError => _initError;

  @override
  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset('packages/face_recognition_kit/assets/models/mobile_facenet.tflite');
      _isReady = true;
      _initError = null;
      debugPrint('TFLite Interpreter loaded successfully: face_recognition_kit');
    } catch (e) {
      _isReady = false;
      _initError = 'Model initialization failed. Ensure mobile_facenet.tflite exists in assets/models/.';
      debugPrint('CRITICAL: Failed to load TFLite model from assets. $e');
    }
  }

  @override
  Future<List<double>> extractEmbedding(CameraImage? image, FaceData face, {int rotation = 0, bool flipHorizontal = false}) async {
    if (_interpreter == null || image == null) return [];

    // 1. Convert CameraImage to img.Image (RAW)
    img.Image convertedImage = _convertCameraImage(image);

    // 2. CROP FIRST using the raw bounding box
    // This is critical because the detector's coordinates match the raw frame.
    final rect = face.boundingBox;
    final double padW = rect.width * 0.1;
    final double padH = rect.height * 0.1;
    
    final int sx = (rect.left - padW).toInt().clamp(0, convertedImage.width);
    final int sy = (rect.top - padH).toInt().clamp(0, convertedImage.height);
    final int sw = (rect.width + 2 * padW).toInt().clamp(1, convertedImage.width - sx);
    final int sh = (rect.height + 2 * padH).toInt().clamp(1, convertedImage.height - sy);

    img.Image faceCrop = img.copyCrop(
      convertedImage,
      x: sx,
      y: sy,
      width: sw,
      height: sh,
    );

    // 3. ROTATE AND FLIP the small crop (Much more accurate and efficient)
    if (rotation != 0) {
      faceCrop = img.copyRotate(faceCrop, angle: rotation);
    }
    if (flipHorizontal) {
      faceCrop = img.copyFlip(faceCrop, direction: img.FlipDirection.horizontal);
    }

    // 4. Resize to AI input size (112x112)
    final img.Image resizedFace = img.copyResize(faceCrop, width: _inputSize, height: _inputSize);

    // 5. Pre-process (normalization)
    final Float32List input = _imageToByteListFloat32(resizedFace);

    // 6. Run inference
    final output = List.filled(1 * 192, 0.0).reshape([1, 192]);
    _interpreter!.run(input.buffer.asFloat32List().reshape([1, 112, 112, 3]), output);

    // 7. L2 Normalization (Crucial for distance stability)
    final List<double> rawResults = List<double>.from(output[0]);
    return _normalize(rawResults);
  }

  List<double> _normalize(List<double> v) {
    double sum = 0;
    for (final x in v) {
      sum += x * x;
    }
    final norm = sqrt(sum);
    if (norm == 0) return v;
    return v.map((x) => x / norm).toList();
  }

  @override
  Future<FaceProfile?> matchFace(List<double> embedding, List<FaceProfile> profiles, {double threshold = 0.58}) async {
    // ZERO-DISTANCE GUARD: If embeddings are empty due to missing model, never return a match.
    if (embedding.isEmpty || profiles.isEmpty) return null;

    FaceProfile? bestMatch;
    double minDistance = double.maxFinite;

    for (final profile in profiles) {
      // Safety check for individual profiles
      if (profile.embedding.isEmpty) continue;

      final distance = _calculateEuclideanDistance(embedding, profile.embedding);
      
      // Biometric Debug Logging: Helps developers fine-tune security
      debugPrint('Biometric comparison: ${profile.name} | Distance: ${distance.toStringAsFixed(3)}');

      if (distance < threshold && distance < minDistance) {
        minDistance = distance;
        bestMatch = profile;
      }
    }

    if (bestMatch != null) {
      debugPrint('MATCH CONFIRMED: ${bestMatch.name} (Dist: ${minDistance.toStringAsFixed(3)})');
    }

    return bestMatch;
  }

  double _calculateEuclideanDistance(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) {
      debugPrint('WARNING: Embedding length mismatch! v1=${v1.length}, v2=${v2.length}. Re-registration required.');
      return 10.0; // Fail distance
    }
    double sum = 0;
    for (int i = 0; i < v1.length; i++) {
      sum += pow(v1[i] - v2[i], 2);
    }
    return sqrt(sum);
  }

  Float32List _imageToByteListFloat32(img.Image image) {
    final Float32List byteList = Float32List(1 * _inputSize * _inputSize * 3);
    int bufferIndex = 0;
    
    // Some models expect BGR (like those trained on OpenCV defaults)
    // Most MobileFaceNet models are RGB (-1 to 1)
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        
        // Changed to BGR as many MobileFaceNet models on GitHub (like the one from MCarlomagno)
        // are converted from OpenCV/Python sources which use BGR order.
        byteList[bufferIndex++] = (pixel.b - 127.5) / 127.5;
        byteList[bufferIndex++] = (pixel.g - 127.5) / 127.5;
        byteList[bufferIndex++] = (pixel.r - 127.5) / 127.5;
      }
    }
    return byteList;
  }

  img.Image _convertCameraImage(CameraImage image) {
    if (image.format.group == ImageFormatGroup.yuv420 || image.format.group == ImageFormatGroup.nv21) {
      return ImageUtils.convertYUV420ToImage(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      return ImageUtils.convertBGRA8888ToImage(image);
    }
    // Fallback to empty if format is unsupported
    return img.Image(width: image.width, height: image.height);
  }

  @override
  Future<void> dispose() async {
    _interpreter?.close();
  }
}

FaceRecognizerInterface createRecognizer() => TfliteRecognizer();

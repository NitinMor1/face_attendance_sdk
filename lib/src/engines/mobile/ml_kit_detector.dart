
import 'package:camera/camera.dart';
import 'package:face_recognition_kit/face_recognition_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart' hide FaceLandmark;

class MlKitDetector implements FaceDetectorInterface {
  late FaceDetector _faceDetector;

  @override
  Future<void> initialize() async {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true, // Enable for verification
        enableClassification: true, // Needed for eye open probability
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  @override
  Future<List<FaceData>> detectFromImage(CameraImage image, int rotation) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final InputImageMetadata metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _getRotation(rotation),
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        // debugPrint('ML Kit: No faces detected');
      } else {
        debugPrint('ML Kit: Detected ${faces.length} faces');
      }

      return faces.map((face) {
        return FaceData(
          boundingBox: face.boundingBox,
          landmarks: _extractLandmarks(face),
          confidence: 0.99, // Static for UI proof
          headEulerAngleY: face.headEulerAngleY,
          headEulerAngleZ: face.headEulerAngleZ,
          leftEyeOpenProbability: face.leftEyeOpenProbability,
          rightEyeOpenProbability: face.rightEyeOpenProbability,
        );
      }).toList();
    } catch (e) {
      debugPrint('ML Kit Detection Error: $e');
      return [];
    }
  }

  Map<String, FaceLandmark> _extractLandmarks(Face face) {
    final Map<String, FaceLandmark> result = {};
    _addLandmark(result, face, FaceLandmarkType.leftEye, 'leftEye');
    _addLandmark(result, face, FaceLandmarkType.rightEye, 'rightEye');
    _addLandmark(result, face, FaceLandmarkType.noseBase, 'nose');
    _addLandmark(result, face, FaceLandmarkType.bottomMouth, 'mouth');
    return result;
  }

  void _addLandmark(Map<String, FaceLandmark> map, Face face, FaceLandmarkType type, String name) {
    final landmark = face.landmarks[type];
    if (landmark != null) {
      map[name] = FaceLandmark(
        type: name,
        position: Offset(landmark.position.x.toDouble(), landmark.position.y.toDouble()),
      );
    }
  }

  InputImageRotation _getRotation(int rotation) {
    switch (rotation) {
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return InputImageRotation.rotation0deg;
    }
  }

  @override
  Future<void> dispose() async {
    await _faceDetector.close();
  }
}

FaceDetectorInterface createDetector() => MlKitDetector();

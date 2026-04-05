import 'package:camera/camera.dart';
import '../models/face_data.dart';
import 'detector_interface.dart';

FaceDetectorInterface createDetector() => throw UnsupportedError(
      'Cannot create a detector without dart:html or dart:io',
    );

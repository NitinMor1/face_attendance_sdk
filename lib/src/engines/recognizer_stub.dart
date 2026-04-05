import 'recognizer_interface.dart';

FaceRecognizerInterface createRecognizer() => throw UnsupportedError(
      'Cannot create a recognizer without dart:html or dart:io',
    );

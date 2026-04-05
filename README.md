# Face Attendance SDK

A professional Flutter SDK for high-performance facial attendance systems. Optimized for collective environments like classrooms and workplaces, it features real-time multi-face detection, seamless biometric enrollment, and an advanced analytics dashboard.

## Features

- 📸 **Real-time Detection**: High-speed face detection on Mobile (ML Kit) and Web (MediaPipe).
- 🧬 **Biometric Extraction**: Generates unique face embeddings for secure, non-image storage of identities.
- 🎓 **Classroom Optimized**: Handles multiple faces simultaneously for rapid roll calls.
- 🏢 **Role-Based Portals**: Built-in support for Faculty Dashboards and Classroom Terminals.
- 📊 **Academic Analytics**: Tracks weekly trends and participation leaderboards.
- 🌐 **True Web Support**: Native web frame capture via JS-Interop and HTML5 Canvas.

## Getting Started

### Prerequisites

- Flutter SDK 3.10.0 or higher.
- `camera` and `google_mlkit_face_detection` (Mobile).
- `@mediapipe/tasks-vision` (Web - included via index.html).

### Installation

Add `face_attendance_sdk` to your `pubspec.yaml`:

```yaml
dependencies:
  face_attendance_sdk: ^1.0.0
```

## Usage

### 1. Simple Face Scanner

```dart
import 'package:face_attendance_sdk/face_attendance_sdk.dart';

FaceScannerView(
  detector: FaceDetectorInterface(),
  recognizer: FaceRecognizerInterface(),
  onFaceDetected: (face, image) {
    print('Face found with confidence: ${face.confidence}');
  },
)
```

### 2. Full Attendance System

Check the `/example` folder for a complete **College Attendance Portal** implementation including:
- Student Registration.
- Multi-face Roll Call.
- Weekly Trends & Analytical Dashboards.

## Additional information

- **Repository**: [https://github.com/NitinMor1/face_attendance_sdk](https://github.com/NitinMor1/face_attendance_sdk)
- **Issues**: Please file bug reports or feature requests at our [issue tracker](https://github.com/NitinMor1/face_attendance_sdk/issues).
- **Contributing**: All contributions are welcome! Submit a Pull Request to help improve the SDK.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

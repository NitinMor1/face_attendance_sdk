# Face Recognition Kit

[![Pub Version](https://img.shields.io/pub/v/face_recognition_kit?color=blue&logo=dart)](https://pub.dev/packages/face_recognition_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20web-blue)](https://pub.dev/packages/face_recognition_kit)

A professional-grade Flutter SDK for high-performance facial recognition. Designed for biometric security, attendance systems, and intelligent kiosks, it offers a seamless experience across **Android, iOS, and Web**.

## 🌟 Key Features

*   🚀 **Real-Time Detection**: High-speed multi-face detection using Google ML Kit (Mobile) and MediaPipe (Web).
*   🧬 **Biometric Extraction**: Generate unique 128D face embeddings for secure identity management.
*   🎭 **Adaptive UI**: Built-in `FaceScannerView` with customizable bounding boxes and recognition feedback.
*   🌐 **Unified Web Support**: Native web frame capture via JS-Interop—no extra plugins required for browser use.
*   📊 **Analytics Optimized**: Integrated data structures for tracking recognition history and performance metrics.
*   🎨 **Rich Feedback**: Automated success dialogs and custom painters for localized UX.

## 📱 Platform Support

| Feature | Android | iOS | Web |
|:--- |:---:|:---:|:---:|
| Face Detection | ✅ | ✅ | ✅ |
| Recognition / Matching | ✅ | ✅ | ✅ |
| Camera Support | ✅ | ✅ | ✅ |
| Background Processing | ✅ | ✅ | ✅ |

## 🚀 Getting Started

### 1. Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  face_recognition_kit: ^1.1.0
```

### 2. Platform Setup

#### Android
Add camera permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

#### iOS
Add permissions to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access for face recognition.</string>
```

#### Web (MediaPipe Setup)
Add the following scripts to your `web/index.html`:
```html
<script src="https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.3/wasm/vision_bundle.js"></script>
```

## 🛠️ Usage

### Core Scanning Experience

```dart
import 'package:face_recognition_kit/face_recognition_kit.dart';

FaceScannerView(
  detector: FaceDetectorInterface(),
  recognizer: FaceRecognizerInterface(),
  profiles: myRegisteredProfiles,
  onFaceRecognized: (profile, image) {
    print('Identity Confirmed: ${profile.name}');
  },
  onFaceDetected: (face, image) {
    print('Unknown Face Detected');
  },
)
```

## 📂 Example Project
Explore the `/example` folder for a complete **Face SDK Showcase** including:
- **Identity Registry**: Managing biometric profiles.
- **Metrics Dashboard**: Performance and recognition logs.
- **Kiosk Interface**: A full-screen production-ready scanning mode.

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

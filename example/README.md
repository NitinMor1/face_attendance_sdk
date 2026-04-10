# Face Recognition Kit Showcase

A professional, high-performance demonstration of the **[Face Recognition Kit](https://pub.dev/packages/face_recognition_kit)** package. This application serves as a comprehensive feature-explorer for identifying and managing biometric identities across Mobile and Web platforms.

## Core Capabilities Demonstrated

- 🛡️ **Biometric Registry**: A streamlined interface for enrolling new identities with advanced embedding extraction.
- 🎯 **Neural Scanner**: real-time, multi-face detection and identification using state-of-the-art AI engines.
- 📊 **Analytics Dashboard**: Monitoring SDK event streams, match confidence, and registry health.
- 🌫️ **Glassmorphism UI**: A premium user interface design using modern Flutter aesthetics like `BackdropFilter` and custom gradients.
- 🌐 **True Cross-Platform**: Identical biometric logic running on **Android, iOS, and Web** (via MediaPipe WASM).

## Quick Start

1. **Clone & Explore**:
   ```bash
   git clone https://github.com/NitinMor1/face_recognition_kit.git
   cd face_recognition_kit/example
   ```

2. **Setup Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Deploy to Web**:
   ```bash
   flutter run -d chrome
   ```

4. **Deploy to Mobile**:
   ```bash
   flutter run
   ```

## Implementation Guide

This example is structured to be a reference for developers:
- `lib/core/`: State management via `ToolkitStore` and generic data models (`SDKIdentity`, `RecognitionEvent`).
- `lib/ui/`: Tab-based architecture demonstrating enrollment, scanning, and metrics.
- `web/`: Custom configuration for handling large-model biometric detection on the web.

## Platform Support

| Feature | Android | iOS | Web |
|---------|---------|-----|-----|
| Face Detection | ✅ | ✅ | ✅ |
| Face Recognition | ✅ | ✅ | ✅ |
| Custom UI Overlays | ✅ | ✅ | ✅ |
| Backdrop Blur | ✅ | ✅ | ✅ |

---
Powered by **Face Recognition Kit v1.1.0**

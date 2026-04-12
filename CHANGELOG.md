## 1.2.0

- **Real-Time Guidance UI**: Introduced smart biometric enrollment messages (e.g., "Look straight", "Move closer").
- **Neural Engine Diagnostics**: Added automatic detection for missing/corrupted AI models with actionable UI feedback.
- **Precision Alignment Engine**: Optimized "Crop-First" strategy to eliminate coordinate drift and improve accuracy.
- **192D Biometric Distillation**: Calibrated the engine for high-dimensional feature extraction.
- **BGR Color Support**: Updated neural input processing to support BGR channel order (standard for converted CV2/InsightFace models).
- **Tuned Security Threshold**: Calibrated standard matching threshold to **0.58** for optimal classroom/office usage.
- **Documentation Overhaul**: Complete professional README upgrade with technical architecture and implementation guides.

## 1.1.0

- **Package Rename**: Renamed officially to `face_recognition_kit`.
- **SDK Precision Overhaul**: 
  - Refactored `FaceScannerView` with `FittedBox` for pinpoint coordinate alignment.
  - Fixed "flipped" mirroring issue on Web front cameras.
- **Biometric Cropping**: 
  - Hardware-accelerated Canvas cropping for Web.
  - Robust face-only capture mode for Mobile.
- **Improved Scanner Intelligence**: 
  - **Single-Face Mode**: Optimized engine to focus on one subject.
  - **Status-Aware Dialogs**: Confirmation pop-ups now trigger only on successful matches.
- **Showcase Example**: Overhauled the example app with **Identity Registry**, **Metrics Dashboard**, and a **Live Neural Scanner**.
- **Branding & API**: Renamed all core classes from "Attendance" to "Recognition" (Dialogs, Status, etc.).
- **Dependency Clean-up**: Updated all plugins to latest versions and optimized Web registration.

## 1.0.0+1

- **Initial Professional Release**: Full Facial Attendance SDK with College Dashboard.
- **Role-Based Portals**: Added "Faculty Dashboard" and "Classroom Terminal" modes.
- **Automated Enrollment**: New confirmation dialog with biometric signature extraction.
- **Web Recognition Support**: Integrated MediaPipe Vision tasks via ES Modules and JS-Interop.
- **Analytics Hub**: Weekly trends and participation analytics.

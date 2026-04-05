# Face Attendance SDK Example

This repository contains a full-featured demonstration of the **Face Attendance SDK** implemented as a **College Attendance Portal**. 

## Features Demonstrated

- 🏫 **Role-Based Portals**: Choose between "Faculty Dashboard" for analytics or "Classroom Terminal" for student check-ins.
- 📸 **Automated Enrollment**: A professional flow for capturing student faces and generating biometric signatures.
- 🎓 **Multi-Face Roll Call**: Rapidly detect and identify multiple students in a single camera view.
- 📊 **Real-time Analytics**: High-end dashboard with weekly trends and participation leaderboards.
- 🌐 **Web & Mobile Support**: Responsive design that works seamlessly on browsers (via JS-Interop) and native Android/iOS.

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/NitinMor1/face_attendance_sdk.git
   cd face_attendance_sdk/example
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run for Web**:
   ```bash
   flutter run -d chrome
   ```
   *Note: For the web version, ensure you have an internet connection to load the MediaPipe Vision WASM assets.*

4. **Run for Mobile**:
   ```bash
   flutter run
   ```

## Project Structure

- `lib/core/`: Contains the `AttendanceStore` (State management) and data models.
- `lib/ui/`: All professional tab implementations (Dashboard, Enrollment, Attendance).
- `web/index.html`: Custom MediaPipe integration for ultra-fast web face detection.

## License

This example is licensed under the same MIT License as the core SDK.

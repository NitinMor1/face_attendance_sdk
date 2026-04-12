import 'package:flutter/material.dart';

/// Configuration options for real-time face guidance messaging.
class FaceGuidanceOptions {
  /// Whether to enable real-time guidance messages.
  final bool enabled;

  /// Message to show when the face is too far to the left.
  final String turnRightMessage;

  /// Message to show when the face is too far to the right.
  final String turnLeftMessage;

  /// Message to show when eyes are closed.
  final String openEyesMessage;

  /// Message to show when the face is not centered or too far.
  final String moveCloserMessage;

  /// Message to show when the environment is too dark.
  final String poorLightingMessage;

  /// Message to show when no face is detected.
  final String noFaceMessage;

  /// Message to show when the face is correctly positioned.
  final String stayStillMessage;

  /// Sensitivity threshold for head rotation (Euler Y).
  /// Typical values are between 10.0 and 40.0.
  final double rotationThreshold;

  /// Sensitivity threshold for eye-open probability (0.0 to 1.0).
  /// Typical value is 0.5.
  final double eyeOpenThreshold;

  /// Sensitivity threshold for brightness (0-255).
  /// Typical value is 40.0.
  final double brightnessThreshold;

  /// Custom builder to allow users to provide their own guidance UI.
  final Widget Function(BuildContext context, String message)? guidanceBuilder;

  const FaceGuidanceOptions({
    this.enabled = false,
    this.turnRightMessage = 'Turn head slightly right',
    this.turnLeftMessage = 'Turn head slightly left',
    this.openEyesMessage = 'Please open your eyes',
    this.moveCloserMessage = 'Move closer and center your face',
    this.poorLightingMessage = 'Improve lighting',
    this.noFaceMessage = 'Align your face',
    this.stayStillMessage = 'Stay still...',
    this.rotationThreshold = 20.0,
    this.eyeOpenThreshold = 0.5,
    this.brightnessThreshold = 40.0,
    this.guidanceBuilder,
  });
}

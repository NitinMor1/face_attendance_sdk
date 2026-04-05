import 'package:flutter/material.dart';

/// Configuration options for the built-in success dialog.
class AttendanceDialogOptions {
  /// The title shown when a face is first detected.
  final String title;

  /// The title shown after a person is successfully recognized.
  final String successTitle;

  /// The message shown under the title. {name} will be replaced by the user's name.
  final String welcomeMessage;

  /// The text for the confirmation button.
  final String confirmButtonText;

  /// The duration the dialog stays open after success before auto-popping.
  final Duration displayDuration;

  /// Custom background gradient colors.
  final List<Color>? backgroundColors;

  /// Primary color for icons and buttons.
  final Color primaryColor;

  const AttendanceDialogOptions({
    this.title = 'Face Detected',
    this.successTitle = 'Attendance Marked!',
    this.welcomeMessage = 'Welcome, {name}',
    this.confirmButtonText = 'Confirm',
    this.displayDuration = const Duration(seconds: 5),
    this.backgroundColors,
    this.primaryColor = Colors.deepPurple,
  });
}

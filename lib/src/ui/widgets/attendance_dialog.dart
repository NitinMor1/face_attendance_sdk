import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/dialog_options.dart';

class AttendanceDialog extends StatelessWidget {
  final Uint8List faceImage;
  final String? name;
  final AttendanceDialogOptions options;
  final VoidCallback onConfirm;

  const AttendanceDialog({
    super.key,
    required this.faceImage,
    required this.options,
    required this.onConfirm,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    final isRecognized = name != null;
    final primaryColor = isRecognized ? Colors.green : options.primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: options.backgroundColors ?? 
              [Colors.white, primaryColor.withValues(alpha: 0.05)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRecognized ? Icons.check_circle : Icons.face,
              color: primaryColor,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              isRecognized ? options.successTitle : options.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: faceImage.isNotEmpty 
                  ? Image.memory(
                      faceImage,
                      width: 160,
                      height: 160,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 160,
                      height: 160,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.person, size: 80, color: Colors.grey),
                    ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isRecognized 
                ? options.welcomeMessage.replaceAll('{name}', name!) 
                : 'Verifying identity...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isRecognized)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onConfirm,
                child: Text(
                  options.confirmButtonText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

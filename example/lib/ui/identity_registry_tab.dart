import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:face_recognition_kit/face_recognition_kit.dart';
import '../core/toolkit_store.dart';
import '../core/models.dart';

class IdentityRegistryTab extends StatefulWidget {
  final FaceDetectorInterface detector;
  final FaceRecognizerInterface recognizer;

  const IdentityRegistryTab({
    super.key,
    required this.detector,
    required this.recognizer,
  });

  @override
  State<IdentityRegistryTab> createState() => _IdentityRegistryTabState();
}

class _IdentityRegistryTabState extends State<IdentityRegistryTab> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _groupController = TextEditingController(text: 'General');
  
  bool _isScanning = false;
  List<double>? _capturedEmbedding;
  Uint8List? _capturedImage;
  String? _captureFeedback;

  void _onFaceCaptured(FaceData face, Uint8List image) async {
    if (_capturedEmbedding != null || !mounted || !_isScanning) return; 

    // BIOMETRIC QUALITY GATE FOR ENROLLMENT:
    // 1. Eyes must be open
    final eyesOpen = (face.leftEyeOpenProbability ?? 0) > 0.4 && 
                      (face.rightEyeOpenProbability ?? 0) > 0.4;
    
    // 2. Head must be centered (Euler angle Y/Z < 15 degrees) - LOOSENED for better UX
    final headCentered = (face.headEulerAngleY ?? 0).abs() < 15 && 
                          (face.headEulerAngleZ ?? 0).abs() < 15;
    
    // 3. Size/Distance check
    final isGoodDistance = face.boundingBox.width > 80;

    String? feedback;
    if (widget.recognizer.initializationError != null) {
      feedback = 'AI Error: Model file missing or corrupted';
    } else if (face.embedding == null || face.embedding!.isEmpty) {
      feedback = 'Initializing AI Model...';
    } else if (!isGoodDistance) {
      feedback = 'Move closer to the camera';
    } else if (!headCentered) {
      feedback = 'Look straight at the camera';
    } else if (!eyesOpen) {
      feedback = 'Ensure eyes are clearly visible';
    }

    if (feedback != null) {
      if (mounted) setState(() => _captureFeedback = feedback);
      return; 
    }

    // Success! Capture conditions met. Clear feedback.
    if (mounted) setState(() => _captureFeedback = null);

    // Success! Capture conditions met.
    setState(() => _isScanning = false);

    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('Confirm Biometric Capture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(image, height: 200, width: 200, fit: BoxFit.cover),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 14,
                    child: Icon(Icons.check, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'High-quality capture detected!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your biometrics were captured under perfect conditions. Proceed with enrollment?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('RETAKE'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ENROLL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _capturedEmbedding = face.embedding;
        _capturedImage = image;
      });
    } else {
      setState(() => _isScanning = true);
    }
  }

  Future<void> _enrollIdentity() async {
    if (_idController.text.isEmpty || _nameController.text.isEmpty || _capturedEmbedding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all identification fields.')),
      );
      return;
    }

    final identity = SDKIdentity(
      id: _idController.text,
      name: _nameController.text,
      group: _groupController.text,
      embedding: _capturedEmbedding!,
    );

    await context.read<ToolkitStore>().addIdentity(identity);
    _resetForm();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Identity Enrolled Successfully!'),
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _idController.clear();
      _nameController.clear();
      _groupController.text = 'General';
      _capturedEmbedding = null;
      _capturedImage = null;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add, color: Colors.indigo),
              ),
              const SizedBox(width: 12),
              const Text(
                'Biometric Enrollment',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Add unique identities to the SDK registry.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          
          if (_isScanning)
            _buildScannerSection()
          else
            _buildEnrollmentForm(),
          
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: (_isScanning || _capturedEmbedding == null) ? null : _enrollIdentity,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
              backgroundColor: Colors.indigo.shade900,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text(
              'FINALIZE ENROLLMENT',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentForm() {
    return Column(
      children: [
        _buildInputField(_idController, 'Identification (e.g. Serial #)', Icons.badge_outlined),
        const SizedBox(height: 20),
        _buildInputField(_nameController, 'Display Name', Icons.person_outline),
        const SizedBox(height: 20),
        _buildInputField(_groupController, 'Category Group', Icons.group_work_outlined),
        const SizedBox(height: 32),
        _buildVisualCaptureButton(),
      ],
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildVisualCaptureButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_capturedImage != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(_capturedImage!, height: 160, width: 160, fit: BoxFit.cover),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _capturedImage = null;
                    _capturedEmbedding = null;
                  }),
                  icon: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ],
            )
          else
            const Icon(Icons.add_a_photo_outlined, size: 64, color: Colors.indigo),
          
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => setState(() => _isScanning = true),
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(_capturedEmbedding != null ? 'UPDATE SCAN' : 'CAPTURE FACE DATA'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerSection() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                FaceScannerView(
                  detector: widget.detector,
                  recognizer: widget.recognizer,
                  onFaceDetected: _onFaceCaptured,
                  enableDefaultDialog: false,
                ),
                if (_captureFeedback != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _captureFeedback!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () => setState(() => _isScanning = false),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('CANCEL SCAN'),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }
}

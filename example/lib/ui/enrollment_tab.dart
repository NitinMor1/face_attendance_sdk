import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:face_recognition_kit/face_recognition_kit.dart';
import '../core/attendance_store.dart';
import '../core/models.dart';

class EnrollmentTab extends StatefulWidget {
  final FaceDetectorInterface detector;
  final FaceRecognizerInterface recognizer;

  const EnrollmentTab({
    super.key,
    required this.detector,
    required this.recognizer,
  });

  @override
  State<EnrollmentTab> createState() => _EnrollmentTabState();
}

class _EnrollmentTabState extends State<EnrollmentTab> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isScanning = false;
  List<double>? _capturedEmbedding;
  Uint8List? _capturedImage;

  void _onFaceCaptured(FaceData face, Uint8List image) async {
    if (_capturedEmbedding != null) return; 

    final confidence = face.confidence ?? 0.0;
    if (face.embedding != null && confidence > 0.6) {
      setState(() => _isScanning = false);

      bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Face Capture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.memory(image, height: 200, width: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 15),
              const Text('Use this photo for registration?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('RETAKE'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('CONFIRM'),
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
  }

  Future<void> _saveUser() async {
    if (_idController.text.isEmpty || _nameController.text.isEmpty || _capturedEmbedding == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing details!')));
      return;
    }

    final user = AppUser(
      id: _idController.text,
      name: _nameController.text,
      embedding: _capturedEmbedding!,
    );

    await context.read<AttendanceStore>().addUser(user);
    _resetForm();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Successful!')));
    }
  }

  void _resetForm() {
    setState(() {
      _idController.clear();
      _nameController.clear();
      _capturedEmbedding = null;
      _capturedImage = null;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Register New Face', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          
          if (_isScanning)
            _buildScannerView()
          else
            _buildForm(),
          
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: (_isScanning || _capturedEmbedding == null) ? null : _saveUser,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 60),
              backgroundColor: Colors.indigo.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('SUBMIT REGISTRATION', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildTextField(_idController, 'User ID / Employee No'),
        const SizedBox(height: 16),
        _buildTextField(_nameController, 'Display Name'),
        const SizedBox(height: 30),
        _buildCaptureSection(),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildCaptureSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        children: [
          if (_capturedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.memory(_capturedImage!, height: 160, width: 160, fit: BoxFit.cover),
            )
          else
            const Icon(Icons.face_retouching_natural, size: 80, color: Colors.blue),
          
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => setState(() => _isScanning = true),
            icon: const Icon(Icons.camera_alt),
            label: Text(_capturedEmbedding != null ? 'Retake Photo' : 'START CAPTURE'),
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: FaceScannerView(
          detector: widget.detector,
          recognizer: widget.recognizer,
          onFaceDetected: _onFaceCaptured,
          enableDefaultDialog: false,
        ),
      ),
    );
  }
}

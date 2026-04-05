import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:face_attendance_sdk/face_attendance_sdk.dart';
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
  final _deptController = TextEditingController();
  UserRole _selectedRole = UserRole.student;
  
  bool _isScanning = false;
  List<double>? _capturedEmbedding;
  Uint8List? _capturedImage;

  void _onFaceCaptured(FaceData face, Uint8List image) async {
    if (_capturedEmbedding != null) return; 

    final confidence = face.confidence ?? 0.0;
    final hasEmbedding = face.embedding != null && face.embedding!.isNotEmpty;

    if (hasEmbedding && confidence > 0.6) {
      debugPrint('Face detected with confidence: $confidence');
      
      // Temporary state to show dialog
      setState(() {
        _isScanning = false;
      });

      bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Text('Confirm Biometric Capture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Is this photo clear for registration?'),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.memory(image, height: 200, width: 200, fit: BoxFit.cover),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('RETAKE', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white),
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
        // Auto-submit after confirmation
        await _saveUser();
      } else {
        setState(() {
          _isScanning = true; // Restart scanner
        });
      }
    }
  }

  Future<void> _saveUser() async {
    if (_idController.text.isEmpty || _nameController.text.isEmpty || _capturedEmbedding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing Details or Face Capture!')),
      );
      return;
    }

    final user = AppUser(
      id: _idController.text,
      name: _nameController.text,
      department: _deptController.text.isEmpty ? 'General' : _deptController.text,
      role: _selectedRole,
      embedding: _capturedEmbedding!,
    );

    await context.read<AttendanceStore>().addUser(user);
    
    if (mounted) {
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student/Faculty Registered Successfully!')),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _idController.clear();
      _nameController.clear();
      _deptController.clear();
      _capturedEmbedding = null;
      _capturedImage = null;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enrollment System',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Register a student or faculty member for biometric classroom attendance.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          
          if (_isScanning)
            _buildScannerSection()
          else
            _buildFormSection(),
          
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: (_isScanning || _capturedEmbedding == null) ? null : _saveUser,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 60),
              backgroundColor: Colors.blue.shade900,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              _capturedEmbedding == null ? 'CAPTURE FACE FIRST' : 'SUBMIT REGISTRATION',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      children: [
        _buildTextField(_idController, 'Roll No / Employee ID', Icons.badge_outlined),
        const SizedBox(height: 16),
        _buildTextField(_nameController, 'Full Name', Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField(_deptController, 'Department (e.g. CS, ME)', Icons.work_outline),
        const SizedBox(height: 16),
        
        _buildRoleSelection(),
        const SizedBox(height: 30),
        
        _buildCapturePreview(),
      ],
    );
  }

  Widget _buildRoleSelection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UserRole>(
          value: _selectedRole,
          isExpanded: true,
          items: UserRole.values.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role.name.toUpperCase()),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedRole = val!),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildCapturePreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          if (_capturedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.memory(_capturedImage!, height: 180, width: 180, fit: BoxFit.cover),
            )
          else
            const Icon(Icons.account_circle, size: 80, color: Colors.blue),
          
          const SizedBox(height: 20),
          Text(
            _capturedEmbedding != null ? 'Face Signature Locked' : 'Biometric Capture Required',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: () => setState(() => _isScanning = true),
            icon: Icon(_capturedEmbedding != null ? Icons.refresh : Icons.camera_alt),
            label: Text(_capturedEmbedding != null ? 'Retake Biometrics' : 'START CAPTURE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            child: FaceScannerView(
              detector: widget.detector,
              recognizer: widget.recognizer,
              onFaceDetected: _onFaceCaptured,
              enableDefaultDialog: false, 
            ),
          ),
        ),
        const SizedBox(height: 15),
        TextButton(
          onPressed: () => setState(() => _isScanning = false),
          child: const Text('CANCEL CAPTURE', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

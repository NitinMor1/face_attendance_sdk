import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:face_attendance_sdk/face_attendance_sdk.dart';
import '../core/attendance_store.dart';
import '../core/models.dart';

class AttendanceTab extends StatefulWidget {
  final FaceDetectorInterface detector;
  final FaceRecognizerInterface recognizer;

  const AttendanceTab({
    super.key,
    required this.detector,
    required this.recognizer,
  });

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  final List<String> _recentlyMarked = [];

  void _onFaceRecognized(FaceProfile profile, dynamic image) {
    final store = context.read<AttendanceStore>();
    try {
      final user = store.users.firstWhere((u) => u.id == profile.id);
      store.markAttendance(user);
      
      // Add to session list if not already there
      if (!_recentlyMarked.contains(user.name)) {
        setState(() {
          _recentlyMarked.insert(0, user.name);
          if (_recentlyMarked.length > 5) _recentlyMarked.removeLast();
        });
      }
    } catch (e) {
      debugPrint('Error marking attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AttendanceStore>();
    final profiles = store.users.map((u) => FaceProfile(
      id: u.id,
      name: u.name,
      embedding: u.embedding,
    )).toList();

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FaceScannerView(
                    detector: widget.detector,
                    recognizer: widget.recognizer,
                    profiles: profiles,
                    enableDefaultDialog: false, // NO blocking dialog for classroom mode
                    onFaceRecognized: _onFaceRecognized,
                  ),
                  _buildOverlayInfo(),
                  _buildSessionList(),
                ],
              ),
            ),
          ),
        ),
        _buildInstructionPanel(store),
      ],
    );
  }

  Widget _buildOverlayInfo() {
    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade900.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.room_outlined, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'CLASSROOM SCANNER',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList() {
    if (_recentlyMarked.isEmpty) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _recentlyMarked.map((name) => Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Present: $name',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildInstructionPanel(AttendanceStore store) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic Roll Call',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Keep student faces visible to the camera. The system will automatically detect and mark them present in the register.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleStat('Registered Students', store.totalStudents.toString()),
              _buildSimpleStat('Currently Marked', store.studentsPresentToday.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
      ],
    );
  }
}

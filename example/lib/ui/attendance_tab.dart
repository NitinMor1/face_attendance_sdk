import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:face_recognition_kit/face_recognition_kit.dart';
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
  AttendanceType _selectedType = AttendanceType.checkIn;
  final List<String> _recentlyMarked = [];

  void _onFaceRecognized(FaceProfile profile, dynamic image) {
    final store = context.read<AttendanceStore>();
    try {
      final user = store.users.firstWhere((u) => u.id == profile.id);
      store.markAttendance(user, _selectedType);
      
      final msg = '${_selectedType == AttendanceType.checkIn ? 'Check-In' : 'Check-Out'}: ${user.name}';
      if (!_recentlyMarked.contains(msg)) {
        setState(() {
          _recentlyMarked.insert(0, msg);
          if (_recentlyMarked.length > 5) _recentlyMarked.removeLast();
        });
      }
    } catch (e) {
      debugPrint('Recognition error: $e');
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
        _buildTypeSelector(),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FaceScannerView(
                    detector: widget.detector,
                    recognizer: widget.recognizer,
                    profiles: profiles,
                    enableDefaultDialog: false, // NO blocking dialog
                    onFaceRecognized: _onFaceRecognized,
                  ),
                  _buildStatusOverlay(),
                  _buildRecentLogs(),
                ],
              ),
            ),
          ),
        ),
        _buildStatsPanel(store),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SegmentedButton<AttendanceType>(
        segments: const [
          ButtonSegment(value: AttendanceType.checkIn, label: Text('Check-In'), icon: Icon(Icons.login)),
          ButtonSegment(value: AttendanceType.checkOut, label: Text('Check-Out'), icon: Icon(Icons.logout)),
        ],
        selected: {_selectedType},
        onSelectionChanged: (val) => setState(() => _selectedType = val.first),
      ),
    );
  }

  Widget _buildStatusOverlay() {
    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade900.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sensors, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'SCANNING FOR ${_selectedType.name.toUpperCase()}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLogs() {
    if (_recentlyMarked.isEmpty) return const SizedBox.shrink();
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _recentlyMarked.map((msg) => Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )).toList(),
      ),
    );
  }

  Widget _buildStatsPanel(AttendanceStore store) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSimpleStat('Registered Users', '${store.users.length}'),
          _buildSimpleStat('Session Logs', '${store.records.length}'),
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

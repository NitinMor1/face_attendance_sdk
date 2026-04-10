import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:face_recognition_kit/face_recognition_kit.dart';
import '../core/toolkit_store.dart';
import '../core/models.dart';

class RecognitionScannerTab extends StatefulWidget {
  final FaceDetectorInterface detector;
  final FaceRecognizerInterface recognizer;

  const RecognitionScannerTab({
    super.key,
    required this.detector,
    required this.recognizer,
  });

  @override
  State<RecognitionScannerTab> createState() => _RecognitionScannerTabState();
}

class _RecognitionScannerTabState extends State<RecognitionScannerTab> {
  final List<String> _recentMatches = [];
  bool _showMesh = true;

  void _onFaceRecognized(FaceProfile profile, Uint8List image) {
    final store = context.read<ToolkitStore>();
    
    // Log the event
    store.logEvent(RecognitionEvent(
      identityId: profile.id,
      identityName: profile.name,
      category: IdentityCategory.enrolled,
      timestamp: DateTime.now(),
      type: EventType.identification,
      confidence: 0.98, // In a real app, this comes from the recognizer
    ));

    final msg = '[Match] ${profile.name}';
    if (!_recentMatches.contains(msg)) {
      setState(() {
        _recentMatches.insert(0, msg);
        if (_recentMatches.length > 3) _recentMatches.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ToolkitStore>();
    final profiles = store.identities.map((i) => FaceProfile(
      id: i.id,
      name: i.name,
      embedding: i.embedding,
    )).toList();

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FaceScannerView(
                    detector: widget.detector,
                    recognizer: widget.recognizer,
                    profiles: profiles,
                    enableDefaultDialog: false, 
                    captureOnlyFace: true, // HIGHLIGHT: This now returns high-quality crops
                    dialogOptions: const RecognitionDialogOptions(
                      title: 'IDENTITY CONFIRMED',
                      confirmButtonText: 'CLOSE',
                    ),
                    onFaceRecognized: _onFaceRecognized,
                  ),
                  _buildLiveOverlay(),
                  _buildMatchFeed(),
                ],
              ),
            ),
          ),
        ),
        _buildRegistryPreview(store),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Recognition',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Running Neural Engines...',
                style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Switch(
            value: _showMesh,
            onChanged: (val) => setState(() => _showMesh = val),
            activeThumbColor: Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveOverlay() {
    return Positioned(
      top: 20,
      left: 20,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                children: [
                  Icon(Icons.radar, color: Colors.greenAccent, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'BIO-SCAN ACTIVE',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildMatchFeed() {
    if (_recentMatches.isEmpty) return const SizedBox.shrink();
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _recentMatches.map((msg) => Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.indigo.shade900.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 12),
              Text(
                msg,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildRegistryPreview(ToolkitStore store) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMiniStat('SDK IDENTITY REGISTRY', '${store.identities.length} Profiles'),
          _buildMiniStat('TOTAL EVENTS', '${store.events.length} Logs'),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
      ],
    );
  }
}

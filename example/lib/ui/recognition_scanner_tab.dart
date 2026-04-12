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
  bool _guidanceEnabled = true;
  double _cropPadding = 0.2;

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
                    captureOnlyFace: true,
                    cropPadding: _cropPadding,
                    guidanceOptions: FaceGuidanceOptions(
                      enabled: _guidanceEnabled,
                      stayStillMessage: 'Perfect! Stay still...',
                    ),
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
                'Intelligent Scanner',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Neural Guidance Active',
                style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.settings_overscan, color: _cropPadding > 0 ? Colors.indigo : Colors.grey),
                onPressed: _showSettingsBottomSheet,
                tooltip: 'Dynamic Crop Settings',
              ),
              Switch(
                value: _guidanceEnabled,
                onChanged: (val) => setState(() => _guidanceEnabled = val),
                activeThumbColor: Colors.indigo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SDK Showcase Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dynamic Crop Padding', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text('${(_cropPadding * 100).toInt()}%', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _cropPadding,
                min: 0.0,
                max: 1.0,
                activeColor: Colors.indigo,
                onChanged: (val) {
                  setModalState(() => _cropPadding = val);
                  setState(() => _cropPadding = val);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Increases the margin around the detected face in the captured output.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Configuration'),
                ),
              ),
            ],
          ),
        ),
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

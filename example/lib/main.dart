import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:face_recognition_kit/face_recognition_kit.dart';

import 'core/toolkit_store.dart';
import 'ui/toolkit_home_screen.dart';
import 'ui/identity_registry_tab.dart';
import 'ui/recognition_scanner_tab.dart';
import 'ui/metrics_dashboard_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = ToolkitStore();
  await store.loadData().timeout(const Duration(seconds: 3), onTimeout: () {});

  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const FaceToolkitApp(),
    ),
  );
}

class FaceToolkitApp extends StatelessWidget {
  const FaceToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Recognition Kit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo.shade900,
          secondary: Colors.blueAccent,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ToolkitHomeScreen(),
        '/showcase': (context) => const ShowcaseDashboard(),
      },
    );
  }
}

class ShowcaseDashboard extends StatefulWidget {
  const ShowcaseDashboard({super.key});

  @override
  State<ShowcaseDashboard> createState() => _ShowcaseDashboardState();
}

class _ShowcaseDashboardState extends State<ShowcaseDashboard> {
  int _selectedIndex = 1; // Start with Scanner
  final FaceDetectorInterface _detector = FaceDetectorInterface();
  final FaceRecognizerInterface _recognizer = FaceRecognizerInterface();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeEngines();
  }

  Future<void> _initializeEngines() async {
    try {
      await _detector.initialize().timeout(const Duration(seconds: 15), onTimeout: () {});
      await _recognizer.initialize().timeout(const Duration(seconds: 10), onTimeout: () {});
    } catch (e) {
      debugPrint('SDK Engine initialization failed: $e');
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _detector.dispose();
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                'Powering up Neural Engines...',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              SizedBox(height: 8),
              Text(
                'Loading biometric models & camera drivers',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final tabs = [
      IdentityRegistryTab(detector: _detector, recognizer: _recognizer),
      RecognitionScannerTab(detector: _detector, recognizer: _recognizer),
      const MetricsDashboardTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
        ),
        title: const Text(
          'SDK SHOWCASE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Face Recognition Kit',
                applicationVersion: '1.1.0',
                applicationLegalese: '© 2026 Biometric AI Systems',
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: tabs[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            backgroundColor: Colors.white,
            selectedItemColor: Colors.indigo.shade900,
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.app_registration_outlined), label: 'Registry'),
              BottomNavigationBarItem(icon: Icon(Icons.center_focus_strong_outlined), label: 'Scanner'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Metrics'),
            ],
          ),
        ),
      ),
    );
  }
}

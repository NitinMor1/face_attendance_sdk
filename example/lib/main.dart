import 'package:face_recognition_kit_example/ui/role_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:face_recognition_kit/face_recognition_kit.dart';

import 'core/attendance_store.dart';
import 'ui/enrollment_tab.dart';
import 'ui/attendance_tab.dart';
import 'ui/logs_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AttendanceStore();
  await store.loadData().timeout(const Duration(seconds: 3), onTimeout: () {});

  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Attendance Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo.shade800,
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
      home: Consumer<AttendanceStore>(
        builder: (context, store, _) {
          return store.appContextRole == null 
            ? const RoleSelectionScreen() 
            : const MainDashboard();
        },
      ),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  final FaceDetectorInterface _detector = FaceDetectorInterface();
  final FaceRecognizerInterface _recognizer = FaceRecognizerInterface();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeInitialEngines();
  }

  Future<void> _initializeInitialEngines() async {
    try {
      await _detector.initialize().timeout(const Duration(seconds: 15), onTimeout: () {});
      await _recognizer.initialize().timeout(const Duration(seconds: 5), onTimeout: () {});
    } catch (e) {
      debugPrint('Engine initialization failed: $e');
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
              SizedBox(height: 16),
              Text('Initializing AI Engines...', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final tabs = [
       EnrollmentTab(detector: _detector, recognizer: _recognizer),
       AttendanceTab(detector: _detector, recognizer: _recognizer),
       const LogsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FACE ATTENDANCE SDK',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.grey),
            onPressed: () {
               context.read<AttendanceStore>().clearData();
            },
          ),
        ],
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            backgroundColor: Colors.white,
            selectedItemColor: Colors.indigo.shade800,
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.person_add_outlined), label: 'Register'),
              BottomNavigationBarItem(icon: Icon(Icons.camera_front_outlined), label: 'Scanner'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Logs'),
            ],
          ),
        ),
      ),
    );
  }
}

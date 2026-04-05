import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:face_attendance_sdk/face_attendance_sdk.dart';

import 'core/attendance_store.dart';
import 'ui/dashboard_tab.dart';
import 'ui/enrollment_tab.dart';
import 'ui/attendance_tab.dart';

import 'ui/role_selection_screen.dart';
import 'core/models.dart';

void main() async {
  print('App starting: main()...');
  WidgetsFlutterBinding.ensureInitialized();
  
  final store = AttendanceStore();
  print('Loading campus data storage...');
  await store.loadData().timeout(const Duration(seconds: 3), onTimeout: () {
    print('Storage load timed out, proceeding with fresh data.');
  });

  print('Launching Campus App...');
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
      title: 'College Facial Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade900,
          primary: Colors.blue.shade900,
          secondary: Colors.indigo,
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
    print('Initializing AI Engines: Detector & Recognizer...');
    try {
      await _detector.initialize().timeout(const Duration(seconds: 15), onTimeout: () {
        print('Detector initialization timed out.');
      });
      await _recognizer.initialize().timeout(const Duration(seconds: 5), onTimeout: () {
        print('Recognizer initialization timed out.');
      });
    } catch (e) {
      print('Engine initialization failed: $e');
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
    print('AI Engines initialization complete.');
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
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Initializing Campus AI Systems...', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final store = context.watch<AttendanceStore>();
    final isFaculty = store.appContextRole == UserRole.faculty;

    // Build tabs based on role
    final List<Widget> tabs = isFaculty 
      ? [const DashboardTab(), AttendanceTab(detector: _detector, recognizer: _recognizer), EnrollmentTab(detector: _detector, recognizer: _recognizer)]
      : [EnrollmentTab(detector: _detector, recognizer: _recognizer), AttendanceTab(detector: _detector, recognizer: _recognizer)];

    final List<BottomNavigationBarItem> navItems = isFaculty 
      ? const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_front), label: 'Roll Call'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add), label: 'Enrollment'),
        ]
      : const [
          BottomNavigationBarItem(icon: Icon(Icons.person_add), label: 'Enrollment'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_front), label: 'Roll Call'),
        ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isFaculty ? 'FACULTY COMMAND CENTER' : 'CLASSROOM TERMINAL',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.switch_account),
          onPressed: () => store.setAppContextRole(null),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => store.clearData(),
          ),
        ],
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
             BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue.shade900,
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: navItems,
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AttendanceStore extends ChangeNotifier {
  static const String _usersKey = 'college_attendance_users';
  static const String _recordsKey = 'college_attendance_records';

  List<AppUser> _users = [];
  List<AttendanceRecord> _records = [];

  List<AppUser> get users => _users;
  List<AttendanceRecord> get records => _records;

  // Stats
  int get totalStudents => _users.where((u) => u.role == UserRole.student).length;
  int get totalFaculty => _users.where((u) => u.role == UserRole.faculty).length;
  
  int get studentsPresentToday {
    final today = DateTime.now();
    return _records
        .where((r) =>
            r.timestamp.year == today.year &&
            r.timestamp.month == today.month &&
            r.timestamp.day == today.day &&
            r.userRole == UserRole.student)
        .map((r) => r.userId)
        .toSet()
        .length;
  }

  int get facultyPresentToday {
    final today = DateTime.now();
    return _records
        .where((r) =>
            r.timestamp.year == today.year &&
            r.timestamp.month == today.month &&
            r.timestamp.day == today.day &&
            r.userRole == UserRole.faculty)
        .map((r) => r.userId)
        .toSet()
        .length;
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Users
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    _users = usersJson
        .map((s) => AppUser.fromJson(jsonDecode(s)))
        .toList();

    // Load Records
    final recordsJson = prefs.getStringList(_recordsKey) ?? [];
    _records = recordsJson
        .map((s) => AttendanceRecord.fromJson(jsonDecode(s)))
        .toList();

    notifyListeners();
  }

  Future<void> addUser(AppUser user) async {
    _users.add(user);
    await _saveUsers();
    notifyListeners();
  }

  Future<void> markAttendance(AppUser user) async {
    final today = DateTime.now();
    
    // Duplicate Prevention: 1 hour cooldown for classroom scenario
    final lastRecord = _records.where((r) => r.userId == user.id).lastOrNull;
    if (lastRecord != null && 
        today.difference(lastRecord.timestamp) < const Duration(hours: 1)) {
      return;
    }

    final record = AttendanceRecord(
      userId: user.id,
      userName: user.name,
      userRole: user.role,
      timestamp: today,
      type: AttendanceType.checkIn,
    );

    _records.add(record);
    await _saveRecords();
    notifyListeners();
  }

  // Monthly Report: Map of student name to list of days present
  Map<String, List<int>> getMonthlyReport(int month, int year) {
    final report = <String, List<int>>{};
    
    for (var user in _users.where((u) => u.role == UserRole.student)) {
      final days = _records
          .where((r) =>
              r.userId == user.id &&
              r.timestamp.month == month &&
              r.timestamp.year == year)
          .map((r) => r.timestamp.day)
          .toSet()
          .toList();
      report[user.name] = days;
    }
    return report;
  }

  UserRole? _appContextRole;
  UserRole? get appContextRole => _appContextRole;

  void setAppContextRole(UserRole? role) {
    _appContextRole = role;
    notifyListeners();
  }

  // Analytics: Weekly Attendance Trend (Last 7 days)
  List<Map<String, dynamic>> getWeeklyTrend() {
    final now = DateTime.now();
    final trend = <Map<String, dynamic>>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final count = _records
          .where((r) =>
              r.timestamp.year == date.year &&
              r.timestamp.month == date.month &&
              r.timestamp.day == date.day &&
              r.userRole == UserRole.student)
          .map((r) => r.userId)
          .toSet()
          .length;
      
      trend.add({
        'day': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
        'count': count,
        'date': date,
      });
    }
    return trend;
  }

  // Analytics: Department Breakdown
  Map<String, int> getDepartmentBreakdown() {
    final stats = <String, int>{};
    final today = DateTime.now();
    
    final presentToday = _records
        .where((r) =>
            r.timestamp.year == today.year &&
            r.timestamp.month == today.month &&
            r.timestamp.day == today.day)
        .map((r) => r.userId)
        .toSet();

    for (var userId in presentToday) {
      final user = _users.firstWhere((u) => u.id == userId, orElse: () => AppUser(id: '', name: '', embedding: [], department: 'Unknown', role: UserRole.student));
      if (user.id.isNotEmpty) {
        stats[user.department] = (stats[user.department] ?? 0) + 1;
      }
    }
    return stats;
  }

  // Analytics: At-Risk Students (< 75% attendance)
  List<AppUser> getAtRiskStudents() {
    if (_records.isEmpty) return [];
    
    final students = _users.where((u) => u.role == UserRole.student).toList();
    final totalSchoolDays = _records.map((r) => '${r.timestamp.year}-${r.timestamp.month}-${r.timestamp.day}').toSet().length;
    
    if (totalSchoolDays == 0) return [];

    return students.where((s) {
      final daysPresent = _records.where((r) => r.userId == s.id).map((r) => '${r.timestamp.year}-${r.timestamp.month}-${r.timestamp.day}').toSet().length;
      return (daysPresent / totalSchoolDays) < 0.75;
    }).toList();
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _users.map((u) => jsonEncode(u.toJson())).toList();
    await prefs.setStringList(_usersKey, json);
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _records.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_recordsKey, json);
  }

  Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usersKey);
    await prefs.remove(_recordsKey);
    _users = [];
    _records = [];
    notifyListeners();
  }
}

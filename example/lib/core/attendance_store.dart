import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AttendanceStore extends ChangeNotifier {
  static const String _usersKey = 'facial_attendance_users';
  static const String _recordsKey = 'facial_attendance_records';

  List<AppUser> _users = [];
  List<AttendanceRecord> _records = [];

  List<AppUser> get users => _users;
  List<AttendanceRecord> get records => _records;

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

  UserRole? _appContextRole;
  UserRole? get appContextRole => _appContextRole;

  void setAppContextRole(UserRole? role) {
    _appContextRole = role;
    notifyListeners();
  }

  Future<void> addUser(AppUser user) async {
    _users.add(user);
    await _saveUsers();
    notifyListeners();
  }

  Future<void> markAttendance(AppUser user, AttendanceType type) async {
    final record = AttendanceRecord(
      userId: user.id,
      userName: user.name,
      userRole: user.role,
      timestamp: DateTime.now(),
      type: type,
    );

    _records.add(record);
    await _saveRecords();
    notifyListeners();
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

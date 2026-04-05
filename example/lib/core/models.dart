import 'dart:convert';

enum UserRole { student, faculty, staff, visitor }

class AppUser {
  final String id;
  final String name;
  final String department;
  final UserRole role;
  final List<double> embedding;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.department,
    required this.role,
    required this.embedding,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'department': department,
        'role': role.index,
        'embedding': embedding,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        name: json['name'],
        department: json['department'],
        role: UserRole.values[json['role']],
        embedding: List<double>.from(json['embedding']),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

enum AttendanceType { checkIn, checkOut }

class AttendanceRecord {
  final String userId;
  final String userName;
  final UserRole userRole;
  final DateTime timestamp;
  final AttendanceType type;

  AttendanceRecord({
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'userRole': userRole.index,
        'timestamp': timestamp.toIso8601String(),
        'type': type.index,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
        userId: json['userId'],
        userName: json['userName'],
        userRole: UserRole.values[json['userRole']],
        timestamp: DateTime.parse(json['timestamp']),
        type: AttendanceType.values[json['type']],
      );
}

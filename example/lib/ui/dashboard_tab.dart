import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/attendance_store.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AttendanceStore>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 25),
          _buildQuickStats(store),
          const SizedBox(height: 35),
          _buildActivitySummary(store),
          const SizedBox(height: 35),
          _buildRecentLogs(store),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SDK Dashboard 👋',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
        ),
        const Text(
          'Real-time biometric monitoring systems.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildQuickStats(AttendanceStore store) {
    return Row(
      children: [
        _buildStatCard('Enrolled Faces', '${store.users.length}', Icons.face, Colors.blue),
        const SizedBox(width: 15),
        _buildStatCard('Bio-Events Today', '${store.records.where((r) => r.timestamp.day == DateTime.now().day).length}', Icons.history, Colors.indigo),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 15),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySummary(AttendanceStore store) {
    final checkIns = store.records.where((r) => r.type.name == 'checkIn').length;
    final checkOuts = store.records.where((r) => r.type.name == 'checkOut').length;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.indigo.shade900,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActivityStat('Total Check-In', checkIns, Colors.greenAccent),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildActivityStat('Total Check-Out', checkOuts, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildActivityStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text('$count', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentLogs(AttendanceStore store) {
    final logs = store.records.reversed.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Real-Time Identifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        if (logs.isEmpty)
          const Center(child: Text('Waiting for face activity...', style: TextStyle(color: Colors.grey)))
        else
          ...logs.map((log) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.person, size: 16, color: Colors.blue.shade900),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${log.type.name.toUpperCase()} • ${DateFormat('HH:mm').format(log.timestamp)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                Text(log.userId, style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
              ],
            ),
          )),
      ],
    );
  }
}

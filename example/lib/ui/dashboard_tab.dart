import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/attendance_store.dart';
import '../core/models.dart';

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
          _buildWeeklyTrend(store),
          const SizedBox(height: 35),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildDepartmentBreakdown(store)),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _buildQuickActions(context, store)),
            ],
          ),
          const SizedBox(height: 35),
          _buildAtRiskPanel(store),
          const SizedBox(height: 35),
          _buildRecentLogs(store),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final hour = DateTime.now().hour;
    String greeting = "Good Morning";
    if (hour >= 12 && hour < 17) greeting = "Good Afternoon";
    if (hour >= 17) greeting = "Good Evening";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, Faculty! 👋',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
        ),
        const Text(
          'Here is what is happening on campus today.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildQuickStats(AttendanceStore store) {
    return Row(
      children: [
        _buildStatCard('Real-time Presence', '${store.studentsPresentToday}', Icons.people_outline, const Color(0xFF2E7D32)),
        const SizedBox(width: 15),
        _buildStatCard('Faculty Logins', '${store.facultyPresentToday}', Icons.badge_outlined, Colors.blue),
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

  Widget _buildWeeklyTrend(AttendanceStore store) {
    final trend = store.getWeeklyTrend();
    final maxCount = trend.isEmpty ? 1 : trend.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b);
    final safeMax = maxCount == 0 ? 1 : maxCount;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Attendance', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.trending_up, color: Color(0xFFB9F6CA)),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend.map((data) {
                final heightFactor = (data['count'] as int) / safeMax;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 12,
                      height: (heightFactor * 90).clamp(5, 90),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(data['count'] == maxCount ? 1.0 : 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(data['day'], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentBreakdown(AttendanceStore store) {
    final stats = store.getDepartmentBreakdown();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Department Participation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        if (stats.isEmpty)
          const Text('No records today', style: TextStyle(color: Colors.grey, fontSize: 12))
        else
          ...stats.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    Text('${entry.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: entry.value / store.totalStudents.clamp(1, 1000),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          )).toList(),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, AttendanceStore store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _buildActionBtn(context, 'Export CSV', Icons.download_outlined, Colors.grey, () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating Comprehensive Attendance Report...')));
        }),
        const SizedBox(height: 12),
        _buildActionBtn(context, 'Clear All', Icons.delete_outline, Colors.red.shade100, () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Reset Database?'),
              content: const Text('This will delete all enrolled students and attendance logs.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('DELETE ALL')),
              ],
            )
          );
          if (confirm == true) store.clearData();
        }),
      ],
    );
  }

  Widget _buildActionBtn(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: Colors.blueGrey.shade700),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAtRiskPanel(AttendanceStore store) {
    final atRisk = store.getAtRiskStudents();
    if (atRisk.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Low Attendance Alerts', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ...atRisk.take(2).map((s) => Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('• ${s.name} (Roll No: ${s.id}) is below 75% attendance.', style: const TextStyle(fontSize: 13)),
          )).toList(),
          if (atRisk.length > 2)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('...and more. Please check full reports.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentLogs(AttendanceStore store) {
    final logs = store.records.reversed.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Live Stream (Roll Call)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        if (logs.isEmpty)
          const Center(child: Text('Waiting for classroom activity...', style: TextStyle(color: Colors.grey)))
        else
          ...logs.map((log) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(log.userName[0], style: TextStyle(color: Colors.blue.shade900, fontSize: 12)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${log.userRole.name.toUpperCase()} • ${DateFormat('HH:mm').format(log.timestamp)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                Text(log.userId, style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
              ],
            ),
          )).toList(),
      ],
    );
  }
}

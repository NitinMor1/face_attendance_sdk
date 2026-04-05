import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/attendance_store.dart';

class LogsTab extends StatelessWidget {
  const LogsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AttendanceStore>();
    final logs = store.records.reversed.toList();

    return Column(
      children: [
        _buildHeader(logs.length),
        Expanded(
          child: logs.isEmpty 
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: logs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildLogCard(logs[index]),
              ),
        ),
      ],
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Activity Logs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('$count records total', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const Icon(Icons.history, color: Colors.blue, size: 30),
        ],
      ),
    );
  }

  Widget _buildLogCard(dynamic log) {
    final isCheckIn = log.type.name == 'checkIn';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCheckIn ? Colors.green.shade50 : Colors.orange.shade50,
            child: Icon(
              isCheckIn ? Icons.login : Icons.logout,
              color: isCheckIn ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('ID: ${log.userId}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(log.timestamp),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              Text(
                DateFormat('MMM dd').format(log.timestamp),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No attendance logs yet.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text('Try scanning a face in the Scanner tab.', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/toolkit_store.dart';
import '../core/models.dart';

class MetricsDashboardTab extends StatelessWidget {
  const MetricsDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ToolkitStore>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsHeader(),
          const SizedBox(height: 24),
          _buildQuickStats(store),
          const SizedBox(height: 32),
          _buildIdentityList(store),
          const SizedBox(height: 32),
          _buildRecentEvents(store),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMetricsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SDK Analytics Hub',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
        ),
        const Text(
          'Monitoring biometric activities & registry health.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildQuickStats(ToolkitStore store) {
    return Row(
      children: [
        _buildStatCard('Enrolled Identities', '${store.identities.length}', Icons.security, Colors.blue),
        const SizedBox(width: 16),
        _buildStatCard('Total Scanner Hits', '${store.events.length}', Icons.bolt, Colors.amber),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityList(ToolkitStore store) {
    final list = store.identities;
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Registry Profiles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final identity = list[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(identity.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(identity.group, style: const TextStyle(fontSize: 10, color: Colors.indigo)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentEvents(ToolkitStore store) {
    final events = store.events.reversed.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Event Stream', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => store.clearAllData(),
              child: const Text('PURGE SDK DATA', style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('No biometric events recorded yet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          )
        else
          ...events.map((event) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade50),
            ),
            child: Row(
              children: [
                _getEventIcon(event.type),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.identityName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        '${event.type.name.toUpperCase()} • ${DateFormat('MMM dd, HH:mm').format(event.timestamp)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (event.type == EventType.identification)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${(event.confidence * 100).toInt()}%',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          )),
      ],
    );
  }

  Widget _getEventIcon(EventType type) {
    IconData icon;
    Color color;
    switch (type) {
      case EventType.enrollment:
        icon = Icons.person_add_alt_1;
        color = Colors.blue;
        break;
      case EventType.identification:
        icon = Icons.verified_user_outlined;
        color = Colors.green;
        break;
      case EventType.verification:
        icon = Icons.qr_code_scanner;
        color = Colors.purple;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/activity_provider.dart';
import '../models/activity.dart';
import 'detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: provider.isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : provider.history.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_run, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Chưa có hoạt động nào',
                style: TextStyle(fontSize: 17, color: Colors.grey[500])),
          ],
        ),
      )
          : Column(
        children: [
          _SummaryBar(history: provider.history),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.history.length,
              itemBuilder: (ctx, i) {
                final a = provider.history[i];
                return _ActivityCard(
                  activity: a,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetailScreen(activity: a)),
                  ),
                  onDelete: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Xóa hoạt động?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Hủy')),
                          TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Xóa',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (ok == true && a.id != null) {
                      context.read<ActivityProvider>().deleteActivity(a.id!);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final List<Activity> history;
  const _SummaryBar({required this.history});

  @override
  Widget build(BuildContext context) {
    final totalDist = history.fold(0.0, (s, a) => s + a.distanceKm);
    final totalCal = history.fold(0.0, (s, a) => s + a.calories);
    final totalSec = history.fold(0, (s, a) => s + a.durationSeconds);
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;

    return Container(
      color: Colors.green[50],
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Sum('${history.length} buổi', 'Tổng', Icons.fitness_center),
          _Sum('${totalDist.toStringAsFixed(1)} km', 'Quãng đường', Icons.route),
          _Sum('${h}h ${m}m', 'Thời gian', Icons.timer),
          _Sum('${totalCal.toStringAsFixed(0)} kcal', 'Calories', Icons.local_fire_department),
        ],
      ),
    );
  }
}

class _Sum extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _Sum(this.value, this.label, this.icon);

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: Colors.green, size: 16),
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
  ]);
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _ActivityCard(
      {required this.activity, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: activity.typeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(activity.typeIcon,
                      style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.typeName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(fmt.format(activity.startTime),
                        style:
                        TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 5),
                    Row(children: [
                      _Mini(Icons.route, activity.formattedDistance),
                      const SizedBox(width: 10),
                      _Mini(Icons.timer, activity.formattedDuration),
                      const SizedBox(width: 10),
                      _Mini(Icons.local_fire_department,
                          '${activity.calories.toStringAsFixed(0)} kcal'),
                    ]),
                  ]),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final IconData icon;
  final String value;
  const _Mini(this.icon, this.value);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: Colors.grey[600]),
      const SizedBox(width: 2),
      Text(value, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
    ],
  );
}
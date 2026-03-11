// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity.dart';
import '../providers/activity_provider.dart';
import 'tracking_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _index == 0 ? const _DashboardTab() : const HistoryScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fitness Tracker',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Chọn hoạt động và bắt đầu',
                style: TextStyle(color: Colors.grey[600], fontSize: 15)),
            const SizedBox(height: 24),

            // Activity selector
            Row(children: [
              Expanded(
                child: _TypeCard(
                  icon: '🚶',
                  label: 'Đi bộ',
                  isSelected: provider.selectedType == ActivityType.walking,
                  onTap: () => provider.setActivityType(ActivityType.walking),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeCard(
                  icon: '🚴',
                  label: 'Đạp xe',
                  isSelected: provider.selectedType == ActivityType.cycling,
                  onTap: () => provider.setActivityType(ActivityType.cycling),
                  color: Colors.green,
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // Weight
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  const Icon(Icons.monitor_weight, color: Colors.blue),
                  const SizedBox(width: 10),
                  const Text('Cân nặng', style: TextStyle(fontSize: 15)),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      if (provider.weightKg > 30) provider.setWeight(provider.weightKg - 1);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${provider.weightKg.toStringAsFixed(0)} kg',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () {
                      if (provider.weightKg < 200) provider.setWeight(provider.weightKg + 1);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // Stats tổng
            Row(children: [
              Expanded(
                child: _StatCard(
                  label: 'Hoạt động',
                  value: '${provider.history.length}',
                  icon: Icons.directions_run,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Tổng km',
                  value: provider.history
                      .fold(0.0, (s, a) => s + a.distanceKm)
                      .toStringAsFixed(1),
                  icon: Icons.route,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Calories',
                  value: provider.history
                      .fold(0.0, (s, a) => s + a.calories)
                      .toStringAsFixed(0),
                  icon: Icons.local_fire_department,
                  color: Colors.red,
                ),
              ),
            ]),

            const SizedBox(height: 32),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrackingScreen()),
                  ).then((_) => context.read<ActivityProvider>().loadHistory());
                },
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text('Bắt đầu', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _TypeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? color : Colors.grey[300]!, width: 2),
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              )),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
        required this.value,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ]),
      ),
    );
  }
}
// lib/screens/result_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/activity.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final Activity activity;
  const ResultScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final points =
    activity.route.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final hasRoute = points.length >= 2;
    final center = hasRoute
        ? LatLng(
      points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length,
      points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length,
    )
        : const LatLng(21.0285, 105.8542);

    return Scaffold(
      backgroundColor: Colors.green,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(children: [
                Text(activity.typeIcon, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 6),
                Text('${activity.typeName} hoàn thành!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(_formatDate(activity.startTime),
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),

            // Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24)),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(children: [
                    // Stats grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.8,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        _Stat(Icons.route, 'Khoảng cách',
                            activity.formattedDistance, Colors.blue),
                        _Stat(Icons.timer, 'Thời gian',
                            activity.formattedDuration, Colors.orange),
                        _Stat(Icons.speed, 'Tốc độ TB',
                            '${activity.avgSpeedKmh.toStringAsFixed(1)} km/h',
                            Colors.green),
                        _Stat(Icons.flash_on, 'Tốc độ max',
                            '${activity.maxSpeedKmh.toStringAsFixed(1)} km/h',
                            Colors.purple),
                        _Stat(Icons.local_fire_department, 'Calories',
                            '${activity.calories.toStringAsFixed(0)} kcal',
                            Colors.red),
                        _Stat(Icons.location_on, 'Điểm GPS',
                            '${activity.route.length}', Colors.teal),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Map
                    if (hasRoute) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Route',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 200,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: center,
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none, // disable gestures
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                'com.example.fitness_tracker',
                              ),
                              PolylineLayer(polylines: [
                                Polyline(
                                    points: points,
                                    strokeWidth: 4,
                                    color: Colors.blue),
                              ]),
                              MarkerLayer(markers: [
                                Marker(
                                  point: points.first,
                                  width: 26,
                                  height: 26,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.play_arrow,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                                Marker(
                                  point: points.last,
                                  width: 26,
                                  height: 26,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.stop,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            ),

            // Done button
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (_) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Xong',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Stat(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color)),
                Text(label,
                    style:
                    TextStyle(fontSize: 10, color: Colors.grey[600])),
              ]),
        ),
      ]),
    );
  }
}
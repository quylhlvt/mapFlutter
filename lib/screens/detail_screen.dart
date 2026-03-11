// lib/screens/detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';

class DetailScreen extends StatelessWidget {
  final Activity activity;
  const DetailScreen({super.key, required this.activity});

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
      appBar: AppBar(
        title: Text('${activity.typeIcon} ${activity.typeName}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map
            SizedBox(
              height: 280,
              child: hasRoute
                  ? FlutterMap(
                options: MapOptions(
                    initialCenter: center, initialZoom: 15),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.fitness_tracker',
                  ),
                  PolylineLayer(polylines: [
                    Polyline(
                        points: points,
                        strokeWidth: 5,
                        color: Colors.blue),
                  ]),
                  MarkerLayer(markers: [
                    Marker(
                      point: points.first,
                      width: 28,
                      height: 28,
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
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.stop,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ]),
                ],
              )
                  : Container(
                  color: Colors.grey[200],
                  child: const Center(
                      child: Text('Không có dữ liệu GPS'))),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, dd/MM/yyyy').format(activity.startTime),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(activity.startTime)} - '
                        '${activity.endTime != null ? DateFormat('HH:mm').format(activity.endTime!) : '--:--'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      _DetailStat(Icons.route, 'Khoảng cách',
                          activity.formattedDistance, Colors.blue),
                      _DetailStat(Icons.timer, 'Thời gian',
                          activity.formattedDuration, Colors.orange),
                      _DetailStat(Icons.speed, 'Tốc độ TB',
                          '${activity.avgSpeedKmh.toStringAsFixed(1)} km/h',
                          Colors.green),
                      _DetailStat(Icons.flash_on, 'Tốc độ max',
                          '${activity.maxSpeedKmh.toStringAsFixed(1)} km/h',
                          Colors.purple),
                      _DetailStat(
                          Icons.local_fire_department,
                          'Calories',
                          '${activity.calories.toStringAsFixed(0)} kcal',
                          Colors.red),
                      _DetailStat(Icons.location_on, 'Điểm GPS',
                          '${activity.route.length} điểm', Colors.teal),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DetailStat(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
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
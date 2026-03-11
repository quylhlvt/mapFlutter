// lib/screens/tracking_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/activity_provider.dart';
import '../models/activity.dart';
import 'result_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  bool _isStarting = false;
  bool _hasStarted = false;
  LatLng _currentCenter = const LatLng(21.0285, 105.8542); // Hà Nội

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    setState(() => _isStarting = true);
    final provider = context.read<ActivityProvider>();
    final success = await provider.startTracking();

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Không thể truy cập GPS. Vui lòng bật GPS và cấp quyền.'),
        backgroundColor: Colors.red,
      ));
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isStarting = false;
      _hasStarted = true;
    });

    // Cập nhật bản đồ mỗi 3 giây
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_hasStarted) {
        timer.cancel();
        return;
      }
      _updateMapCenter();
    });
  }

  void _updateMapCenter() {
    final route = context.read<ActivityProvider>().getLiveRoute();
    if (route.isNotEmpty) {
      final last = route.last;
      final newCenter = LatLng(last.latitude, last.longitude);
      setState(() => _currentCenter = newCenter);
      _mapController.move(newCenter, _mapController.camera.zoom);
    }
  }

  Future<void> _stopTracking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kết thúc hoạt động?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tiếp tục')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kết thúc', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final provider = context.read<ActivityProvider>();
    final activity = await provider.stopTracking();
    setState(() => _hasStarted = false);

    if (mounted && activity != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(activity: activity)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final route = provider.getLiveRoute();
    final polylinePoints =
    route.map((p) => LatLng(p.latitude, p.longitude)).toList();

    return Scaffold(
      body: Stack(
        children: [
          // OpenStreetMap - không cần API key
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fitness_tracker',
              ),
              // Route line
              if (polylinePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 5,
                      color: Colors.blue,
                    ),
                  ],
                ),
              // Start marker + current position
              if (polylinePoints.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: polylinePoints.first,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    if (polylinePoints.length > 1)
                      Marker(
                        point: polylinePoints.last,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 18),
                        ),
                      ),
                  ],
                ),
            ],
          ),

          // Loading
          if (_isStarting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Đang kết nối GPS...',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                          provider.selectedType == ActivityType.walking
                              ? '🚶'
                              : '🚴',
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                          provider.selectedType == ActivityType.walking
                              ? 'Đi bộ'
                              : 'Đạp xe',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
                  ),
                  const Spacer(),
                  FloatingActionButton.small(
                    heroTag: 'locate',
                    onPressed: _updateMapCenter,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),
          ),

          // Bottom stats
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _LiveStat(
                        label: 'Khoảng cách',
                        value: provider.distanceKm >= 1
                            ? provider.distanceKm.toStringAsFixed(2)
                            : (provider.distanceKm * 1000).toStringAsFixed(0),
                        unit: provider.distanceKm >= 1 ? 'km' : 'm',
                        color: Colors.blue,
                      ),
                      _LiveStat(
                        label: 'Thời gian',
                        value: provider.formattedDuration,
                        unit: '',
                        color: Colors.orange,
                      ),
                      _LiveStat(
                        label: 'Tốc độ',
                        value: provider.currentSpeedKmh.toStringAsFixed(1),
                        unit: 'km/h',
                        color: Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Calories
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${provider.calories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.red),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 14),

                  // Stop button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _hasStarted ? _stopTracking : null,
                      icon: const Icon(Icons.stop_circle),
                      label: const Text('Kết thúc',
                          style: TextStyle(fontSize: 17)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _LiveStat(
      {required this.label,
        required this.value,
        required this.unit,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      const SizedBox(height: 2),
      RichText(
        text: TextSpan(children: [
          TextSpan(
              text: value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color)),
          if (unit.isNotEmpty)
            TextSpan(
                text: ' $unit',
                style:
                TextStyle(fontSize: 13, color: Colors.grey[600])),
        ]),
      ),
    ]);
  }
}
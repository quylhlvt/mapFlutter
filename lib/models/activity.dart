// lib/models/activity.dart

import 'package:flutter/material.dart';

enum ActivityType { walking, cycling }

class ActivityPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double speed;

  ActivityPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.speed,
  });

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'speed': speed,
  };

  factory ActivityPoint.fromMap(Map<String, dynamic> map) => ActivityPoint(
    latitude: map['latitude'],
    longitude: map['longitude'],
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    speed: map['speed'],
  );
}

class Activity {
  final int? id;
  final ActivityType type;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final int durationSeconds;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final double calories;
  final List<ActivityPoint> route;

  Activity({
    this.id,
    required this.type,
    required this.startTime,
    this.endTime,
    required this.distanceKm,
    required this.durationSeconds,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.calories,
    required this.route,
  });

  String get typeName => type == ActivityType.walking ? 'Đi bộ' : 'Đạp xe';
  String get typeIcon => type == ActivityType.walking ? '🚶' : '🚴';
  Color get typeColor => type == ActivityType.walking
      ? const Color(0xFF2196F3)
      : const Color(0xFF4CAF50);

  String get formattedDuration {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get formattedDistance => distanceKm >= 1
      ? '${distanceKm.toStringAsFixed(2)} km'
      : '${(distanceKm * 1000).toStringAsFixed(0)} m';

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.index,
    'startTime': startTime.millisecondsSinceEpoch,
    'endTime': endTime?.millisecondsSinceEpoch,
    'distanceKm': distanceKm,
    'durationSeconds': durationSeconds,
    'avgSpeedKmh': avgSpeedKmh,
    'maxSpeedKmh': maxSpeedKmh,
    'calories': calories,
  };

  factory Activity.fromMap(Map<String, dynamic> map, List<ActivityPoint> route) =>
      Activity(
        id: map['id'],
        type: ActivityType.values[map['type']],
        startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
        endTime: map['endTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
            : null,
        distanceKm: map['distanceKm'],
        durationSeconds: map['durationSeconds'],
        avgSpeedKmh: map['avgSpeedKmh'],
        maxSpeedKmh: map['maxSpeedKmh'],
        calories: map['calories'],
        route: route,
      );
}
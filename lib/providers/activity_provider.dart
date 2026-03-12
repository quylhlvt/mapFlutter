// lib/providers/activity_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../services/calories_service.dart';

enum TrackingState { idle, running }

class ActivityProvider extends ChangeNotifier {
  final _locationService = LocationService();
  final _dbService = DatabaseService();

  TrackingState _state = TrackingState.idle;
  ActivityType _selectedType = ActivityType.walking;
  double _weightKg = 60.0;

  double _distanceKm = 0;
  double _currentSpeedKmh = 0;
  int _durationSeconds = 0;
  double _calories = 0;

  DateTime? _startTime;
  Timer? _timer;
  List<Activity> _history = [];
  bool _isLoadingHistory = false;

  // Getters
  TrackingState get state => _state;
  ActivityType get selectedType => _selectedType;
  double get weightKg => _weightKg;
  double get distanceKm => _distanceKm;
  double get currentSpeedKmh => _currentSpeedKmh;
  int get durationSeconds => _durationSeconds;
  double get calories => _calories;
  List<Activity> get history => _history;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isTracking => _state == TrackingState.running;

  List<ActivityPoint> getLiveRoute() => _locationService.getRoute();

  String get formattedDuration {
    final h = _durationSeconds ~/ 3600;
    final m = (_durationSeconds % 3600) ~/ 60;
    final s = _durationSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  ActivityProvider() {
    _loadWeight(); // 👈 load ngay khi khởi tạo
  }
  void setActivityType(ActivityType type) {
    _selectedType = type;
    notifyListeners();
  }
  Future<void> _loadWeight() async {
    final prefs = await SharedPreferences.getInstance();
    _weightKg = prefs.getDouble('weight_kg') ?? 60;
    notifyListeners();
  }

  Future<void> setWeight(double value) async {
    _weightKg = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('weight_kg', value); // 👈 lưu mỗi khi thay đổi
  }



  Future<bool> startTracking() async {
    final hasPermission = await _locationService.requestPermission();
    if (!hasPermission) return false;

    _distanceKm = 0;
    _currentSpeedKmh = 0;
    _durationSeconds = 0;
    _calories = 0;
    _startTime = DateTime.now();
    _state = TrackingState.running;

    _locationService.onStatsUpdate = (distance, speed) {
      _distanceKm = distance;
      _currentSpeedKmh = speed;
      _calories = CaloriesService.calculate(
        type: _selectedType,
        durationSeconds: _durationSeconds,
        weightKg: _weightKg,
        avgSpeedKmh: _locationService.getAvgSpeed(),
      );
      notifyListeners();
    };

    _locationService.start();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _durationSeconds++;
      notifyListeners();
    });

    notifyListeners();
    return true;
  }

  Future<Activity?> stopTracking() async {
    _state = TrackingState.idle;
    _timer?.cancel();
    _locationService.stop();

    if (_startTime == null) return null;

    final activity = Activity(
      type: _selectedType,
      startTime: _startTime!,
      endTime: DateTime.now(),
      distanceKm: _distanceKm,
      durationSeconds: _durationSeconds,
      avgSpeedKmh: _locationService.getAvgSpeed(),
      maxSpeedKmh: _locationService.getMaxSpeed(),
      calories: _calories,
      route: _locationService.getRoute(),
    );

    await _dbService.saveActivity(activity);
    await loadHistory();
    notifyListeners();
    return activity;
  }

  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    notifyListeners();
    _history = await _dbService.getAllActivities();
    _isLoadingHistory = false;
    notifyListeners();
  }

  Future<void> deleteActivity(int id) async {
    await _dbService.deleteActivity(id);
    await loadHistory();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationService.stop();
    super.dispose();
  }
}
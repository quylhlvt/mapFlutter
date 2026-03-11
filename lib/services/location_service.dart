// lib/services/location_service.dart

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/activity.dart';

class LocationService {
  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;
  double _totalDistanceMeters = 0;
  double _maxSpeed = 0;
  double _currentSpeed = 0;
  final List<ActivityPoint> _route = [];
  final List<double> _speeds = [];

  Function(double distanceKm, double speedKmh)? onStatsUpdate;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  void start() {
    _lastPosition = null;
    _totalDistanceMeters = 0;
    _maxSpeed = 0;
    _currentSpeed = 0;
    _route.clear();
    _speeds.clear();

    // Dùng GPS offline - không cần internet
    const settings = // Xóa AndroidSettings, thay bằng:
     LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: settings).listen(_onPosition);
  }

  void stop() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  void _onPosition(Position position) {
    // Lọc nhiễu GPS: bỏ qua nếu accuracy kém
    if (position.accuracy > 30) return;

    if (_lastPosition != null) {
      final delta = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // Lọc GPS jump: bỏ qua nếu nhảy quá xa
      if (delta < 500) {
        _totalDistanceMeters += delta;
      }
    }

    // Tốc độ từ GPS (m/s → km/h)
    _currentSpeed = position.speed < 0 ? 0.0 : position.speed * 3.6;
    _speeds.add(_currentSpeed);
    if (_currentSpeed > _maxSpeed) _maxSpeed = _currentSpeed;

    _route.add(ActivityPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      speed: _currentSpeed,
    ));

    _lastPosition = position;
    onStatsUpdate?.call(getDistanceKm(), _currentSpeed);
  }

  double getDistanceKm() => _totalDistanceMeters / 1000;
  double getCurrentSpeed() => _currentSpeed;
  double getMaxSpeed() => _maxSpeed;
  double getAvgSpeed() {
    final nonZero = _speeds.where((s) => s > 0).toList();
    if (nonZero.isEmpty) return 0;
    return nonZero.reduce((a, b) => a + b) / nonZero.length;
  }

  List<ActivityPoint> getRoute() => List.unmodifiable(_route);
  Position? getLastPosition() => _lastPosition;
}
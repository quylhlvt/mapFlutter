// lib/services/calories_service.dart

import '../models/activity.dart';

class CaloriesService {
  /// Tính calories theo MET
  /// Calories = MET × cân nặng (kg) × thời gian (giờ)
  static double calculate({
    required ActivityType type,
    required int durationSeconds,
    required double weightKg,
    double avgSpeedKmh = 0,
  }) {
    double met;

    if (type == ActivityType.walking) {
      if (avgSpeedKmh < 3) met = 2.5;
      else if (avgSpeedKmh < 5) met = 3.5;
      else if (avgSpeedKmh < 6) met = 4.5;
      else met = 6.0;
    } else {
      if (avgSpeedKmh < 15) met = 4.0;
      else if (avgSpeedKmh < 20) met = 6.0;
      else if (avgSpeedKmh < 25) met = 8.0;
      else met = 10.0;
    }

    return met * weightKg * (durationSeconds / 3600);
  }
}
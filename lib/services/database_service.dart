// lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/activity.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = join(await getDatabasesPath(), 'fitness.db');
    return openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE activities (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type INTEGER NOT NULL,
          startTime INTEGER NOT NULL,
          endTime INTEGER,
          distanceKm REAL NOT NULL,
          durationSeconds INTEGER NOT NULL,
          avgSpeedKmh REAL NOT NULL,
          maxSpeedKmh REAL NOT NULL,
          calories REAL NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE activity_points (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          activityId INTEGER NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          timestamp INTEGER NOT NULL,
          speed REAL NOT NULL,
          FOREIGN KEY (activityId) REFERENCES activities(id) ON DELETE CASCADE
        )
      ''');
    });
  }

  Future<int> saveActivity(Activity activity) async {
    final db = await database;
    final id = await db.insert('activities', activity.toMap()..remove('id'));
    for (final point in activity.route) {
      await db.insert('activity_points', {'activityId': id, ...point.toMap()});
    }
    return id;
  }

  Future<List<Activity>> getAllActivities() async {
    final db = await database;
    final maps = await db.query('activities', orderBy: 'startTime DESC');
    final activities = <Activity>[];
    for (final map in maps) {
      final points = await db.query('activity_points',
          where: 'activityId = ?',
          whereArgs: [map['id']],
          orderBy: 'timestamp ASC');
      activities.add(Activity.fromMap(
          map, points.map((p) => ActivityPoint.fromMap(p)).toList()));
    }
    return activities;
  }

  Future<void> deleteActivity(int id) async {
    final db = await database;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
    await db.delete('activity_points', where: 'activityId = ?', whereArgs: [id]);
  }
}
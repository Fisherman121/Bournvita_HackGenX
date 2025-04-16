import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/detection.dart';

class LocalStorage {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'garbage_detections.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE detections(
            id TEXT PRIMARY KEY,
            timestamp TEXT NOT NULL,
            detectionClass TEXT NOT NULL,
            confidence REAL NOT NULL,
            status TEXT NOT NULL,
            imagePath TEXT NOT NULL,
            imageUrl TEXT,
            forCleaning INTEGER NOT NULL,
            location TEXT NOT NULL,
            zoneName TEXT NOT NULL,
            cameraId TEXT NOT NULL,
            cleanedBy TEXT,
            cleanedAt TEXT,
            notes TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertDetection(Detection detection) async {
    final db = await database;
    await db.insert(
      'detections',
      detection.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Detection>> getDetections() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('detections');
    return List.generate(maps.length, (i) {
      return Detection.fromMap(maps[i]);
    });
  }

  Future<Detection?> getDetection(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'detections',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Detection.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateDetection(Detection detection) async {
    final db = await database;
    await db.update(
      'detections',
      detection.toMap(),
      where: 'id = ?',
      whereArgs: [detection.id],
    );
  }

  Future<void> deleteDetection(String id) async {
    final db = await database;
    await db.delete(
      'detections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllDetections() async {
    final db = await database;
    await db.delete('detections');
  }

  Future<void> markAsCleaned(String timestamp, String cleanedBy, String notes) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'detections',
      {
        'status': 'cleaned',
        'cleanedBy': cleanedBy,
        'cleanedAt': now,
        'notes': notes,
      },
      where: 'timestamp = ?',
      whereArgs: [timestamp],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
} 
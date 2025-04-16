import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/detection.dart';

class LocalStorage {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'detections.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE detections(
            timestamp TEXT PRIMARY KEY,
            detectionClass TEXT,
            confidence REAL,
            status TEXT,
            imagePath TEXT,
            imageUrl TEXT,
            forCleaning INTEGER,
            cameraId TEXT,
            zoneName TEXT,
            location TEXT,
            cleanedBy TEXT,
            cleanedAt TEXT,
            notes TEXT,
            lastSynced INTEGER
          )
        ''');
      },
      version: 1,
    );
  }
  
  Future<void> saveDetections(List<Detection> detections) async {
    final db = await database;
    final batch = db.batch();
    
    for (final detection in detections) {
      batch.insert(
        'detections',
        {
          'timestamp': detection.timestamp,
          'detectionClass': detection.detectionClass,
          'confidence': detection.confidence,
          'status': detection.status,
          'imagePath': detection.imagePath,
          'imageUrl': detection.imageUrl,
          'forCleaning': detection.forCleaning ? 1 : 0,
          'cameraId': detection.cameraId,
          'zoneName': detection.zoneName,
          'location': detection.location,
          'cleanedBy': detection.cleanedBy,
          'cleanedAt': detection.cleanedAt,
          'notes': detection.notes,
          'lastSynced': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }
  
  Future<List<Detection>> getDetections() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('detections');
    
    return List.generate(maps.length, (i) {
      return Detection.fromJson(maps[i]);
    });
  }
  
  Future<void> markAsCleaned(String timestamp, String cleanedBy, String notes) async {
    final db = await database;
    await db.update(
      'detections',
      {
        'status': 'cleaned',
        'cleanedBy': cleanedBy,
        'cleanedAt': DateTime.now().toIso8601String(),
        'notes': notes,
      },
      where: 'timestamp = ?',
      whereArgs: [timestamp],
    );
  }
  
  Future<void> deleteAllDetections() async {
    final db = await database;
    await db.delete('detections');
  }
} 
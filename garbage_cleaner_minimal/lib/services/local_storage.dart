import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/detection.dart';
import 'api_service.dart';

class LocalStorage {
  static Database? _database;
  static final LocalStorage _instance = LocalStorage._internal();
  
  factory LocalStorage() {
    return _instance;
  }
  
  LocalStorage._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'detections.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }
  
  Future<void> _createDb(Database db, int version) async {
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
        syncedAt TEXT
      )
    ''');
  }
  
  Future<void> saveDetections(List<Detection> detections) async {
    final db = await database;
    
    final batch = db.batch();
    for (var detection in detections) {
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
          'syncedAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }
  
  Future<List<Detection>> getDetections() async {
    final db = await database;
    final maps = await db.query('detections', orderBy: 'timestamp DESC');
    
    return List.generate(maps.length, (i) {
      return Detection(
        timestamp: maps[i]['timestamp'] as String,
        detectionClass: maps[i]['detectionClass'] as String,
        confidence: maps[i]['confidence'] as double,
        status: maps[i]['status'] as String,
        imagePath: maps[i]['imagePath'] as String,
        imageUrl: maps[i]['imageUrl'] as String,
        forCleaning: maps[i]['forCleaning'] == 1,
        cameraId: maps[i]['cameraId'] as String,
        zoneName: maps[i]['zoneName'] as String,
        location: maps[i]['location'] as String,
        cleanedBy: maps[i]['cleanedBy'] as String?,
        cleanedAt: maps[i]['cleanedAt'] as String?,
        notes: maps[i]['notes'] as String?,
      );
    });
  }
  
  Future<Detection?> getDetection(String timestamp) async {
    final db = await database;
    final maps = await db.query(
      'detections',
      where: 'timestamp = ?',
      whereArgs: [timestamp],
    );
    
    if (maps.isEmpty) return null;
    
    return Detection(
      timestamp: maps[0]['timestamp'] as String,
      detectionClass: maps[0]['detectionClass'] as String,
      confidence: maps[0]['confidence'] as double,
      status: maps[0]['status'] as String,
      imagePath: maps[0]['imagePath'] as String,
      imageUrl: maps[0]['imageUrl'] as String,
      forCleaning: maps[0]['forCleaning'] == 1,
      cameraId: maps[0]['cameraId'] as String,
      zoneName: maps[0]['zoneName'] as String,
      location: maps[0]['location'] as String,
      cleanedBy: maps[0]['cleanedBy'] as String?,
      cleanedAt: maps[0]['cleanedAt'] as String?,
      notes: maps[0]['notes'] as String?,
    );
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
        'syncedAt': null,
      },
      where: 'timestamp = ?',
      whereArgs: [timestamp],
    );
  }
  
  Future<void> markAsSynced(String timestamp) async {
    final db = await database;
    
    await db.update(
      'detections',
      {
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'timestamp = ?',
      whereArgs: [timestamp],
    );
  }
  
  Future<List<Detection>> getUnsynced() async {
    final db = await database;
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String();
    
    final maps = await db.query(
      'detections',
      where: 'syncedAt IS NULL OR syncedAt < ?',
      whereArgs: [fiveMinutesAgo],
    );
    
    return List.generate(maps.length, (i) {
      return Detection(
        timestamp: maps[i]['timestamp'] as String,
        detectionClass: maps[i]['detectionClass'] as String,
        confidence: maps[i]['confidence'] as double,
        status: maps[i]['status'] as String,
        imagePath: maps[i]['imagePath'] as String,
        imageUrl: maps[i]['imageUrl'] as String,
        forCleaning: maps[i]['forCleaning'] == 1,
        cameraId: maps[i]['cameraId'] as String,
        zoneName: maps[i]['zoneName'] as String,
        location: maps[i]['location'] as String,
        cleanedBy: maps[i]['cleanedBy'] as String?,
        cleanedAt: maps[i]['cleanedAt'] as String?,
        notes: maps[i]['notes'] as String?,
      );
    });
  }
  
  Future<void> deleteAllDetections() async {
    final db = await database;
    await db.delete('detections');
  }
  
  Future<void> updateFromServer(List<Detection> serverDetections) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('detections');
      
      for (var detection in serverDetections) {
        await txn.insert(
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
            'syncedAt': DateTime.now().toIso8601String(),
          },
        );
      }
    });
  }

  Future<bool> syncWithServer() async {
    final apiService = ApiService();
    bool success = false;
    
    try {
      final unsynced = await getUnsynced();
      
      if (unsynced.isNotEmpty) {
        await apiService.syncDetections(unsynced);
        
        for (var detection in unsynced) {
          await markAsSynced(detection.timestamp);
        }
      }
      
      final serverDetections = await apiService.getAllDetections();
      
      if (serverDetections.isNotEmpty) {
        await updateFromServer(serverDetections);
      }
      
      success = true;
    } catch (e) {
      print('Error syncing with server: $e');
      success = false;
    }
    
    return success;
  }
  
  Future<bool> fullRefreshFromServer() async {
    final apiService = ApiService();
    bool success = false;
    
    try {
      final serverDetections = await apiService.getAllDetections();
      
      await updateFromServer(serverDetections);
      success = true;
    } catch (e) {
      print('Error refreshing from server: $e');
      success = false;
    } finally {
      apiService.dispose();
    }
    
    return success;
  }

  Future<bool> addDetectionAndSync(Detection detection) async {
    final apiService = ApiService();
    bool success = false;
    
    try {
      await saveDetections([detection]);
      
      success = await apiService.addDetection(detection);
      
      if (success) {
        await markAsSynced(detection.timestamp);
      }
    } catch (e) {
      print('Error adding detection and syncing: $e');
      success = false;
    }
    
    return success;
  }
  
  Future<bool> updateStatusAndSync(String timestamp, String status, String? cleanedBy, String? notes) async {
    final apiService = ApiService();
    bool success = false;
    
    try {
      if (status == 'cleaned' && cleanedBy != null) {
        await markAsCleaned(timestamp, cleanedBy, notes ?? '');
      } else {
        final db = await database;
        await db.update(
          'detections',
          {'status': status, 'syncedAt': null},
          where: 'timestamp = ?',
          whereArgs: [timestamp],
        );
      }
      
      success = await apiService.updateDetectionStatus(timestamp, status, cleanedBy: cleanedBy, notes: notes);
      
      if (success) {
        await markAsSynced(timestamp);
      }
    } catch (e) {
      print('Error updating status and syncing: $e');
      success = false;
    }
    
    return success;
  }
} 
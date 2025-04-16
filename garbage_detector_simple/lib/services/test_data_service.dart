import '../models/detection.dart';
import 'local_storage.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';

class TestDataService {
  final LocalStorage _localStorage;
  final Random _random = Random();
  final Uuid _uuid = Uuid();

  TestDataService(this._localStorage);

  Future<void> addTestDetections(int count) async {
    final List<String> zones = ['Zone A', 'Zone B', 'Zone C', 'Zone D'];
    final List<String> classes = ['plastic', 'paper', 'glass', 'organic', 'metal'];
    final List<String> statuses = ['detected', 'confirmed', 'false_positive', 'cleaned'];
    final List<String> cameras = ['camera_01', 'camera_02', 'camera_03'];

    for (int i = 0; i < count; i++) {
      final now = DateTime.now().subtract(Duration(hours: _random.nextInt(72)));
      final status = statuses[_random.nextInt(statuses.length)];
      final isCleaned = status == 'cleaned';
      
      final detection = Detection(
        id: _uuid.v4(),
        timestamp: now.toIso8601String(),
        detectionClass: classes[_random.nextInt(classes.length)],
        confidence: 0.5 + _random.nextDouble() * 0.5, // 0.5 to 1.0
        status: status,
        imagePath: 'images/test_image_${i + 1}.jpg',
        location: 'Lat: ${44.4 + _random.nextDouble()}, Long: ${20.4 + _random.nextDouble()}',
        zoneName: zones[_random.nextInt(zones.length)],
        cameraId: cameras[_random.nextInt(cameras.length)],
        forCleaning: _random.nextBool() ? 1 : 0,
        cleanedBy: isCleaned ? 'Test User ${_random.nextInt(5) + 1}' : null,
        cleanedAt: isCleaned ? DateTime.now().subtract(Duration(hours: _random.nextInt(24))).toIso8601String() : null,
        notes: isCleaned ? 'Test cleanup note ${i + 1}' : null,
      );
      
      await _localStorage.insertDetection(detection);
    }
  }

  Future<void> clearAllTestData() async {
    await _localStorage.clearAllDetections();
  }
} 
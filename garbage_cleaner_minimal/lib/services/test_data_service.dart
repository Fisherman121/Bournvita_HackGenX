import '../models/detection.dart';
import 'local_storage.dart';

class TestDataService {
  static final List<Detection> _testDetections = [
    Detection(
      timestamp: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      detectionClass: 'Plastic Bottle',
      confidence: 0.95,
      status: 'pending',
      imagePath: '',
      imageUrl: '',
      forCleaning: true,
      cameraId: 'CAM001',
      zoneName: 'Zone A',
      location: 'Near Entrance',
    ),
    Detection(
      timestamp: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      detectionClass: 'Cardboard Box',
      confidence: 0.88,
      status: 'pending',
      imagePath: '',
      imageUrl: '',
      forCleaning: true,
      cameraId: 'CAM002',
      zoneName: 'Zone B',
      location: 'Parking Area',
    ),
    Detection(
      timestamp: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      detectionClass: 'Food Waste',
      confidence: 0.92,
      status: 'cleaned',
      imagePath: '',
      imageUrl: '',
      forCleaning: true,
      cameraId: 'CAM003',
      zoneName: 'Zone C',
      location: 'Food Court',
      cleanedBy: 'Staff 1',
      cleanedAt: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      notes: 'Cleaned and disposed properly',
    ),
    Detection(
      timestamp: DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      detectionClass: 'Paper Waste',
      confidence: 0.85,
      status: 'pending',
      imagePath: '',
      imageUrl: '',
      forCleaning: true,
      cameraId: 'CAM001',
      zoneName: 'Zone A',
      location: 'Office Area',
    ),
    Detection(
      timestamp: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      detectionClass: 'Metal Can',
      confidence: 0.90,
      status: 'cleaned',
      imagePath: '',
      imageUrl: '',
      forCleaning: true,
      cameraId: 'CAM002',
      zoneName: 'Zone B',
      location: 'Recycling Area',
      cleanedBy: 'Staff 2',
      cleanedAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      notes: 'Recycled',
    ),
    // Additional test detections for variety
    Detection(
      timestamp: DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      detectionClass: 'Glass Bottle',
      confidence: 0.91,
      status: 'pending',
      imagePath: '',
      imageUrl: '',
      forCleaning: true,
      cameraId: 'CAM001',
      zoneName: 'Zone D',
      location: 'Kitchen Area',
    ),
    Detection(
      timestamp: DateTime.now().subtract(const Duration(hours: 7)).toIso8601String(),
      detectionClass: 'Electronic Waste',
      confidence: 0.87,
      status: 'pending',
      imagePath: '',
      imageUrl: '',
      forCleaning: true,
      cameraId: 'CAM003',
      zoneName: 'Zone C',
      location: 'Office Storage',
    ),
  ];

  static Future<void> addTestData() async {
    final storage = LocalStorage();
    await storage.saveDetections(_testDetections);
  }

  static Future<void> clearTestData() async {
    final storage = LocalStorage();
    await storage.deleteAllDetections();
  }
} 
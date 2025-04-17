import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/detection.dart';
import '../services/local_storage.dart';
import '../services/api_service.dart';

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
    final localStorage = LocalStorage();
    
    List<Detection> detections = [];
    
    // Create 5 test detections
    for (int i = 0; i < 5; i++) {
      final classIndex = i % _testDetections.length;
      final zoneIndex = i % _testDetections.length;
      
      detections.add(
        Detection(
          timestamp: _generateTimestamp(),
          detectionClass: _testDetections[classIndex].detectionClass,
          confidence: 0.7 + (i * 0.05),
          status: i % 3 == 0 ? 'cleaned' : 'pending',
          imagePath: 'test_image_$i.jpg',
          imageUrl: 'https://via.placeholder.com/150?text=${_testDetections[classIndex].detectionClass}',
          forCleaning: true,
          cameraId: 'cam-${i + 1}',
          zoneName: _testDetections[zoneIndex].zoneName,
          location: _testDetections[zoneIndex].location,
          cleanedBy: i % 3 == 0 ? 'Test User' : null,
          cleanedAt: i % 3 == 0 ? DateTime.now().toIso8601String() : null,
          notes: i % 3 == 0 ? 'Test cleanup note' : null,
        ),
      );
    }
    
    await localStorage.saveDetections(detections);
  }

  static Future<void> clearTestData() async {
    final storage = LocalStorage();
    await storage.deleteAllDetections();
  }

  // Generate a timestamp in the ISO 8601 format
  static String _generateTimestamp() {
    final now = DateTime.now();
    return now.toIso8601String();
  }

  // Add sample data from the Flask server endpoint
  static Future<bool> loadSampleDataFromServer() async {
    try {
      final url = await ApiService.getBaseUrl();
      final response = await http.get(
        Uri.parse('$url/sample_data'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Sync with server to get the new data
          final localStorage = LocalStorage();
          return await localStorage.syncWithServer();
        }
      }
      return false;
    } catch (e) {
      print('Error loading sample data from server: $e');
      return false;
    }
  }
} 
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/detection.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client = http.Client();
  final Uuid _uuid = Uuid();
  
  ApiService({required this.baseUrl});
  
  Future<List<Detection>> fetchDetections() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/detections'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => _convertToDetection(json)).toList();
      } else {
        throw Exception('Failed to load detections: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<String> downloadImage(String imagePath) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/view_image/$imagePath'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // This is just the URL - in a real implementation you'd need to 
        // save the image locally or handle it differently
        return '$baseUrl/view_image/$imagePath';
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error downloading image: $e');
    }
  }
  
  Detection _convertToDetection(Map<String, dynamic> json) {
    // Handle confidence which can be a double or a string
    double confidence = 0.0;
    if (json['confidence'] != null) {
      if (json['confidence'] is num) {
        confidence = (json['confidence'] as num).toDouble();
      } else if (json['confidence'] is String) {
        confidence = double.tryParse(json['confidence']) ?? 0.0;
      }
    }

    // Handle class which could be in different fields
    String detectionClass = 'Unknown';
    if (json['class'] != null) {
      detectionClass = json['class'].toString();
    } else if (json['detectionClass'] != null) {
      detectionClass = json['detectionClass'].toString();
    }

    // Get image path and construct URL
    String imagePath = json['image_path'] ?? '';
    String imageUrl = '$baseUrl/view_image/$imagePath';
    
    // Construct location string from coordinates if available
    String location = 'Unknown';
    if (json['coordinates'] != null) {
      location = 'Lat: ${json['coordinates'][0]}, Long: ${json['coordinates'][1]}';
    } else if (json['location'] != null) {
      location = json['location'].toString();
    }
    
    // Parse status with fallback
    String status = json['status'] ?? 'detected';
    
    // Generate a unique ID for this detection
    String id = _uuid.v4();
    
    // Get timestamp with fallback to current time
    String timestamp = json['timestamp'] ?? DateTime.now().toIso8601String();
    
    return Detection(
      id: id,
      timestamp: timestamp,
      detectionClass: detectionClass,
      confidence: confidence,
      status: status,
      imagePath: imagePath,
      imageUrl: imageUrl,
      forCleaning: 1, // Default all detections for cleaning
      location: location,
      zoneName: json['zone_name'] ?? 'Default Zone',
      cameraId: json['camera_id'] ?? 'CAM001',
      cleanedBy: json['cleaned_by'],
      cleanedAt: json['cleaned_at'],
      notes: json['notes'],
    );
  }
  
  Future<void> reportCleaned(String id, String cleanedBy, String notes) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/report_cleaned'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': id,
          'cleaned_by': cleanedBy,
          'notes': notes,
          'cleaned_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to report cleaned: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error reporting cleaned: $e');
    }
  }
  
  void dispose() {
    _client.close();
  }
} 
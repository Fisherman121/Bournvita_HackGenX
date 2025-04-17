import '../utils/config.dart';
import '../services/api_service.dart';

class Detection {
  final String timestamp;
  final String detectionClass;
  final double confidence;
  final String status;
  final String imagePath;
  final String imageUrl;
  final bool forCleaning;
  final String cameraId;
  final String zoneName;
  final String location;
  String? cleanedBy;
  String? cleanedAt;
  String? notes;

  Detection({
    required this.timestamp,
    required this.detectionClass,
    required this.confidence,
    required this.status,
    required this.imagePath,
    required this.imageUrl,
    required this.forCleaning,
    required this.cameraId,
    required this.zoneName,
    required this.location,
    this.cleanedBy,
    this.cleanedAt,
    this.notes,
  });

  factory Detection.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
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

    // Handle image path and url, constructing if necessary
    String imagePath = json['image_path'] ?? '';
    String imageUrl = json['image_url'] ?? '';
    
    if (imagePath.isNotEmpty && imageUrl.isEmpty && baseUrl != null) {
      // Use provided baseUrl to construct the full URL
      imageUrl = '$baseUrl/view_image/$imagePath';
    } else if (imagePath.isNotEmpty && imageUrl.isEmpty) {
       // Use the robust image server URL from Config
      imageUrl = Config.getDirectImageUrl(imagePath);
    }
    
    // Handle minimal detection case where imagePath might be missing
    if (imageUrl.isEmpty && json.containsKey('minimal') && json['minimal'] == true) {
        // Get placeholder from Config
        imageUrl = '${Config.getImageServerUrl()}/static/images/placeholder-image.jpg';
    }

    return Detection(
      timestamp: json['timestamp'] ?? '',
      detectionClass: detectionClass,
      confidence: confidence,
      status: json['status'] ?? 'pending',
      imagePath: imagePath,
      imageUrl: imageUrl, // Use the constructed or provided URL
      forCleaning: json['forCleaning'] ?? false,
      cameraId: json['camera_id'] ?? 'unknown',
      zoneName: json['zone_name'] ?? 'Unknown Zone',
      location: json['location'] ?? 'Unknown Location',
      cleanedBy: json['cleaned_by'],
      cleanedAt: json['cleaned_at'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'class': detectionClass,
      'confidence': confidence,
      'status': status,
      'image_path': imagePath,
      'image_url': imageUrl,
      'forCleaning': forCleaning,
      'camera_id': cameraId,
      'zone_name': zoneName,
      'location': location,
      'cleaned_by': cleanedBy,
      'cleaned_at': cleanedAt,
      'notes': notes,
    };
  }
  
  bool get isCleaned => status == 'cleaned';

  // Simplified getter for effective image URL
  String get effectiveImageUrl {
    // If we're using the test mode from API service, prefer the test URL
    if (ApiService.useTestMode && ApiService.testImageServerUrl.isNotEmpty) {
      print('DEBUG: Using test image URL: ${ApiService.testImageServerUrl}');
      return ApiService.testImageServerUrl;
    }
    
    // Try different approaches to construct a valid image URL
    
    // 1. If imageUrl is absolute and valid, use it directly
    if (imageUrl.isNotEmpty && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      print('DEBUG: Using direct imageUrl: $imageUrl');
      return imageUrl;
    }
    
    // 2. If we have an imagePath, construct using the fixed server URL
    if (imagePath.isNotEmpty) {
      final imageFileName = imagePath.split('/').last;
      
      // Try several endpoints based on the server configuration
      
      // Method 1: Use direct uploads-direct endpoint
      final directUrl = '${Config.getImageServerUrl()}/uploads-direct/$imageFileName';
      print('DEBUG: Using uploads-direct URL: $directUrl');
      return directUrl;
    }
    
    // 3. Fallback to using the view_image endpoint with better path handling
    if (imagePath.isNotEmpty) {
      final path = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
      final url = '${Config.getImageServerUrl()}/view_image/$path';
      print('DEBUG: Using view_image URL with path: $url');
      return url;
    }
    
    // 4. If all else fails, return a placeholder image
    final placeholderUrl = '${Config.getImageServerUrl()}/static/images/placeholder-image.jpg';
    print('DEBUG: Using placeholder image: $placeholderUrl');
    return placeholderUrl;
  }
  
  // Try using image-by-timestamp endpoint which has better error handling
  String get timestampImageUrl {
    // Encode the timestamp for use in URL
    final safeTimestamp = Uri.encodeComponent(timestamp);
    return '${Config.getImageServerUrl()}/image-by-timestamp/$safeTimestamp';
  }
  
  // URL that uses direct image access by filename
  String get directImageUrl {
    if (imagePath.isEmpty) return effectiveImageUrl;
    
    final imageFileName = imagePath.split('/').last;
    return '${Config.getImageServerUrl()}/image-direct/$imageFileName';
  }
  
  // Get image URL as base64 encoded string - useful if direct URLs don't work
  String get base64ImageUrl {
    if (imagePath.isEmpty) return effectiveImageUrl;
    
    final imageFileName = imagePath.split('/').last;
    return '${Config.getImageServerUrl()}/get_image_base64/$imageFileName';
  }
  
  // Check if image is likely to exist
  bool get hasImage => imagePath.isNotEmpty || imageUrl.isNotEmpty;
} 
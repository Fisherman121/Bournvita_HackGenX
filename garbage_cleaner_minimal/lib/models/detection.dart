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
       // Fallback if no baseUrl provided (less reliable)
      imageUrl = 'http://10.0.2.2:8080/view_image/$imagePath';
    }
    
    // Handle minimal detection case where imagePath might be missing
    if (imageUrl.isEmpty && json.containsKey('minimal') && json['minimal'] == true) {
        if (baseUrl != null) {
            imageUrl = '$baseUrl/static/images/placeholder-image.jpg';
        } else {
            imageUrl = 'http://10.0.2.2:8080/static/images/placeholder-image.jpg'; // Default placeholder
        }
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
} 
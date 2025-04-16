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

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'detectionClass': detectionClass,
      'confidence': confidence,
      'status': status,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'forCleaning': forCleaning ? 1 : 0,
      'cameraId': cameraId,
      'zoneName': zoneName,
      'location': location,
      'cleanedBy': cleanedBy,
      'cleanedAt': cleanedAt,
      'notes': notes,
    };
  }

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      timestamp: json['timestamp'] ?? '',
      detectionClass: json['detectionClass'] ?? '',
      confidence: json['confidence'] is double 
          ? json['confidence'] 
          : (json['confidence'] is int ? (json['confidence'] as int).toDouble() : 0.0),
      status: json['status'] ?? 'pending',
      imagePath: json['imagePath'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      forCleaning: json['forCleaning'] == 1,
      cameraId: json['cameraId'] ?? '',
      zoneName: json['zoneName'] ?? '',
      location: json['location'] ?? '',
      cleanedBy: json['cleanedBy'],
      cleanedAt: json['cleanedAt'],
      notes: json['notes'],
    );
  }
  
  bool get isCleaned => status.toLowerCase() == 'cleaned';
} 
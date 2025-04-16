class Detection {
  final String? id;
  final String timestamp;
  final String detectionClass;
  final double confidence;
  final String status;
  final String imagePath;
  final String? imageUrl;
  final int forCleaning;
  final String location;
  final String zoneName;
  final String cameraId;
  final String? cleanedBy;
  final String? cleanedAt;
  final String? notes;

  Detection({
    this.id,
    required this.timestamp,
    required this.detectionClass,
    required this.confidence,
    required this.status,
    required this.imagePath,
    this.imageUrl,
    required this.forCleaning,
    required this.location,
    required this.zoneName,
    required this.cameraId,
    this.cleanedBy,
    this.cleanedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'detectionClass': detectionClass,
      'confidence': confidence,
      'status': status,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'forCleaning': forCleaning,
      'location': location,
      'zoneName': zoneName,
      'cameraId': cameraId,
      'cleanedBy': cleanedBy,
      'cleanedAt': cleanedAt,
      'notes': notes,
    };
  }

  factory Detection.fromMap(Map<String, dynamic> map) {
    return Detection(
      id: map['id'],
      timestamp: map['timestamp'],
      detectionClass: map['detectionClass'],
      confidence: map['confidence'],
      status: map['status'],
      imagePath: map['imagePath'],
      imageUrl: map['imageUrl'],
      forCleaning: map['forCleaning'],
      location: map['location'],
      zoneName: map['zoneName'],
      cameraId: map['cameraId'],
      cleanedBy: map['cleanedBy'],
      cleanedAt: map['cleanedAt'],
      notes: map['notes'],
    );
  }

  Detection copyWith({
    String? id,
    String? timestamp,
    String? detectionClass,
    double? confidence,
    String? status,
    String? imagePath,
    String? imageUrl,
    int? forCleaning,
    String? location,
    String? zoneName,
    String? cameraId,
    String? cleanedBy,
    String? cleanedAt,
    String? notes,
  }) {
    return Detection(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      detectionClass: detectionClass ?? this.detectionClass,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      forCleaning: forCleaning ?? this.forCleaning,
      location: location ?? this.location,
      zoneName: zoneName ?? this.zoneName,
      cameraId: cameraId ?? this.cameraId,
      cleanedBy: cleanedBy ?? this.cleanedBy,
      cleanedAt: cleanedAt ?? this.cleanedAt,
      notes: notes ?? this.notes,
    );
  }

  bool get isCleaned => status.toLowerCase() == 'cleaned';
  bool get isForCleaning => forCleaning == 1;
  bool get needsAttention => !isCleaned && isForCleaning;
  bool get isRecent {
    final detectionTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    return now.difference(detectionTime).inHours < 24; // Less than 24 hours old
  }
  
  bool get hasImage => imagePath.isNotEmpty || (imageUrl != null && imageUrl!.isNotEmpty);
  
  DateTime get detectionTime => DateTime.parse(timestamp);
  DateTime? get cleaningTime => cleanedAt != null ? DateTime.parse(cleanedAt!) : null;
  
  String get formattedTimestamp {
    final time = detectionTime;
    return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  String get formattedCleanedAt {
    if (cleaningTime == null) return 'Not cleaned';
    final time = cleaningTime!;
    return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  String get displayClass {
    if (detectionClass.isEmpty) return 'Unknown';
    // Capitalize first letter of each word
    return detectionClass.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  String get displayConfidence {
    return '${(confidence * 100).toStringAsFixed(0)}%';
  }
  
  String get effectiveImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }
    if (imagePath.isNotEmpty) {
      // This assumes a specific pattern - adjust based on your server setup
      return 'http://10.0.2.2:8080/view_image/$imagePath';
    }
    return '';
  }
} 
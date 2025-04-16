import 'dart:io';

class GarbageReport {
  final String id;
  final File imageFile;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String status;

  GarbageReport({
    required this.id,
    required this.imageFile,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.status,
  });

  // In a real app, you might want to convert to/from JSON for API communication
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imageFile.path,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }
} 
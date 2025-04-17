class Zone {
  final String id;
  final String name;
  final String description;
  final List<String> cameraIds;
  final Map<String, dynamic>? location;
  final bool isActive;

  Zone({
    required this.id,
    required this.name,
    required this.description,
    required this.cameraIds,
    this.location,
    this.isActive = true,
  });

  String get zoneName => name;
  
  String get locationString => location != null 
      ? (location!['address'] as String?) ?? 'Unknown Location' 
      : 'Unknown Location';

  factory Zone.fromJson(String id, Map<String, dynamic> json) {
    // Handle cameraIds which could be a list of strings or a single string
    List<String> parseCameraIds() {
      if (json['camera_ids'] == null) return [];
      
      if (json['camera_ids'] is List) {
        return (json['camera_ids'] as List).map((e) => e.toString()).toList();
      } else if (json['camera_ids'] is String) {
        final idString = json['camera_ids'] as String;
        return idString.split(',').map((e) => e.trim()).toList();
      }
      
      return [];
    }

    return Zone(
      id: id,
      name: json['name'] ?? 'Unknown Zone',
      description: json['description'] ?? '',
      cameraIds: parseCameraIds(),
      location: json['location'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'camera_ids': cameraIds,
      'location': location,
      'is_active': isActive,
    };
  }

  @override
  String toString() => name;
} 
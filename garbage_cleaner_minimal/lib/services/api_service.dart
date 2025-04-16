import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart'; // Import IOClient
import '../models/detection.dart';
import '../models/zone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class ApiService {
  static String _baseUrl = Config.apiBaseUrl;
  final http.Client _client;
  static bool debugMode = true; // Enable debug printing

  ApiService({
    String? baseUrl,
    http.Client? client,
  }) : _client = client ?? getClient();

  static String get baseUrl => _baseUrl;
  static set baseUrl(String url) => _baseUrl = url;

  // Use dart:io HttpClient via IOClient for more control
  static http.Client getClient() {
    final ioClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30) // Connection timeout
      ..idleTimeout = const Duration(seconds: 30); // Idle timeout
      
    // This line bypasses certificate validation - USE WITH CAUTION
    // ONLY for debugging local HTTP servers. Remove for production HTTPS.
    ioClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      
    return IOClient(ioClient);
  }
  
  // Debug print function
  static void debugPrint(String message) {
    if (debugMode) {
      print("API_DEBUG: $message");
    }
  }
  
  // Get all detections with a simpler approach (try to minimize data)
  Future<List<Detection>> getSimpleDetections() async {
    try {
      final url = await getBaseUrl();
      debugPrint("Trying simplified approach with URL: $url/api_check");
      
      // First just test if the API is reachable at all
      final testResponse = await http.get(
        Uri.parse('$url/api_check'),
      ).timeout(const Duration(seconds: 30)); // Longer timeout
      
      if (testResponse.statusCode == 200) {
        debugPrint("API check successful, trying to get detections");
        
        // Now try to get actual detections
        final logsResponse = await http.get(
          Uri.parse('$url/get_logs'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 30)); // Longer timeout
        
        if (logsResponse.statusCode == 200 && logsResponse.body.isNotEmpty) {
          debugPrint("Got logs response, length: ${logsResponse.body.length}");
          try {
            final List<dynamic> detectionList = json.decode(logsResponse.body);
            debugPrint("Parsed ${detectionList.length} detections");
            
            return detectionList.map((json) {
              // Add image_url if not present
              if (json['image_path'] != null && !json.containsKey('image_url')) {
                json['image_url'] = '$url/view_image/${json['image_path']}';
              }
              return Detection.fromJson(json);
            }).toList();
          } catch (e) {
            debugPrint("Error parsing JSON: $e");
            return [];
          }
        } else {
          debugPrint("Invalid logs response: ${logsResponse.statusCode}, body length: ${logsResponse.body.length}");
          return [];
        }
      } else {
        debugPrint("API check failed: ${testResponse.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error in simple detections: $e");
      return [];
    }
  }
  
  // Get the base URL - used by all API methods
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      baseUrl = savedUrl;
      debugPrint("Using saved URL: $baseUrl");
    }
    return baseUrl;
  }
  
  // Setup method to configure server URL
  static Future<void> setupServerUrl(String url) async {
    if (url.trim().isEmpty) return;
    
    baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
    debugPrint("Server URL set to: $url");
  }
  
  // Initialize from saved preferences
  static Future<void> initFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      baseUrl = savedUrl;
      debugPrint("Loaded server URL from prefs: $baseUrl");
    } else {
      debugPrint("Using default server URL: $baseUrl");
    }
  }
  
  // Test connection to server using IOClient
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final url = await getBaseUrl();
      debugPrint("Testing connection to $url/api_check");
      final response = await _client.get(
        Uri.parse('$url/api_check'),
      ).timeout(const Duration(seconds: 30));
      
      debugPrint("Test Connection - Status: ${response.statusCode}");
      return {
        'success': response.statusCode == 200,
        'message': response.statusCode == 200 ? 'Connection successful' : 'Connection failed',
        'status_code': response.statusCode,
      };
    } catch (e) {
      debugPrint("Connection error: $e");
      return {'success': false, 'message': 'Connection error: $e', 'error': e.toString()};
    }
  }
  
  // Get all detections directly from logs (not just those marked for cleaning)
  Future<List<Detection>> getAllDetections() async {
    try {
      final url = await getBaseUrl();
      final response = await _client.get(
        Uri.parse('$url/detections'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Config.apiTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Detection.fromJson(json, baseUrl: url)).toList();
      } else {
        throw ApiException('Failed to fetch detections', statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }
  
  // Get all detections from the server (only cleaning tasks)
  Future<List<Detection>> getCleaningDetections() async {
    try {
      final url = await getBaseUrl();
      debugPrint("Fetching cleaning detections from: $url/mobile/get_detections");
      final response = await _client.get(
        Uri.parse('$url/mobile/get_detections'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Config.apiTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['detections'] != null) {
          final List<dynamic> detectionList = data['detections'];
          debugPrint("Parsed ${detectionList.length} cleaning detections");
          return detectionList.map((json) => Detection.fromJson(json, baseUrl: url)).toList();
        } else {
          throw ApiException('Invalid response format', statusCode: response.statusCode);
        }
      } else {
        throw ApiException('Failed to fetch cleaning detections', statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }
  
  // Fallback method - try direct API call without JSON parsing using IOClient
  Future<String> getRawLogs() async {
    try {
      final url = await getBaseUrl();
      final response = await _client.get(Uri.parse('$url/get_logs'));
      return response.body;
    } catch (e) {
      return "Error: $e";
    }
  }
  
  // Update detection status
  Future<void> updateDetectionStatus(String timestamp, String status) async {
    try {
      final url = await getBaseUrl();
      final response = await _client.patch(
        Uri.parse('$url/detections/$timestamp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      ).timeout(Config.apiTimeout);

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to update detection status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }
  
  // Mark detection as cleaned with additional info
  Future<void> reportCleaned(
    String timestamp,
    String cleanedBy,
    String notes,
  ) async {
    try {
      final url = await getBaseUrl();
      final response = await _client.post(
        Uri.parse('$url/detections/$timestamp/cleaned'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'cleanedBy': cleanedBy,
          'notes': notes,
          'cleanedAt': DateTime.now().toIso8601String(),
        }),
      ).timeout(Config.apiTimeout);

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to report cleaning',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }
  
  // Get all zones from the server
  Future<List<Zone>> getZones() async {
    try {
      final url = await getBaseUrl();
      final response = await _client.get(
        Uri.parse('$url/mobile/get_zones'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Config.apiTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['zones'] != null) {
          final Map<String, dynamic> zonesMap = data['zones'];
          List<Zone> zones = [];
          
          zonesMap.forEach((id, zoneData) {
            zones.add(Zone.fromJson(id, zoneData));
          });
          
          return zones;
        } else {
          throw ApiException('Invalid zones response format', statusCode: response.statusCode);
        }
      } else {
        throw ApiException('Failed to fetch zones', statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }
  
  // Set active camera
  Future<bool> setActiveCamera(String cameraId) async {
    try {
      final url = await getBaseUrl();
      final response = await _client.post(
        Uri.parse('$url/mobile/set_camera'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'camera_id': cameraId,
        }),
      ).timeout(Config.apiTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw ApiException('Failed to set active camera', statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }
  
  // Upload cleaning report
  Future<bool> uploadReport({
    required File imageFile,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      final url = await getBaseUrl();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$url/upload_report'),
      );
      
      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );
      
      // Add fields
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['timestamp'] = DateTime.now().toIso8601String();
      
      if (notes != null) {
        request.fields['notes'] = notes;
      }
      
      var streamedResponse = await request.send().timeout(Config.apiTimeout);
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode != 200) {
        throw ApiException('Failed to upload report', statusCode: response.statusCode);
      }
      
      return true;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }
  
  // Get lightweight data for mobile testing
  Future<List<Detection>> getMinimalDetections() async {
    try {
      final url = await getBaseUrl();
      debugPrint("Fetching minimal detections from: $url/mobile_minimal");
      final response = await _client.get(
        Uri.parse('$url/mobile_minimal'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Config.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['minimal_detections'] != null) {
          final List<dynamic> detectionList = data['minimal_detections'];
          debugPrint("Parsed ${detectionList.length} minimal detections");
          
          List<Detection> detections = [];
          for (var json in detectionList) {
            // Add the minimal flag to ensure proper processing in fromJson
            json['minimal'] = true;
            detections.add(Detection.fromJson(json, baseUrl: url));
          }
          
          return detections;
        } else {
          throw ApiException('Invalid minimal detections format', statusCode: response.statusCode);
        }
      } else {
        throw ApiException('Failed to fetch minimal detections', statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<void> uploadDetection(Detection detection) async {
    try {
      final url = await getBaseUrl();
      final response = await _client.post(
        Uri.parse('$url/detections'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(detection.toJson()),
      ).timeout(Config.apiTimeout);

      if (response.statusCode != 201) {
        throw ApiException(
          'Failed to upload detection',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Sync local detections with server
  Future<void> syncDetections(List<Detection> localDetections) async {
    try {
      final url = await getBaseUrl();
      final response = await _client.post(
        Uri.parse('$url/mobile/sync_detections'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'detections': localDetections.map((d) => d.toJson()).toList(),
        }),
      ).timeout(Config.apiTimeout);
      
      if (response.statusCode != 200) {
        throw ApiException('Failed to sync detections', statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
} 
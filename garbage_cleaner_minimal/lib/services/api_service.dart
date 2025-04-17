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
  
  // Track which image server URL works best
  static String? _workingImageServerUrl;
  
  // Add flag to bypass normal URL building for testing purposes
  static bool useTestMode = false;
  static String testImageServerUrl = ''; // Will be set by the test UI

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
  
  // Test image server connectivity
  Future<Map<String, dynamic>> testImageServer() async {
    try {
      final baseUrl = await getBaseUrl();
      final imageUrl = '${Config.getImageServerUrl()}/static/images/placeholder-image.jpg';
      final altImageUrl = '$baseUrl/static/images/placeholder-image.jpg';
      
      debugPrint("Testing image server URL: $imageUrl");
      
      try {
        // Try first image URL
        final response = await _client.head(
          Uri.parse(imageUrl),
        ).timeout(const Duration(seconds: 10));
        
        debugPrint("Image server test - Primary URL - Status: ${response.statusCode}");
        
        if (response.statusCode == 200) {
          // Save this as the working URL
          final urlBase = imageUrl.substring(0, imageUrl.lastIndexOf('/static'));
          setWorkingImageServerUrl(urlBase);
          
          return {
            'success': true,
            'message': 'Image server connection successful',
            'status_code': response.statusCode,
            'url_used': imageUrl,
          };
        }
      } catch (e) {
        debugPrint("Primary image URL test failed: $e");
      }
      
      // If first URL failed, try alternative URL
      debugPrint("Trying alternative image URL: $altImageUrl");
      
      try {
        final altResponse = await _client.head(
          Uri.parse(altImageUrl),
        ).timeout(const Duration(seconds: 10));
        
        debugPrint("Image server test - Alternative URL - Status: ${altResponse.statusCode}");
        
        if (altResponse.statusCode == 200) {
          // Save this as the working URL
          final urlBase = altImageUrl.substring(0, altImageUrl.lastIndexOf('/static'));
          setWorkingImageServerUrl(urlBase);
          
          return {
            'success': true,
            'message': 'Alternative image URL connection successful',
            'status_code': altResponse.statusCode,
            'url_used': altImageUrl,
          };
        }
        
        return {
          'success': false,
          'message': 'Both image URLs failed - Status: ${altResponse.statusCode}',
          'status_code': altResponse.statusCode,
        };
      } catch (e) {
        debugPrint("Alternative image URL test failed: $e");
        return {
          'success': false,
          'message': 'All image server tests failed',
          'error': e.toString(),
        };
      }
    } catch (e) {
      debugPrint("Image server test error: $e");
      return {'success': false, 'message': 'Image server error: $e', 'error': e.toString()};
    }
  }
  
  // Get all detections directly from the new API endpoint with fallbacks
  Future<List<Detection>> getAllDetections() async {
    List<String> errors = [];
    
    // List of endpoints to try in order
    final endpoints = [
      "/api/detections",   // New API endpoint
      "/get_logs",         // Legacy endpoint
      "/mobile/get_detections", // Mobile-specific endpoint
    ];
    
    for (final endpoint in endpoints) {
      try {
        final url = await getBaseUrl();
        final fullUrl = "$url$endpoint";
        debugPrint("Fetching detections from: $fullUrl");
        
        final response = await _client.get(
          Uri.parse(fullUrl),
          headers: {'Content-Type': 'application/json'},
        ).timeout(Config.apiTimeout);

        if (response.statusCode == 200) {
          // Try to parse the response based on the endpoint format
          if (endpoint == "/api/detections") {
            // New API format with success flag and detections array
            final data = json.decode(response.body);
            if (data['success'] == true && data['detections'] != null) {
              final List<dynamic> detectionList = data['detections'];
              debugPrint("Parsed ${detectionList.length} detections from $endpoint");
              return detectionList.map((json) => Detection.fromJson(json, baseUrl: url)).toList();
            }
          } else if (endpoint == "/get_logs") {
            // Direct array format from legacy endpoint
            final List<dynamic> detectionList = json.decode(response.body);
            debugPrint("Parsed ${detectionList.length} detections from $endpoint");
            return detectionList.map((json) => Detection.fromJson(json, baseUrl: url)).toList();
          } else if (endpoint == "/mobile/get_detections") {
            // Mobile format with success flag and detections array
            final data = json.decode(response.body);
            if (data['success'] == true && data['detections'] != null) {
              final List<dynamic> detectionList = data['detections'];
              debugPrint("Parsed ${detectionList.length} detections from $endpoint");
              return detectionList.map((json) => Detection.fromJson(json, baseUrl: url)).toList();
            }
          }
        }
        
        // If we get here, the endpoint didn't return valid data
        errors.add("Endpoint $endpoint returned status ${response.statusCode}");
        
      } catch (e) {
        debugPrint("Error fetching from $endpoint: $e");
        errors.add("$endpoint: ${e.toString()}");
        // Continue to next endpoint
      }
    }
    
    // If we've tried all endpoints and none worked
    final errorMsg = "All endpoints failed: ${errors.join(', ')}";
    debugPrint(errorMsg);
    throw ApiException(errorMsg);
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
  
  // Update detection status using new API endpoint
  Future<bool> updateDetectionStatus(String timestamp, String status, {String? cleanedBy, String? notes}) async {
    try {
      final url = await getBaseUrl();
      debugPrint("Updating detection status at: $url/api/detections/$timestamp");
      
      final payload = {
        'status': status,
      };
      
      if (status == 'cleaned' && cleanedBy != null) {
        payload['cleanedBy'] = cleanedBy;
        if (notes != null) {
          payload['notes'] = notes;
        }
      }
      
      final response = await _client.patch(
        Uri.parse('$url/api/detections/$timestamp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(Config.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw ApiException('Failed to update detection status', statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint("Error updating detection status: $e");
      return false;
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

  // Sync local detections with the server
  Future<bool> syncDetections(List<Detection> localDetections) async {
    try {
      // First update any local changes to the server
      for (var detection in localDetections) {
        if (detection.status == 'cleaned') {
          // If it's been cleaned locally, update on server
          await updateDetectionStatus(
            detection.timestamp, 
            detection.status,
            cleanedBy: detection.cleanedBy,
            notes: detection.notes
          );
        }
      }
      
      // Then get latest from server
      return true;
    } catch (e) {
      debugPrint("Error syncing detections: $e");
      return false;
    }
  }

  Future<bool> addDetection(Detection detection) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/detections'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(detection.toJson()),
      ).timeout(Config.apiTimeout);
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding detection: $e');
      return false;
    }
  }

  void dispose() {
    _client.close();
  }

  // Get a working image URL (with caching)
  static String getImageUrl(String path) {
    // If test mode is enabled, use the test URL
    if (useTestMode && testImageServerUrl.isNotEmpty) {
      debugPrint("Using test image URL: $testImageServerUrl");
      return testImageServerUrl;
    }
    
    String baseUrl;
    if (_workingImageServerUrl != null) {
      // Use cached working URL 
      baseUrl = _workingImageServerUrl!;
    } else {
      // Default to Config image server
      baseUrl = Config.getImageServerUrl();
    }
    
    // Ensure path doesn't start with a slash if baseUrl ends with one
    if (baseUrl.endsWith('/') && path.startsWith('/')) {
      path = path.substring(1);
    } else if (!baseUrl.endsWith('/') && !path.startsWith('/')) {
      path = '/$path';
    }
    
    final fullUrl = baseUrl + path;
    
    // Ensure the URL uses http or https
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      return 'http://$fullUrl';
    }
    
    return fullUrl;
  }
  
  // Update the working image server URL based on test results
  static void setWorkingImageServerUrl(String url) {
    debugPrint("Setting working image server URL to: $url");
    _workingImageServerUrl = url;
  }

  // New method to fetch an image as base64 from the server
  Future<String?> getImageAsBase64(String imagePath) async {
    if (imagePath.isEmpty) return null;
    
    try {
      final servers = [
        // Try multiple possible servers
        "${ApiService.baseUrl}/get_image_base64/$imagePath",
        "http://172.26.26.216:5000/get_image_base64/$imagePath",
        "http://10.0.2.2:8080/get_image_base64/$imagePath",
      ];
      
      for (final serverUrl in servers) {
        try {
          debugPrint("Trying to fetch image as base64 from: $serverUrl");
          final response = await _client.get(
            Uri.parse(serverUrl),
          ).timeout(const Duration(seconds: 10));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['success'] == true && data['image_data'] != null) {
              final base64Data = data['image_data'];
              debugPrint("Successfully retrieved image as base64, length: ${base64Data.length}");
              return base64Data;
            }
          }
        } catch (e) {
          debugPrint("Error fetching image as base64 from $serverUrl: $e");
          // Continue to next server
        }
      }
      
      // If we reach here, we couldn't get the base64 data from any server
      return null;
    } catch (e) {
      debugPrint("Error in getImageAsBase64: $e");
      return null;
    }
  }
  
  // Fallback to a built-in base64 image of a placeholder
  static String getPlaceholderImageBase64() {
    // This is a very small base64-encoded placeholder image
    return "iVBORw0KGgoAAAANSUhEUgAAAGQAAABkAQMAAABKLAcXAAAAA1BMVEXm5uTwA8sKAAAAE0lEQVR4AWOgFRgFo2AUjIJRQE8AAAs8AAEjhT8SAAAAAElFTkSuQmCC";
  }
} 
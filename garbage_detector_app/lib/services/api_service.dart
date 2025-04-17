import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/detection.dart';
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
  static bool debugMode = true;
  
  // Track which image server URL works best
  static String? _workingImageServerUrl;
  
  // Add flag to bypass normal URL building for testing purposes
  static bool useTestMode = false;
  static String testImageServerUrl = '';

  ApiService({
    String? baseUrl,
    http.Client? client,
  }) : _client = client ?? getClient();

  static String get baseUrl => _baseUrl;
  static set baseUrl(String url) => _baseUrl = url;

  // Use dart:io HttpClient via IOClient for more control
  static http.Client getClient() {
    final ioClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 30);
      
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
  
  // Get all detections with a simpler approach
  Future<List<Detection>> getSimpleDetections() async {
    try {
      final url = await getBaseUrl();
      debugPrint("Trying simplified approach with URL: $url/api_check");
      
      // First just test if the API is reachable at all
      final testResponse = await http.get(
        Uri.parse('$url/api_check'),
      ).timeout(const Duration(seconds: 30));
      
      if (testResponse.statusCode == 200) {
        debugPrint("API check successful, trying to get detections");
        
        // Now try to get actual detections
        final logsResponse = await http.get(
          Uri.parse('$url/get_logs'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 30));
        
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
  
  // Set the working image server URL
  static void setWorkingImageServerUrl(String url) {
    _workingImageServerUrl = url;
    debugPrint("Set working image server URL to: $url");
  }
  
  // Get the working image server URL
  static String? getWorkingImageServerUrl() {
    return _workingImageServerUrl;
  }
} 
import 'dart:io';
import 'package:flutter/foundation.dart';

class Config {
  // Default API URL - will be replaced with the one saved in SharedPreferences
  static String apiBaseUrl = 'http://172.26.26.216:5000';
  
  // Flag to force using a specific URL for image loading
  static bool useFixedImageServerUrl = true;
  
  // Fixed image server URL - use this if you're having issues with image loading
  static String fixedImageServerUrl = 'http://172.26.26.216:5000';
  
  // List of fallback image server URLs to try
  static final List<String> fallbackUrls = [
    'http://172.26.26.216:5000',  // Direct IP Port 5000
    'http://172.26.26.216:8080',  // Direct IP Port 8080
    'http://10.0.2.2:8080',       // Android Emulator to Host
    'http://localhost:8080',      // Direct localhost
  ];
  
  // API timeout duration
  static const apiTimeout = Duration(seconds: 30);
  
  // App name
  static const appName = 'Garbage Detector';
  
  // App version
  static const appVersion = '1.0.0';
  
  // Debug mode
  static const bool debugMode = true;
  
  // Database Configuration
  static const String dbName = 'detections.db';
  static const int dbVersion = 1;
  
  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const bool enableBackgroundSync = true;
  static const int maxSyncRetries = 3;
  static const Duration retryDelay = Duration(seconds: 30);
  
  // Storage Configuration
  static const String detectionsBoxName = 'detections';
  static const String settingsBoxName = 'settings';
  
  // Authentication
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const Duration sessionTimeout = Duration(days: 7);
  
  // UI Configuration
  static const int maxRecentDetections = 10;
  static const Duration loadingTimeout = Duration(seconds: 10);
  static const Duration toastDuration = Duration(seconds: 3);
  
  // Image Configuration
  static const double maxImageSize = 1024;  // Maximum width/height for uploaded images
  static const int jpegQuality = 85;  // JPEG compression quality (0-100)
  
  // Location Configuration
  static const Duration locationTimeout = Duration(seconds: 15);
  static const double locationAccuracy = 50.0;  // Desired accuracy in meters
  
  // Helper methods
  static String getPlatformSpecificApiUrl() {
    if (Platform.isAndroid) {
      // For Android emulator, 10.0.2.2 maps to the host's localhost
      return 'http://10.0.2.2:8080';
    } else if (Platform.isIOS) {
      return 'http://localhost:8080'; // iOS simulator
    } else {
      return 'http://localhost:8080'; // Default for web/desktop
    }
  }
  
  // Get URL for images with server-specific configuration
  static String getImageServerUrl() {
    if (useFixedImageServerUrl) {
      return fixedImageServerUrl;
    }
    
    // Otherwise use the configured API URL
    return apiBaseUrl;
  }
  
  // Get direct URL for viewing images - useful for debug
  static String getDirectImageUrl(String imagePath) {
    final baseUrl = getImageServerUrl();
    final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    
    // Try different URL formats based on the server endpoint
    if (baseUrl.contains('172.26.26.216')) {
      // For the specific server setup
      return '$baseUrl/uploads-direct/${Uri.encodeComponent(cleanPath.split('/').last)}';
    } else {
      // For other server setups
      return '$baseUrl/view_image/$cleanPath';
    }
  }
  
  // Debug method to print all config values
  static void printConfig() {
    print('DEBUG CONFIG: apiBaseUrl = $apiBaseUrl');
    print('DEBUG CONFIG: platformSpecific URL = ${getPlatformSpecificApiUrl()}');
    print('DEBUG CONFIG: imageServer URL = ${getImageServerUrl()}');
    print('DEBUG CONFIG: useFixedImageServerUrl = $useFixedImageServerUrl');
  }
} 
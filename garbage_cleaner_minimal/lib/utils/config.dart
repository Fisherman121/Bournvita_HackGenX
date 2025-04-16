import 'dart:io';

class Config {
  // API Configuration
  static const String apiBaseUrl = 'http://10.0.2.2:8080'; // Default for Android emulator
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Database Configuration
  static const String dbName = 'detections.db';
  static const int dbVersion = 1;
  
  // App Configuration
  static const String appName = 'Garbage Detector';
  static const bool debugMode = true;
  
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
      return 'http://10.0.2.2:8080'; // Android emulator
    } else if (Platform.isIOS) {
      return 'http://localhost:8080'; // iOS simulator
    } else {
      return 'http://localhost:8080'; // Default for web/desktop
    }
  }
} 
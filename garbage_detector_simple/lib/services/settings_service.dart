import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _apiUrlKey = 'api_url';
  static const String _userNameKey = 'user_name';
  static const String _syncIntervalKey = 'sync_interval_minutes';
  
  // Default values
  static const String defaultApiUrl = 'http://10.0.2.2:8080';
  static const String defaultUserName = 'Staff User';
  static const int defaultSyncInterval = 1; // 1 minute
  
  // Singleton instance
  static SettingsService? _instance;
  
  // Private constructor
  SettingsService._();
  
  // Factory constructor to get the singleton instance
  factory SettingsService() {
    _instance ??= SettingsService._();
    return _instance!;
  }
  
  // Cached settings
  String? _apiUrl;
  String? _userName;
  int? _syncInterval;
  
  // Get API URL
  Future<String> getApiUrl() async {
    if (_apiUrl != null) return _apiUrl!;
    
    final prefs = await SharedPreferences.getInstance();
    _apiUrl = prefs.getString(_apiUrlKey) ?? defaultApiUrl;
    return _apiUrl!;
  }
  
  // Set API URL
  Future<void> setApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, url);
    _apiUrl = url;
  }
  
  // Get user name
  Future<String> getUserName() async {
    if (_userName != null) return _userName!;
    
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString(_userNameKey) ?? defaultUserName;
    return _userName!;
  }
  
  // Set user name
  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    _userName = name;
  }
  
  // Get sync interval in minutes
  Future<int> getSyncIntervalMinutes() async {
    if (_syncInterval != null) return _syncInterval!;
    
    final prefs = await SharedPreferences.getInstance();
    _syncInterval = prefs.getInt(_syncIntervalKey) ?? defaultSyncInterval;
    return _syncInterval!;
  }
  
  // Set sync interval in minutes
  Future<void> setSyncIntervalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_syncIntervalKey, minutes);
    _syncInterval = minutes;
  }
  
  // Clear all settings
  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiUrlKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_syncIntervalKey);
    
    _apiUrl = null;
    _userName = null;
    _syncInterval = null;
  }
} 
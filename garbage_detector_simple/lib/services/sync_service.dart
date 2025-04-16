import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/detection.dart';
import 'api_service.dart';
import 'local_storage.dart';

class SyncService {
  final ApiService _apiService;
  final LocalStorage _localStorage;
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  static const Duration _syncInterval = Duration(minutes: 1);
  static const String _lastSyncKey = 'last_sync_timestamp';
  
  SyncService({
    required ApiService apiService,
    required LocalStorage localStorage,
  }) : _apiService = apiService, _localStorage = localStorage;
  
  Future<void> startSync() async {
    // Perform initial sync
    await syncData();
    
    // Start periodic sync
    _syncTimer = Timer.periodic(_syncInterval, (_) async {
      await syncData();
    });
  }
  
  Future<void> syncData() async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    try {
      // Fetch detections from the API
      final detections = await _apiService.fetchDetections();
      
      // Get existing detections from local storage
      final localDetections = await _localStorage.getDetections();
      
      // Create a map of local detections by imagePath for easy lookup
      final localDetectionMap = <String, Detection>{};
      for (var detection in localDetections) {
        if (detection.imagePath.isNotEmpty) {
          localDetectionMap[detection.imagePath] = detection;
        }
      }
      
      // Process each detection from the API
      for (var apiDetection in detections) {
        // Check if we already have this detection locally
        final existingDetection = localDetectionMap[apiDetection.imagePath];
        
        if (existingDetection == null) {
          // This is a new detection, insert it
          await _localStorage.insertDetection(apiDetection);
        } else {
          // Only update if the API version has changes
          // For simplicity here, we just check if cleanedBy is different
          if (apiDetection.cleanedBy != existingDetection.cleanedBy ||
              apiDetection.status != existingDetection.status) {
            // Update with the new information
            await _localStorage.updateDetection(apiDetection.copyWith(
              id: existingDetection.id,
            ));
          }
        }
      }
      
      // Update last sync timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
    } catch (e) {
      // Log error but don't rethrow
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    if (timestamp != null) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  Future<void> syncDetection(String id) async {
    try {
      final detection = await _localStorage.getDetection(id);
      if (detection != null && detection.isCleaned) {
        await _apiService.reportCleaned(
          id,
          detection.cleanedBy ?? 'Unknown',
          detection.notes ?? '',
        );
      }
    } catch (e) {
      print('Error syncing detection: $e');
    }
  }
  
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  void dispose() {
    stopSync();
  }
} 
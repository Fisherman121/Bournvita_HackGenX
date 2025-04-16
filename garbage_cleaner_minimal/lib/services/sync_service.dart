import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/detection.dart';
import 'api_service.dart';
import 'local_storage.dart';
import 'storage_service.dart';
import 'config.dart';

class SyncService {
  final ApiService _apiService;
  final StorageService _storageService;
  Timer? _syncTimer;
  bool _isSyncing = false;
  final _syncController = StreamController<SyncStatus>.broadcast();
  
  Stream<SyncStatus> get syncStatus => _syncController.stream;
  
  SyncService({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;
  
  void startPeriodicSync() {
    if (!Config.enableBackgroundSync) return;
    
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Config.syncInterval, (_) => sync());
  }
  
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      _syncController.add(SyncStatus(status: SyncState.inProgress));
      
      // Step 1: Upload local detections that haven't been synced
      final localDetections = await _storageService.getUnsynced();
      for (final detection in localDetections) {
        try {
          await _apiService.uploadDetection(detection);
          await _storageService.markAsSynced(detection.timestamp);
        } catch (e) {
          debugPrint('Failed to sync detection ${detection.timestamp}: $e');
          // Continue with next detection even if one fails
        }
      }
      
      // Step 2: Fetch all detections from server
      final serverDetections = await _apiService.getAllDetections();
      
      // Step 3: Update local storage with server data
      await _storageService.updateFromServer(serverDetections);
      
      _syncController.add(SyncStatus(
        status: SyncState.completed,
        lastSynced: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Sync failed: $e');
      _syncController.add(SyncStatus(
        status: SyncState.error,
        error: e.toString(),
      ));
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<void> dispose() async {
    stopPeriodicSync();
    await _apiService.dispose();
    _syncController.close();
  }
}

enum SyncState {
  inProgress,
  completed,
  error,
}

class SyncStatus {
  final SyncState status;
  final DateTime? lastSynced;
  final String? error;
  
  SyncStatus({
    required this.status,
    this.lastSynced,
    this.error,
  });
} 
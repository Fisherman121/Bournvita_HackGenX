import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/detection.dart';
import 'services/local_storage.dart';
import 'services/api_service.dart';
import 'services/sync_service.dart';
import 'services/settings_service.dart';
import 'screens/settings_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run the app
  runApp(const GarbageDetectorApp());
}

class GarbageDetectorApp extends StatelessWidget {
  const GarbageDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garbage Detector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const DetectionListPage(),
    );
  }
}

class DetectionListPage extends StatefulWidget {
  const DetectionListPage({super.key});

  @override
  State<DetectionListPage> createState() => _DetectionListPageState();
}

class _DetectionListPageState extends State<DetectionListPage> {
  final LocalStorage _localStorage = LocalStorage();
  final SettingsService _settingsService = SettingsService();
  late ApiService _apiService;
  late SyncService _syncService;
  
  List<Detection> _detections = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastSyncTime;
  bool _isConnected = true;
  String _userName = 'Staff User';

  @override
  void initState() {
    super.initState();
    _initServices();
  }
  
  Future<void> _initServices() async {
    setState(() => _isLoading = true);
    
    try {
      // Load settings first
      final apiUrl = await _settingsService.getApiUrl();
      final userName = await _settingsService.getUserName();
      final syncInterval = await _settingsService.getSyncIntervalMinutes();
      
      // Initialize API service with the loaded URL
      _apiService = ApiService(baseUrl: apiUrl);
      
      // Initialize sync service with the loaded interval
      _syncService = SyncService(
        apiService: _apiService, 
        localStorage: _localStorage
      );
      
      // Start synchronization
      _syncService.startSync();
      
      // Update user name
      setState(() {
        _userName = userName;
      });
      
      // Update last sync time
      _updateSyncTime();
      
      // Load detections
      _loadDetections();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _updateSyncTime() async {
    final lastSync = await _syncService.getLastSyncTime();
    if (mounted) {
      setState(() {
        _lastSyncTime = lastSync;
      });
    }
  }

  Future<void> _loadDetections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First try to sync with the server
      if (_isConnected) {
        try {
          await _syncService.syncData();
          _updateSyncTime();
        } catch (e) {
          // If sync fails, we'll show local data with a connectivity warning
          setState(() {
            _isConnected = false;
          });
        }
      }
      
      // Then load from local storage
      final detections = await _localStorage.getDetections();
      setState(() {
        _detections = detections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load detections: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsCleaned(Detection detection) async {
    try {
      // Update local storage first
      await _localStorage.markAsCleaned(
        detection.timestamp,
        _userName,
        'Marked as cleaned from app',
      );
      
      // Then try to sync with the server
      if (_isConnected && detection.id != null) {
        try {
          await _syncService.syncDetection(detection.id!);
        } catch (e) {
          // If sync fails, we'll show a warning but the local update is already done
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Warning: Could not sync with server: $e')),
          );
        }
      }
      
      // Refresh the detections list
      _loadDetections();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to mark as cleaned: $e';
      });
    }
  }
  
  Future<void> _openSettings() async {
    // Navigate to settings screen
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    
    // If settings were changed, reinitialize services
    if (result == true) {
      _syncService.dispose();
      await _initServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garbage Detections'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetections,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetections,
        child: Column(
          children: [
            // Connection status indicator
            if (!_isConnected)
              Container(
                color: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                width: double.infinity,
                child: const Text(
                  'Offline Mode - Using local data only',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            
            // Last sync time indicator
            if (_lastSyncTime != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.sync, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Last synced: ${_formatSyncTime(_lastSyncTime!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Main content
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDetections,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_detections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text('No detections found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDetections,
              child: const Text('Check for Detections'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _detections.length,
      itemBuilder: (context, index) {
        final detection = _detections[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Detection image, if available
              if (detection.hasImage)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  child: Image.network(
                    detection.effectiveImageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 120,
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              
              // Detection details
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getColorForClass(detection.detectionClass),
                  child: Text(detection.detectionClass.substring(0, 1).toUpperCase()),
                ),
                title: Text('${detection.displayClass} (${detection.displayConfidence})'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${detection.status}'),
                    Text('Zone: ${detection.zoneName}'),
                    Text('Camera: ${detection.cameraId}'),
                    Text('Time: ${detection.formattedTimestamp}'),
                    if (detection.cleanedBy != null)
                      Text('Cleaned by: ${detection.cleanedBy}'),
                  ],
                ),
                isThreeLine: true,
                trailing: detection.status != 'cleaned'
                    ? IconButton(
                        icon: const Icon(Icons.cleaning_services),
                        onPressed: () => _markAsCleaned(detection),
                        tooltip: 'Mark as cleaned',
                      )
                    : const Icon(Icons.check_circle, color: Colors.green),
                onTap: () => _showDetailDialog(detection),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getColorForClass(String detectionClass) {
    switch (detectionClass.toLowerCase()) {
      case 'plastic':
        return Colors.blue;
      case 'paper':
        return Colors.yellow.shade800;
      case 'metal':
        return Colors.grey;
      case 'glass':
        return Colors.lightBlue;
      case 'organic':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  void _showDetailDialog(Detection detection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${detection.displayClass} Detection'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show image if available
              if (detection.hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    detection.effectiveImageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Container(
                        height: 200,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              _detailRow('Time', detection.formattedTimestamp),
              _detailRow('Status', detection.status),
              _detailRow('Confidence', detection.displayConfidence),
              _detailRow('Zone', detection.zoneName),
              _detailRow('Camera', detection.cameraId),
              _detailRow('Location', detection.location),
              if (detection.isForCleaning)
                _detailRow('Marked for cleaning', 'Yes'),
              if (detection.cleanedBy != null) ...[
                _detailRow('Cleaned by', detection.cleanedBy!),
                _detailRow('Cleaned at', detection.formattedCleanedAt),
                _detailRow('Notes', detection.notes ?? 'No notes'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!detection.isCleaned)
            TextButton(
              onPressed: () {
                _markAsCleaned(detection);
                Navigator.of(context).pop();
              },
              child: const Text('Mark as Cleaned'),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
}

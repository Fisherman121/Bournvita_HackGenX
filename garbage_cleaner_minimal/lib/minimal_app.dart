import 'package:flutter/material.dart';
import 'models/detection.dart';
import 'services/local_storage.dart';
import 'services/test_data_service.dart';
import 'services/api_service.dart';
import 'utils/config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service from preferences
  await ApiService.initFromPrefs();
  
  // Add test data to local storage
  await TestDataService.addTestData();
  
  runApp(const MinimalApp());
}

class MinimalApp extends StatelessWidget {
  const MinimalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Config.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const DetectionListPage(),
    );
  }
}

class DetectionListPage extends StatefulWidget {
  const DetectionListPage({Key? key}) : super(key: key);

  @override
  State<DetectionListPage> createState() => _DetectionListPageState();
}

class _DetectionListPageState extends State<DetectionListPage> {
  final LocalStorage _storage = LocalStorage();
  final ApiService _apiService = ApiService();
  List<Detection> _detections = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _syncStatus = 'Not synced';
  String _serverUrl = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    // Load the current server URL
    _serverUrl = await ApiService.getBaseUrl();
    
    // Load local data
    await _loadDetections();
    
    // Initial sync if possible
    await _syncWithServer();
  }

  Future<void> _loadDetections() async {
    setState(() => _isLoading = true);
    
    try {
      final detections = await _storage.getDetections();
      setState(() {
        _detections = detections;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading detections: $e');
      setState(() {
        _isLoading = false;
        _syncStatus = 'Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  Future<void> _syncWithServer() async {
    if (_isSyncing) return;
    
    setState(() {
      _isSyncing = true;
      _syncStatus = 'Syncing...';
    });
    
    try {
      // Test connection first
      final connectionTest = await _apiService.testConnection();
      
      if (!connectionTest['success']) {
        setState(() {
          _syncStatus = 'Server unreachable';
          _isSyncing = false;
        });
        return;
      }
      
      // Proceed with sync
      final success = await _storage.syncWithServer();
      
      // Reload detections
      if (success) {
        await _loadDetections();
        setState(() {
          _syncStatus = 'Synced at ${_formatTime(DateTime.now())}';
        });
      } else {
        setState(() {
          _syncStatus = 'Sync failed';
        });
      }
    } catch (e) {
      print('Error syncing: $e');
      setState(() {
        _syncStatus = 'Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync error: $e')),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }
  
  Future<void> _updateServerUrl() async {
    final TextEditingController controller = TextEditingController(text: _serverUrl);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'e.g., http://10.0.2.2:8080',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await ApiService.setupServerUrl(newUrl);
                setState(() {
                  _serverUrl = newUrl;
                });
                if (mounted) Navigator.pop(context);
                _syncWithServer();
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garbage Detection Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetections,
            tooltip: 'Refresh local',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncWithServer,
            tooltip: 'Sync with server',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _updateServerUrl,
            tooltip: 'Server settings',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'add_test') {
                await TestDataService.addTestData();
                _loadDetections();
              } else if (value == 'clear') {
                await _storage.deleteAllDetections();
                _loadDetections();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'add_test',
                child: Text('Add Test Data'),
              ),
              const PopupMenuItem<String>(
                value: 'clear',
                child: Text('Clear All Data'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                Icon(
                  _isSyncing 
                      ? Icons.sync
                      : _syncStatus.contains('Error') 
                          ? Icons.error
                          : _syncStatus.contains('unreachable')
                              ? Icons.cloud_off
                              : Icons.cloud_done,
                  color: _isSyncing
                      ? Colors.blue
                      : _syncStatus.contains('Error') || _syncStatus.contains('unreachable') 
                          ? Colors.red
                          : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _syncStatus,
                    style: TextStyle(
                      color: _syncStatus.contains('Error') || _syncStatus.contains('unreachable')
                          ? Colors.red
                          : null,
                    ),
                  ),
                ),
                Text('Server: ${_serverUrl.split('://').last}', 
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _detections.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('No detections found'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                await TestDataService.addTestData();
                                _loadDetections();
                              },
                              child: const Text('Add Test Data'),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _syncWithServer,
                              child: const Text('Sync with Server'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _detections.length,
                        itemBuilder: (context, index) {
                          final detection = _detections[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(detection.status),
                                child: Text(
                                  detection.detectionClass.isNotEmpty
                                      ? detection.detectionClass[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(detection.detectionClass),
                              subtitle: Text(
                                '${detection.zoneName} - ${_formatTimestamp(detection.timestamp)}',
                              ),
                              trailing: detection.status.toLowerCase() != 'cleaned'
                                  ? IconButton(
                                      icon: const Icon(Icons.check_circle),
                                      onPressed: () => _markAsCleaned(detection),
                                      color: Colors.green,
                                    )
                                  : const Icon(Icons.check_circle, color: Colors.grey),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow('Status', detection.status),
                                      _buildDetailRow('Confidence', '${(detection.confidence * 100).toStringAsFixed(1)}%'),
                                      _buildDetailRow('Location', detection.location),
                                      _buildDetailRow('Zone', detection.zoneName),
                                      _buildDetailRow('Camera ID', detection.cameraId),
                                      _buildDetailRow('Timestamp', _formatTimestamp(detection.timestamp)),
                                      if (detection.status.toLowerCase() == 'cleaned') ...[
                                        _buildDetailRow('Cleaned By', detection.cleanedBy ?? 'Unknown'),
                                        _buildDetailRow('Cleaned At', _formatTimestamp(detection.cleanedAt ?? '')),
                                        _buildDetailRow('Notes', detection.notes ?? 'No notes'),
                                      ],
                                      if (detection.status.toLowerCase() != 'cleaned') ...[
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () => _markAsCleaned(detection),
                                            child: const Text('MARK AS CLEANED'),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _syncWithServer,
        tooltip: 'Sync with Server',
        child: const Icon(Icons.sync),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'cleaned':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
    } catch (e) {
      return timestamp;
    }
  }
  
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _markAsCleaned(Detection detection) async {
    try {
      await _storage.markAsCleaned(
        detection.timestamp,
        'Staff',
        'Marked as cleaned from minimal app',
      );
      await _loadDetections();
      
      // Try to sync with server after marking as cleaned
      _syncWithServer();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as cleaned')),
        );
      }
    } catch (e) {
      print('Error marking as cleaned: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
} 
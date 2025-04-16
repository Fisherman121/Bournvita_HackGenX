import 'package:flutter/material.dart';
import 'models/detection.dart';
import 'services/local_storage.dart';
import 'services/test_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add test data to local storage
  await TestDataService.addTestData();
  
  runApp(const RunnableApp());
}

class RunnableApp extends StatelessWidget {
  const RunnableApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garbage Detection Viewer',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const DetectionListPage(),
      debugShowCheckedModeBanner: false,
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
  List<Detection> _detections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetections();
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
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Log Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetections,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await _storage.deleteAllDetections();
              _loadDetections();
            },
          ),
        ],
      ),
      body: _isLoading
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
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _detections.length,
                  itemBuilder: (context, index) {
                    final detection = _detections[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${detection.status}'),
                            Text('Location: ${detection.location}'),
                            Text('Time: ${_formatTimestamp(detection.timestamp)}'),
                          ],
                        ),
                        trailing: detection.status.toLowerCase() != 'cleaned'
                            ? IconButton(
                                icon: const Icon(Icons.check_circle),
                                onPressed: () => _markAsCleaned(detection),
                                color: Colors.green,
                              )
                            : const Icon(Icons.check_circle, color: Colors.grey),
                        onTap: () => _showDetailsDialog(context, detection),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await TestDataService.addTestData();
          _loadDetections();
        },
        tooltip: 'Add Test Data',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Detection detection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(detection.detectionClass),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          if (detection.status.toLowerCase() != 'cleaned')
            ElevatedButton(
              onPressed: () {
                _markAsCleaned(detection);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('MARK AS CLEANED'),
            ),
        ],
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
            width: 90,
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
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
    } catch (e) {
      return timestamp;
    }
  }

  Future<void> _markAsCleaned(Detection detection) async {
    try {
      await _storage.markAsCleaned(
        detection.timestamp,
        'Staff',
        'Marked as cleaned from app',
      );
      await _loadDetections();
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/detection.dart';
import 'services/local_storage.dart';
import 'services/test_data_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run the app
  runApp(const DetectionViewerApp());
}

class DetectionViewerApp extends StatelessWidget {
  const DetectionViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garbage Detection Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const DetectionViewerPage(),
    );
  }
}

class DetectionViewerPage extends StatefulWidget {
  const DetectionViewerPage({super.key});

  @override
  State<DetectionViewerPage> createState() => _DetectionViewerPageState();
}

class _DetectionViewerPageState extends State<DetectionViewerPage> {
  final LocalStorage _localStorage = LocalStorage();
  late TestDataService _testDataService;
  List<Detection> _detections = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _testDataService = TestDataService(_localStorage);
    _loadDetections();
  }

  Future<void> _loadDetections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
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

  Future<void> _addTestData() async {
    try {
      await _testDataService.addTestDetections(5);
      _loadDetections();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to add test data: $e';
      });
    }
  }

  Future<void> _deleteAllData() async {
    try {
      await _localStorage.deleteAllDetections();
      _loadDetections();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to delete data: $e';
      });
    }
  }

  Future<void> _markAsCleaned(Detection detection) async {
    try {
      await _localStorage.markAsCleaned(
        detection.timestamp,
        'Test User',
        'Marked as cleaned from app',
      );
      _loadDetections();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to mark as cleaned: $e';
      });
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
            icon: const Icon(Icons.delete),
            onPressed: _deleteAllData,
            tooltip: 'Delete All',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addTestData,
            tooltip: 'Add Test Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetections,
        child: _buildBody(),
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
              onPressed: _addTestData,
              child: const Text('Add Test Data'),
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
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorForClass(detection.detectionClass),
              child: Text(detection.detectionClass.substring(0, 1).toUpperCase()),
            ),
            title: Text('${detection.detectionClass} (${detection.confidence.toStringAsFixed(2)})'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${detection.status}'),
                Text('Zone: ${detection.zoneName}'),
                Text('Camera: ${detection.cameraId}'),
                Text('Time: ${_formatTimestamp(detection.timestamp)}'),
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

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showDetailDialog(Detection detection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${detection.detectionClass} Detection'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Time', _formatTimestamp(detection.timestamp)),
              _detailRow('Status', detection.status),
              _detailRow('Confidence', detection.confidence.toStringAsFixed(2)),
              _detailRow('Zone', detection.zoneName),
              _detailRow('Camera', detection.cameraId),
              _detailRow('Location', detection.location ?? 'Unknown'),
              if (detection.forCleaning == 1)
                _detailRow('Marked for cleaning', 'Yes'),
              if (detection.cleanedBy != null) ...[
                _detailRow('Cleaned by', detection.cleanedBy!),
                _detailRow('Cleaned at', _formatTimestamp(detection.cleanedAt!)),
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
          if (detection.status != 'cleaned')
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
} 
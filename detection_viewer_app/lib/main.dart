import 'package:flutter/material.dart';
import 'models/detection.dart';
import 'services/local_storage.dart';
import 'services/test_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add test data
  await TestDataService.addTestData();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Detection Viewer',
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Detection Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetections,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await TestDataService.clearTestData();
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
                            detection.detectionClass[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(detection.detectionClass),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${detection.status}'),
                            Text('Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%'),
                            Text('Location: ${detection.location}'),
                            Text('Zone: ${detection.zoneName}'),
                          ],
                        ),
                        trailing: detection.status.toLowerCase() != 'cleaned'
                            ? IconButton(
                                icon: const Icon(Icons.check_circle),
                                onPressed: () => _markAsCleaned(detection),
                                color: Colors.green,
                              )
                            : const Icon(Icons.check_circle, color: Colors.grey),
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

  Future<void> _markAsCleaned(Detection detection) async {
    try {
      await _storage.markAsCleaned(
        detection.timestamp,
        'Staff',
        'Marked as cleaned from the app',
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

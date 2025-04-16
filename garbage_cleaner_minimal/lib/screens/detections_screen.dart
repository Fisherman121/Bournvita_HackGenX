import 'package:flutter/material.dart';
import '../models/detection.dart';
import '../services/local_storage.dart';

class DetectionsScreen extends StatefulWidget {
  const DetectionsScreen({Key? key}) : super(key: key);

  @override
  State<DetectionsScreen> createState() => _DetectionsScreenState();
}

class _DetectionsScreenState extends State<DetectionsScreen> {
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
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading detections: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetections,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _detections.isEmpty
              ? const Center(child: Text('No detections found'))
              : RefreshIndicator(
                  onRefresh: _loadDetections,
                  child: ListView.builder(
                    itemCount: _detections.length,
                    itemBuilder: (context, index) {
                      final detection = _detections[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                              if (detection.zoneName != null)
                                Text('Zone: ${detection.zoneName}'),
                              Text('Time: ${_formatTimestamp(detection.timestamp)}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.check_circle),
                            onPressed: () => _markAsCleaned(detection),
                            color: Colors.green,
                          ),
                        ),
                      );
                    },
                  ),
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
        'User', // You can replace this with actual user info
        'Marked as cleaned from app',
      );
      await _loadDetections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as cleaned')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking as cleaned: $e')),
        );
      }
    }
  }
} 
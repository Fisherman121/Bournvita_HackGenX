import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/detection.dart';
import '../services/local_storage.dart';
import 'detection_detail_screen.dart';

class DetectionsScreen extends StatefulWidget {
  const DetectionsScreen({Key? key}) : super(key: key);

  @override
  State<DetectionsScreen> createState() => _DetectionsScreenState();
}

class _DetectionsScreenState extends State<DetectionsScreen> {
  final LocalStorage _localStorage = LocalStorage();
  List<Detection> _detections = [];
  bool _isLoading = false;
  String _filter = 'all'; // 'all', 'pending', 'cleaned'

  @override
  void initState() {
    super.initState();
    _loadDetections();
  }

  Future<void> _loadDetections() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final detections = await _localStorage.getDetections();
      
      if (mounted) {
        setState(() {
          _detections = detections;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading detections: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Detection> get _filteredDetections {
    if (_filter == 'all') {
      return _detections;
    } else if (_filter == 'pending') {
      return _detections.where((d) => d.status == 'pending').toList();
    } else if (_filter == 'cleaned') {
      return _detections.where((d) => d.status == 'cleaned').toList();
    }
    return _detections;
  }

  Future<void> _syncWithServer() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Show a syncing message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Syncing detections with server...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Sync with server
      final success = await _localStorage.syncWithServer();
      
      // Reload detections
      await _loadDetections();
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error syncing with server: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _refreshDetections() async {
    await _loadDetections();
  }

  void _markAsCleaned(Detection detection) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetectionDetailScreen(detection: detection),
      ),
    );
    
    if (result == true) {
      await _loadDetections();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garbage Detections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncWithServer,
            tooltip: 'Sync with server',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Detections'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: 'cleaned',
                child: Text('Cleaned'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDetections,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredDetections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${_filter == 'all' ? '' : _filter} detections found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        TextButton(
                          onPressed: _syncWithServer,
                          child: const Text('Sync with server'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredDetections.length,
                    itemBuilder: (context, index) {
                      final detection = _filteredDetections[index];
                      return DetectionListItem(
                        detection: detection,
                        onTap: () => _markAsCleaned(detection),
                      );
                    },
                  ),
      ),
    );
  }
}

class DetectionListItem extends StatelessWidget {
  final Detection detection;
  final VoidCallback onTap;

  const DetectionListItem({
    Key? key,
    required this.detection,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format timestamp
    DateTime? dateTime;
    try {
      dateTime = DateTime.parse(detection.timestamp);
    } catch (e) {
      print('Error parsing timestamp: $e');
    }

    final dateFormat = DateFormat('MMM d, h:mm a');
    final formattedDate = dateTime != null ? dateFormat.format(dateTime) : 'Unknown date';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image thumbnail
              if (detection.hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.network(
                      detection.effectiveImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      cacheWidth: 160, // Cache with 2x resolution for crisp display
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.no_photography, color: Colors.grey),
                ),
              const SizedBox(width: 16),
              // Detection details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            detection.detectionClass,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: detection.status == 'cleaned' ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            detection.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(formattedDate),
                    Text(
                      detection.zoneName,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Confidence: ${(detection.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: detection.confidence > 0.7 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
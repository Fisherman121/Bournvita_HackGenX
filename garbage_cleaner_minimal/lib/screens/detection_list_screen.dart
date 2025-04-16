import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/detection.dart';
import '../services/api_service.dart';
import 'detection_detail_screen.dart';

class DetectionListScreen extends StatefulWidget {
  const DetectionListScreen({Key? key}) : super(key: key);

  @override
  State<DetectionListScreen> createState() => _DetectionListScreenState();
}

class _DetectionListScreenState extends State<DetectionListScreen> {
  final ApiService _apiService = ApiService();
  List<Detection> _detections = [];
  bool _isLoading = false;
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _fetchDetections();
    
    // Set up periodic refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchDetections();
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _fetchDetections() async {
    if (_isLoading) return;
    
    // Check if widget is still mounted before setting state
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    
    try {
      final detections = await _apiService.getAllDetections();
      // Check if widget is still mounted before setting state
      if (!mounted) return;
      setState(() {
        _detections = detections;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching detections: $e');
      // Check if widget is still mounted before setting state
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching detections: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garbage Detections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDetections,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetections,
        child: _isLoading && _detections.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _detections.isEmpty
                ? _buildNoDetectionsView()
                : ListView.builder(
                    itemCount: _detections.length,
                    itemBuilder: (context, index) {
                      final detection = _detections[index];
                      return _buildDetectionCard(detection);
                    },
                  ),
      ),
    );
  }
  
  Widget _buildNoDetectionsView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              const Icon(
                Icons.search_off,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'No detections found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh or check the connection',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Connection Info:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text('Server URL: ${ApiService.baseUrl}', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  // Create a test detection
                  try {
                    final response = await http.get(
                      Uri.parse('${ApiService.baseUrl}/create_test_detection')
                    );
                    if (response.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test detection created'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _fetchDetections();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed: ${response.statusCode}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('CREATE TEST DETECTION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _checkServerStatus();
                },
                icon: const Icon(Icons.network_check),
                label: const Text('CHECK SERVER'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _checkServerStatus() async {
    final serverUrlController = TextEditingController(text: ApiService.baseUrl);
    
    // Show a dialog to enter or confirm the server URL
    final selectedUrl = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: serverUrlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'http://192.168.x.x:5000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'URL endpoints to try:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
            Text(
              '- http://10.0.2.2:5000 (Android Emulator)\n'
              '- http://localhost:5000 (Web)\n'
              '- http://127.0.0.1:5000 (Local)',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, serverUrlController.text),
            child: const Text('CHECK'),
          ),
        ],
      ),
    );
    
    if (selectedUrl == null || selectedUrl.isEmpty) {
      return;
    }
    
    // Save the URL for future use if it changed
    if (selectedUrl != ApiService.baseUrl) {
      await ApiService.setupServerUrl(selectedUrl);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking server connection...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api_check'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Server connected: ${ApiService.baseUrl}'),
                Text('Detections: ${data['detection_count']}'),
                Text('Time: ${data['timestamp']}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        
        // If no detections, offer to create test data
        if (data['detection_count'] == 0) {
          _showCreateTestDataDialog();
        } else {
          // Fetch detections since the connection succeeded
          _fetchDetections();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Server returned status: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Connection error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showCreateTestDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Detections Found'),
        content: const Text(
          'Would you like to create test detection data to help with app testing?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createTestData();
            },
            child: const Text('CREATE TEST DATA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _createTestData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating test detection data...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/populate_test_data'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${data['message']}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Fetch the new test data
        _fetchDetections();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to create test data: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error creating test data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Widget _buildDetectionCard(Detection detection) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetectionDetailScreen(detection: detection),
            ),
          ).then((_) => _fetchDetections()); // Refresh when returning from details
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.green.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${detection.zoneName} - ${detection.location}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: detection.isCleaned ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      detection.isCleaned ? 'Cleaned' : 'Pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 16/9,
              child: Image.network(
                detection.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / 
                            loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red, size: 40),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detection.detectionClass,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Detected at: ${detection.timestamp}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (detection.isCleaned && detection.cleanedBy != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Cleaned by: ${detection.cleanedBy}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!detection.isCleaned)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetectionDetailScreen(detection: detection),
                      ),
                    ).then((_) => _fetchDetections());
                  },
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Mark as Cleaned'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 
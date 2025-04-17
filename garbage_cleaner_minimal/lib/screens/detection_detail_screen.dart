import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/detection.dart';
import '../services/local_storage.dart';
import '../utils/config.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'dart:convert';
import 'dart:math' as math;

class DetectionDetailScreen extends StatefulWidget {
  final Detection detection;
  
  const DetectionDetailScreen({
    Key? key,
    required this.detection,
  }) : super(key: key);

  @override
  State<DetectionDetailScreen> createState() => _DetectionDetailScreenState();
}

class _DetectionDetailScreenState extends State<DetectionDetailScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _cleanedByController = TextEditingController();
  bool _isCleaning = false;
  bool _isLoading = false;
  final LocalStorage _localStorage = LocalStorage();
  
  // Add variables to track server ping results
  Map<String, String> _serverTestResults = {};
  bool _isTestingServers = false;
  
  // Text controller for the test URL
  final TextEditingController _testUrlController = TextEditingController(
    text: 'http://172.26.26.216:5000/static/images/placeholder-image.jpg'
  );
  
  @override
  void initState() {
    super.initState();
    _notesController.text = widget.detection.notes ?? '';
    _cleanedByController.text = widget.detection.cleanedBy ?? 'Staff'; // Default value
    
    // Test server connectivity
    _testAllServers();
    
    // Force refresh detections from the server
    _refreshDetectionsFromServer();
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    _cleanedByController.dispose();
    _testUrlController.dispose();
    super.dispose();
  }
  
  Future<void> _markAsCleaned() async {
    if (_isLoading) return;

    // Basic validation
    if (_cleanedByController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter who cleaned this detection'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _localStorage.updateStatusAndSync(
        widget.detection.timestamp,
        'cleaned',
        _cleanedByController.text.trim(),
        _notesController.text.trim(),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Detection marked as cleaned and synced with server'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Return success to the previous screen
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        // It was saved locally but not synced
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved locally but failed to sync with server. Will retry on next sync.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking as cleaned: $e'),
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
  
  Future<void> _testAllServers() async {
    setState(() => _isTestingServers = true);
    
    // Test different server URLs
    final servers = [
      {'name': 'localhost:8080', 'url': 'http://localhost:8080/api_check'},
      {'name': '10.0.2.2:8080', 'url': 'http://10.0.2.2:8080/api_check'},
      {'name': 'apiBaseUrl', 'url': '${Config.apiBaseUrl}/api_check'},
      {'name': 'platformSpecific', 'url': '${Config.getPlatformSpecificApiUrl()}/api_check'},
      {'name': '172.26.26.216:5000', 'url': 'http://172.26.26.216:5000/api_check'},
      {'name': '172.26.26.216:8080', 'url': 'http://172.26.26.216:8080/api_check'},
      // Add specific image tests
      {'name': 'localhost /static', 'url': 'http://localhost:8080/static/images/placeholder-image.jpg'},
      {'name': '10.0.2.2 /static', 'url': 'http://10.0.2.2:8080/static/images/placeholder-image.jpg'},
      {'name': '172.26... /static', 'url': 'http://172.26.26.216:5000/static/images/placeholder-image.jpg'},
    ];
    
    for (var server in servers) {
      try {
        final result = await _pingServer(server['url']!);
        if (mounted) {
          setState(() {
            _serverTestResults[server['name']!] = result;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _serverTestResults[server['name']!] = 'Error: $e';
          });
        }
      }
    }
    
    if (mounted) {
      setState(() => _isTestingServers = false);
    }
  }
  
  Future<String> _pingServer(String url) async {
    try {
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      return 'Status ${response.statusCode}: ${response.reasonPhrase ?? ""}';
    } catch (e) {
      return 'Failed: $e';
    }
  }
  
  Future<void> _refreshDetectionsFromServer() async {
    try {
      final apiService = ApiService();
      final localStorage = LocalStorage();
      
      // Show in the console we're trying to refresh
      print('DEBUG: Forcing refresh of detections from server');
      
      // Try to do a full refresh from server
      final success = await localStorage.fullRefreshFromServer();
      print('DEBUG: Force refresh ${success ? "successful" : "failed"}');
      
    } catch (e) {
      print('DEBUG: Error refreshing detections: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Format timestamp
    DateTime? dateTime;
    try {
      dateTime = DateTime.parse(widget.detection.timestamp);
    } catch (e) {
      print('Error parsing timestamp: $e');
    }

    final dateFormat = DateFormat('MMMM d, yyyy - h:mm a');
    final formattedDate = dateTime != null 
      ? dateFormat.format(dateTime) 
      : 'Unknown date';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Details'),
        actions: [
          if (widget.detection.status != 'cleaned')
            TextButton.icon(
              onPressed: _isCleaning ? null : () {
                setState(() {
                  _isCleaning = true;
                });
              },
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Mark Cleaned',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: RobustImageDisplay(detection: widget.detection),
                    ),
                  ),
                ),
                
                // Add debug image test panel
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Image Diagnostics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Attempting to load from: ${widget.detection.effectiveImageUrl}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Alternative URLs test:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        
                        // Test URL 1: Direct hardcoded IP
                        _buildTestImage(
                          'http://10.0.2.2:8080/static/images/placeholder-image.jpg',
                          height: 50,
                          label: '10.0.2.2:8080/static'
                        ),
                        
                        // Test URL 2: Config IP
                        _buildTestImage(
                          '${Config.apiBaseUrl}/static/images/placeholder-image.jpg',
                          height: 50,
                          label: 'Config.apiBaseUrl'
                        ),
                        
                        // Test URL 3: Raw path
                        _buildTestImage(
                          'http://localhost:8080/static/images/placeholder-image.jpg',
                          height: 50,
                          label: 'localhost:8080'
                        ),
                        
                        // Test URL 4: Platform specific
                        _buildTestImage(
                          '${Config.getPlatformSpecificApiUrl()}/static/images/placeholder-image.jpg',
                          height: 50, 
                          label: 'Platform Specific'
                        ),
                        
                        // Test image path if available
                        if (widget.detection.imagePath.isNotEmpty)
                          _buildTestImage(
                            'http://10.0.2.2:8080/view_image/${widget.detection.imagePath}',
                            height: 50,
                            label: 'Direct Image Path'
                          ),
                          
                        // Display server test results
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Server Tests:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  ApiService.useTestMode = false;
                                  ApiService.testImageServerUrl = '';
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              child: const Text('Reset URL Mode', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),

                        // Show test results
                        _isTestingServers
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : Column(
                              children: _serverTestResults.entries.map((entry) => 
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: TextStyle(
                                            fontSize: 11, 
                                            color: entry.value.contains('Status 200') 
                                              ? Colors.green 
                                              : Colors.red,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ).toList(),
                            ),
                            
                        // Refresh button
                        Center(
                          child: TextButton.icon(
                            onPressed: _isTestingServers ? null : _testAllServers,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Refresh Tests'),
                          ),
                        ),
                        
                        // Direct URL test
                        const SizedBox(height: 16),
                        const Text(
                          'Direct URL Test:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        TextField(
                          controller: _testUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Test URL',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 12),
                          onSubmitted: (value) {
                            setState(() {
                              // Set URL to test mode
                              ApiService.useTestMode = true;
                              ApiService.testImageServerUrl = value;
                            });
                          },
                        ),
                        
                        // Test URL button
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  ApiService.useTestMode = true;
                                  ApiService.testImageServerUrl = _testUrlController.text;
                                });
                              },
                              child: const Text('Test This URL'),
                            ),
                          ),
                        ),
                        
                        // More common test URLs
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _buildQuickTestButton('localhost/static',
                                'http://localhost:8080/static/images/placeholder-image.jpg'),
                            _buildQuickTestButton('10.0.2.2/static',
                                'http://10.0.2.2:8080/static/images/placeholder-image.jpg'),
                            _buildQuickTestButton('Server IP Port 5000',
                                'http://172.26.26.216:5000/static/images/placeholder-image.jpg'),
                            _buildQuickTestButton('Server IP Port 8080',
                                'http://172.26.26.216:8080/static/images/placeholder-image.jpg'),
                          ],
                        ),
                        
                        // Reset URL Mode button
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    ApiService.useTestMode = false;
                                    ApiService.testImageServerUrl = '';
                                    _testUrlController.clear();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Test URL mode reset'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Reset URL Mode'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.detection.detectionClass,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Chip(
                              label: Text(
                                widget.detection.status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: widget.detection.status == 'cleaned'
                                ? Colors.green
                                : Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Confidence: ${(widget.detection.confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.detection.confidence > 0.7
                              ? Colors.green
                              : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        _buildInfoRow(
                          'Date',
                          formattedDate,
                          Icons.calendar_today,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Zone',
                          widget.detection.zoneName,
                          Icons.location_on,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Location',
                          widget.detection.location,
                          Icons.map,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Camera ID',
                          widget.detection.cameraId,
                          Icons.camera_alt,
                        ),
                        if (widget.detection.status == 'cleaned') ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          _buildInfoRow(
                            'Cleaned By',
                            widget.detection.cleanedBy ?? 'Unknown',
                            Icons.person,
                          ),
                          const SizedBox(height: 8),
                          if (widget.detection.cleanedAt != null)
                            _buildInfoRow(
                              'Cleaned At',
                              _formatCleanedDate(widget.detection.cleanedAt!),
                              Icons.access_time,
                            ),
                          const SizedBox(height: 8),
                          if (widget.detection.notes != null && widget.detection.notes!.isNotEmpty)
                            _buildInfoRow(
                              'Notes',
                              widget.detection.notes!,
                              Icons.note,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isCleaning) ...[
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mark as Cleaned',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _cleanedByController,
                            decoration: const InputDecoration(
                              labelText: 'Cleaned By',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.note),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isCleaning = false;
                                  });
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: _markAsCleaned,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Confirm Cleaned'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                ElevatedButton(
                  onPressed: () {
                    final testImageUrl = 'http://172.26.26.216:5000/static/images/placeholder-image.jpg';
                    print('Testing direct image URL: $testImageUrl');
                    
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Direct Image Test'),
                          content: Container(
                            width: 300,
                            height: 300,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Attempting to load: $testImageUrl'),
                                SizedBox(height: 10),
                                Expanded(
                                  child: Image.network(
                                    testImageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('ERROR LOADING IMAGE: $error');
                                      return Column(
                                        children: [
                                          Icon(Icons.error, color: Colors.red, size: 50),
                                          Text('Failed to load image: $error', style: TextStyle(color: Colors.red)),
                                          SizedBox(height: 20),
                                          Text('Falling back to base64 image:'),
                                          Image.memory(
                                            base64Decode('iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAApgAAAKYB3X3/OAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAANCSURBVEiJtZZPbBtFFMZ/M7ubXdtdb1xSFyeilBapySVU8h8OoFaooFSqiihIVIpQBKci6KEg9Q6H9kovIHoCIVQJJCKE1ENFjnAgcaSGC6rEnxBwA04Tx43t2FnvDAfjkNibxgHxnWb2e/u992bee7tCa00YFsffekFY+nUzFtjW0LrvjRXrCDIAaPLlW0nHL0SsZtVoaF98mLrx3pdhOqLtYPHChahZcYYO7KvPFxvRl5XPp1sN3adWiD1ZAqD6XYK1b/dvE5IWryTt2udLFedwc1+9kLp+vbbpoDh+6TklxBeAi9TL0taeWpdmZzQDry0AcO+jQ12RyohqqoYoo8RDwJrU+qXkjWtfi8Xxt58BdQuwQs9qC/afLwCw8tnQbqYAPsgxE1S6F3EAIXux2oQFKm0ihMsOF71dHYx+f3NND68ghCu1YIoePPQN1pGRABkJ6Bus96CutRZMydTl+TvuiRW1m3n0eDl0vRPcEysqdXn+jsQPsrHMquGeXEaY4Yk4wxWcY5V/9scqOMOVUFthatyTy8QyqwZ+kDURKoMWxNKr2EeqVKcTNOajqKoBgOE28U4tdQl5p5bwCw7BWquaZSzAPlwjlithJtp3pTImSqQRrb2Z8PHGigD4RZuNX6JYj6wj7O4TFLbCO/Mn/m8R+h6rYSUb3ekokRY6f/YukArN979jcW+V/S8g0eT/N3VN3kTqWbQ428m9/8k0P/1aIhF36PccEl6EhOcAUCrXKZXXWS3XKd2vc/TRBG9O5ELC17MmWubD2nKhUKZa26Ba2+D3P+4/MNCFwg59oWVeYhkzgN/JDR8deKBoD7Y+ljEjGZ0sosXVTvbc6RHirr2reNy1OXd6pJsQ+gqjk8VWFYmHrwBzW/n+uMPFiRwHB2I7ih8ciHFxIkd/3Omk5tCDV1t+2nNu5sxxpDFNx+huNhVT3/zMDz8usXC3ddaHBj1GHj/As08fwTS7Kt1HBTmyN29vdwAw+/wbwLVOJ3uAD1wi/dUH7Qei66PfyuRj4Ik9is+hglfbkbfR3cnZm7chlUWLdwmprtCohX4HUtlOcQjLYCu+fzGJH2QRKvP3UNz8bWk1qMxjGTOMThZ3kvgLI5AzFfo379UAAAAASUVORK5CYII='),
                                            fit: BoxFit.contain,
                                          ),
                                        ],
                                      );
                                    },
                                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                            SizedBox(height: 10),
                                            Text('Loading image... ${loadingProgress.cumulativeBytesLoaded} bytes'),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Close'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text('Test Direct Image Loading'),
                ),
                ElevatedButton(
                  onPressed: () {
                    print('Testing base64 image display');
                    
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Base64 Image Test'),
                          content: Container(
                            width: 300,
                            height: 300,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Displaying hardcoded base64 image'),
                                SizedBox(height: 10),
                                Expanded(
                                  child: Image.memory(
                                    base64Decode('iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAApgAAAKYB3X3/OAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAANCSURBVEiJtZZPbBtFFMZ/M7ubXdtdb1xSFyeilBapySVU8h8OoFaooFSqiihIVIpQBKci6KEg9Q6H9kovIHoCIVQJJCKE1ENFjnAgcaSGC6rEnxBwA04Tx43t2FnvDAfjkNibxgHxnWb2e/u992bee7tCa00YFsffekFY+nUzFtjW0LrvjRXrCDIAaPLlW0nHL0SsZtVoaF98mLrx3pdhOqLtYPHChahZcYYO7KvPFxvRl5XPp1sN3adWiD1ZAqD6XYK1b/dvE5IWryTt2udLFedwc1+9kLp+vbbpoDh+6TklxBeAi9TL0taeWpdmZzQDry0AcO+jQ12RyohqqoYoo8RDwJrU+qXkjWtfi8Xxt58BdQuwQs9qC/afLwCw8tnQbqYAPsgxE1S6F3EAIXux2oQFKm0ihMsOF71dHYx+f3NND68ghCu1YIoePPQN1pGRABkJ6Bus96CutRZMydTl+TvuiRW1m3n0eDl0vRPcEysqdXn+jsQPsrHMquGeXEaY4Yk4wxWcY5V/9scqOMOVUFthatyTy8QyqwZ+kDURKoMWxNKr2EeqVKcTNOajqKoBgOE28U4tdQl5p5bwCw7BWquaZSzAPlwjlithJtp3pTImSqQRrb2Z8PHGigD4RZuNX6JYj6wj7O4TFLbCO/Mn/m8R+h6rYSUb3ekokRY6f/YukArN979jcW+V/S8g0eT/N3VN3kTqWbQ428m9/8k0P/1aIhF36PccEl6EhOcAUCrXKZXXWS3XKd2vc/TRBG9O5ELC17MmWubD2nKhUKZa26Ba2+D3P+4/MNCFwg59oWVeYhkzgN/JDR8deKBoD7Y+ljEjGZ0sosXVTvbc6RHirr2reNy1OXd6pJsQ+gqjk8VWFYmHrwBzW/n+uMPFiRwHB2I7ih8ciHFxIkd/3Omk5tCDV1t+2nNu5sxxpDFNx+huNhVT3/zMDz8usXC3ddaHBj1GHj/As08fwTS7Kt1HBTmyN29vdwAw+/wbwLVOJ3uAD1wi/dUH7Qei66PfyuRj4Ik9is+hglfbkbfR3cnZm7chlUWLdwmprtCohX4HUtlOcQjLYCu+fzGJH2QRKvP3UNz8bWk1qMxjGTOMThZ3kvgLI5AzFfo379UAAAAASUVORK5CYII='),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Close'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text('Test Base64 Image Display'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final response = await http.get(
                        Uri.parse('http://172.26.26.216:5000/ping'),
                        headers: {'Connection': 'keep-alive'},
                      ).timeout(Duration(seconds: 5));
                      
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Network Connection Test'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status code: ${response.statusCode}'),
                                SizedBox(height: 8),
                                Text('Response body: ${response.body}'),
                                SizedBox(height: 8),
                                Text('Headers: ${response.headers}'),
                              ],
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Close'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Connection Error'),
                            content: Text('Error: ${e.toString()}'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Close'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Text('Test Network Connection'),
                ),
              ],
            ),
          ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _formatCleanedDate(String cleanedAtStr) {
    try {
      final cleanedAt = DateTime.parse(cleanedAtStr);
      final now = DateTime.now();
      final difference = now.difference(cleanedAt);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return cleanedAtStr;
    }
  }

  Widget _buildTestImage(String url, {required double height, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Text(
                url,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 16),
                onPressed: () {
                  setState(() {
                    // Force refresh
                  });
                },
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: height,
              width: double.infinity,
              color: Colors.grey[200],
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('DEBUG: Test image error ($label): $error');
                      return Center(
                        child: Text('Failed: $error', style: const TextStyle(fontSize: 10, color: Colors.red)),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        print('DEBUG: Test image loaded ($label): $url');
                        return child;
                      }
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                          strokeWidth: 2,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.black54,
                      child: Text(
                        label,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTestButton(String label, String url) {
    return TextButton(
      onPressed: () {
        setState(() {
          _testUrlController.text = url;
          ApiService.useTestMode = true;
          ApiService.testImageServerUrl = url;
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.grey[200],
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class RobustImageDisplay extends StatefulWidget {
  final Detection detection;
  
  const RobustImageDisplay({Key? key, required this.detection}) : super(key: key);
  
  @override
  State<RobustImageDisplay> createState() => _RobustImageDisplayState();
}

class _RobustImageDisplayState extends State<RobustImageDisplay> {
  bool _isLoading = true;
  bool _useBase64Fallback = false;
  String? _currentUrl;
  int _urlAttemptIndex = 0;
  List<String> _urlsToTry = [];
  bool _showDebugOverlay = true;
  String _debugMessage = "";
  
  // Hardcoded base64 image that will definitely display
  static const String _fallbackBase64 = 
      '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';
  
  @override
  void initState() {
    super.initState();
    // Print detailed debugging info about the detection
    print("DEBUG: Detection details for image loading:");
    print("DEBUG: timestamp = ${widget.detection.timestamp}");
    print("DEBUG: imagePath = ${widget.detection.imagePath}");
    print("DEBUG: imageUrl = ${widget.detection.imageUrl}");
    print("DEBUG: effectiveImageUrl = ${widget.detection.effectiveImageUrl}");
    
    // Build a list of URLs to try, from most likely to least
    _buildUrlList();
    
    // Start trying the URLs sequentially
    _tryNextUrl();
  }
  
  void _buildUrlList() {
    _urlsToTry = [];
    
    // First try the standard approaches provided by the Detection class
    if (widget.detection.effectiveImageUrl.isNotEmpty) {
      _urlsToTry.add(widget.detection.effectiveImageUrl);
    }
    
    // Try direct image URL if available
    if (widget.detection.imageUrl.isNotEmpty) {
      if (!_urlsToTry.contains(widget.detection.imageUrl)) {
        _urlsToTry.add(widget.detection.imageUrl);
      }
    }
    
    // Try the specialized endpoints
    _urlsToTry.add(widget.detection.directImageUrl);
    _urlsToTry.add(widget.detection.timestampImageUrl);
    
    // Try the uploads-direct approach with just the filename
    if (widget.detection.imagePath.isNotEmpty) {
      final filename = widget.detection.imagePath.split('/').last;
      final uploadsDirectUrl = '${Config.getImageServerUrl()}/uploads-direct/$filename';
      if (!_urlsToTry.contains(uploadsDirectUrl)) {
        _urlsToTry.add(uploadsDirectUrl);
      }
    }
    
    // Try placeholder as last resort
    final placeholderUrl = '${Config.getImageServerUrl()}/static/images/placeholder-image.jpg';
    if (!_urlsToTry.contains(placeholderUrl)) {
      _urlsToTry.add(placeholderUrl);
    }
    
    // Add some fallback URLs to try with each server
    if (widget.detection.imagePath.isNotEmpty) {
      final filename = widget.detection.imagePath.split('/').last;
      
      // Try with different server URLs from Config
      for (final serverUrl in Config.fallbackUrls) {
        // Try view_image endpoint
        _urlsToTry.add('$serverUrl/view_image/${widget.detection.imagePath}');
        
        // Try uploads-direct endpoint
        _urlsToTry.add('$serverUrl/uploads-direct/$filename');
        
        // Try image-direct endpoint
        _urlsToTry.add('$serverUrl/image-direct/$filename');
      }
    }
    
    // Debug output
    print("DEBUG: Will try ${_urlsToTry.length} URLs in sequence");
    for (int i = 0; i < _urlsToTry.length; i++) {
      print("DEBUG: URL #$i: ${_urlsToTry[i]}");
    }
  }
  
  void _tryNextUrl() {
    if (_urlAttemptIndex >= _urlsToTry.length) {
      // We've tried all URLs without success, use base64 fallback
      setState(() {
        _useBase64Fallback = true;
        _debugMessage = "All URLs failed, using base64 fallback";
      });
      return;
    }
    
    // Get the next URL to try
    _currentUrl = _urlsToTry[_urlAttemptIndex];
    print("DEBUG: Trying URL #$_urlAttemptIndex: $_currentUrl");
    
    setState(() {
      _isLoading = true;
      _useBase64Fallback = false;
      _debugMessage = "Trying URL #$_urlAttemptIndex: ${_currentUrl?.split('/').last ?? 'unknown'}";
    });
    
    // Move to next URL for next attempt
    _urlAttemptIndex++;
  }
  
  @override
  Widget build(BuildContext context) {
    // Choose an approach based on whether we're using base64 fallback
    if (_useBase64Fallback) {
      return _buildBase64Image();
    }
    
    // Check if we have a URL to try
    if (_currentUrl == null || _currentUrl!.isEmpty) {
      return _buildErrorDisplay("No image URL available");
    }
    
    return Stack(
      children: [
        Image.network(
          _currentUrl!,
          fit: BoxFit.cover,
          headers: {'Cache-Control': 'no-cache, no-store'},
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              _isLoading = false;
              return child;
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  ),
                  const SizedBox(height: 8),
                  Text("Loading image...\n${_currentUrl?.split('/').last ?? ''}"),
                  const SizedBox(height: 4),
                  Text("Attempt #$_urlAttemptIndex of ${_urlsToTry.length}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print("DEBUG: Error loading image: $error\nURL: $_currentUrl");
            
            // Try the next URL
            Future.microtask(() {
              if (mounted) {
                _tryNextUrl();
              }
            });
            
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text("Trying next URL...",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text("Last failed: ${_currentUrl?.split('/').last ?? ''}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        ),
        
        // Debug overlay
        if (_showDebugOverlay)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Image URL: ${_currentUrl?.split('/').last ?? 'Unknown'}",
                          style: const TextStyle(color: Colors.yellow, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "Attempt: $_urlAttemptIndex/${_urlsToTry.length}",
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                  Text(
                    _debugMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  // Build an image from a base64 string that definitely will work
  Widget _buildBase64Image() {
    try {
      // Decode the base64 string to bytes
      final imageBytes = base64Decode(_fallbackBase64);
      
      return Stack(
        children: [
          // Display the image from memory
          Image.memory(
            imageBytes,
            fit: BoxFit.contain,
          ),
          
          // Debug overlay
          if (_showDebugOverlay)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Using fallback base64 image",
                      style: TextStyle(color: Colors.yellow, fontSize: 12),
                    ),
                    Text(
                      "Tried ${_urlAttemptIndex} URLs - all failed. Using embedded image.",
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    } catch (e) {
      return _buildErrorDisplay("Base64 decoding failed: $e");
    }
  }
  
  Widget _buildErrorDisplay(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text("Image Loading Failed", style: TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
} 
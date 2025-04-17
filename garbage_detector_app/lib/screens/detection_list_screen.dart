import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/detection.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';

class DetectionListScreen extends StatefulWidget {
  const DetectionListScreen({Key? key}) : super(key: key);

  @override
  State<DetectionListScreen> createState() => _DetectionListScreenState();
}

class _DetectionListScreenState extends State<DetectionListScreen> {
  List<Detection> _detections = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadDetections();
  }

  Future<void> _loadDetections() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final detections = await _apiService.getSimpleDetections();
      setState(() {
        _detections = detections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading detections: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshDetections() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final detections = await _apiService.getSimpleDetections();
      setState(() {
        _detections = detections;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing detections: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Garbage Detections'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshDetections,
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: themeProvider.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshDetections,
              child: _detections.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No detections found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _detections.length,
                      itemBuilder: (context, index) {
                        final detection = _detections[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (detection.hasImage)
                                CachedNetworkImage(
                                  imageUrl: detection.effectiveImageUrl,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.error,
                                    size: 48,
                                  ),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Class: ${detection.detectionClass}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Confidence: ${(detection.confidence * 100).toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Location: ${detection.location}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Timestamp: ${detection.timestamp}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
} 
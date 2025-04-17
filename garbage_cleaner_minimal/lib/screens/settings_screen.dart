import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiUrlController = TextEditingController();
  bool _isLoading = false;
  String _testStatus = '';
  String _imageTestResult = '';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('api_url') ?? Config.apiBaseUrl;
    
    setState(() {
      _apiUrlController.text = savedUrl;
    });
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
      _testStatus = '';
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_url', _apiUrlController.text);
      
      // Update global configuration
      Config.apiBaseUrl = _apiUrlController.text;
      
      // Test connection
      final apiService = ApiService();
      Map<String, dynamic> result = await apiService.testConnection();
      bool success = result['success'] as bool;
      
      setState(() {
        _testStatus = success ? 'Connection successful!' : 'Connection failed: ${result['message']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testStatus = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _testImageServer() async {
    setState(() {
      _imageTestResult = '';
    });
    
    try {
      final apiService = ApiService();
      Map<String, dynamic> result = await apiService.testImageServer();
      bool success = result['success'] as bool;
      
      setState(() {
        _imageTestResult = success ? 'Success' : 'Failed: ${result['message']}';
      });
    } catch (e) {
      setState(() {
        _imageTestResult = 'Error: ${e.toString()}';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiUrlController,
              decoration: const InputDecoration(
                labelText: 'API URL',
                hintText: 'http://example.com/api',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    child: Text(_isLoading ? 'Testing...' : 'Save & Test Connection'),
                  ),
                ),
              ],
            ),
            if (_testStatus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _testStatus,
                  style: TextStyle(
                    color: _testStatus.contains('successful') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('App Version'),
              subtitle: Text(Config.appVersion),
              leading: const Icon(Icons.info_outline),
            ),
            
            // Add diagnostic section
            const SizedBox(height: 24),
            const Text(
              'Diagnostics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testImageServer,
              child: const Text('Test Image Server'),
            ),
            if (_imageTestResult.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _imageTestResult,
                  style: TextStyle(
                    color: _imageTestResult.contains('Success') ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }
} 
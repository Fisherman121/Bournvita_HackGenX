import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _settingsService = SettingsService();
  
  final _apiUrlController = TextEditingController();
  final _userNameController = TextEditingController();
  
  bool _isLoading = true;
  int _syncInterval = 1;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final apiUrl = await _settingsService.getApiUrl();
      final userName = await _settingsService.getUserName();
      final syncInterval = await _settingsService.getSyncIntervalMinutes();
      
      setState(() {
        _apiUrlController.text = apiUrl;
        _userNameController.text = userName;
        _syncInterval = syncInterval;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _settingsService.setApiUrl(_apiUrlController.text);
      await _settingsService.setUserName(_userNameController.text);
      await _settingsService.setSyncIntervalMinutes(_syncInterval);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
        Navigator.pop(context, true); // Return true to indicate settings changed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _settingsService.clearSettings();
        await _loadSettings();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings reset to defaults')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error resetting settings: $e')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // API URL
                  const Text(
                    'API Server',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _apiUrlController,
                    decoration: const InputDecoration(
                      labelText: 'API URL',
                      hintText: 'http://10.0.2.2:8080',
                      border: OutlineInputBorder(),
                      helperText: 'For Android emulator, use 10.0.2.2 for localhost',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an API URL';
                      }
                      // Very basic URL validation
                      if (!value.startsWith('http')) {
                        return 'URL must start with http:// or https://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // User Settings
                  const Text(
                    'User Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _userNameController,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      hintText: 'Enter your name',
                      border: OutlineInputBorder(),
                      helperText: 'Used when marking detections as cleaned',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Sync Interval
                  const Text(
                    'Sync Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _syncInterval,
                    decoration: const InputDecoration(
                      labelText: 'Sync Interval',
                      border: OutlineInputBorder(),
                      helperText: 'How often to check for new detections',
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Every minute')),
                      DropdownMenuItem(value: 5, child: Text('Every 5 minutes')),
                      DropdownMenuItem(value: 15, child: Text('Every 15 minutes')),
                      DropdownMenuItem(value: 30, child: Text('Every 30 minutes')),
                      DropdownMenuItem(value: 60, child: Text('Every hour')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _syncInterval = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _resetToDefaults,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset to Defaults'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Settings'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
  
  @override
  void dispose() {
    _apiUrlController.dispose();
    _userNameController.dispose();
    super.dispose();
  }
} 
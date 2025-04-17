import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:provider/provider.dart';

// Import our components
import 'models/detection.dart';
import 'models/zone.dart';
import 'services/api_service.dart';
import 'services/local_storage.dart';
import 'services/test_data_service.dart';
import 'screens/detection_list_screen.dart';
import 'screens/detection_detail_screen.dart';
import 'screens/zone_management_screen.dart';
import 'screens/detections_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/theme_settings_screen.dart';
import 'utils/config.dart';
import 'providers/theme_provider.dart';
import 'widgets/theme_toggle_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Print configuration for debugging
  Config.printConfig();
  
  // Initialize API service with saved server URL
  await ApiService.initFromPrefs();
  print("Starting app with server URL: ${ApiService.baseUrl}");
  
  // Test image server connectivity
  try {
    final apiService = ApiService();
    final result = await apiService.testImageServer();
    if (result['success'] as bool) {
      print("Image server test successful, using URL: ${result['url_used']}");
    } else {
      print("Image server test failed: ${result['message']}");
    }
  } catch (e) {
    print("Failed to test image server: $e");
  }
  
  // Add test data to local storage
  await TestDataService.addTestData();
  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: GarbageCleanerApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class GarbageCleanerApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const GarbageCleanerApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Garbage Cleaner',
      themeMode: themeProvider.themeMode, // This controls light/dark mode
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        colorScheme: ColorScheme.light(
          primary: Colors.green[700]!,
          secondary: Colors.green[400]!,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey[800],
        colorScheme: ColorScheme.dark(
          primary: Colors.green[700]!,
          secondary: Colors.green[400]!,
          surface: Colors.grey[800]!,
          background: Colors.grey[900]!,
        ),
      ),
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Simple hardcoded login for demo
    if (_usernameController.text == 'staff' && _passwordController.text == 'password123') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid username or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.green[700],
        actions: [
          const ThemeToggleButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.delete_outline,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Garbage Detection System',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Management App',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.themeMode == ThemeMode.dark 
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('LOGIN'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Use: staff / password123',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeProvider.themeMode == ThemeMode.dark 
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThemeSettingsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.amber[700] : Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('THEME SETTINGS'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: const ThemeToggleButton(showAsAction: false),
      bottomNavigationBar: BottomAppBar(
        color: isDark ? Colors.grey[850] : Colors.green[700],
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
              label: Text(
                isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: () {
                themeProvider.setThemeMode(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocalStorage _localStorage = LocalStorage();
  int _currentIndex = 0;
  List<Detection> _recentDetections = [];
  bool _isLoadingDetections = false;

  final List<Widget> _screens = [
    const DashboardContent(),
    const DetectionsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchRecentDetections();
  }
  
  Future<void> _fetchRecentDetections() async {
    if (_isLoadingDetections) return;

    // Check if widget is still mounted before setting state
    if (!mounted) return;
    setState(() {
      _isLoadingDetections = true;
    });

    try {
      final detections = await _localStorage.getDetections();
      // Check if widget is still mounted before setting state
      if (!mounted) return;
        setState(() {
        _recentDetections = detections.take(5).toList();
        _isLoadingDetections = false;
        });
    } catch (e) {
      print('Error fetching detections: $e');
      // Check if widget is still mounted before setting state
      if (!mounted) return;
      setState(() {
        _isLoadingDetections = false;
      });
    }
  }

  // Add this method to sync with the server
  Future<void> _syncWithServer() async {
    if (_isLoadingDetections) return;

    // Check if widget is still mounted before setting state
    if (!mounted) return;
    setState(() {
      _isLoadingDetections = true;
    });

    try {
      // Show a syncing message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Syncing with server...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Perform the sync
      final success = await _localStorage.syncWithServer();
      
      // Refresh the detections list
      if (success) {
        await _fetchRecentDetections();
        
        // Show success message
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync failed. Check your connection.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error syncing with server: $e');
      // Show error message
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Sync error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    } finally {
      // Check if widget is still mounted before setting state
      if (!mounted) return;
    setState(() {
        _isLoadingDetections = false;
      });
    }
  }

  Future<void> _handleLogout() async {
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garbage Cleaner'),
        actions: [
          // Theme toggle button
          const ThemeToggleButton(),
          // Add a refresh button to sync with server
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncWithServer,
            tooltip: 'Sync with server',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Open settings screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.color_lens),
            tooltip: 'Theme Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ThemeSettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 2) {
            // Toggle theme when the theme button is pressed
            final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
            themeProvider.setThemeMode(
              themeProvider.themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Detections',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            label: 'Theme',
          ),
        ],
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({Key? key}) : super(key: key);

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final LocalStorage _storage = LocalStorage();
  List<Detection> _recentDetections = [];
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
        _recentDetections = detections.take(5).toList();
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
    return RefreshIndicator(
      onRefresh: _loadDetections,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: const Icon(
                              Icons.person,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome, Staff',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Waste Management Team',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your CCTV-Monitored Detection System is active and running smoothly.',
                        style: TextStyle(fontSize: 15),
                      ),
          ],
        ),
      ),
              ),
              
              const SizedBox(height: 24),
              
              // Quick stats
              Row(
                    children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.camera_alt,
                      title: 'Active Cameras',
                      value: '3',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.delete_outline,
                      title: 'Pending Cleanup',
                      value: '${_recentDetections.where((d) => d.status.toLowerCase() != 'cleaned').length}',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Recent detections
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Detections',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to detections tab
                      (context.findAncestorStateOfType<_DashboardScreenState>())?.setState(() {
                        (context.findAncestorStateOfType<_DashboardScreenState>())?._currentIndex = 1;
                      });
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              
                      const SizedBox(height: 8),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _recentDetections.isEmpty
                      ? Card(
                          elevation: 0,
                          color: Colors.grey[100],
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No recent detections',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _recentDetections.map((detection) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => _showDetectionDetails(context, detection),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      // Add thumbnail image
                                      if (detection.hasImage)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: SizedBox(
                                            width: 60,
                                            height: 60,
                          child: Image.network(
                                              detection.effectiveImageUrl,
                            fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                                );
                                              },
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                              return Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[200],
                                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                );
                                              },
                                              cacheWidth: 120, // Cache with 2x resolution for crisp display
                                            ),
                                          ),
                                        )
                                      else
                                        CircleAvatar(
                                          backgroundColor: _getStatusColor(detection.status),
                                          radius: 20,
                                          child: Text(
                                            detection.detectionClass[0].toUpperCase(),
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                            Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              detection.detectionClass,
                                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                                            Text(
                                              '${detection.zoneName} - ${_formatTimestamp(detection.timestamp)}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: detection.status.toLowerCase() == 'cleaned'
                                              ? Colors.green
                                              : Colors.orange,
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
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            );
                          }).toList(),
                        ),
              
              const SizedBox(height: 24),
              
              // Add Test Data button
              Card(
                elevation: 2,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () async {
                    await TestDataService.addTestData();
                    _loadDetections();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test data added')),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
                    child: Row(
          children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          radius: 24,
                          child: const Icon(
                            Icons.add,
                            color: Colors.blue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                              Text(
                                'Add Test Data',
                      style: TextStyle(
                                  fontSize: 16,
                        fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                                  Text(
                                'Add sample detections to test the application',
                                    style: TextStyle(
                                  fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: Colors.blue,
                        ),
                      ],
                            ),
                          ),
                        ),
              ),
              
              const SizedBox(height: 16),
              
              // Load Sample Data from Server button
              Card(
                elevation: 2,
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () async {
                    // Show loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Loading sample data from server...')),
                    );
                    
                    // Load sample data from server
                    final success = await TestDataService.loadSampleDataFromServer();
                    
                    if (success) {
                      _loadDetections();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sample data loaded from server'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to load sample data from server'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          radius: 24,
                          child: const Icon(
                            Icons.cloud_download,
                            color: Colors.green,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Load Server Data',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Load sample detections from the server',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDetectionDetails(BuildContext context, Detection detection) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
                                  children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
                                    Text(
                detection.detectionClass,
                                      style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Add image if available
              if (detection.hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    detection.effectiveImageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image, size: 32, color: Colors.grey)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
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
              const SizedBox(height: 16),
              if (detection.status.toLowerCase() != 'cleaned')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _storage.markAsCleaned(
                        detection.timestamp,
                        'Staff',
                        'Marked as cleaned via dashboard',
                      );
                      Navigator.pop(context);
                      _loadDetections();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('MARK AS CLEANED'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'models/detection.dart';
import 'services/api_service.dart';
import 'utils/config.dart';
import 'screens/detection_list_screen.dart';
import 'screens/login_screen.dart';
import 'providers/theme_provider.dart';

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
  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: GarbageDetectorApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class GarbageDetectorApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const GarbageDetectorApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Garbage Detector',
      themeMode: themeProvider.themeMode,
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
      home: isLoggedIn ? const DetectionListScreen() : const LoginScreen(),
    );
  }
}

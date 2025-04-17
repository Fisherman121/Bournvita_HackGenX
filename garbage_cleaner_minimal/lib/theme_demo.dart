import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ThemeDemoApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveThemePreference();
    notifyListeners();
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeMode.toString());
  }
}

class ThemeDemoApp extends StatelessWidget {
  const ThemeDemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Theme Demo',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ThemeDemoScreen(),
    );
  }
}

class ThemeDemoScreen extends StatelessWidget {
  const ThemeDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Demo'),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.green[700],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              size: 100,
              color: isDarkMode ? Colors.amber : Colors.orange,
            ),
            const SizedBox(height: 32),
            Text(
              'Current Theme: ${isDarkMode ? "Dark" : "Light"}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                themeProvider.toggleTheme();
              },
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              label: Text('Switch to ${isDarkMode ? "Light" : "Dark"} Theme'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32, 
                  vertical: 16,
                ),
                backgroundColor: isDarkMode ? Colors.amber : Colors.green,
                foregroundColor: isDarkMode ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
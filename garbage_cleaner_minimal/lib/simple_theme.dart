import 'package:flutter/material.dart';

void main() {
  runApp(const SimpleThemeApp());
}

class SimpleThemeApp extends StatefulWidget {
  const SimpleThemeApp({Key? key}) : super(key: key);

  @override
  State<SimpleThemeApp> createState() => _SimpleThemeAppState();
}

class _SimpleThemeAppState extends State<SimpleThemeApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Theme',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Simple Theme Demo'),
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.green[700],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                size: 100,
                color: _isDarkMode ? Colors.amber : Colors.orange,
              ),
              const SizedBox(height: 32),
              Text(
                'Current Theme: ${_isDarkMode ? "Dark" : "Light"}',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isDarkMode = !_isDarkMode;
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32, 
                    vertical: 16,
                  ),
                ),
                child: Text('Switch to ${_isDarkMode ? "Light" : "Dark"} Theme'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
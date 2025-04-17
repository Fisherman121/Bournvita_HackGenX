import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              themeProvider.themeMode == ThemeMode.dark 
                ? Icons.dark_mode 
                : Icons.light_mode,
              size: 80,
              color: themeProvider.themeMode == ThemeMode.dark 
                ? Colors.amber 
                : Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              'Current Theme:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              themeProvider.themeMode == ThemeMode.dark 
                ? 'Dark Mode' 
                : themeProvider.themeMode == ThemeMode.light 
                  ? 'Light Mode' 
                  : 'System Mode',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: themeProvider.themeMode == ThemeMode.dark 
                  ? Colors.amber 
                  : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                themeProvider.setThemeMode(ThemeMode.light);
              },
              icon: const Icon(Icons.light_mode),
              label: const Text('LIGHT THEME'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32, 
                  vertical: 16,
                ),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                themeProvider.setThemeMode(ThemeMode.dark);
              },
              icon: const Icon(Icons.dark_mode),
              label: const Text('DARK THEME'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32, 
                  vertical: 16,
                ),
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                themeProvider.setThemeMode(ThemeMode.system);
              },
              icon: const Icon(Icons.settings_system_daydream),
              label: const Text('SYSTEM THEME'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32, 
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
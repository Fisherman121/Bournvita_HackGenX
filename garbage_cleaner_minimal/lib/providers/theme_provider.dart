import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedTheme = _prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        // Convert saved string to ThemeMode enum
        if (savedTheme.contains('dark')) {
          _themeMode = ThemeMode.dark;
        } else if (savedTheme.contains('light')) {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.system;
        }
      } else {
        // Default to system theme if no preference is saved
        _themeMode = ThemeMode.system;
      }
      
      // Force notifyListeners even if no change to ensure UI is updated
      notifyListeners();
    } catch (e) {
      print('Error loading theme mode: $e');
      // Default to system theme if there's an error
      _themeMode = ThemeMode.system;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; // Skip if no change
    
    _themeMode = mode;
    try {
      await _prefs.setString(_themeKey, mode.toString());
      print('Theme changed to: ${mode.toString()}');
    } catch (e) {
      print('Error saving theme mode: $e');
    }
    notifyListeners();
  }
} 
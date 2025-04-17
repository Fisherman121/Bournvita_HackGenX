import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeProvider() {
    _loadThemeMode();
  }
  
  ThemeMode get themeMode => _themeMode;
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemeMode();
    notifyListeners();
  }
  
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeMode();
    notifyListeners();
  }
  
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode');
    
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }
  
  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeMode.toString());
  }
} 
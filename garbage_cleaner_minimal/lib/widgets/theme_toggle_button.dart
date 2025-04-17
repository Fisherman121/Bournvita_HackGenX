import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool showAsAction;
  final ThemeMode? themeMode;
  final Function(ThemeMode)? onThemeModeChanged;

  const ThemeToggleButton({
    Key? key, 
    this.showAsAction = true,
    this.themeMode,
    this.onThemeModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = (themeMode ?? themeProvider.themeMode) == ThemeMode.dark;
    final toggleTheme = onThemeModeChanged ?? themeProvider.setThemeMode;

    if (showAsAction) {
      return IconButton(
        icon: Icon(
          isDarkMode ? Icons.light_mode : Icons.dark_mode,
          color: isDarkMode ? Colors.amber : Colors.white,
          size: 28,
        ),
        onPressed: () {
          toggleTheme(
            isDarkMode ? ThemeMode.light : ThemeMode.dark,
          );
        },
        tooltip: 'Toggle theme',
      );
    } else {
      return FloatingActionButton(
        onPressed: () {
          toggleTheme(
            isDarkMode ? ThemeMode.light : ThemeMode.dark,
          );
        },
        backgroundColor: isDarkMode ? Colors.amber[700] : Colors.green[700],
        tooltip: 'Toggle theme',
        child: Icon(
          isDarkMode ? Icons.light_mode : Icons.dark_mode,
          size: 28,
          color: Colors.white,
        ),
      );
    }
  }
} 
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Simple username/password validation
    // In a real app, you would connect to your backend API
    if (username == 'staff' && password == 'password123') {
      _user = User(
        id: '1',
        name: 'Cleaning Staff',
        username: username,
        email: 'staff@example.com',
      );

      // Save login state
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('isLoggedIn', true);
      prefs.setString('username', username);
      prefs.setString('userId', '1');

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _user = null;
    
    // Clear login state
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', false);
    prefs.remove('username');
    prefs.remove('userId');
    
    notifyListeners();
  }

  // Initialize user from shared preferences if they were logged in
  Future<void> initUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    if (isLoggedIn) {
      final username = prefs.getString('username') ?? '';
      final userId = prefs.getString('userId') ?? '';
      
      _user = User(
        id: userId,
        name: 'Cleaning Staff',
        username: username,
        email: 'staff@example.com',
      );
      
      notifyListeners();
    }
  }
} 
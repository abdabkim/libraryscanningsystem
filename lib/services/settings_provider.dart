import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  double _fontSize = 16.0;
  bool _isLoading = false;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  double get fontSize => _fontSize;
  bool get isLoading => _isLoading;

  ThemeData get currentTheme => _darkModeEnabled
      ? ThemeData.dark().copyWith(
    primaryColor: Colors.teal,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
    ),
  )
      : ThemeData.light().copyWith(
    primaryColor: Colors.blue,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
    ),
  );

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      _fontSize = prefs.getDouble('font_size') ?? 16.0;
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (_notificationsEnabled == value) return;

    _notificationsEnabled = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
    } catch (e) {
      debugPrint('Error saving notification setting: $e');
    }
  }

  Future<void> setDarkModeEnabled(bool value) async {
    if (_darkModeEnabled == value) return;

    _darkModeEnabled = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode_enabled', value);
    } catch (e) {
      debugPrint('Error saving dark mode setting: $e');
    }
  }

  Future<void> setFontSize(double value) async {
    if (_fontSize == value) return;

    _fontSize = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('font_size', value);
    } catch (e) {
      debugPrint('Error saving font size setting: $e');
    }
  }

  Future<void> resetSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notificationsEnabled = true;
      _darkModeEnabled = false;
      _fontSize = 16.0;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', true);
      await prefs.setBool('dark_mode_enabled', false);
      await prefs.setDouble('font_size', 16.0);
    } catch (e) {
      debugPrint('Error resetting settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
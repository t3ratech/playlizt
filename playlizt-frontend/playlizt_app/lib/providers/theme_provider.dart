/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/27 08:33
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/playlizt_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _keyTheme = 'settings.theme';
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    _saveTheme();
    notifyListeners();
  }

  Future<void> setTheme(PlayliztTheme theme) async {
    switch (theme) {
      case PlayliztTheme.dark:
        _themeMode = ThemeMode.dark;
        break;
      case PlayliztTheme.light:
        _themeMode = ThemeMode.light;
        break;
      case PlayliztTheme.system:
        _themeMode = ThemeMode.system;
        break;
    }
    await _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final themeId = prefs.getString(_keyTheme);
    if (themeId != null) {
      final theme = playliztThemeFromId(themeId);
      if (theme != null) {
        switch (theme) {
          case PlayliztTheme.dark:
            _themeMode = ThemeMode.dark;
            break;
          case PlayliztTheme.light:
            _themeMode = ThemeMode.light;
            break;
          case PlayliztTheme.system:
            _themeMode = ThemeMode.system;
            break;
        }
      }
      notifyListeners();
    }
  } 

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    PlayliztTheme theme;
    switch (_themeMode) {
      case ThemeMode.dark:
        theme = PlayliztTheme.dark;
        break;
      case ThemeMode.light:
        theme = PlayliztTheme.light;
        break;
      case ThemeMode.system:
        theme = PlayliztTheme.system;
        break;
    }
    await prefs.setString(_keyTheme, playliztThemeId(theme));
  }
}

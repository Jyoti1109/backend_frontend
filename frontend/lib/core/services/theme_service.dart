import 'package:flutter/material.dart';
import 'package:good_news/core/services/preferences_service.dart';

enum AppThemeType { green, pink }

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  // ✅ डीफॉल्ट: Light Mode (UI ला आधीपासूनच light दाखवायचं)
  ThemeMode _themeMode = ThemeMode.light;
  AppThemeType _themeType = AppThemeType.green;
  double _fontSize = 1.0;
  bool _reduceMotion = false;

  ThemeMode get themeMode => _themeMode;
  AppThemeType get themeType => _themeType;
  double get fontSize => _fontSize;
  bool get reduceMotion => _reduceMotion;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadPreferences() async {
    // ✅ Important: Default to LIGHT if no preference exists
    final isDark = await PreferencesService.getBool('isDarkMode') ?? false; // false = light mode

    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    final themeTypeIndex = await PreferencesService.getInt('themeType') ?? 0;
    _themeType = AppThemeType.values[themeTypeIndex];

    _fontSize = await PreferencesService.getDouble('fontSize') ?? 1.0;
    _reduceMotion = await PreferencesService.getBool('reduceMotion') ?? false;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    // Save: true if dark, false if light
    await PreferencesService.setBool('isDarkMode', mode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> setThemeType(AppThemeType type) async {
    _themeType = type;
    await PreferencesService.setInt('themeType', type.index);
    notifyListeners();
  }

  Future<void> setFontSize(double scale) async {
    _fontSize = scale.clamp(0.8, 1.4);
    await PreferencesService.setDouble('fontSize', _fontSize);
    notifyListeners();
  }

  Future<void> setReduceMotion(bool reduce) async {
    _reduceMotion = reduce;
    await PreferencesService.setBool('reduceMotion', reduce);
    notifyListeners();
  }

  Duration getAnimationDuration(Duration defaultDuration) {
    return _reduceMotion ? Duration.zero : defaultDuration;
  }
}
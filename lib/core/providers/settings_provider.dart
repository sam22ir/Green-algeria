import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';

class SettingsProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ar', 'AE');
  bool _notificationsEnabled = true;

  SettingsProvider() {
    _loadFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get notificationsEnabled => _notificationsEnabled;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return false; 
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    
    final themeStr = _prefs!.getString('theme_mode');
    if (themeStr == 'light') _themeMode = ThemeMode.light;
    else if (themeStr == 'dark') _themeMode = ThemeMode.dark;
    else _themeMode = ThemeMode.system;

    final langCode = _prefs!.getString('language_code');
    if (langCode == 'en') _locale = const Locale('en', 'US');
    else _locale = const Locale('ar', 'AE'); 

    _notificationsEnabled = _prefs!.getBool('notifications_enabled') ?? true;
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _initPrefs();
    String themeStr = 'system';
    if (mode == ThemeMode.light) themeStr = 'light';
    else if (mode == ThemeMode.dark) themeStr = 'dark';
    await _prefs!.setString('theme_mode', themeStr);
  }

  Future<void> setLocale(Locale loc) async {
    _locale = loc;
    notifyListeners();
    await _initPrefs();
    await _prefs!.setString('language_code', loc.languageCode);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    await _initPrefs();
    await _prefs!.setBool('notifications_enabled', enabled);

    // Sync state with FCM logic
    final userModel = AuthService().currentUserModel;
    if (enabled) {
      await NotificationService().subscribeToTopic('national-notifications');
      if (userModel?.provinceId != null) {
        await NotificationService().subscribeToTopic('province-${userModel!.provinceId}');
      }
    } else {
      await NotificationService().unsubscribeFromTopic('national-notifications');
      if (userModel?.provinceId != null) {
        await NotificationService().unsubscribeFromTopic('province-${userModel!.provinceId}');
      }
    }
  }
}


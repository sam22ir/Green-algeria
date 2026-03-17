import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../services/auth_service.dart';

class SettingsProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ar');
  bool _notifNationalCampaigns = true;
  bool _notifProvincialCampaigns = true;
  bool _notifLocalCampaigns = true;
  bool _notifMyCampaigns = true;
  bool _notifSupport = true;
  bool _notifSystem = true;

  SettingsProvider();

  Future<void> loadInitialPrefs() async {
    await _loadFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  
  bool get notifNationalCampaigns => _notifNationalCampaigns;
  bool get notifProvincialCampaigns => _notifProvincialCampaigns;
  bool get notifLocalCampaigns => _notifLocalCampaigns;
  bool get notifMyCampaigns => _notifMyCampaigns;
  bool get notifSupport => _notifSupport;
  bool get notifSystem => _notifSystem;

  bool get isDarkMode => _themeMode == ThemeMode.dark || 
      (_themeMode == ThemeMode.system && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    
    final themeStr = _prefs!.getString('theme_mode');
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    final langCode = _prefs!.getString('language_code');
    if (langCode == 'en') {
      _locale = const Locale('en');
    } else {
      _locale = const Locale('ar');
    } 

    _notifNationalCampaigns = _prefs!.getBool('notif_national_campaigns') ?? true;
    _notifProvincialCampaigns = _prefs!.getBool('notif_provincial_campaigns') ?? true;
    _notifLocalCampaigns = _prefs!.getBool('notif_local_campaigns') ?? true;
    _notifMyCampaigns = _prefs!.getBool('notif_my_campaigns') ?? true;
    _notifSupport = _prefs!.getBool('notif_support') ?? true;
    _notifSystem = _prefs!.getBool('notif_system') ?? true;
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _initPrefs();
    String themeStr = 'system';
    if (mode == ThemeMode.light) {
      themeStr = 'light';
    } else if (mode == ThemeMode.dark) {
      themeStr = 'dark';
    }
    await _prefs!.setString('theme_mode', themeStr);
  }

  Future<void> setLocale(Locale loc) async {
    _locale = loc;
    notifyListeners();
    await _initPrefs();
    await _prefs!.setString('language_code', loc.languageCode);
  }

  Future<void> setNotifNationalCampaigns(bool enabled) async {
    _notifNationalCampaigns = enabled;
    notifyListeners();
    await _initPrefs();
    await _prefs!.setBool('notif_national_campaigns', enabled);
    _syncTopic('national-campaigns', enabled);
  }

  Future<void> setNotifProvincialCampaigns(bool enabled) async {
    _notifProvincialCampaigns = enabled;
    notifyListeners();
    await _initPrefs();
    await _prefs!.setBool('notif_provincial_campaigns', enabled);
    _syncProvincialTopic('campaigns', enabled);
  }

  Future<void> setNotifLocalCampaigns(bool enabled) async {
    _notifLocalCampaigns = enabled;
    notifyListeners();
    await _initPrefs();
    await _prefs!.setBool('notif_local_campaigns', enabled);
    _syncTopic('local-campaigns', enabled);
  }
  
  Future<void> setNotifMyCampaigns(bool enabled) async {
    _notifMyCampaigns = enabled;
    notifyListeners();
    await _initPrefs();
    await _prefs!.setBool('notif_my_campaigns', enabled);
    // User specific topic: my-campaigns-{uid}
    final uid = AuthService().firebaseUser?.id;
    if (uid != null) {
      _syncTopic('updates-$uid', enabled);
    }
  }

  Future<void> setNotifSupport(bool enabled) async {
    _notifSupport = enabled;
    notifyListeners();
    await _initPrefs();
    await _prefs!.setBool('notif_support', enabled);
    final uid = AuthService().firebaseUser?.id;
    if (uid != null) {
      _syncTopic('support-$uid', enabled);
    }
  }

  Future<void> setNotifSystem(bool enabled) async {
    _notifSystem = enabled;
    notifyListeners();
    await _initPrefs();
    await _prefs!.setBool('notif_system', enabled);
    _syncTopic('system-notifications', enabled);
  }

  Future<void> _syncTopic(String topic, bool enabled) async {
    try {
      if (enabled) {
        await NotificationService().subscribeToTopic(topic);
      } else {
        await NotificationService().unsubscribeFromTopic(topic);
      }
    } catch (e) {
      debugPrint('Failed to sync topic $topic: $e');
    }
  }

  Future<void> _syncProvincialTopic(String suffix, bool enabled) async {
    try {
      final user = AuthService().currentUserModel;
      if (user?.provinceId != null) {
        final topic = suffix == 'campaigns' 
            ? 'province-${user!.provinceId}-campaigns' 
            : 'province-${user!.provinceId}';
        _syncTopic(topic, enabled);
      }
    } catch (e) {
      debugPrint('Failed to sync provincial topic: $e');
    }
  }
}



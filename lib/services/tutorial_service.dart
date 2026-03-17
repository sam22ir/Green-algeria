import 'package:shared_preferences/shared_preferences.dart';

/// Manages "has the user seen the tutorial for this screen?" state.
/// Keys are simple screen IDs like 'home', 'map', 'campaigns', etc.
class TutorialService {
  static const _prefix = 'tutorial_seen_';

  /// Returns true if the tutorial for [screenId] should be shown.
  static Future<bool> shouldShow(String screenId) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('$_prefix$screenId') ?? false);
  }

  /// Marks the tutorial for [screenId] as seen — won't show again.
  static Future<void> markSeen(String screenId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$screenId', true);
  }

  /// Resets all tutorials (useful for dev/debug).
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}

import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'whats_new_last_seen_version';

abstract final class WhatsNewSeenStore {
  static Future<String?> lastSeenVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey);
  }

  static Future<void> markSeen(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, version);
  }
}

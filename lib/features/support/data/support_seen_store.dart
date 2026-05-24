import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Última vez que o usuário viu cada ticket (para badge de atualização).
class SupportSeenStore {
  SupportSeenStore(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'support_ticket_last_seen';

  static Future<SupportSeenStore> open() async {
    return SupportSeenStore(await SharedPreferences.getInstance());
  }

  Map<String, String> _readMap() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  Future<void> markSeen(String ticketId, String updatedAt) async {
    final map = _readMap();
    map[ticketId] = updatedAt;
    await _prefs.setString(_key, jsonEncode(map));
  }

  String? lastSeenAt(String ticketId) => _readMap()[ticketId];
}

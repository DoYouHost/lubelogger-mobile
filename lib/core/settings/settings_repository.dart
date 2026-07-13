import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'server_profile.dart';

/// Persists the server profile in SharedPreferences. The URL, auth mode and
/// username are not secrets — [CredentialsStore] holds the key/password.
class SettingsRepository {
  SettingsRepository(this._prefs);

  static const _profileKey = 'server_profile';

  final SharedPreferences _prefs;

  ServerProfile? loadProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      return ServerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Treat a corrupted entry as no profile — the user goes through setup
      // again instead of the app crashing on launch.
      return null;
    }
  }

  Future<void> saveProfile(ServerProfile profile) =>
      _prefs.setString(_profileKey, jsonEncode(profile.toJson()));

  Future<void> clearProfile() => _prefs.remove(_profileKey);
}

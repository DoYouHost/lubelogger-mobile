import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle_tab.dart';
import 'server_profile.dart';
import 'units_settings.dart';

/// Persists the server profile and display preferences in SharedPreferences.
/// The URL is not a secret — [CredentialsStore] holds the API key.
class SettingsRepository {
  SettingsRepository(this._prefs);

  static const _profileKey = 'server_profile';
  static const _unitsKey = 'units_settings';
  static const _visibleTabsKey = 'visible_tabs';
  static const _tabOrderKey = 'tab_order';
  static const _remindersEnabledKey = 'reminder_notifications_enabled';
  static const _diagnosticsSessionKey = 'diagnostics_session';

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

  UnitsSettings loadUnits() {
    final raw = _prefs.getString(_unitsKey);
    if (raw == null) return const UnitsSettings();
    try {
      return UnitsSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const UnitsSettings();
    }
  }

  Future<void> saveUnits(UnitsSettings units) =>
      _prefs.setString(_unitsKey, jsonEncode(units.toJson()));

  /// The record tabs the user wants visible. Absent (never set) defaults to all
  /// tabs; unknown persisted ids are dropped so removing a tab type can't break
  /// loading.
  Set<VehicleTab> loadVisibleTabs() {
    final names = _prefs.getStringList(_visibleTabsKey);
    if (names == null) return VehicleTab.values.toSet();
    return {
      for (final n in names) ?VehicleTab.byName(n),
    };
  }

  Future<void> saveVisibleTabs(Set<VehicleTab> tabs) => _prefs.setStringList(
        _visibleTabsKey,
        [for (final t in tabs) t.name],
      );

  /// The order record tabs appear in — on the vehicle screen (after the always-
  /// first Dashboard) and in the FAB add sheet. A full permutation of
  /// [VehicleTab.values]; visibility is tracked separately by [loadVisibleTabs].
  /// Absent (never set) defaults to enum order; unknown persisted ids are
  /// dropped, and any tab missing from the stored order (e.g. one added in a
  /// newer app version) is appended so it can never disappear.
  List<VehicleTab> loadTabOrder() {
    final names = _prefs.getStringList(_tabOrderKey);
    if (names == null) return VehicleTab.values.toList();
    final ordered = [
      for (final n in names) ?VehicleTab.byName(n),
    ];
    final seen = ordered.toSet();
    return [
      ...ordered,
      for (final t in VehicleTab.values)
        if (!seen.contains(t)) t,
    ];
  }

  Future<void> saveTabOrder(List<VehicleTab> order) => _prefs.setStringList(
        _tabOrderKey,
        [for (final t in order) t.name],
      );

  /// Whether the background check may post past-due reminder notifications.
  /// Opt-in (defaults off) since it needs the Android 13+ notification
  /// permission. Also read by the WorkManager background isolate.
  bool loadRemindersEnabled() => _prefs.getBool(_remindersEnabledKey) ?? false;

  Future<void> saveRemindersEnabled(bool enabled) =>
      _prefs.setBool(_remindersEnabledKey, enabled);

  /// Id of the diagnostic recording in progress, or null when nothing is being
  /// recorded — the id doubles as the flag. Written by the UI isolate and read
  /// by the WorkManager one, which is how a recording started in the app reaches
  /// an isolate that shares no Dart state with it.
  ///
  /// A leftover id at startup means the app died mid-recording; the bug-report
  /// controller clears it and offers the salvaged files.
  String? loadDiagnosticsSession() {
    final id = _prefs.getString(_diagnosticsSessionKey);
    return (id == null || id.isEmpty) ? null : id;
  }

  Future<void> saveDiagnosticsSession(String? session) => session == null
      ? _prefs.remove(_diagnosticsSessionKey)
      : _prefs.setString(_diagnosticsSessionKey, session);
}

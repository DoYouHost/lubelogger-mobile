import 'package:shared_preferences/shared_preferences.dart';

/// Persists the set of reminder due-cycle keys already notified about, so the
/// periodic check posts each past-due reminder only once. Written and read only
/// by the WorkManager background isolate (via a fresh `SharedPreferences` load
/// each run), so there's no cross-isolate cache staleness to worry about. See
/// [planReminderNotifications] for how the set evolves.
class ReminderNotifiedStore {
  ReminderNotifiedStore(this._prefs);

  static const _key = 'reminder_notified_keys';

  final SharedPreferences _prefs;

  Set<String> load() => _prefs.getStringList(_key)?.toSet() ?? <String>{};

  Future<void> save(Set<String> keys) =>
      _prefs.setStringList(_key, keys.toList());
}

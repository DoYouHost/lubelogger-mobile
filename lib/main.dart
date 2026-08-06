import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/app_localizations_loader.dart';
import 'core/diagnostics/diagnostic_recorder.dart';
import 'core/diagnostics/log_event.dart';
import 'core/diagnostics/session_facts.dart';
import 'core/format/formatters.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/reminder_worker.dart';
import 'core/quick_actions_service.dart';
import 'core/settings/settings_repository.dart';
import 'features/quick_actions/quick_action_handler.dart';
import 'providers.dart';
import 'router.dart';

/// Shared notification handle for the UI isolate (init + launch payload). The
/// WorkManager background isolate builds its own instance — the two isolates
/// share no Dart state, only the native plugin underneath.
final notificationService = NotificationService();

/// Bundled fonts (Manrope, JetBrains Mono) aren't pub packages, so their OFL
/// licenses aren't picked up by Flutter's automatic per-package license
/// collection — register them manually so they show up on the licenses page.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    const licenses = {
      'Manrope': 'assets/licenses/OFL-Manrope.txt',
      'JetBrains Mono': 'assets/licenses/OFL-JetBrainsMono.txt',
    };
    for (final entry in licenses.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}

/// Navigate to a vehicle from a tapped reminder notification (payload = vehicle
/// id). Best-effort: silently ignores a malformed payload or a not-yet-ready
/// navigator — and says so in the diagnostic log, because "I tapped the
/// notification and nothing opened" is otherwise an event with no trace at all.
void _openVehicleFromNotification(String? payload) {
  final id = int.tryParse(payload ?? '');
  final context = rootNavigatorKey.currentContext;
  DiagnosticRecorder.active?.add(
    LogSource.notif,
    'tapped',
    lvl: id == null || context == null ? LogLevel.warn : LogLevel.info,
    fields: {
      'vid': id,
      'reason': id == null
          ? 'badPayload'
          : context == null
              ? 'noNavigator'
              : null,
    },
  );
  if (id == null) return;
  context?.go('/vehicle/$id');
}

Future<void> main() async {
  AppStart.at = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  // Numbers and money follow the device's regional format (separators, and
  // whether the currency symbol leads or trails the amount).
  Formatters.useLocale(
    WidgetsBinding.instance.platformDispatcher.locale.toString(),
  );
  final prefs = await SharedPreferences.getInstance();

  // Notification + quick-action setup is non-essential to the app running, so a
  // failure here (e.g. a missing/stripped resource) must never keep runApp()
  // below from executing — swallow and log instead of taking the whole app down.
  String? launchPayload;
  try {
    // Reminder notifications: set up the plugin + background worker, and arm the
    // periodic check when the user is signed in and has opted in.
    final l10n = await loadAppLocalizations();
    await notificationService.init(
      channelName: l10n.notifReminderChannelName,
      channelDescription: l10n.notifReminderChannelDescription,
      onTap: _openVehicleFromNotification,
    );
    await initReminderWorker();
    final settings = SettingsRepository(prefs);
    final signedIn = settings.loadProfile() != null;
    if (signedIn && settings.loadRemindersEnabled()) {
      await registerReminderWorker();
    }

    // Launcher quick actions: register the tap handler (it fires now if the app
    // was cold-launched from a shortcut) and publish the add-record shortcuts
    // while signed in.
    await quickActionsService.init((type) => pendingQuickAction.value = type);
    if (signedIn) {
      await quickActionsService.setRecordShortcuts(
        fuelLabel: l10n.quickActionAddFuel,
        odometerLabel: l10n.quickActionAddOdometer,
      );
    }

    launchPayload = await notificationService.launchPayload();
  } catch (error, stack) {
    debugPrint('Non-essential startup init failed (continuing): $error\n$stack');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const LubeLoggerApp(),
    ),
  );

  // App launched by tapping a notification: deep-link once the first frame (and
  // thus the router) is ready.
  if (launchPayload != null) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openVehicleFromNotification(launchPayload),
    );
  }
}

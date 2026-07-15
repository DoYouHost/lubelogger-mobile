import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/vehicles_repository.dart';
import '../api/api_client.dart';
import '../app_localizations_loader.dart';
import '../auth/credentials_store.dart';
import '../models/vehicle.dart';
import '../settings/settings_repository.dart';
import 'notification_service.dart';
import 'reminder_notifications.dart';
import 'reminder_notified_store.dart';

/// Unique WorkManager task id — one scheduled instance at a time.
const _reminderTaskUniqueName = 'lubelogger.reminderCheck';
const _reminderTaskName = 'reminderCheck';

/// How often the background check runs. WorkManager's floor is 15 min; actual
/// firing is best-effort (Doze/OEM battery managers may delay it), which is fine
/// for maintenance reminders measured in days.
const reminderCheckInterval = Duration(hours: 3);

/// WorkManager entry point. Runs in a background isolate, so it must be a
/// top-level function marked with the vm:entry-point pragma to survive tree
/// shaking / AOT.
@pragma('vm:entry-point')
void reminderCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await runReminderCheck();
    } on Object {
      // Never crash the worker; the next scheduled run retries.
    }
    return true;
  });
}

/// Register the WorkManager callback dispatcher. Call once from `main()` before
/// scheduling any task.
Future<void> initReminderWorker() =>
    Workmanager().initialize(reminderCallbackDispatcher);

/// Schedule the recurring past-due reminder check. Idempotent —
/// [ExistingPeriodicWorkPolicy.update] keeps a single task and refreshes its
/// spec without disrupting a run in progress.
Future<void> registerReminderWorker() => Workmanager().registerPeriodicTask(
      _reminderTaskUniqueName,
      _reminderTaskName,
      frequency: reminderCheckInterval,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );

/// Cancel the recurring check (on logout or when the user turns notifications
/// off).
Future<void> cancelReminderWorker() =>
    Workmanager().cancelByUniqueName(_reminderTaskUniqueName);

/// One pass of the background check: fetch reminders for every vehicle, post a
/// notification for each newly past-due one, and persist the notified set so
/// each due-cycle alerts only once. Rebuilds the API stack from scratch because
/// the background isolate shares no state with the app (see the reminder
/// notifications analysis in memory). Safe to call directly in tests.
Future<void> runReminderCheck() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsRepository(prefs);

  // Nothing to do when logged out or the user hasn't opted in.
  final profile = settings.loadProfile();
  if (profile == null || !settings.loadRemindersEnabled()) return;

  final credentials = SecureCredentialsStore();
  if (await credentials.readApiKey() == null) return;

  final repo = VehiclesRepository(
    ApiClient(profile: profile, credentials: credentials).dio,
  );

  // Collect every currently past-due reminder across all vehicles.
  final alerts = <ReminderAlert>[];
  final vehicles = await repo.list();
  for (final vehicle in vehicles) {
    try {
      final reminders = await repo.reminders(vehicle.id);
      final name = _vehicleName(vehicle);
      for (final reminder in reminders) {
        final alert = reminderAlertFor(vehicle.id, name, reminder);
        if (alert != null) alerts.add(alert);
      }
    } on Object {
      // Skip a vehicle whose reminders can't be fetched; others still notify.
      continue;
    }
  }

  final store = ReminderNotifiedStore(prefs);
  final plan = planReminderNotifications(alerts, store.load());

  if (plan.toNotify.isNotEmpty) {
    final l10n = await loadAppLocalizations();
    final service = NotificationService();
    await service.init(
      channelName: l10n.notifReminderChannelName,
      channelDescription: l10n.notifReminderChannelDescription,
    );
    for (final alert in plan.toNotify) {
      await service.showReminder(
        id: alert.notificationId,
        title: l10n.notifReminderTitle,
        body: l10n.notifReminderBody(alert.vehicleName, alert.description),
        payload: '${alert.vehicleId}',
        channelName: l10n.notifReminderChannelName,
        channelDescription: l10n.notifReminderChannelDescription,
      );
    }
  }

  // Persist exactly the currently past-due keys — self-pruning (see the plan).
  await store.save(plan.nextNotified);
}

String _vehicleName(Vehicle vehicle) {
  if (vehicle.makeModel.isNotEmpty) return vehicle.makeModel;
  if (vehicle.licensePlate.isNotEmpty) return vehicle.licensePlate;
  return '#${vehicle.id}';
}

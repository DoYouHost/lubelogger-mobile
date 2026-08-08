import 'package:shared_preferences/shared_preferences.dart';

import '../../data/vehicles_repository.dart';
import '../app_localizations_loader.dart';
import '../diagnostics/diagnostic_recorder.dart';
import '../diagnostics/log_event.dart';
import '../models/vehicle.dart';
import 'notification_service.dart';
import 'reminder_notifications.dart';
import 'reminder_notified_store.dart';

/// One pass of the past-due reminder check: fetch reminders for every vehicle,
/// post a notification for each newly past-due one, and persist the notified
/// set so each due-cycle alerts only once.
///
/// The background pass owns the isolate setup, the credentials and [repo] — the
/// isolate shares no state with the app, and building that stack twice would
/// mean two clients over one queue.
Future<void> runReminderPass(
  SharedPreferences prefs,
  VehiclesRepository repo,
) async {
  final log = DiagnosticRecorder.active;

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
    } on Object catch (error) {
      // Skip a vehicle whose reminders can't be fetched; others still notify.
      // The HTTP probe already recorded the failed call; this says what the
      // worker did about it, which the call alone does not.
      log?.add(
        LogSource.notif,
        'vehicle_skipped',
        lvl: LogLevel.warn,
        fields: {'vid': vehicle.id, 'type': error.runtimeType.toString()},
      );
      continue;
    }
  }

  final store = ReminderNotifiedStore(prefs);
  final plan = planReminderNotifications(alerts, store.load());
  // Counts, never the reminders themselves: a description is the user's text
  // and a vehicle name is their car. "Three were past due and none of them
  // notified" is the whole diagnosis anyway.
  log?.add(
    LogSource.notif,
    'planned',
    fields: {
      'due': alerts.length,
      'notify': plan.toNotify.length,
      'known': plan.nextNotified.length,
    },
  );

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
      log?.add(
        LogSource.notif,
        'posted',
        fields: {'vid': alert.vehicleId, 'nid': alert.notificationId},
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

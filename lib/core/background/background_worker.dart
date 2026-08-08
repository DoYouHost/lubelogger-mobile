import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/vehicles_repository.dart';
import '../api/api_client.dart';
import '../auth/credentials_store.dart';
import '../cache/sync_service.dart';
import '../cache/write_queue.dart';
import '../diagnostics/diagnostic_recorder.dart';
import '../diagnostics/log_event.dart';
import '../notifications/reminder_worker.dart';
import '../settings/settings_repository.dart';
import '../diagnostics/session_facts.dart';

/// Unique WorkManager task id. Still named after the reminder check, which is
/// all it used to do: an installed app already has a periodic task registered
/// under this name, and a new name would leave that one scheduled forever
/// beside its replacement.
const _periodicTaskUniqueName = 'lubelogger.reminderCheck';
const _periodicTaskName = 'reminderCheck';

/// A single extra pass, asked for when a write lands in the queue. Its network
/// constraint is the point: it fires when connectivity comes back rather than
/// at the next three-hour tick.
const _retryTaskUniqueName = 'lubelogger.retryWrites';
const _retryTaskName = 'retryWrites';

/// How often the background pass runs. WorkManager's floor is 15 min; actual
/// firing is best-effort (Doze/OEM battery managers may delay it), which is fine
/// for maintenance reminders measured in days and for a cache the app refreshes
/// on its own as soon as it is opened.
const backgroundPassInterval = Duration(hours: 3);

/// WorkManager entry point. Runs in a background isolate, so it must be a
/// top-level function marked with the vm:entry-point pragma to survive tree
/// shaking / AOT.
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await runBackgroundPass();
    } on Object {
      // Never crash the worker; the next scheduled run retries.
    }
    return true;
  });
}

/// Register the WorkManager callback dispatcher. Call once from `main()` before
/// scheduling any task.
Future<void> initBackgroundWorker() =>
    Workmanager().initialize(backgroundCallbackDispatcher);

/// Schedule the recurring pass. Idempotent —
/// [ExistingPeriodicWorkPolicy.update] keeps a single task and refreshes its
/// spec without disrupting a run in progress.
Future<void> registerBackgroundWorker() => Workmanager().registerPeriodicTask(
      _periodicTaskUniqueName,
      _periodicTaskName,
      frequency: backgroundPassInterval,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );

/// Cancel the recurring pass (on logout).
Future<void> cancelBackgroundWorker() =>
    Workmanager().cancelByUniqueName(_periodicTaskUniqueName);

/// Ask for one pass as soon as there is a network again — what a queued write
/// is waiting for. [ExistingWorkPolicy.keep] makes repeat calls free, so every
/// queued write may ask without stacking up passes.
Future<void> requestWriteRetry() => Workmanager().registerOneOffTask(
      _retryTaskUniqueName,
      _retryTaskName,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );

/// One background pass: deliver what the write queue is holding, refresh what
/// the app opens onto, then check for past-due reminders.
///
/// The three share a task on purpose. WorkManager's floor is 15 minutes and
/// every additional periodic task is another wake-up an OEM battery manager can
/// decide to skip; one pass that does three things survives better than three
/// that each do one. Safe to call directly in tests.
Future<void> runBackgroundPass() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsRepository(prefs);

  // Continues a diagnostic recording the app started, if one is running. This
  // isolate is invisible from the UI, and "the app notified me at 3 a.m." or
  // "my edit never arrived" has no other witness. Null when nothing is being
  // recorded, which is the normal case.
  final recording = await DiagnosticRecorder.startBackground(
    settings: settings,
    stream: LogStream.worker,
    loadSecrets: () => sessionSecrets(
      profile: settings.loadProfile(),
      credentials: SecureCredentialsStore(),
    ),
  );
  try {
    await _pass(prefs, settings);
  } on Object catch (error, stack) {
    // The dispatcher above swallows this so the task never crashes, which means
    // a pass that dies halfway — an unreachable server, a response the parser
    // choked on — leaves no trace anywhere. Recorded here, where there is still
    // a stream to write to, then rethrown to the caller that owns the policy.
    DiagnosticRecorder.active?.add(
      LogSource.err,
      'worker_failed',
      lvl: LogLevel.error,
      fields: {
        'type': error.runtimeType.toString(),
        'msg': error.toString(),
        'stack': stack.toString(),
      },
    );
    rethrow;
  } finally {
    await recording?.stop();
  }
}

Future<void> _pass(
  SharedPreferences prefs,
  SettingsRepository settings,
) async {
  final log = DiagnosticRecorder.active;
  log?.add(LogSource.app, 'worker_started');

  final profile = settings.loadProfile();
  if (profile == null) {
    log?.add(LogSource.app, 'worker_skipped', fields: {'reason': 'noProfile'});
    return;
  }
  final credentials = SecureCredentialsStore();
  if (await credentials.readApiKey() == null) {
    log?.add(LogSource.app, 'worker_skipped', fields: {'reason': 'noKey'});
    return;
  }

  final queue = WriteQueue(prefs);
  final client = ApiClient(
    profile: profile,
    credentials: credentials,
    queue: queue,
  );
  final repository = VehiclesRepository(client.dio);
  final sync = SyncService(
    dio: client.dio,
    queue: queue,
    repository: repository,
  );

  // Delivery first: a warm cache that predates the queue would show the user
  // records without the edit they are waiting on.
  final outcome = await sync.drain();
  if (settings.loadBackgroundRefreshEnabled()) {
    await sync.warmCache();
  }
  if (settings.loadRemindersEnabled()) {
    await runReminderPass(prefs, repository);
  }

  log?.add(
    LogSource.app,
    'worker_finished',
    fields: {'sent': outcome.delivered, 'left': outcome.remaining},
  );
}

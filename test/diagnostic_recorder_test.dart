import 'dart:convert';
import 'dart:io';

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/diagnostics/diagnostics_wiring.dart';
import 'package:lubelogger_mobile/core/diagnostics/report_config.dart';
import 'package:lubelogger_mobile/core/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How a recording reaches the WorkManager isolate: through the session id in
/// [SettingsRepository]. The recorder itself is `app_diagnostics`' and tested
/// there.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late SettingsRepository settings;
  late DiagnosticRecorder recorder;

  DiagnosticRecorder build() => lubeloggerRecorder(
    settings: settings,
    loadFacts: () async => const SessionFacts(app: '0.2.7+207'),
    resolveDirectory: () async => dir,
  );

  Future<BackgroundRecording?> startWorker() =>
      DiagnosticRecorder.startBackground(
        sessions: SettingsSessionStore(settings),
        stream: LogStream.worker,
        redactor: lubeloggerRedactor,
        sessionLimit: recordingLimit,
        resolveDirectory: () async => dir,
        // The error probe swaps the global handlers; a test must not keep those.
        attachErrors: false,
      );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('lubelogger-diagnostics');
    SharedPreferences.setMockInitialValues({});
    settings = SettingsRepository(await SharedPreferences.getInstance());
    recorder = build();
  });

  tearDown(() async {
    if (DiagnosticRecorder.isRecording) await recorder.stop();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('a running recording is discoverable by the other isolate', () async {
    expect(settings.loadDiagnosticsSession(), isNull);
    await recorder.start();
    expect(settings.loadDiagnosticsSession(), isNotNull);
    await recorder.stop();
    expect(settings.loadDiagnosticsSession(), isNull);
  });

  test('the worker stream is folded in, stamped with its origin', () async {
    await recorder.start();
    final session = settings.loadDiagnosticsSession()!;
    DiagnosticRecorder.active!.add(LogSource.ui, 'tap', fields: {'id': 'a.b'});
    await recorder.stop();

    // The worker's heap never holds the UI's store, so it opens its own stream
    // from the id the app left in preferences.
    await settings.saveDiagnosticsSession(session);
    final recording = await startWorker();
    expect(recording, isNotNull);
    recording!.store.add(LogSource.notif, 'posted');
    await recording.stop();
    await settings.saveDiagnosticsSession(null);

    final merged = [
      for (final line in const LineSplitter()
          .convert(await build().recover(session))
          .skip(1))
        jsonDecode(line) as Map<String, Object?>,
    ];
    expect(merged.firstWhere((r) => r['evt'] == 'posted')['iso'], 'worker');
    expect(merged.firstWhere((r) => r['evt'] == 'tap')['iso'], isNull);
  });

  test('the worker refuses a session that is not there', () async {
    expect(await startWorker(), isNull);
    expect(dir.listSync(), isEmpty);
  });
}

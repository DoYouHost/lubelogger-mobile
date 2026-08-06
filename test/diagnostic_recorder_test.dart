import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/diagnostics/diagnostic_recorder.dart';
import 'package:lubelogger_mobile/core/diagnostics/log_event.dart';
import 'package:lubelogger_mobile/core/diagnostics/session_facts.dart';
import 'package:lubelogger_mobile/core/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late SettingsRepository settings;
  late DiagnosticRecorder recorder;

  DiagnosticRecorder build() => DiagnosticRecorder(
        settings: settings,
        loadFacts: () async => const SessionFacts(app: '0.2.7+207'),
        resolveDirectory: () async => dir,
      );

  List<Map<String, Object?>> records(String jsonl) => [
        for (final line in const LineSplitter().convert(jsonl).skip(1))
          jsonDecode(line) as Map<String, Object?>,
      ];

  /// One pass of the WorkManager isolate, as far as this process can imitate
  /// one: the app is not recording (that isolate has its own heap, where
  /// `active` is always null), the session id is in preferences, and the stream
  /// it opens is its own file.
  Future<void> runBackgroundPass(
    String session,
    void Function(dynamic store) write,
  ) async {
    expect(DiagnosticRecorder.isRecording, isFalse,
        reason: 'the background isolate never shares a heap with the UI');
    await settings.saveDiagnosticsSession(session);
    final recording = await DiagnosticRecorder.startBackground(
      settings: settings,
      stream: LogStream.worker,
      resolveDirectory: () async => dir,
      // The error probe swaps the global handlers; a test must not keep those.
      attachErrors: false,
    );
    expect(recording, isNotNull);
    write(recording!.store);
    await recording.stop();
    await settings.saveDiagnosticsSession(null);
  }

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

  test('the session is mirrored to disk as it is recorded', () async {
    await recorder.start();
    DiagnosticRecorder.active!.add(LogSource.ui, 'tap', fields: {'id': 'a.b'});
    await recorder.flushMirror();

    final file = dir.listSync().whereType<File>().single;
    expect(file.readAsStringSync(), contains('"evt":"tap"'));
  });

  test('a session that nobody stopped is recovered from its file', () async {
    await recorder.start();
    DiagnosticRecorder.active!.add(LogSource.ui, 'tap', fields: {'id': 'a.b'});
    await recorder.flushMirror();
    final session = settings.loadDiagnosticsSession()!;

    // The app dies: no `stop`, the flag still set. A fresh recorder — a fresh
    // process, as far as this class is concerned — picks the files up.
    final log = await build().recover(session);

    expect(records(log).map((r) => r['evt']), contains('tap'));
  });

  test('a session holding only its header is not worth offering', () async {
    await recorder.start();
    await recorder.flushMirror();
    final session = settings.loadDiagnosticsSession()!;
    // Strip everything the start wrote, leaving the header alone.
    final file = File('${dir.path}/session-$session.jsonl');
    final header = const LineSplitter().convert(file.readAsStringSync()).first;
    file.writeAsStringSync('$header\n');

    expect(await build().recover(session), isEmpty);
  });

  test('the background stream is folded in, stamped with its origin', () async {
    await recorder.start();
    final session = settings.loadDiagnosticsSession()!;
    DiagnosticRecorder.active!.add(LogSource.ui, 'tap', fields: {'id': 'a.b'});
    await recorder.stop();

    await runBackgroundPass(
      session,
      (store) => store.add(LogSource.notif, 'posted'),
    );

    final merged = records(await build().recover(session));
    final posted = merged.firstWhere((r) => r['evt'] == 'posted');
    expect(posted['iso'], 'worker');
    // The UI's own records stay unstamped, and both are on one timeline.
    expect(merged.firstWhere((r) => r['evt'] == 'tap')['iso'], isNull);
  });

  test('discarding takes both streams off the disk', () async {
    await recorder.start();
    final session = settings.loadDiagnosticsSession()!;
    DiagnosticRecorder.active!.add(LogSource.ui, 'tap');
    await recorder.stop();
    await runBackgroundPass(
      session,
      (store) => store.add(LogSource.notif, 'posted'),
    );
    expect(dir.listSync().length, 2);

    await recorder.discardSession(session);
    expect(dir.listSync(), isEmpty);
  });

  test('the background isolate refuses a session that is not there', () async {
    final recording = await DiagnosticRecorder.startBackground(
      settings: settings,
      stream: LogStream.worker,
      resolveDirectory: () async => dir,
      attachErrors: false,
    );
    expect(recording, isNull);
    expect(dir.listSync(), isEmpty);
  });

  test('a background stream with no UI header is never opened', () async {
    // The flag says a recording is on, but the file it points at is not there —
    // an orphan file with a clock of its own would be worse than nothing.
    await settings.saveDiagnosticsSession('deadbeef');
    final recording = await DiagnosticRecorder.startBackground(
      settings: settings,
      stream: LogStream.worker,
      resolveDirectory: () async => dir,
      attachErrors: false,
    );
    expect(recording, isNull);
    expect(dir.listSync(), isEmpty);
  });

  test('starting a recording sweeps what earlier ones left behind', () async {
    await recorder.start();
    await recorder.flushMirror();
    await recorder.stop();
    expect(dir.listSync(), isNotEmpty);

    await recorder.start();
    await recorder.flushMirror();
    final session = settings.loadDiagnosticsSession()!;
    for (final file in dir.listSync().whereType<File>()) {
      expect(file.path, contains(session));
    }
  });

  test('a device with no writable directory still records in memory', () async {
    final memoryOnly = DiagnosticRecorder(
      settings: settings,
      loadFacts: () async => const SessionFacts(app: '0.2.7+207'),
      resolveDirectory: () async => throw const FileSystemException('nope'),
    );
    await memoryOnly.start();
    DiagnosticRecorder.active!.add(LogSource.ui, 'tap');

    expect(
      records(await memoryOnly.stop()).map((r) => r['evt']),
      contains('tap'),
    );
  });
}

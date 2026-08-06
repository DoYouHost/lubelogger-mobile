import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/diagnostics/relay_client.dart';
import 'package:lubelogger_mobile/core/diagnostics/relay_pow.dart';
import 'package:lubelogger_mobile/core/diagnostics/report_envelope.dart';
import 'package:lubelogger_mobile/core/diagnostics/report_outbox.dart';
import 'package:lubelogger_mobile/core/diagnostics/report_sender.dart';
import 'package:lubelogger_mobile/core/diagnostics/session_facts.dart';

/// The relay, as far as these tests are concerned: a challenge with no proof of
/// work to solve, and whatever answer to `/report` the test asks for.
class _FakeRelay implements HttpClientAdapter {
  _FakeRelay({this.notBefore = Duration.zero});

  final Duration notBefore;

  /// Long enough that no test has to think about a ticket going stale.
  static const expiresIn = Duration(minutes: 10);

  int reportStatus = 201;

  final List<Map<String, Object?>> reports = [];
  int challenges = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final now = DateTime.now();
    if (options.uri.path.endsWith('/challenge')) {
      challenges++;
      return _json({
        'ticket': 'signed-$challenges',
        'nbf': now.add(notBefore).millisecondsSinceEpoch,
        'exp': now.add(expiresIn).millisecondsSinceEpoch,
        'seed': 'seed',
        // Zero bits: the proof of work is not what these tests are about, and
        // a real one would need an isolate.
        'bits': 0,
      });
    }
    reports.add((options.data as Map).cast<String, Object?>());
    return _json(
      {'url': 'https://example.invalid/issues/1'},
      status: reportStatus,
    );
  }

  static ResponseBody _json(Object? body, {int status = 200}) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

const _log = '{"v":1,"ts":"2026-08-06T12:00:00.000Z","session":"abc",'
    '"stream":"ui","app":"0.2.7+207","scheme":"https"}\n'
    '{"t":0,"src":"app","evt":"recording_started"}\n';

void main() {
  late Directory dir;
  late _FakeRelay relay;
  late ReportOutbox outbox;

  ReportSender build({bool demo = false}) => ReportSender(
        client: RelayClient(
          Dio()..httpClientAdapter = relay,
          baseUrl: 'https://relay.invalid',
        ),
        outbox: outbox,
        installId: () async => 'install-1',
        demoMode: () => demo,
      );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('lubelogger-outbox');
    relay = _FakeRelay();
    outbox = ReportOutbox(root: dir);
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('a ready ticket sends the report and yields the issue URL', () async {
    final sender = build();
    final states = <SendState>[];
    sender.states.listen(states.add);

    await sender.prepare();
    await sender.submit(description: 'the garage stays empty', log: _log);
    await Future<void>.delayed(Duration.zero);

    expect(states.last.phase, SendPhase.sent);
    expect(states.last.issueUrl, 'https://example.invalid/issues/1');
    // Nothing left queued once the issue exists.
    expect(await outbox.peek(), isNull);
    sender.dispose();
  });

  test('the envelope is read off the log, and the log goes gzipped', () async {
    final sender = build();
    await sender.prepare();
    await sender.submit(description: 'what went wrong', log: _log);

    final report = relay.reports.single;
    expect(report['installId'], 'install-1');
    expect(report['description'], 'what went wrong');
    expect(report['logSchema'], 1);
    expect((report['header']! as Map)['app'], '0.2.7+207');

    final sent = utf8.decode(
      gzip.decode(base64Decode(report['logGz']! as String)),
    );
    expect(sent, _log);
    sender.dispose();
  });

  test('a bug says so on the wire, so the relay can tell them apart', () async {
    final sender = build();
    await sender.prepare();
    await sender.submit(description: 'the garage stays empty', log: _log);

    expect(relay.reports.single['kind'], 'bug');
    sender.dispose();
  });

  group('change and feature requests', () {
    test('a request goes out with no log at all', () async {
      final sender = build();
      await sender.prepare();
      await sender.submitRequest(
        kind: ReportKind.feature,
        description: 'let me sort the fuel table by cost',
        envelope: requestEnvelope(
          const SessionFacts(app: '0.2.8+208', server: '1.4.9', locale: 'pl'),
        ),
      );

      final report = relay.reports.single;
      expect(report['kind'], 'feature');
      expect(report['description'], 'let me sort the fuel table by cost');
      // Absent, not empty: the relay has to be able to tell a request from a
      // bug report whose recording came out blank.
      expect(report.containsKey('logGz'), isFalse);
      expect(report.containsKey('logSchema'), isFalse);
      sender.dispose();
    });

    test('the header holds the versions and nothing about the phone', () async {
      final sender = build();
      await sender.prepare();
      await sender.submitRequest(
        kind: ReportKind.change,
        description: 'the date picker should open on the last date used',
        envelope: requestEnvelope(
          const SessionFacts(
            app: '0.2.8+208',
            server: '1.4.9',
            locale: 'pl',
            os: 'Android 15',
            environment: {'device': 'Xiaomi 2201123G', 'tz': '+02:00'},
          ),
        ),
      );

      final header = (relay.reports.single['header']! as Map)
          .cast<String, Object?>();
      expect(header['app'], '0.2.8+208');
      expect(header['server'], '1.4.9');
      expect(header['locale'], 'pl');
      // An idea is answered by reading it; whose phone it came from is not part
      // of the answer, so it does not go into a public issue.
      expect(header.keys, isNot(contains('device')));
      expect(header.keys, isNot(contains('tz')));
      expect(header.keys, isNot(contains('os')));
      sender.dispose();
    });

    test('a queued request survives the app without growing a log', () async {
      relay = _FakeRelay(notBefore: const Duration(minutes: 5));
      final sender = build();
      await sender.prepare();
      await sender.submitRequest(
        kind: ReportKind.change,
        description: 'remember the last vehicle',
        envelope: requestEnvelope(const SessionFacts(app: '0.2.8+208')),
      );

      final queued = await outbox.peek();
      expect(queued, isNotNull);
      expect(queued!.kind, ReportKind.change);
      expect(queued.hasLog, isFalse);
      // The missing log must not read as a log that went missing.
      expect(queued.logPath, isNull);
      sender.dispose();
    });
  });

  test('a ticket that is not due yet queues the report to disk', () async {
    relay = _FakeRelay(notBefore: const Duration(minutes: 5));
    final sender = build();
    final states = <SendState>[];
    sender.states.listen(states.add);

    await sender.prepare();
    await sender.submit(description: 'later then', log: _log);
    await Future<void>.delayed(Duration.zero);

    expect(states.last.phase, SendPhase.waiting);
    expect(relay.reports, isEmpty);
    // On disk, so closing the app does not lose it.
    final pending = await outbox.peek();
    expect(pending, isNotNull);
    expect(await outbox.readLog(pending!), _log);
    sender.dispose();
  });

  test('a dead end drops the report instead of retrying forever', () async {
    relay.reportStatus = 409; // already reported
    final sender = build();
    final states = <SendState>[];
    sender.states.listen(states.add);

    await sender.prepare();
    await sender.submit(description: 'again', log: _log);
    await Future<void>.delayed(Duration.zero);

    expect(states.last.phase, SendPhase.failed);
    expect(states.last.failure, RelayFailure.duplicate);
    expect(await outbox.peek(), isNull);
    sender.dispose();
  });

  test('demo mode never calls out and never queues anything', () async {
    final sender = build(demo: true);
    final states = <SendState>[];
    sender.states.listen(states.add);

    await sender.prepare();
    await sender.submit(description: 'from the store demo', log: _log);
    await Future<void>.delayed(Duration.zero);

    expect(relay.challenges, 0);
    expect(relay.reports, isEmpty);
    expect(states.last.failure, RelayFailure.demo);
    expect(await outbox.peek(), isNull);
    sender.dispose();
  });

  test('a ticket already in hand is not paid for twice', () async {
    final sender = build();
    await sender.prepare();
    await sender.prepare();
    expect(relay.challenges, 1);
    sender.dispose();
  });

  test('cancelling a queued report takes it off the disk', () async {
    relay = _FakeRelay(notBefore: const Duration(minutes: 5));
    final sender = build();

    await sender.prepare();
    await sender.submit(description: 'never mind', log: _log);
    expect(await outbox.peek(), isNotNull);

    await sender.cancel();
    expect(await outbox.peek(), isNull);
    sender.dispose();
  });

  test('a slot pointing at a log that is gone clears itself', () async {
    final ticket = RelayTicket(
      ticket: 'signed',
      notBefore: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      challenge: const PowChallenge(seed: 'seed', bits: 0),
    );
    final pending = await outbox.put(
      id: 'x',
      kind: ReportKind.bug,
      description: 'd',
      header: const {'app': '0.2.7+207'},
      logSchema: 1,
      ticket: ticket,
      log: _log,
    );
    File(pending.logPath!).deleteSync();

    expect(await outbox.peek(), isNull);
  });
}

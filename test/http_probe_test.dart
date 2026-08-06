import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/api/api_client.dart';
import 'package:lubelogger_mobile/core/diagnostics/diagnostic_recorder.dart';
import 'package:lubelogger_mobile/core/diagnostics/log_event.dart';
import 'package:lubelogger_mobile/core/diagnostics/session_facts.dart';
import 'package:lubelogger_mobile/core/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers every request from a canned table, so the probe sees a real dio
/// round trip without a server.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.answer);

  final ResponseBody Function(RequestOptions options) answer;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      answer(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? body, {int status = 200}) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DiagnosticRecorder recorder;
  late Dio dio;

  Future<List<Map<String, Object?>>> stopAndRead() async {
    final jsonl = await recorder.stop();
    return [
      for (final line in const LineSplitter().convert(jsonl).skip(1))
        jsonDecode(line) as Map<String, Object?>,
    ];
  }

  /// Only the records the HTTP probe wrote — the session also carries its own
  /// start and stop markers.
  List<Map<String, Object?>> httpOnly(List<Map<String, Object?>> records) =>
      [for (final r in records) if (r['src'] == 'http') r];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    recorder = DiagnosticRecorder(
      settings: SettingsRepository(prefs),
      loadFacts: () async => const SessionFacts(app: '0.2.7+207'),
      // In memory only: nothing here is testing the durable mirror.
      resolveDirectory: () async => null,
    );
    dio = createBareDio()..options.baseUrl = 'https://lube.example.com';
  });

  tearDown(() async {
    if (DiagnosticRecorder.isRecording) await recorder.stop();
  });

  test('nothing is recorded while no session is running', () async {
    dio.httpClientAdapter = _FakeAdapter((_) => _json([]));
    await dio.get<dynamic>('/api/vehicles');
    expect(DiagnosticRecorder.active, isNull);
  });

  test('a response records method, path, status, count and vehicle', () async {
    dio.httpClientAdapter = _FakeAdapter((_) => _json([
          {'id': 1, 'date': '2026-08-01', 'odometer': '1000'},
          {'id': 2, 'date': '2026-08-02', 'odometer': '1100'},
        ]));
    await recorder.start();
    await dio.get<dynamic>(
      '/api/vehicle/gasrecords',
      queryParameters: {'vehicleId': 7},
    );

    final record = httpOnly(await stopAndRead()).single;
    expect(record['evt'], 'response');
    expect(record['method'], 'GET');
    expect(record['path'], '/api/vehicle/gasrecords');
    expect(record['status'], 200);
    expect(record['n'], 2);
    expect(record['vid'], 7);
  });

  test('the sampled record keeps its shape and drops the user text', () async {
    dio.httpClientAdapter = _FakeAdapter((_) => _json([
          {
            'id': 4,
            'licensePlate': 'WX 1234A',
            'year': '2016',
            'notes': 'bought from a friend',
          },
        ]));
    await recorder.start();
    await dio.get<dynamic>('/api/vehicles');

    final first = httpOnly(await stopAndRead()).single['first'] as Map;
    expect(first['id'], 4);
    expect(first['year'], '2016');
    expect(first['licensePlate'], '<str:8>');
    expect(first['notes'], '<str:20>');
  });

  test('an unchanged answer degrades to `same`', () async {
    dio.httpClientAdapter = _FakeAdapter((_) => _json([
          {'id': 1, 'date': '2026-08-01'},
        ]));
    await recorder.start();
    await dio.get<dynamic>('/api/vehicles');
    await dio.get<dynamic>('/api/vehicles');

    final records = httpOnly(await stopAndRead());
    expect(records.first.containsKey('first'), isTrue);
    expect(records.last['same'], true);
    expect(records.last.containsKey('first'), isFalse);
  });

  test('two vehicles dedupe against themselves, not each other', () async {
    dio.httpClientAdapter = _FakeAdapter(
      (options) => _json([
        {'id': 1, 'vehicleId': options.uri.queryParameters['vehicleId']},
      ]),
    );
    await recorder.start();
    await dio.get<dynamic>(
      '/api/vehicle/reminders',
      queryParameters: {'vehicleId': 1},
    );
    await dio.get<dynamic>(
      '/api/vehicle/reminders',
      queryParameters: {'vehicleId': 2},
    );

    final records = httpOnly(await stopAndRead());
    expect(records.every((r) => r.containsKey('first')), isTrue);
  });

  test('an endpoint that answers with a person is never sampled', () async {
    dio.httpClientAdapter = _FakeAdapter(
      (_) => _json({'userName': 'anna', 'emailAddress': 'anna@example.com'}),
    );
    await recorder.start();
    await dio.get<dynamic>('/api/whoami');

    final record = httpOnly(await stopAndRead()).single;
    expect(record.containsKey('first'), isFalse);
  });

  test('a write is recorded on its way out, with the shape it sent', () async {
    dio.httpClientAdapter = _FakeAdapter((_) => _json({'ok': true}));
    await recorder.start();
    await dio.post<dynamic>(
      '/api/vehicle/gasrecords/add',
      queryParameters: {'vehicleId': 3},
      data: {
        'date': '01/15/2024',
        'odometer': '148230',
        'isFillToFull': 'True',
        'notes': 'private',
      },
    );

    final records = httpOnly(await stopAndRead());
    final request = records.first;
    expect(request['evt'], 'request');
    expect(request['lvl'], 'debug');
    expect(request['method'], 'POST');
    expect(request['vid'], 3);
    // What the app formatted is the thing under suspicion, so it is kept…
    expect(request['body'], {
      'date': '01/15/2024',
      'odometer': '148230',
      'isFillToFull': 'True',
      // …and what the user typed is not.
      'notes': '<str:7>',
    });
  });

  test('a delete names the record it is deleting', () async {
    dio.httpClientAdapter = _FakeAdapter((_) => _json({'ok': true}));
    await recorder.start();
    await dio.delete<dynamic>(
      '/api/vehicle/gasrecords/delete',
      queryParameters: {'id': 91},
    );

    expect(httpOnly(await stopAndRead()).first['rid'], 91);
  });

  test('an upload is described, never sampled', () async {
    dio.httpClientAdapter = _FakeAdapter((_) => _json([]));
    await recorder.start();
    final form = FormData();
    form.files.add(
      MapEntry(
        'documents',
        MultipartFile.fromBytes([1, 2, 3, 4], filename: 'Anna receipt.PDF'),
      ),
    );
    await dio.post<dynamic>('/api/documents/upload', data: form);

    final body = httpOnly(await stopAndRead()).first['body'] as Map;
    expect(body['fields'], isNull);
    expect(body['files'], 1);
    expect(body['bytes'], 4);
    expect(body['exts'], ['pdf']);
    expect(body.toString(), isNot(contains('Anna')));
  });

  test('a 200 with an empty body on a read is called out', () async {
    dio.httpClientAdapter = _FakeAdapter(
      (_) => ResponseBody.fromString('', 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      }),
    );
    await recorder.start();
    await dio.get<dynamic>('/api/vehicles');

    expect(httpOnly(await stopAndRead()).single['empty'], true);
  });

  test('a failure records the type, the status and a body preview', () async {
    dio.httpClientAdapter =
        _FakeAdapter((_) => _json({'message': 'no scope'}, status: 401));
    await recorder.start();
    await expectLater(
      dio.get<dynamic>('/api/vehicles'),
      throwsA(isA<DioException>()),
    );

    final record = httpOnly(await stopAndRead()).single;
    expect(record['evt'], 'error');
    expect(record['lvl'], 'warn');
    expect(record['status'], 401);
    expect(record['type'], 'badResponse');
    expect(record['body'], contains('no scope'));
  });

  test('no response at all is an error, not a warning', () async {
    dio.httpClientAdapter = _FakeAdapter(
      (options) => throw DioException.connectionError(
        requestOptions: options,
        reason: 'nothing listening',
      ),
    );
    await recorder.start();
    await expectLater(
      dio.get<dynamic>('/api/vehicles'),
      throwsA(isA<DioException>()),
    );

    final record = httpOnly(await stopAndRead()).single;
    expect(record['lvl'], 'error');
    expect(record['status'], isNull);
    expect(record['msg'], contains('nothing listening'));
  });

  test('the API key never reaches a record', () async {
    dio.httpClientAdapter = _FakeAdapter(
      (_) => _json({'detail': 'key sekretny-klucz-123 rejected'}, status: 403),
    );
    await recorder.start();
    DiagnosticRecorder.active!.redactor
        .remember('sekretny-klucz-123', '[APIKEY]');
    await expectLater(
      dio.get<dynamic>('/api/vehicles'),
      throwsA(isA<DioException>()),
    );

    final record = httpOnly(await stopAndRead()).single;
    expect(record['body'], contains('[APIKEY]'));
    expect(record.toString(), isNot(contains('sekretny-klucz-123')));
  });

  test('the host never reaches a record', () async {
    dio.httpClientAdapter = _FakeAdapter((_) => _json([]));
    await recorder.start();
    await dio.get<dynamic>('/api/vehicles');

    final record = httpOnly(await stopAndRead()).single;
    expect(record['path'], '/api/vehicles');
    expect(record.toString(), isNot(contains('lube.example.com')));
  });

  test('a session starts with a clean set of fingerprints', () async {
    dio.httpClientAdapter = _FakeAdapter((_) => _json([
          {'id': 1, 'date': '2026-08-01'},
        ]));
    await recorder.start();
    await dio.get<dynamic>('/api/vehicles');
    await recorder.stop();

    await recorder.start();
    await dio.get<dynamic>('/api/vehicles');
    expect(httpOnly(await stopAndRead()).single.containsKey('first'), isTrue);
  });

  test('the session header carries the server fingerprint, not the URL',
      () async {
    final fingerprinted = DiagnosticRecorder(
      settings: SettingsRepository(await SharedPreferences.getInstance()),
      loadFacts: () async => SessionFacts(
        app: '0.2.7+207',
        serverUrl: ServerFingerprint.tryParse('https://lube.example.com:8443'),
      ),
      resolveDirectory: () async => null,
    );
    await fingerprinted.start();
    final header = jsonDecode(
      const LineSplitter().convert(await fingerprinted.stop()).first,
    ) as Map<String, Object?>;

    expect(header['scheme'], 'https');
    expect(header['host_kind'], 'name');
    expect(header['port'], 8443);
    expect(header.toString(), isNot(contains('lube.example.com')));
  });
}

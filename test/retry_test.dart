import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/api/retry_interceptor.dart';
import 'package:lubelogger_mobile/core/cache/http_cache.dart';
import 'package:lubelogger_mobile/core/cache/offline_interceptor.dart';
import 'package:lubelogger_mobile/core/cache/write_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays a scripted sequence of outcomes, one per attempt, and counts how many
/// times it was asked.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.outcomes);

  /// Each entry is either an `int` status code or a [DioExceptionType] to throw.
  final List<Object> outcomes;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final outcome = outcomes[calls.clamp(0, outcomes.length - 1)];
    calls++;
    if (outcome is DioExceptionType) {
      throw DioException(requestOptions: options, type: outcome);
    }
    return ResponseBody.fromString(
      jsonEncode({'ok': calls}),
      outcome as int,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({Dio dio, _ScriptedAdapter adapter, List<Duration> slept}) _client(
  List<Object> outcomes, {
  OfflineStatus? status,
  int maxAttempts = kDefaultMaxAttempts,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  final adapter = _ScriptedAdapter(outcomes);
  final slept = <Duration>[];
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(RetryInterceptor(
    dio: dio,
    status: status,
    maxAttempts: maxAttempts,
    // Deterministic and instant: the delay is asserted, never waited through.
    sleep: (d) async => slept.add(d),
  ));
  return (dio: dio, adapter: adapter, slept: slept);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('retries', () {
    test('a dropped connection is tried again and succeeds', () async {
      final (:dio, :adapter, slept: _) =
          _client([DioExceptionType.connectionError, 200]);

      final res = await dio.get<Map<String, dynamic>>('/api/vehicles');

      expect(res.statusCode, 200);
      expect(adapter.calls, 2);
    });

    test('a 5xx is tried again — LubeLogger may be restarting', () async {
      final (:dio, :adapter, slept: _) = _client([502, 200]);

      await expectLater(dio.get<dynamic>('/api/vehicles'), completes);
      expect(adapter.calls, 2);
    });

    test('attempts stop at the cap and the failure surfaces', () async {
      final (:dio, :adapter, :slept) =
          _client([DioExceptionType.connectionError]);

      await expectLater(dio.get<dynamic>('/api/vehicles'), throwsA(
        isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.connectionError),
      ));
      expect(adapter.calls, kDefaultMaxAttempts);
      expect(slept, hasLength(kDefaultMaxAttempts - 1));
    });

    test('each wait is longer than the last, and none is zero', () async {
      final (:dio, adapter: _, :slept) = _client(
        [DioExceptionType.connectionError],
        maxAttempts: 4,
      );

      await expectLater(dio.get<dynamic>('/api/vehicles'), throwsA(anything));

      expect(slept, hasLength(3));
      // Jitter spreads each step over its lower half, so the bands cannot
      // overlap and the order holds on every run.
      expect(slept[0], greaterThan(Duration.zero));
      expect(slept[1], greaterThan(slept[0]));
      expect(slept[2], greaterThan(slept[1]));
      expect(slept.last, lessThan(kDefaultRetryDelay * 9));
    });
  });

  group('does not retry', () {
    test('a refusal the server meant — 400, 401, 404', () async {
      for (final status in [400, 401, 404]) {
        final (:dio, :adapter, slept: _) = _client([status]);

        await expectLater(
          dio.get<dynamic>('/api/vehicles'),
          throwsA(isA<DioException>()),
        );
        expect(adapter.calls, 1, reason: 'HTTP $status');
      }
    });

    test('a timeout — it already spent the whole budget', () async {
      // The point of the exclusion: three receive timeouts would turn a 15s
      // failure into a 45s one, and the stale copy the user could have had
      // arrives three times later.
      final (:dio, :adapter, slept: _) =
          _client([DioExceptionType.receiveTimeout]);

      await expectLater(
        dio.get<dynamic>('/api/vehicles'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 1);
    });

    test('a write — re-sending an add can create the record twice', () async {
      final (:dio, :adapter, slept: _) =
          _client([DioExceptionType.connectionError]);

      await expectLater(
        dio.post<dynamic>('/api/vehicle/gasrecords/add', data: {'cost': '1'}),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 1);
    });

    test('anything, once the server is known to be down', () async {
      // The offline banner is already up; retrying only makes every screen
      // slower to fall back to its stored copy.
      final status = OfflineStatus()..unreachable();
      final (:dio, :adapter, slept: _) =
          _client([DioExceptionType.connectionError], status: status);

      await expectLater(
        dio.get<dynamic>('/api/vehicles'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 1);
    });
  });

  // The order of the two interceptors is the whole point: retrying *after* the
  // offline fallback would never run, because the fallback answers the error
  // with the stored copy and the request succeeds.
  group('ahead of the offline fallback', () {
    late Directory root;
    late WriteQueue queue;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('lubelogger_retry_test');
      SharedPreferences.setMockInitialValues({});
      queue = WriteQueue(await SharedPreferences.getInstance());
    });

    tearDown(() async {
      if (root.existsSync()) await root.delete(recursive: true);
    });

    ({Dio dio, OfflineStatus status, HttpCache cache}) chain(
      List<Object> outcomes,
    ) {
      final cache = HttpCache(
        baseUrl: 'https://example.test',
        supportDirectory: () async => root,
      );
      final status = OfflineStatus();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = _ScriptedAdapter(outcomes);
      dio.interceptors
        ..add(RetryInterceptor(dio: dio, status: status, sleep: (_) async {}))
        ..add(OfflineInterceptor(cache: cache, queue: queue, status: status));
      return (dio: dio, status: status, cache: cache);
    }

    test('a blip is retried, not turned into "you are offline"', () async {
      final (:dio, :status, :cache) =
          chain([DioExceptionType.connectionError, 200]);
      await cache.write(
        HttpCache.keyFor(method: 'GET', path: '/api/vehicles', query: const {}),
        {'ok': 'stale'},
      );

      final res = await dio.get<Map<String, dynamic>>('/api/vehicles');

      expect(res.data, {'ok': 2}, reason: 'the fresh body, not the stored one');
      expect(status.offline, isFalse, reason: 'no banner for one lost packet');
    });

    test('a real outage still falls back once the attempts are spent',
        () async {
      final (:dio, :status, :cache) = chain([DioExceptionType.connectionError]);
      await cache.write(
        HttpCache.keyFor(method: 'GET', path: '/api/vehicles', query: const {}),
        {'ok': 'stale'},
      );

      final res = await dio.get<Map<String, dynamic>>('/api/vehicles');

      expect(res.data, {'ok': 'stale'});
      expect(status.offline, isTrue);
    });
  });
}

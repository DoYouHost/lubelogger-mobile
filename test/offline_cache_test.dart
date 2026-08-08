import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/api/api_exceptions.dart';
import 'package:lubelogger_mobile/core/cache/http_cache.dart';
import 'package:lubelogger_mobile/core/cache/offline_interceptor.dart';
import 'package:lubelogger_mobile/core/cache/sync_service.dart';
import 'package:lubelogger_mobile/core/cache/write_queue.dart';
import 'package:lubelogger_mobile/data/vehicles_repository.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A server that can be switched off, so "the network is gone" is a line of the
/// test rather than a mock of every failure mode.
class _Server implements HttpClientAdapter {
  bool up = true;
  int status = 200;
  Object body = const <Object>[];

  /// Every request that actually left, newest last.
  final List<RequestOptions> calls = [];

  int get requests => calls.length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    if (!up) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'test: server is off',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late _Server server;
  late WriteQueue queue;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('lubelogger_cache_test');
    server = _Server();
    SharedPreferences.setMockInitialValues({});
    queue = WriteQueue(await SharedPreferences.getInstance());
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  HttpCache cacheFor([String baseUrl = 'https://one.example']) =>
      HttpCache(baseUrl: baseUrl, supportDirectory: () async => root);

  ({Dio dio, VehiclesRepository repo}) client({HttpCache? cache}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://one.example'))
      ..httpClientAdapter = server
      ..interceptors.add(OfflineInterceptor(
        cache: cache ?? cacheFor(),
        queue: queue,
        status: OfflineStatus(),
      ));
    return (dio: dio, repo: VehiclesRepository(dio));
  }

  const oneVehicle = [
    {
      'vehicleData': {'id': 1, 'year': 2019, 'make': 'Toyota', 'model': 'Yaris'},
      'lastReportedOdometer': 1000,
    },
  ];

  group('the stored copy', () {
    test('survives a round trip and reports whether it changed', () async {
      final cache = cacheFor();
      const key = 'GET /api/vehicles';

      expect(await cache.write(key, [1, 2]), isTrue, reason: 'first write');
      expect((await cache.read(key))?.body, [1, 2]);
      expect(await cache.write(key, [1, 2]), isFalse, reason: 'same body');
      expect(await cache.write(key, [1, 3]), isTrue, reason: 'different body');
    });

    test('is keyed per server, so two households never mix', () async {
      await cacheFor('https://one.example').write('GET /api/vehicles', [1]);
      expect(
        await cacheFor('https://two.example').read('GET /api/vehicles'),
        isNull,
      );
    });

    test('sorts the query, so parameter order is not a second entry', () {
      expect(
        HttpCache.keyFor(
          method: 'get',
          path: '/api/x',
          query: {'b': 2, 'a': 1},
        ),
        HttpCache.keyFor(
          method: 'GET',
          path: '/api/x',
          query: {'a': 1, 'b': 2},
        ),
      );
    });
  });

  group('reading without a server', () {
    test('answers from the last stored copy', () async {
      server.body = oneVehicle;
      final c = client();
      expect((await c.repo.allInfo()).single.vehicle.id, 1);

      server.up = false;
      final offline = await c.repo.allInfo();
      expect(offline.single.vehicle.id, 1);
      expect(offline.single.lastReportedOdometer, 1000);
    });

    test('still fails when there is nothing stored', () async {
      server.up = false;
      await expectLater(client().repo.allInfo(), throwsA(isA<NetworkException>()));
    });

    test('a refusal is an answer, not an outage — no stale copy for it',
        () async {
      server.body = oneVehicle;
      final c = client();
      await c.repo.allInfo();

      // 401 means the key lost its scope. Serving yesterday's records instead
      // would hide that completely.
      server.status = 401;
      server.body = {'success': false};
      await expectLater(c.repo.allInfo(), throwsA(isA<AuthException>()));
    });

    test('cache-first answers without asking at all', () async {
      server.body = oneVehicle;
      final c = client();
      await c.repo.allInfo();
      expect(server.requests, 1);

      final probe = CacheProbe();
      await c.repo.withCache(probe, cacheFirst: true).allInfo();
      expect(server.requests, 1, reason: 'answered off the disk');
      expect(probe.servedFromCache, isTrue);
      expect(probe.shouldRevalidate, isTrue);
    });

    test('a write the server took outranks every stored copy', () async {
      server.body = oneVehicle;
      final c = client();
      await c.repo.allInfo();

      // The list a form returns to must not be the one from before the save.
      server.body = {'success': true, 'message': ''};
      await c.repo.deleteGasRecord(7);

      server.body = oneVehicle;
      final probe = CacheProbe();
      await c.repo.withCache(probe, cacheFirst: true).allInfo();
      expect(probe.servedFromCache, isFalse);

      // And once asked, the answer is trusted again.
      final after = CacheProbe();
      await c.repo.withCache(after, cacheFirst: true).allInfo();
      expect(after.servedFromCache, isTrue);
    });

    test('a revalidation that changed the data stops the next one looping',
        () async {
      server.body = oneVehicle;
      final c = client();
      await c.repo.allInfo();

      // The refresh a cache-first read triggers, finding something new.
      server.body = [
        {...oneVehicle.first, 'lastReportedOdometer': 2000},
      ];
      final refresh = CacheProbe();
      await c.repo.withCache(refresh, revalidate: true).allInfo();
      expect(refresh.changed, isTrue);

      // The re-read that change causes must not ask for a refresh of its own,
      // or the two would trade places forever.
      final reread = CacheProbe();
      await c.repo.withCache(reread, cacheFirst: true).allInfo();
      expect(reread.servedFromCache, isTrue);
      expect(reread.shouldRevalidate, isFalse);
    });
  });

  group('opening the app with a stored copy', () {
    /// The refresh behind a cache-first answer is deliberately unawaited, and
    /// it reads and writes a file on either side of the wire — so the test
    /// waits for what it expects rather than for a number of event-loop turns.
    Future<void> until(bool Function() done) async {
      for (var i = 0; i < 500 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    }

    /// Long enough for one more refresh to have happened, had there been one.
    Future<void> settle() async {
      for (var i = 0; i < 50; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    }

    ProviderContainer containerOn(VehiclesRepository repo) {
      final c = ProviderContainer(
        overrides: [vehiclesRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('shows records with the server unreachable', () async {
      server.body = oneVehicle;
      final c = client();
      await c.repo.allInfo(); // an earlier session

      server.up = false;
      final garage = await containerOn(c.repo).read(garageProvider.future);
      expect(garage.single.vehicle.id, 1);
    });

    test('answers off the disk, then refreshes and rebuilds only on a change',
        () async {
      server.body = oneVehicle;
      final c = client();
      await c.repo.allInfo();
      server.calls.clear();

      final container = containerOn(c.repo);
      // Settled values only: an invalidated provider also emits a loading state
      // still carrying the old records, which is not the screen changing.
      final seen = <double>[];
      container.listen(
        garageProvider,
        (_, next) {
          if (next.isLoading || !next.hasValue) return;
          seen.add(next.requireValue.single.lastReportedOdometer);
        },
        fireImmediately: true,
      );

      // Nothing new on the server: the refresh happens and the screen is left
      // exactly where it was.
      expect(
        (await container.read(garageProvider.future)).single.lastReportedOdometer,
        1000,
      );
      await until(() => server.requests == 1);
      await settle();
      expect(seen, [1000], reason: 'an unchanged refresh must not rebuild');

      // Now the server has something to say. The stored answer arrives first
      // and the new one replaces it.
      server.body = [
        {...oneVehicle.first, 'lastReportedOdometer': 2000},
      ];
      container.invalidate(garageProvider);
      expect(
        (await container.read(garageProvider.future)).single.lastReportedOdometer,
        1000,
        reason: 'the disk answers before the server does',
      );
      await until(() => seen.length >= 3);
      await settle();

      expect(seen, [1000, 1000, 2000]);
      expect(
        server.requests,
        2,
        reason: 'one refresh per read — the re-read came off the disk',
      );
    });
  });

  group('writing without a server', () {
    Future<void> addFuel(VehiclesRepository repo, double odometer) =>
        repo.addGasRecord(
          vehicleId: 1,
          date: DateTime(2026, 3, 1),
          odometer: odometer,
          fuelConsumed: 40,
          cost: 250,
          isFillToFull: true,
          missedFuelUp: false,
        );

    test('is queued, and the form is told it was saved', () async {
      server.up = false;
      final c = client();

      // No throw: the record exists as far as the user is concerned; what is
      // pending is its delivery.
      await addFuel(c.repo, 1000);
      expect(queue.pending.single.path, '/api/vehicle/gasrecords/add');
      expect(queue.pending.single.query['vehicleId'], 1);
    });

    test('is delivered in order once the server is back', () async {
      server.up = false;
      final c = client();
      await addFuel(c.repo, 1000);
      await addFuel(c.repo, 2000);
      expect(queue.pending.length, 2);

      server.up = true;
      server.body = {'success': true, 'message': ''};
      server.calls.clear(); // the two refused attempts are not the delivery
      final outcome = await SyncService(
        dio: c.dio,
        queue: queue,
        repository: c.repo,
      ).drain();

      expect(outcome.delivered, 2);
      expect(queue.pending, isEmpty);
      expect(
        [for (final r in server.calls) (r.data as Map)['odometer']],
        ['1000.0', '2000.0'],
        reason: 'an edit that follows an add is meaningless if it lands first',
      );
    });

    test('one the server refuses is set aside, not retried forever', () async {
      server.up = false;
      final c = client();
      await addFuel(c.repo, 1000);

      server.up = true;
      server.body = {'success': false, 'message': 'Input object invalid'};
      final outcome = await SyncService(
        dio: c.dio,
        queue: queue,
        repository: c.repo,
      ).drain();

      expect(outcome.delivered, 0);
      expect(outcome.refused, 1);
      expect(queue.pending, isEmpty);
      expect(queue.rejected.single.lastError, 'Input object invalid');
    });

    test('the queue keeps holding when the server is still away', () async {
      server.up = false;
      final c = client();
      await addFuel(c.repo, 1000);

      final outcome = await SyncService(
        dio: c.dio,
        queue: queue,
        repository: c.repo,
      ).drain();

      expect(outcome.stopped, isTrue);
      expect(outcome.remaining, 1);
      expect(queue.pending.single.attempts, 1);
    });

    test('an attachment upload is never queued', () async {
      server.up = false;
      final c = client();
      final file = File('${root.path}/note.txt')..writeAsStringSync('hello');

      await expectLater(
        c.repo.uploadDocuments([(path: file.path, name: 'note.txt')]),
        throwsA(isA<NetworkException>()),
        reason: 'a queue that outlives the process cannot promise the file',
      );
      expect(queue.pending, isEmpty);
    });
  });
}

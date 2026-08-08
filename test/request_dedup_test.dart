import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/demo/demo_http_adapter.dart';
import 'package:lubelogger_mobile/core/models/vehicle_record.dart';
import 'package:lubelogger_mobile/data/vehicles_repository.dart';
import 'package:lubelogger_mobile/providers.dart';

/// Guards the request count behind the two screens that fan out the most. Every
/// screen here works either way — a duplicate fetch shows the same numbers — so
/// nothing but a count catches a provider that goes back to fetching its own
/// copy of a list another provider already has.
void main() {
  late List<String> paths;

  /// Records the path of every request that reaches the wire, then lets the
  /// demo backend answer it.
  VehiclesRepository countingRepo() {
    final dio = Dio(BaseOptions(baseUrl: 'http://demo'))
      ..httpClientAdapter = DemoHttpClientAdapter(latency: Duration.zero)
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            paths.add(options.path);
            handler.next(options);
          },
        ),
      );
    return VehiclesRepository(dio);
  }

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [vehiclesRepositoryProvider.overrideWithValue(countingRepo())],
    );
    addTearDown(c.dispose);
    return c;
  }

  int count(String path) => paths.where((p) => p == path).length;

  setUp(() => paths = []);

  test('the garage loads in one request, whatever its size', () async {
    final c = container();
    final garage = await c.read(garageProvider.future);

    expect(garage.length, greaterThan(1));
    expect(paths, ['/api/vehicle/info']);
  });

  test('the fuel tab, its statistics and the expense chart share one log',
      () async {
    final c = container();
    await Future.wait([
      c.read(gasRecordsProvider(1).future),
      c.read(gasStatsProvider(1).future),
      c.read(monthlyBreakdownProvider(1).future),
      c.read(lastOdometerDateProvider(1).future),
    ]);

    expect(count('/api/vehicle/gasrecords'), 1);
    expect(count('/api/vehicle/odometerrecords'), 1);
    expect(count('/api/vehicle/info'), 1);
  });

  test('the expense chart reads the same records the tabs list', () async {
    final c = container();
    await Future.wait([
      c.read(monthlyBreakdownProvider(1).future),
      for (final kind in RecordKind.values)
        c.read(vehicleRecordsProvider((vehicleId: 1, kind: kind)).future),
    ]);

    for (final kind in RecordKind.values) {
      expect(count(kind.endpoint), 1, reason: kind.name);
    }
  });

  test('refreshing a record list refetches it and recomputes what derives',
      () async {
    final c = container();
    final before = await c.read(gasStatsProvider(1).future);
    c.invalidate(gasRecordsProvider(1));
    final after = await c.read(gasStatsProvider(1).future);

    expect(count('/api/vehicle/gasrecords'), 2);
    expect(after.totalRawDistance, before.totalRawDistance);
  });
}

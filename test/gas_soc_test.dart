import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/models/gas_record.dart';
import 'package:lubelogger_mobile/data/vehicles_repository.dart';

/// Captures the request a repository call makes, so the assertions are about
/// what actually goes on the wire.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'message': ''}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({VehiclesRepository repo, _CapturingAdapter adapter}) _repo() {
  final adapter = _CapturingAdapter();
  final dio = Dio(BaseOptions(baseUrl: 'http://server'))
    ..httpClientAdapter = adapter;
  return (repo: VehiclesRepository(dio), adapter: adapter);
}

Map<String, dynamic> _body(_CapturingAdapter adapter) =>
    adapter.captured!.data as Map<String, dynamic>;

void main() {
  test('a gas record reads the state of charge either side of a charge', () {
    final record = GasRecord.fromJson({
      'id': 1,
      'date': '2026-04-05',
      'odometer': 1000,
      'fuelConsumed': 40,
      'cost': 12,
      'isFillToFull': true,
      'missedFuelUp': false,
      'startingSoc': 18,
      'endingSoc': 92,
    });

    expect(record.startingSoc, 18);
    expect(record.endingSoc, 92);
  });

  test('an update resends the record\'s own state of charge', () async {
    // The server derives battery capacity from
    // fuelConsumed / (endingSoc - startingSoc), so writing the two equal — as
    // the app used to, with a hardcoded 0/0 — divides by zero and leaves the
    // vehicle reporting no energy consumption at all.
    final (:repo, :adapter) = _repo();

    await repo.updateGasRecord(
      vehicleId: 1,
      id: 7,
      date: DateTime(2026, 4, 5),
      odometer: 1000,
      fuelConsumed: 40,
      cost: 12,
      isFillToFull: true,
      missedFuelUp: false,
      startingSoc: 18,
      endingSoc: 92,
    );

    expect(_body(adapter)['startingSoc'], '18');
    expect(_body(adapter)['endingSoc'], '92');
  });

  test('a new record defaults to the server\'s own 20/80', () async {
    final (:repo, :adapter) = _repo();

    await repo.addGasRecord(
      vehicleId: 1,
      date: DateTime(2026, 4, 5),
      odometer: 1000,
      fuelConsumed: 40,
      cost: 12,
      isFillToFull: true,
      missedFuelUp: false,
    );

    expect(_body(adapter)['startingSoc'], '20');
    expect(_body(adapter)['endingSoc'], '80');
  });

  test('the fields are always sent, never left empty', () async {
    // Before 1.7.0 the server int.Parse'd them with no guard, so an absent or
    // empty value answered 500.
    final (:repo, :adapter) = _repo();

    await repo.addGasRecord(
      vehicleId: 1,
      date: DateTime(2026, 4, 5),
      odometer: 1000,
      fuelConsumed: 40,
      cost: 12,
      isFillToFull: true,
      missedFuelUp: false,
      startingSoc: 0,
      endingSoc: 0,
    );

    expect(_body(adapter)['startingSoc'], '0');
    expect(_body(adapter)['endingSoc'], '0');
  });
}

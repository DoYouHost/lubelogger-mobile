import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/demo/demo_http_adapter.dart';
import 'package:lubelogger_mobile/core/models/plan_record.dart';
import 'package:lubelogger_mobile/core/models/reminder_record.dart';
import 'package:lubelogger_mobile/core/models/vehicle_record.dart';
import 'package:lubelogger_mobile/data/vehicles_repository.dart';

/// Exercises the demo backend end-to-end through a real Dio + the production
/// repository and model parsers, so a wire-shape mismatch fails here rather than
/// only showing up as empty screens in the app.
void main() {
  VehiclesRepository repo() {
    final dio = Dio(BaseOptions(baseUrl: 'http://demo'))
      ..httpClientAdapter = DemoHttpClientAdapter(latency: Duration.zero);
    return VehiclesRepository(dio);
  }

  test('garage lists both seeded vehicles with correct fuel flags', () async {
    final vehicles = await repo().list();
    expect(vehicles.map((v) => v.id), containsAll(<int>[1, 2]));
    expect(vehicles.firstWhere((v) => v.id == 2).isDiesel, isTrue);
    expect(vehicles.firstWhere((v) => v.id == 1).makeModel, 'Toyota Corolla');
  });

  test('vehicle info aggregates costs and reminder counts consistently',
      () async {
    final r = repo();
    final info = await r.info(1);
    final reminders = await r.reminders(1);
    expect(info.totalCost, greaterThan(0));
    expect(info.lastReportedOdometer, greaterThan(60000));
    final counted = info.veryUrgentReminderCount +
        info.urgentReminderCount +
        info.notUrgentReminderCount +
        info.pastDueReminderCount;
    expect(counted, reminders.length);
    expect(info.pastDueReminderCount, greaterThanOrEqualTo(1));
  });

  test('every record tab parses its seeded data', () async {
    final r = repo();
    expect((await r.gasRecords(1)).length, 9);
    expect((await r.gasRecords(1)).every((g) => g.isFillToFull), isTrue);
    expect((await r.odometerRecords(1)), isNotEmpty);
    expect((await r.records(RecordKind.service, 1)).length, 2);
    expect((await r.records(RecordKind.tax, 1)).single.odometer, isNull);
    expect((await r.supplyRecords(1)).length, 2);
    expect((await r.planRecords(1)).single.progress, PlanProgress.inProgress);
    expect((await r.notes(1)).single.pinned, isTrue);
    expect((await r.equipmentRecords(1)).length, 2);
  });

  test('reminders carry a computed urgency, at least one past due', () async {
    final reminders = await repo().reminders(1);
    expect(reminders, isNotEmpty);
    expect(reminders.every((x) => x.urgency != ReminderUrgency.unknown), isTrue);
    expect(
      reminders.any((x) => x.urgency == ReminderUrgency.pastDue),
      isTrue,
    );
  });

  test('add / update / delete a service record round-trips', () async {
    final r = repo();
    final before = (await r.records(RecordKind.service, 2)).length;

    await r.addRecord(
      kind: RecordKind.service,
      vehicleId: 2,
      date: DateTime(2026, 1, 5),
      description: 'Demo brake fluid',
      cost: 42,
      odometer: 140000,
    );
    var list = await r.records(RecordKind.service, 2);
    expect(list.length, before + 1);
    final added = list.firstWhere((x) => x.description == 'Demo brake fluid');

    await r.updateRecord(
      kind: RecordKind.service,
      id: added.id,
      date: DateTime(2026, 1, 6),
      description: 'Demo brake fluid (updated)',
      cost: 44,
      odometer: 140050,
    );
    list = await r.records(RecordKind.service, 2);
    expect(list.any((x) => x.description == 'Demo brake fluid (updated)'), isTrue);

    await r.deleteRecord(RecordKind.service, added.id);
    list = await r.records(RecordKind.service, 2);
    expect(list.length, before);
  });

  test('adding a vehicle returns its new id and grows the garage', () async {
    final r = repo();
    final before = (await r.list()).length;
    final id = await r.addVehicle(
      year: 2020,
      make: 'Honda',
      model: 'Civic',
      licensePlate: 'DEMO-303',
      fuelType: 'Gasoline',
    );
    expect(id, isNotNull);
    final after = await r.list();
    expect(after.length, before + 1);
    expect(after.any((v) => v.id == id && v.makeModel == 'Honda Civic'), isTrue);
  });

  test('deleting a vehicle removes it and its records from the garage',
      () async {
    final r = repo();
    final id = await r.addVehicle(
      year: 2018,
      make: 'Mazda',
      model: '3',
      licensePlate: 'DEMO-909',
      fuelType: 'Gasoline',
    );
    expect(id, isNotNull);
    await r.addRecord(
      kind: RecordKind.service,
      vehicleId: id!,
      date: DateTime(2026, 2, 1),
      description: 'Demo service before delete',
      cost: 10,
      odometer: 100,
    );

    await r.deleteVehicle(id);

    final after = await r.list();
    expect(after.any((v) => v.id == id), isFalse);
    expect(await r.records(RecordKind.service, id), isEmpty);
  });

  test('server metadata endpoints answer', () async {
    final r = repo();
    expect((await r.whoAmI()).isRoot, isTrue);
    expect((await r.serverInfo()).currencySymbol, r'$');
    expect((await r.serverVersion()).updateAvailable, isFalse);
    expect(await r.makeBackup(), contains('demo'));
  });
}

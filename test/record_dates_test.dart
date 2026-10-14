import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/models/gas_record.dart';
import 'package:lubelogger_mobile/core/models/odometer_record.dart';
import 'package:lubelogger_mobile/core/models/plan_record.dart';
import 'package:lubelogger_mobile/core/models/reminder_record.dart';
import 'package:lubelogger_mobile/core/models/supply_record.dart';
import 'package:lubelogger_mobile/core/models/vehicle_record.dart';

/// Every date LubeLogger sends is a calendar date. A server or proxy that
/// spells one as UTC midnight must still land on that day, as a local date —
/// read as an instant it is a UTC value, which sorts and compares against the
/// app's local dates a day off for anyone west of UTC.
void main() {
  const utcMidnight = '2024-05-15T00:00:00Z';
  final day = DateTime(2024, 5, 15);

  final dates = <String, DateTime? Function(String raw)>{
    'gas': (raw) => GasRecord.fromJson({'date': raw}).date,
    'service': (raw) => VehicleRecord.fromJson({'date': raw}).date,
    'supply': (raw) => SupplyRecord.fromJson({'date': raw}).date,
    'odometer': (raw) => OdometerRecord.fromJson({'date': raw}).date,
    'reminder': (raw) => ReminderRecord.fromJson({'dueDate': raw}).dueDate,
    'plan': (raw) => PlanRecord.fromJson({'dateCreated': raw}).dateCreated,
  };

  dates.forEach((kind, read) {
    test('$kind: a date is that day, whichever way it is spelled', () {
      expect(read('2024-05-15'), day);
      expect(read(utcMidnight), day);
      expect(read('not a date'), isNull);
    });
  });
}

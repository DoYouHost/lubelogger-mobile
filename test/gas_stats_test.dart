import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/gas_stats.dart';
import 'package:lubelogger_mobile/core/models/gas_record.dart';

GasRecord rec(
  String date,
  double odo,
  double fuel, {
  bool full = true,
  bool missed = false,
}) =>
    GasRecord(
      id: 0,
      date: DateTime.parse(date),
      odometer: odo,
      fuelConsumed: fuel,
      cost: 0,
      isFillToFull: full,
      missedFuelUp: missed,
    );

void main() {
  group('GasStats.from', () {
    test('simple full-tank sequence: average = totalΔ / totalFuel', () {
      // First record has no prior odometer → no economy. Next two each define a
      // full-tank interval: 200 km / 20 L and 300 km / 25 L.
      final stats = GasStats.from([
        rec('2026-01-01', 1000, 18),
        rec('2026-02-01', 1200, 20),
        rec('2026-03-01', 1500, 25),
      ]);

      // Average ignores the priming record: only the two resolved full-tank
      // intervals count (200 km/20 L and 300 km/25 L), never the primer's 18 L.
      expect(stats.totalRawDistance, 500); // 200 + 300
      expect(stats.totalRawVolume, closeTo(45, 1e-9)); // 20 + 25
    });

    test('distance span is max minus min odometer', () {
      final stats = GasStats.from([
        rec('2026-01-01', 1000, 18),
        rec('2026-02-01', 1200, 20),
        rec('2026-03-01', 1500, 25),
      ]);
      expect(stats.distanceSpan, 500);
    });

    test('partial fills accumulate until the next full tank', () {
      // 1000 → 1100 partial (10 L), 1100 → 1300 full (15 L): the full-tank
      // economy covers the whole 300 km on 25 L → ratio 12 km/L.
      final stats = GasStats.from([
        rec('2026-01-01', 1000, 18), // primer
        rec('2026-02-01', 1100, 10, full: false),
        rec('2026-03-01', 1300, 15),
      ]);
      final march = stats.monthly.firstWhere((m) => m.month == 3);
      expect(march.rawRatio, closeTo(300 / 25, 1e-9));
    });

    test('missed fuel-up resets the accumulator', () {
      // The missed fill drops its interval; the following full tank only counts
      // distance/fuel since the missed one.
      final stats = GasStats.from([
        rec('2026-01-01', 1000, 18), // primer
        rec('2026-02-01', 1200, 15, missed: true),
        rec('2026-03-01', 1400, 20),
      ]);
      // Only the 1200→1400 interval resolves: 200 km / 20 L.
      final march = stats.monthly.firstWhere((m) => m.month == 3);
      expect(march.rawRatio, closeTo(200 / 20, 1e-9));
      expect(stats.monthly.where((m) => m.month == 2), isEmpty);
    });

    test('empty log yields no economy', () {
      final stats = GasStats.from([]);
      expect(stats.hasEconomy, isFalse);
      expect(stats.averageRawRatio, isNull);
      expect(stats.distanceSpan, 0);
      expect(stats.monthly, isEmpty);
    });
  });

  group('electric vehicles', () {
    // A 40 kWh pack: each session adds 40 × the charge it gains, so the pack
    // size the server infers per record lands back on 40.
    GasRecord charge(String date, double odo, int from, int to) => GasRecord(
          id: 0,
          date: DateTime.parse(date),
          odometer: odo,
          fuelConsumed: 40 * (to - from) / 100,
          cost: 0,
          isFillToFull: true,
          missedFuelUp: false,
          startingSoc: from,
          endingSoc: to,
        );

    test('consumption is the charge lost since the previous session', () {
      // Charged to 80%, driven down to 20% → 60% of a 40 kWh pack = 24 kWh,
      // over 200 km. The 20 kWh this session *added* is not what was used.
      final rows = fuelRows(
        [charge('2026-01-01', 1000, 30, 80), charge('2026-02-01', 1200, 20, 70)],
        isElectric: true,
      );

      expect(rows.last.rawConsumption, closeTo(24, 1e-9));
      expect(rows.last.rawRatio, closeTo(200 / 24, 1e-9));
    });

    test('the same log read as combustion uses the record amount instead', () {
      // Guards the flag itself: without it the economy is computed off the
      // energy put in (20 kWh), which is the bug the derivation exists to fix.
      final rows = fuelRows(
        [charge('2026-01-01', 1000, 30, 80), charge('2026-02-01', 1200, 20, 70)],
      );
      expect(rows.last.rawConsumption, closeTo(20, 1e-9));
    });

    test('a session that adds no charge sizes no pack', () {
      // Equal ends divide by zero on the server; here they contribute nothing.
      final rows = fuelRows(
        [charge('2026-01-01', 1000, 30, 80), charge('2026-02-01', 1200, 50, 50)],
        isElectric: true,
      );
      expect(rows.last.rawConsumption, 0);
      expect(rows.last.rawRatio, isNull);
    });

    test('charging past the previous level consumes nothing, never a negative',
        () {
      final rows = fuelRows(
        [charge('2026-01-01', 1000, 30, 60), charge('2026-02-01', 1200, 70, 90)],
        isElectric: true,
      );
      expect(rows.last.rawConsumption, 0);
    });

    test('fill-to-full does not gate a battery', () {
      // A partial fill defers a tank's economy to the next full one; a charge is
      // always measured against the previous session, so it resolves right away.
      final partial = [
        charge('2026-01-01', 1000, 30, 80),
        GasRecord(
          id: 0,
          date: DateTime.parse('2026-02-01'),
          odometer: 1200,
          fuelConsumed: 20,
          cost: 0,
          isFillToFull: false,
          missedFuelUp: false,
          startingSoc: 20,
          endingSoc: 70,
        ),
      ];
      expect(fuelRows(partial, isElectric: true).last.rawRatio, isNotNull);
      expect(fuelRows(partial).last.rawRatio, isNull);
    });

    test('the lifetime average uses the derived consumption', () {
      final stats = GasStats.from(
        [
          charge('2026-01-01', 1000, 30, 80),
          charge('2026-02-01', 1200, 20, 70),
          charge('2026-03-01', 1500, 20, 70),
        ],
        isElectric: true,
      );
      expect(stats.totalRawDistance, 500);
      // 80% → 20% is 24 kWh; the third session starts from 70%, so 70% → 20%
      // is 20. Each drop is measured from where the previous one left off.
      expect(stats.totalRawVolume, closeTo(24 + 20, 1e-9));
    });
  });
}

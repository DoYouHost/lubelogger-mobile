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
}

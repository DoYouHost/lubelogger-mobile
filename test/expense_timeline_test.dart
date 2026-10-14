import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/chart_range.dart';
import 'package:lubelogger_mobile/core/format/expense_timeline.dart';
import 'package:lubelogger_mobile/core/models/dated_cost.dart';

DatedCost cost(String date, double amount) =>
    DatedCost(date: DateTime.parse(date), cost: amount);

OdometerReading reading(String date, double odo) =>
    (date: DateTime.parse(date), odometer: odo);

ChartWindow months(String start, String end) => ChartWindow(
  start: DateTime.parse(start),
  end: DateTime.parse(end),
  bucket: ChartBucket.month,
);

void main() {
  group('ExpenseTimeline', () {
    test('sums costs per slot across categories', () {
      final t = ExpenseTimeline.from(
        costsByCategory: {
          ExpenseCategory.service: [
            cost('2026-03-05', 100),
            cost('2026-03-20', 50),
          ],
          ExpenseCategory.fuel: [
            cost('2026-03-10', 30),
            cost('2026-05-01', 40),
          ],
        },
        odometerReadings: const [],
      );
      final b = t.bucketed(months('2026-03-01', '2026-05-31'));

      expect(
        [for (final e in b) e.start],
        [DateTime(2026, 3), DateTime(2026, 4), DateTime(2026, 5)],
      );
      expect([for (final e in b) e.totalCost], [180, 0, 40]);
      expect(b.first.byCategory[ExpenseCategory.service], 150);
    });

    test('the same month of different years stays apart', () {
      final t = ExpenseTimeline.from(
        costsByCategory: {
          ExpenseCategory.service: [cost('2026-03-05', 100)],
          ExpenseCategory.tax: [cost('2025-03-15', 200)],
        },
        odometerReadings: [
          reading('2025-02-01', 1000),
          reading('2025-03-01', 1400),
          reading('2026-03-01', 9000),
        ],
      );
      final b = t.bucketed(months('2025-03-01', '2026-03-31'));

      expect(b.first.totalCost, 200);
      expect(b.first.distance, 400);
      expect(b.last.totalCost, 100);
      expect(b.last.distance, 7600);
    });

    test(
      'distance is the gain between consecutive readings, on the later date',
      () {
        final t = ExpenseTimeline.from(
          costsByCategory: const {},
          odometerReadings: [
            reading('2026-03-25', 1000), // primer: no prior reading
            reading('2026-04-01', 1200),
            reading('2026-04-20', 1350),
            reading('2026-05-10', 1500),
          ],
        );
        final b = t.bucketed(months('2026-03-01', '2026-05-31'));
        expect([for (final e in b) e.distance], [0, 350, 150]);
      },
    );

    test('records outside the window are left out of slots and totals', () {
      final t = ExpenseTimeline.from(
        costsByCategory: {
          ExpenseCategory.repair: [
            cost('2026-06-14', 500), // the day before the window
            cost('2026-06-15', 70),
            cost('2026-09-15', 900), // the day after
          ],
        },
        odometerReadings: const [],
      );
      final window = ChartWindow(
        start: DateTime(2026, 6, 15),
        end: DateTime(2026, 9, 14),
        bucket: ChartBucket.week,
      );

      expect(t.totalsIn(window), {ExpenseCategory.repair: 70});
      expect(t.bucketed(window).fold<double>(0, (s, e) => s + e.totalCost), 70);
    });

    test('records without a date are ignored', () {
      final t = ExpenseTimeline.from(
        costsByCategory: {
          ExpenseCategory.fuel: [const DatedCost(date: null, cost: 10)],
        },
        odometerReadings: const [(date: null, odometer: 5000)],
      );
      expect(t.costs, isEmpty);
      expect(t.distances, isEmpty);
    });
  });

  group('highestReadingDate', () {
    test('a repeated top reading dates from its latest record', () {
      final readings = [
        reading('2026-01-01', 50000),
        reading('2026-02-01', 50000),
        reading('2025-12-01', 49000),
      ];
      expect(highestReadingDate(readings), DateTime(2026, 2));
      expect(highestReadingDate(readings.reversed), DateTime(2026, 2));
    });

    test('a higher reading wins over a later lower one', () {
      final date = highestReadingDate([
        reading('2026-01-01', 50000),
        reading('2026-03-01', 42000),
      ]);
      expect(date, DateTime(2026, 1));
    });

    test('records without an odometer or a date never supply the date', () {
      expect(
        highestReadingDate([
          reading('2026-05-01', 0),
          (date: null, odometer: 60000),
        ]),
        isNull,
      );
    });
  });
}

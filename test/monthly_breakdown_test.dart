import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/calendar_month.dart';
import 'package:lubelogger_mobile/core/format/monthly_breakdown.dart';
import 'package:lubelogger_mobile/core/models/dated_cost.dart';

DatedCost cost(String date, double amount) =>
    DatedCost(date: DateTime.parse(date), cost: amount);

OdometerReading reading(String date, double odo) =>
    (date: DateTime.parse(date), odometer: odo);

void main() {
  group('MonthlyBreakdown.from', () {
    test('sums costs per month across categories', () {
      final b = MonthlyBreakdown.from(
        costsByCategory: {
          ExpenseCategory.service: [cost('2026-03-05', 100), cost('2026-03-20', 50)],
          ExpenseCategory.fuel: [cost('2026-03-10', 30), cost('2026-07-01', 40)],
        },
        odometerReadings: const [],
      );

      expect(b.months[DateTime(2026, 3)]!.totalCost, 180);
      expect(b.months[DateTime(2026, 7)]!.totalCost, 40);
    });

    test('the same month of different years stays apart', () {
      final b = MonthlyBreakdown.from(
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

      expect(b.months[DateTime(2026, 3)]!.totalCost, 100);
      expect(b.months[DateTime(2025, 3)]!.totalCost, 200);
      expect(b.months[DateTime(2025, 3)]!.distance, 400);
      expect(b.months[DateTime(2026, 3)]!.distance, 7600);
    });

    test('dominant category is the highest-spend type that month', () {
      final b = MonthlyBreakdown.from(
        costsByCategory: {
          ExpenseCategory.service: [cost('2026-03-05', 100)],
          ExpenseCategory.repair: [cost('2026-03-06', 250)],
          ExpenseCategory.fuel: [cost('2026-03-07', 40)],
        },
        odometerReadings: const [],
      );
      expect(
        b.months[DateTime(2026, 3)]!.dominantCategory,
        ExpenseCategory.repair,
      );
    });

    test('distance is the delta between consecutive odometer readings', () {
      final b = MonthlyBreakdown.from(
        costsByCategory: const {},
        odometerReadings: [
          reading('2026-03-25', 1000), // primer: no prior reading
          reading('2026-04-01', 1200), // +200 → April
          reading('2026-04-20', 1350), // +150 → April
          reading('2026-05-10', 1500), // +150 → May
        ],
      );
      expect(b.months[DateTime(2026, 4)]!.distance, 350);
      expect(b.months[DateTime(2026, 5)]!.distance, 150);
      expect(b.hasDistance, isTrue);
    });

    test('empty input has no months', () {
      final b = MonthlyBreakdown.from(
        costsByCategory: const {},
        odometerReadings: const [],
      );
      expect(b.months, isEmpty);
      expect(b.hasCost, isFalse);
      expect(b.hasDistance, isFalse);
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

  group('trailingMonths', () {
    test('ends with the current month and crosses the year boundary', () {
      final window = trailingMonths(DateTime(2026, 9, 13, 17, 30));
      expect(window, hasLength(12));
      expect(window.first, DateTime(2025, 10));
      expect(window.last, DateTime(2026, 9));
    });

    test('matches the keys records are bucketed under', () {
      final window = trailingMonths(DateTime(2026, 1, 31));
      expect(window.first, DateTime(2025, 2));
      expect(window, contains(monthOf(DateTime(2025, 12, 31, 23, 59))));
    });
  });
}

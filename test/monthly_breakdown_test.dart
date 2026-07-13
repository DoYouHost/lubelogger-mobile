import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/monthly_breakdown.dart';
import 'package:lubelogger_mobile/core/models/dated_cost.dart';

DatedCost cost(String date, double amount) =>
    DatedCost(date: DateTime.parse(date), cost: amount);

OdometerReading reading(String date, double odo) =>
    (date: DateTime.parse(date), odometer: odo);

void main() {
  group('MonthlyBreakdown.from', () {
    test('sums costs per calendar month across categories', () {
      final b = MonthlyBreakdown.from(
        costsByCategory: {
          ExpenseCategory.service: [cost('2026-03-05', 100), cost('2026-03-20', 50)],
          ExpenseCategory.fuel: [cost('2026-03-10', 30), cost('2026-07-01', 40)],
          ExpenseCategory.tax: [cost('2025-03-15', 200)], // different year, same month
        },
        odometerReadings: const [],
      );

      final march = b.months.firstWhere((m) => m.month == 3);
      // 100 + 50 (service) + 30 (fuel) + 200 (tax, prior year folds into March).
      expect(march.totalCost, 380);
      final july = b.months.firstWhere((m) => m.month == 7);
      expect(july.totalCost, 40);
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
      final march = b.months.firstWhere((m) => m.month == 3);
      expect(march.dominantCategory, ExpenseCategory.repair);
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
      expect(b.months.firstWhere((m) => m.month == 4).distance, 350);
      expect(b.months.firstWhere((m) => m.month == 5).distance, 150);
      expect(b.hasDistance, isTrue);
    });

    test('always yields 12 months; empty input is all zeros', () {
      final b = MonthlyBreakdown.from(
        costsByCategory: const {},
        odometerReadings: const [],
      );
      expect(b.months.length, 12);
      expect(b.hasCost, isFalse);
      expect(b.hasDistance, isFalse);
      expect(b.months.every((m) => m.dominantCategory == null), isTrue);
    });
  });
}

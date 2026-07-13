import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/monthly_breakdown.dart';
import 'package:lubelogger_mobile/core/models/dated_cost.dart';
import 'package:lubelogger_mobile/core/models/odometer_record.dart';

DatedCost cost(String date, double amount) =>
    DatedCost(date: DateTime.parse(date), cost: amount);

void main() {
  group('MonthlyBreakdown.from', () {
    test('sums costs per calendar month across categories', () {
      final b = MonthlyBreakdown.from(
        costsByCategory: {
          ExpenseCategory.service: [cost('2026-03-05', 100), cost('2026-03-20', 50)],
          ExpenseCategory.fuel: [cost('2026-03-10', 30), cost('2026-07-01', 40)],
          ExpenseCategory.tax: [cost('2025-03-15', 200)], // different year, same month
        },
        odometerRecords: const [],
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
        odometerRecords: const [],
      );
      final march = b.months.firstWhere((m) => m.month == 3);
      expect(march.dominantCategory, ExpenseCategory.repair);
    });

    test('distance sums odometer spans per month', () {
      final b = MonthlyBreakdown.from(
        costsByCategory: const {},
        odometerRecords: [
          OdometerRecord.fromJson(
              {'date': '2026-04-01', 'initialOdometer': 1000, 'odometer': 1200}),
          OdometerRecord.fromJson(
              {'date': '2026-04-20', 'initialOdometer': 1200, 'odometer': 1350}),
        ],
      );
      final april = b.months.firstWhere((m) => m.month == 4);
      expect(april.distance, 350); // 200 + 150
      expect(b.hasDistance, isTrue);
    });

    test('always yields 12 months; empty input is all zeros', () {
      final b = MonthlyBreakdown.from(
        costsByCategory: const {},
        odometerRecords: const [],
      );
      expect(b.months.length, 12);
      expect(b.hasCost, isFalse);
      expect(b.hasDistance, isFalse);
      expect(b.months.every((m) => m.dominantCategory == null), isTrue);
    });
  });
}

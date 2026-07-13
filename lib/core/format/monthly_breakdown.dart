import '../models/dated_cost.dart';
import '../models/odometer_record.dart';

/// Expense record type, for coloring the monthly-expense bars by their dominant
/// category (colors are assigned in the UI layer).
enum ExpenseCategory { service, repair, upgrade, fuel, tax }

/// One calendar month's expenses (broken down by category) and distance, for the
/// "Expenses and Distance Traveled by Month" combo chart. Costs are summed
/// across every record type per month; distance comes from odometer records —
/// mirroring LubeLogger's report aggregation. Distance stays in raw stored
/// units (converted at display time).
class MonthlyBreakdown {
  const MonthlyBreakdown({required this.months});

  final List<MonthlyEntry> months;

  bool get hasCost => months.any((m) => m.totalCost > 0);
  bool get hasDistance => months.any((m) => m.distance > 0);

  factory MonthlyBreakdown.from({
    required Map<ExpenseCategory, List<DatedCost>> costsByCategory,
    required List<OdometerRecord> odometerRecords,
  }) {
    final entries = [
      for (var month = 1; month <= 12; month++)
        _MutableEntry(month: month),
    ];

    costsByCategory.forEach((category, records) {
      for (final r in records) {
        final m = r.date?.month;
        if (m == null) continue;
        entries[m - 1].byCategory[category] =
            (entries[m - 1].byCategory[category] ?? 0) + r.cost;
      }
    });

    for (final r in odometerRecords) {
      final m = r.date?.month;
      if (m == null) continue;
      entries[m - 1].distance += r.distanceTraveled;
    }

    return MonthlyBreakdown(
      months: [for (final e in entries) e.freeze()],
    );
  }
}

/// Immutable per-month result.
class MonthlyEntry {
  const MonthlyEntry({
    required this.month,
    required this.byCategory,
    required this.distance,
  });

  final int month;
  final Map<ExpenseCategory, double> byCategory;
  final double distance;

  double get totalCost =>
      byCategory.values.fold<double>(0, (sum, c) => sum + c);

  /// The category with the highest spend this month, or null when there's none.
  ExpenseCategory? get dominantCategory {
    ExpenseCategory? best;
    var bestCost = 0.0;
    byCategory.forEach((category, cost) {
      if (cost > bestCost) {
        bestCost = cost;
        best = category;
      }
    });
    return best;
  }
}

class _MutableEntry {
  _MutableEntry({required this.month});

  final int month;
  final Map<ExpenseCategory, double> byCategory = {};
  double distance = 0;

  MonthlyEntry freeze() => MonthlyEntry(
        month: month,
        byCategory: Map.unmodifiable(byCategory),
        distance: distance,
      );
}

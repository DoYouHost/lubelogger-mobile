import '../models/dated_cost.dart';
import 'calendar_month.dart';

/// A single odometer reading on the shared distance timeline (sourced from both
/// gas and odometer records). Raw stored distance unit.
typedef OdometerReading = ({DateTime? date, double odometer});

/// When the highest odometer value was last seen: a car standing still logs the
/// same value again, and the later record is the fresher confirmation. A zero
/// odometer is a record without a reading, so it never counts.
DateTime? highestReadingDate(Iterable<OdometerReading> readings) {
  DateTime? bestDate;
  var bestOdometer = 0.0;
  for (final (:date, :odometer) in readings) {
    if (date == null || odometer <= 0 || odometer < bestOdometer) continue;
    if (odometer > bestOdometer || date.isAfter(bestDate!)) {
      bestOdometer = odometer;
      bestDate = date;
    }
  }
  return bestDate;
}

/// Expense record type, for coloring the monthly-expense bars by their dominant
/// category (colors are assigned in the UI layer).
enum ExpenseCategory { service, repair, upgrade, fuel, tax }

/// Each month's expenses (broken down by category) and distance, for the
/// "Expenses and Distance by Month" combo chart. Costs are summed across every
/// record type per month. Distance is derived from a single timeline of every
/// odometer reading (gas + odometer records) — the delta between consecutive
/// readings is attributed to the later reading's month — so a vehicle that only
/// logs fuel still gets a distance line. Distance stays in raw stored units.
class MonthlyBreakdown {
  const MonthlyBreakdown({required this.months});

  /// Keyed by [monthOf]; a month with no records is absent.
  final Map<DateTime, MonthlyEntry> months;

  bool get hasCost => months.values.any((m) => m.totalCost > 0);
  bool get hasDistance => months.values.any((m) => m.distance > 0);

  factory MonthlyBreakdown.from({
    required Map<ExpenseCategory, List<DatedCost>> costsByCategory,
    required List<OdometerReading> odometerReadings,
  }) {
    final entries = <DateTime, _MutableEntry>{};
    _MutableEntry entryFor(DateTime date) {
      final month = monthOf(date);
      return entries[month] ??= _MutableEntry(month: month);
    }

    costsByCategory.forEach((category, records) {
      for (final r in records) {
        final date = r.date;
        if (date == null) continue;
        final entry = entryFor(date);
        entry.byCategory[category] = (entry.byCategory[category] ?? 0) + r.cost;
      }
    });

    // Build the distance line from a chronological odometer timeline: each
    // reading's gain over the previous one lands in that reading's month.
    final timeline = [
      for (final r in odometerReadings)
        if (r.date != null && r.odometer > 0) r,
    ]..sort((a, b) {
        final byDate = a.date!.compareTo(b.date!);
        return byDate != 0 ? byDate : a.odometer.compareTo(b.odometer);
      });
    double? previous;
    for (final r in timeline) {
      if (previous != null) {
        final delta = r.odometer - previous;
        if (delta > 0) entryFor(r.date!).distance += delta;
      }
      previous = r.odometer;
    }

    return MonthlyBreakdown(
      months: {
        for (final e in entries.values) e.month: e.freeze(),
      },
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

  /// First day of the month, see [monthOf].
  final DateTime month;
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

  final DateTime month;
  final Map<ExpenseCategory, double> byCategory = {};
  double distance = 0;

  MonthlyEntry freeze() => MonthlyEntry(
        month: month,
        byCategory: Map.unmodifiable(byCategory),
        distance: distance,
      );
}

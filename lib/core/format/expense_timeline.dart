import '../models/dated_cost.dart';
import 'chart_range.dart';

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

/// Expense record type (colors and display order are the UI layer's).
enum ExpenseCategory { service, repair, upgrade, fuel, tax }

/// Every dated expense and distance gain of one vehicle, sliced into chart
/// slots on demand so switching a chart's range needs no refetch.
///
/// Distance comes from a single timeline of every odometer reading (gas +
/// odometer records): the gain over the previous reading is attributed to the
/// later reading's date, so a vehicle that only logs fuel still has distance.
/// Distance stays in raw stored units.
class ExpenseTimeline {
  const ExpenseTimeline._({required this.costs, required this.distances});

  factory ExpenseTimeline.from({
    required Map<ExpenseCategory, List<DatedCost>> costsByCategory,
    required List<OdometerReading> odometerReadings,
  }) {
    final costs = [
      for (final MapEntry(key: category, value: records)
          in costsByCategory.entries)
        for (final r in records)
          if (r.date != null)
            (category: category, date: r.date!, cost: r.cost),
    ];

    final timeline = [
      for (final r in odometerReadings)
        if (r.date != null && r.odometer > 0) r,
    ]..sort((a, b) {
        final byDate = a.date!.compareTo(b.date!);
        return byDate != 0 ? byDate : a.odometer.compareTo(b.odometer);
      });
    final distances = <({DateTime date, double distance})>[];
    double? previous;
    for (final r in timeline) {
      if (previous != null && r.odometer > previous) {
        distances.add((date: r.date!, distance: r.odometer - previous));
      }
      previous = r.odometer;
    }

    return ExpenseTimeline._(costs: costs, distances: distances);
  }

  final List<({ExpenseCategory category, DateTime date, double cost})> costs;
  final List<({DateTime date, double distance})> distances;

  /// One entry per slot of [window], oldest first; empty slots included.
  List<ExpenseBucket> bucketed(ChartWindow window) {
    final starts = window.bucketStarts;
    final entries = [for (final s in starts) ExpenseBucket._(s)];
    for (final c in costs) {
      final i = window.indexOf(c.date, starts);
      if (i == null) continue;
      final byCategory = entries[i].byCategory;
      byCategory[c.category] = (byCategory[c.category] ?? 0) + c.cost;
    }
    for (final d in distances) {
      final i = window.indexOf(d.date, starts);
      if (i != null) entries[i].distance += d.distance;
    }
    return entries;
  }

  /// Spend per category inside [window]; categories with none are absent.
  Map<ExpenseCategory, double> totalsIn(ChartWindow window) {
    final totals = <ExpenseCategory, double>{};
    for (final c in costs) {
      if (window.contains(c.date)) {
        totals[c.category] = (totals[c.category] ?? 0) + c.cost;
      }
    }
    return totals;
  }
}

/// One chart slot: its first day, spend per category and raw distance.
class ExpenseBucket {
  ExpenseBucket._(this.start);

  final DateTime start;
  final Map<ExpenseCategory, double> byCategory = {};
  double distance = 0;

  double get totalCost =>
      byCategory.values.fold<double>(0, (sum, c) => sum + c);
}

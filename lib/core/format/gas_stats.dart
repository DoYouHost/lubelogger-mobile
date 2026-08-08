import '../models/gas_record.dart';

/// Energy drawn from the battery since the previous charge, ported from
/// LubeLogger's `GasHelper`. An electric record logs the energy put *in*, so the
/// pack size has to be inferred from the charge this session added before the
/// drop since the last one can be priced in kWh. A session that adds no
/// measurable charge sizes no pack, and so contributes nothing.
double _energyUsedSince(GasRecord record, int previousEndingSoc) {
  final charged = (record.endingSoc - record.startingSoc) / 100;
  if (charged <= 0 || previousEndingSoc <= 0) return 0;
  final packSize = record.fuelConsumed / charged;
  final used = (previousEndingSoc - record.startingSoc) / 100 * packSize;
  return used > 0 ? used : 0;
}

/// The server's ordering, which the running totals below depend on.
List<GasRecord> _chronological(List<GasRecord> records) => [...records]..sort((
  a,
  b,
) {
  final da = a.date, db = b.date;
  final byDate = (da == null || db == null) ? 0 : da.compareTo(db);
  if (byDate != 0) return byDate;
  final byOdometer = a.odometer.compareTo(b.odometer);
  return byOdometer != 0 ? byOdometer : a.endingSoc.compareTo(b.endingSoc);
});

/// One calendar month's fuel economy, as a raw distance/volume ratio (stored
/// distance units per stored volume unit). The screen converts it to the user's
/// chosen unit + measurement base for display.
class MonthlyEconomy {
  const MonthlyEconomy({required this.month, required this.rawRatio});

  /// Calendar month, 1 (Jan) … 12 (Dec).
  final int month;

  /// Average of the per-record distance÷volume ratios for this month, in raw
  /// stored units. Mirrors LubeLogger's report, which averages per-record
  /// economy in MPG-space before converting to the display unit.
  final double rawRatio;
}

/// Fuel statistics derived from a vehicle's refuel log, ported from LubeLogger's
/// `GasHelper.GetGasRecordViewModels` / `GetAverageGasMileage` and the monthly
/// mileage report. Everything is kept in the server's raw stored units (no unit
/// conversion here); `Formatters` applies the measurement base + display unit.
///
/// Economy is only defined between fill-to-full refuels: partial fills are
/// accumulated until the next full tank, and a "missed fuel up" resets the
/// accumulator (its distance/fuel can't be attributed). This matches the server
/// so our numbers line up with the LubeLogger web UI.
class GasStats {
  const GasStats({
    required this.totalRawDistance,
    required this.totalRawVolume,
    required this.distanceSpan,
    required this.monthly,
  });

  /// Distance (raw units) counted toward the lifetime average.
  final double totalRawDistance;

  /// Volume (raw units) counted toward the lifetime average.
  final double totalRawVolume;

  /// Highest minus lowest odometer across all records (raw units) — the
  /// dashboard's "Distance Traveled".
  final double distanceSpan;

  /// Per-calendar-month average economy (raw ratio), only for months with data.
  final List<MonthlyEconomy> monthly;

  bool get hasEconomy => totalRawDistance > 0 && totalRawVolume > 0;

  /// Lifetime average as a raw distance/volume ratio, or null when undefined.
  double? get averageRawRatio =>
      hasEconomy ? totalRawDistance / totalRawVolume : null;

  factory GasStats.from(List<GasRecord> records, {bool isElectric = false}) {
    final sorted = _chronological(records);

    double previousOdometer = 0;
    int previousEndingSoc = 0;
    double unFactoredVolume = 0;
    double unFactoredDistance = 0;

    double avgDistance = 0; // Σ delta for records included in the average.
    double avgVolume = 0; // Σ fuel for records included in the average.
    double minOdometer = double.infinity;
    double maxOdometer = 0;

    // Per-record ratio grouped by calendar month (only records that resolve a
    // full-tank economy contribute — the rest are null and skipped).
    final ratiosByMonth = <int, List<double>>{};

    for (var i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      if (r.odometer > 0) {
        minOdometer = r.odometer < minOdometer ? r.odometer : minOdometer;
        maxOdometer = r.odometer > maxOdometer ? r.odometer : maxOdometer;
      }

      // The first record only seeds `previousOdometer`: with no prior reading,
      // its delta would be the entire odometer. Mirrors the server's `i > 0`
      // guard, so the first fill never yields a bogus economy.
      if (i == 0) {
        if (r.odometer > 0) previousOdometer = r.odometer;
        if (r.endingSoc != 0) previousEndingSoc = r.endingSoc;
        continue;
      }

      var delta = r.odometer - previousOdometer;
      if (delta < 0) delta = 0;
      final volume = isElectric
          ? _energyUsedSince(r, previousEndingSoc)
          : r.fuelConsumed;
      double? ratio;

      if (r.missedFuelUp) {
        // Distance since the last full tank is unattributable; drop it.
        unFactoredVolume = 0;
        unFactoredDistance = 0;
      } else if (isElectric) {
        // A charge is measured against the previous one, so there is no partial
        // fill to carry forward and "fill to full" says nothing about a battery.
        if (volume > 0 && delta > 0 && r.odometer > 0) ratio = delta / volume;
      } else if (r.isFillToFull && r.odometer > 0) {
        final totalVolume = unFactoredVolume + volume;
        final totalDistance = unFactoredDistance + delta;
        if (volume > 0 && delta > 0 && totalVolume > 0) {
          ratio = totalDistance / totalVolume;
        }
        unFactoredVolume = 0;
        unFactoredDistance = 0;
      } else {
        unFactoredVolume += volume;
        unFactoredDistance += delta;
      }

      // IncludeInAverage: a resolved economy, or a partial/odometer-less record
      // that still carries real fuel (but never a missed fuel-up).
      final includeInAverage = !r.missedFuelUp &&
          ((ratio != null && ratio > 0) ||
              !r.isFillToFull ||
              r.odometer == 0);
      if (includeInAverage) {
        avgDistance += delta;
        avgVolume += volume;
      }

      if (ratio != null && ratio > 0 && r.date != null) {
        (ratiosByMonth[r.date!.month] ??= []).add(ratio);
      }

      if (r.odometer > 0) previousOdometer = r.odometer;
      if (r.endingSoc != 0) previousEndingSoc = r.endingSoc;
    }

    final monthly = [
      for (final entry in ratiosByMonth.entries)
        MonthlyEconomy(
          month: entry.key,
          rawRatio:
              entry.value.reduce((a, b) => a + b) / entry.value.length,
        ),
    ]..sort((a, b) => a.month.compareTo(b.month));

    return GasStats(
      totalRawDistance: avgDistance,
      totalRawVolume: avgVolume,
      distanceSpan: maxOdometer > minOdometer ? maxOdometer - minOdometer : 0,
      monthly: monthly,
    );
  }
}

/// One row of the fuel-history table, in raw stored units. [rawDelta] is the
/// odometer gain since the previous (older) fuel-up — null for the oldest row,
/// which has no prior reading. [rawRatio] is the fill-to-full economy
/// (distance ÷ volume) resolved at this record, or null for a partial fill /
/// missed fuel-up, mirroring how the server's per-record economy column blanks.
class FuelRow {
  const FuelRow({
    required this.record,
    required this.rawDelta,
    required this.rawRatio,
    required this.rawConsumption,
  });

  final GasRecord record;
  final double? rawDelta;
  final double? rawRatio;

  /// Fuel or energy attributed to this row. Equal to the record's own amount for
  /// a combustion vehicle; for an electric one it is [_energyUsedSince], which
  /// is what the server shows in the same column and totals underneath it.
  final double rawConsumption;
}

/// Per-record fuel rows in chronological order (oldest first), reusing the same
/// fill-to-full accumulation as [GasStats.from] so per-row economy matches the
/// server: partial fills accumulate their distance/volume into the next full
/// tank, and a missed fuel-up drops the unattributable span.
List<FuelRow> fuelRows(List<GasRecord> records, {bool isElectric = false}) {
  final sorted = _chronological(records);

  double previousOdometer = 0;
  int previousEndingSoc = 0;
  double unFactoredVolume = 0;
  double unFactoredDistance = 0;
  final rows = <FuelRow>[];

  for (var i = 0; i < sorted.length; i++) {
    final r = sorted[i];

    // The oldest record only seeds `previousOdometer`; with no prior reading it
    // gets no delta and no economy (matches GasStats' `i == 0` guard).
    if (i == 0) {
      if (r.odometer > 0) previousOdometer = r.odometer;
      if (r.endingSoc != 0) previousEndingSoc = r.endingSoc;
      rows.add(FuelRow(
        record: r,
        rawDelta: null,
        rawRatio: null,
        rawConsumption: r.fuelConsumed,
      ));
      continue;
    }

    var delta = r.odometer - previousOdometer;
    if (delta < 0) delta = 0;
    final volume = isElectric
        ? _energyUsedSince(r, previousEndingSoc)
        : r.fuelConsumed;
    double? ratio;

    if (r.missedFuelUp) {
      unFactoredVolume = 0;
      unFactoredDistance = 0;
    } else if (isElectric) {
      if (volume > 0 && delta > 0 && r.odometer > 0) ratio = delta / volume;
    } else if (r.isFillToFull && r.odometer > 0) {
      final totalVolume = unFactoredVolume + volume;
      final totalDistance = unFactoredDistance + delta;
      if (volume > 0 && delta > 0 && totalVolume > 0) {
        ratio = totalDistance / totalVolume;
      }
      unFactoredVolume = 0;
      unFactoredDistance = 0;
    } else {
      unFactoredVolume += volume;
      unFactoredDistance += delta;
    }

    rows.add(FuelRow(
      record: r,
      rawDelta: r.odometer > 0 ? delta : null,
      rawRatio: (ratio != null && ratio > 0) ? ratio : null,
      rawConsumption: volume,
    ));

    if (r.odometer > 0) previousOdometer = r.odometer;
    if (r.endingSoc != 0) previousEndingSoc = r.endingSoc;
  }

  return rows;
}

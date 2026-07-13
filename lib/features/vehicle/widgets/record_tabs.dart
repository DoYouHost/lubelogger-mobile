import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/formatters.dart';
import '../../../core/format/gas_stats.dart';
import '../../../core/models/gas_record.dart';
import '../../../core/models/odometer_record.dart';
import '../../../core/models/vehicle_record.dart';
import '../../../core/settings/units_settings.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../forms/add_fuel_form.dart';
import 'record_table.dart';

const _placeholder = '—';

/// Short date in the user's chosen order + separator, or a dash when missing.
String _date(DateTime? d, UnitsSettings units) =>
    d == null ? _placeholder : units.formatDate(d);

/// Odometer / distance reading in the display unit, bare (unit lives in the
/// column header). Engine-hour vehicles show the raw hours instead.
String _odo(double? raw, UnitsSettings units, {required bool useHours}) {
  if (raw == null || raw <= 0) return _placeholder;
  final value =
      useHours ? raw : Formatters.distanceValue(raw, units.base, units.distance);
  return Formatters.odometer(value);
}

String _distanceUnitLabel(UnitsSettings units, {required bool useHours}) =>
    useHours ? 'h' : units.distance.label;

/// Odometer readings table: Date, Odometer, Δ (gain since the previous reading).
class OdometerTab extends ConsumerWidget {
  const OdometerTab({super.key, required this.vehicleId, required this.useHours});

  final int vehicleId;
  final bool useHours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final units = ref.watch(unitsSettingsProvider);
    final async = ref.watch(odometerRecordsProvider(vehicleId));
    final unit = _distanceUnitLabel(units, useHours: useHours);

    return RecordsTabBody<OdometerRecord>(
      async: async,
      emptyIcon: Icons.speed,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(odometerRecordsProvider(vehicleId));
        await ref.read(odometerRecordsProvider(vehicleId).future);
      },
      builder: (records) {
        // Ascending to compute each reading's gain over the prior one, then
        // reversed so the newest reading sits at the top.
        final ascending = [...records]
          ..sort((a, b) => _compareDates(a.date, b.date));
        final deltas = <int, double?>{};
        double? previous;
        for (var i = 0; i < ascending.length; i++) {
          final o = ascending[i].odometer;
          deltas[i] = (previous != null && o > previous) ? o - previous : null;
          previous = o > 0 ? o : previous;
        }
        return RecordTable(
          columns: [
            RecordColumn(l10n.colDate, flex: 4),
            RecordColumn('${l10n.colOdometer} ($unit)', flex: 4, numeric: true),
            RecordColumn('Δ ($unit)', flex: 3, numeric: true),
          ],
          rows: [
            for (var i = ascending.length - 1; i >= 0; i--)
              [
                _date(ascending[i].date, units),
                _odo(ascending[i].odometer, units, useHours: useHours),
                _odo(deltas[i], units, useHours: useHours),
              ],
          ],
        );
      },
    );
  }
}

/// Generic (date + cost) records table for service / repair / upgrade / tax.
/// Tax has no odometer column.
class GenericRecordsTab extends ConsumerWidget {
  const GenericRecordsTab({
    super.key,
    required this.vehicleId,
    required this.kind,
    required this.useHours,
  });

  final int vehicleId;
  final RecordKind kind;
  final bool useHours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final units = ref.watch(unitsSettingsProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final key = (vehicleId: vehicleId, kind: kind);
    final async = ref.watch(vehicleRecordsProvider(key));
    final unit = _distanceUnitLabel(units, useHours: useHours);

    return RecordsTabBody<VehicleRecord>(
      async: async,
      emptyIcon: Icons.receipt_long,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(vehicleRecordsProvider(key));
        await ref.read(vehicleRecordsProvider(key).future);
      },
      builder: (records) {
        final sorted = [...records]
          ..sort((a, b) => _compareDates(b.date, a.date)); // newest first
        return RecordTable(
          columns: [
            RecordColumn(l10n.colDate, flex: 3),
            if (kind.hasOdometer)
              RecordColumn('${l10n.colOdometer} ($unit)',
                  flex: 3, numeric: true),
            RecordColumn(l10n.colDescription, flex: 5),
            RecordColumn(l10n.colCost, flex: 3, numeric: true),
          ],
          rows: [
            for (final r in sorted)
              [
                _date(r.date, units),
                if (kind.hasOdometer)
                  _odo(r.odometer, units, useHours: useHours),
                r.description.isEmpty ? _placeholder : r.description,
                Formatters.currency(r.cost, symbol),
              ],
          ],
        );
      },
    );
  }
}

/// Fuel history table (design #4): summary pills + per-record table with
/// Date, Odometer, Δ, economy, Cost, price/volume. Economy uses [fuelRows]'
/// fill-to-full accumulation so it matches the server.
class FuelTab extends ConsumerWidget {
  const FuelTab({super.key, required this.vehicleId, required this.useHours});

  final int vehicleId;
  final bool useHours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(unitsSettingsProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final async = ref.watch(gasRecordsProvider(vehicleId));
    final stats = ref.watch(gasStatsProvider(vehicleId)).valueOrNull;
    final unit = _distanceUnitLabel(units, useHours: useHours);

    String econ(double? rawRatio) {
      if (rawRatio == null) return _placeholder;
      final v =
          Formatters.fuelEconomyValue(rawRatio, 1, units.base, units.economy);
      return v == null ? _placeholder : v.toStringAsFixed(1);
    }

    String pricePerVolume(GasRecord r) => r.fuelConsumed <= 0
        ? _placeholder
        : Formatters.currency(r.cost / r.fuelConsumed, symbol);

    return RecordsTabBody<GasRecord>(
      async: async,
      emptyIcon: Icons.local_gas_station,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(gasRecordsProvider(vehicleId));
        ref.invalidate(gasStatsProvider(vehicleId));
        await ref.read(gasRecordsProvider(vehicleId).future);
      },
      builder: (records) {
        final rows = fuelRows(records); // chronological (oldest first)
        final displayed = [for (var i = rows.length - 1; i >= 0; i--) rows[i]];
        final totalFuel = records.fold<double>(0, (s, r) => s + r.fuelConsumed);
        final totalCost = records.fold<double>(0, (s, r) => s + r.cost);

        // Per-record economies in the display unit, for min/max. Avg uses the
        // lifetime distance÷volume ratio (matches the dashboard + server).
        final economies = <double>[
          for (final r in rows)
            if (r.rawRatio != null)
              Formatters.fuelEconomyValue(
                  r.rawRatio!, 1, units.base, units.economy)!,
        ];
        final avg = stats?.averageRawRatio;
        final avgDisplayed = avg == null
            ? null
            : Formatters.fuelEconomyValue(avg, 1, units.base, units.economy);
        String econLabel(double? v) =>
            v == null ? _placeholder : '${v.toStringAsFixed(1)} ${units.economy.label}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SummaryPillRow(pills: [
              DashPill(
                label: l10n.fuelPillRecords(records.length),
                accent: t.accentGold,
                accentInk: t.accentGoldInk,
              ),
              DashPill(
                label: l10n.fuelPillAvg(econLabel(avgDisplayed)),
                accent: t.accentBlue,
              ),
              if (economies.isNotEmpty) ...[
                DashPill(
                  label: l10n.fuelPillMin(
                      econLabel(economies.reduce((a, b) => a < b ? a : b))),
                  accent: t.accentBlue,
                ),
                DashPill(
                  label: l10n.fuelPillMax(
                      econLabel(economies.reduce((a, b) => a > b ? a : b))),
                  accent: t.accentBlue,
                ),
              ],
              if (stats != null)
                DashPill(
                  label: l10n.fuelPillDistance(
                      '${_odo(stats.distanceSpan, units, useHours: useHours)} $unit'),
                  accent: t.accentOrange,
                ),
              DashPill(
                label: l10n.fuelPillFuel(
                    '${Formatters.odometer(totalFuel)} ${units.base.volumeLabel}'),
                accent: t.accentOrange,
              ),
              DashPill(
                label: l10n.fuelPillCost(Formatters.currency(totalCost, symbol)),
                accent: t.accentGold,
                accentInk: t.accentGoldInk,
              ),
            ]),
            RecordTable(
              columns: [
                RecordColumn(l10n.colDate, flex: 4),
                RecordColumn('${l10n.colOdometer} ($unit)',
                    flex: 4, numeric: true),
                RecordColumn('Δ ($unit)', flex: 3, numeric: true),
                RecordColumn(units.economy.label, flex: 3, numeric: true),
                RecordColumn(l10n.colCost, flex: 4, numeric: true),
                RecordColumn('$symbol/${units.base.volumeLabel}',
                    flex: 3, numeric: true),
              ],
              rows: [
                for (final row in displayed)
                  [
                    _date(row.record.date, units),
                    _odo(row.record.odometer, units, useHours: useHours),
                    _odo(row.rawDelta, units, useHours: useHours),
                    econ(row.rawRatio),
                    Formatters.currency(row.record.cost, symbol),
                    pricePerVolume(row.record),
                  ],
              ],
              onRowTap: (i) =>
                  showAddFuelForm(context, vehicleId, existing: displayed[i].record),
            ),
          ],
        );
      },
    );
  }
}

/// Chronological compare with nulls sorted last.
int _compareDates(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

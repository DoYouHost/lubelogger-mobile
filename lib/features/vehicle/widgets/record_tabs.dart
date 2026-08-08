import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/formatters.dart';
import '../../../core/format/gas_stats.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/models/equipment_record.dart';
import '../../../core/models/gas_record.dart';
import '../../../core/models/note_record.dart';
import '../../../core/models/odometer_record.dart';
import '../../../core/models/plan_record.dart';
import '../../../core/models/reminder_record.dart';
import '../../../core/models/supply_record.dart';
import '../../../core/models/vehicle_record.dart';
import '../../../core/format/vehicle_units.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../forms/add_equipment_form.dart';
import '../forms/add_fuel_form.dart';
import '../forms/add_generic_record_form.dart';
import '../forms/add_note_form.dart';
import '../forms/add_odometer_form.dart';
import '../forms/add_plan_form.dart';
import '../forms/add_reminder_form.dart';
import '../forms/add_supply_form.dart';
import 'record_list.dart';

const _placeholder = '—';

/// Short date in the user's chosen order + separator, or a dash when missing.
String _date(DateTime? d, VehicleUnits units) =>
    d == null ? _placeholder : units.formatDate(d);

/// Odometer / distance reading in the display unit, bare (no unit suffix).
String _odo(double? raw, VehicleUnits units) => (raw == null || raw <= 0)
    ? _placeholder
    : Formatters.odometer(units.toDisplayDistance(raw));

/// [_odo] with its unit label appended, or just the bare placeholder when
/// there's no reading — a record card shows "—" alone, never "— km".
String _odoUnit(double? raw, VehicleUnits units) {
  final v = _odo(raw, units);
  return v == _placeholder ? v : '$v ${units.distanceLabel}';
}

/// Odometer readings as a card list: each card headlines the reading, with the
/// gain since the previous reading (Δ) in the meta row.
class OdometerTab extends ConsumerWidget {
  const OdometerTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final async = ref.watch(odometerRecordsProvider(vehicleId));

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
        return ResponsiveCardWrap(
          children: [
            for (var i = ascending.length - 1; i >= 0; i--)
              RecordCard(
                date: _date(ascending[i].date, units),
                headline: _odoUnit(ascending[i].odometer, units),
                meta: [
                  RecordMetaItem(
                    Icons.trending_up,
                    _odoUnit(deltas[i], units),
                  ),
                ],
                onTap: () => showAddOdometerForm(
                  context,
                  vehicleId,
                  existing: ascending[i],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Generic (date + cost) record cards for service / repair / upgrade / tax.
/// Tax cards have no odometer meta item.
class GenericRecordsTab extends ConsumerWidget {
  const GenericRecordsTab({
    super.key,
    required this.vehicleId,
    required this.kind,
  });

  final int vehicleId;
  final RecordKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final symbol = ref.watch(currencySymbolProvider);
    final key = (vehicleId: vehicleId, kind: kind);
    final async = ref.watch(vehicleRecordsProvider(key));

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
        return ResponsiveCardWrap(
          children: [
            for (final r in sorted)
              RecordCard(
                date: _date(r.date, units),
                headline: Formatters.currency(r.cost, symbol),
                headlineColor: t.accentGoldInk,
                description: r.description.isEmpty
                    ? _placeholder
                    : r.description,
                meta: [
                  if (kind.hasOdometer)
                    RecordMetaItem(
                      Icons.speed,
                      _odoUnit(r.odometer, units),
                    ),
                ],
                onTap: kind.editable
                    ? () => showGenericRecordForm(
                        context,
                        vehicleId,
                        kind,
                        existing: r,
                      )
                    : null,
              ),
          ],
        );
      },
    );
  }
}

/// Fuel history: summary pills + a card per fill-up (design handoff — date +
/// cost headline, meta row of odometer / Δ / economy / price-per-volume).
/// Economy uses [fuelRows]' fill-to-full accumulation so it matches the server.
class FuelTab extends ConsumerWidget {
  const FuelTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final symbol = ref.watch(currencySymbolProvider);
    final async = ref.watch(gasRecordsProvider(vehicleId));
    final stats = ref.watch(gasStatsProvider(vehicleId)).valueOrNull;

    String econ(double? rawRatio) {
      if (rawRatio == null) return _placeholder;
      final v = units.economyValue(rawRatio, 1);
      return v == null ? _placeholder : Formatters.number(v, decimals: 1);
    }

    // Cost per unit divides by what was bought, so an electric record uses the
    // energy it put in rather than the energy the battery later gave up.
    String pricePerUnit(GasRecord r) => r.fuelConsumed <= 0
        ? _placeholder
        : Formatters.currency(r.cost / r.fuelConsumed, symbol);

    String econMeta(double? rawRatio) {
      final v = econ(rawRatio);
      return v == _placeholder ? v : '$v ${units.economyLabel}';
    }

    String priceMeta(GasRecord r) {
      final v = pricePerUnit(r);
      return v == _placeholder ? v : '$v/${units.consumptionLabel}';
    }

    return RecordsTabBody<GasRecord>(
      async: async,
      emptyIcon: Icons.local_gas_station,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(gasRecordsProvider(vehicleId));
        await ref.read(gasRecordsProvider(vehicleId).future);
      },
      builder: (records) {
        final rows = fuelRows(records, isElectric: units.isElectric);
        final displayed = [for (var i = rows.length - 1; i >= 0; i--) rows[i]];
        final totalFuel = rows.fold<double>(0, (s, r) => s + r.rawConsumption);
        final totalCost = records.fold<double>(0, (s, r) => s + r.cost);

        // Per-record economies in the display unit, for min/max. Avg uses the
        // lifetime distance÷volume ratio (matches the dashboard + server).
        final economies = <double>[
          for (final r in rows)
            if (r.rawRatio != null) units.economyValue(r.rawRatio!, 1)!,
        ];
        final avg = stats?.averageRawRatio;
        final avgDisplayed = avg == null ? null : units.economyValue(avg, 1);
        String econLabel(double? v) => v == null
            ? _placeholder
            : '${Formatters.number(v, decimals: 1)} ${units.economyLabel}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SummaryPillRow(
              pills: [
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
                      econLabel(economies.reduce((a, b) => a < b ? a : b)),
                    ),
                    accent: t.accentBlue,
                  ),
                  DashPill(
                    label: l10n.fuelPillMax(
                      econLabel(economies.reduce((a, b) => a > b ? a : b)),
                    ),
                    accent: t.accentBlue,
                  ),
                ],
                if (stats != null)
                  DashPill(
                    label: l10n.fuelPillDistance(
                      _odoUnit(stats.distanceSpan, units),
                    ),
                    accent: t.accentOrange,
                  ),
                DashPill(
                  label: (units.isElectric ? l10n.fuelPillEnergy : l10n.fuelPillFuel)(
                    '${Formatters.odometer(totalFuel)} ${units.consumptionLabel}',
                  ),
                  accent: t.accentOrange,
                ),
                DashPill(
                  label: l10n.fuelPillCost(
                    Formatters.currency(totalCost, symbol),
                  ),
                  accent: t.accentGold,
                  accentInk: t.accentGoldInk,
                ),
              ],
            ),
            ResponsiveCardWrap(
              children: [
                for (final row in displayed)
                  RecordCard(
                    date: _date(row.record.date, units),
                    headline: Formatters.currency(row.record.cost, symbol),
                    headlineColor: t.accentGoldInk,
                    meta: [
                      RecordMetaItem(
                        Icons.speed,
                        _odoUnit(row.record.odometer, units),
                      ),
                      RecordMetaItem(
                        Icons.trending_up,
                        _odoUnit(row.rawDelta, units),
                      ),
                      RecordMetaItem(
                        Icons.local_gas_station,
                        econMeta(row.rawRatio),
                      ),
                      RecordMetaItem(Icons.sell, priceMeta(row.record)),
                    ],
                    onTap: () => showAddFuelForm(
                      context,
                      vehicleId,
                      existing: row.record,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Supply / part records as cards: date + cost headline, with part number,
/// supplier and quantity in the meta row.
class SupplyTab extends ConsumerWidget {
  const SupplyTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final symbol = ref.watch(currencySymbolProvider);
    final async = ref.watch(supplyRecordsProvider(vehicleId));

    return RecordsTabBody<SupplyRecord>(
      async: async,
      emptyIcon: Icons.inventory_2_outlined,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(supplyRecordsProvider(vehicleId));
        await ref.read(supplyRecordsProvider(vehicleId).future);
      },
      builder: (records) {
        final sorted = [...records]
          ..sort((a, b) => _compareDates(b.date, a.date)); // newest first
        return ResponsiveCardWrap(
          children: [
            for (final r in sorted)
              RecordCard(
                date: _date(r.date, units),
                headline: Formatters.currency(r.cost, symbol),
                headlineColor: t.accentGoldInk,
                description: r.description.isEmpty
                    ? _placeholder
                    : r.description,
                meta: [
                  if (r.partNumber.isNotEmpty)
                    RecordMetaItem(Icons.tag, r.partNumber),
                  if (r.partSupplier.isNotEmpty)
                    RecordMetaItem(Icons.storefront, r.partSupplier),
                  if (r.partQuantity.isNotEmpty)
                    RecordMetaItem(Icons.numbers, r.partQuantity),
                ],
                onTap: () => showAddSupplyForm(context, vehicleId, existing: r),
              ),
          ],
        );
      },
    );
  }
}

/// Planner items as cards: creation date + estimated cost, with priority and
/// progress in the meta row.
class PlanTab extends ConsumerWidget {
  const PlanTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final symbol = ref.watch(currencySymbolProvider);
    final async = ref.watch(planRecordsProvider(vehicleId));

    return RecordsTabBody<PlanRecord>(
      async: async,
      emptyIcon: Icons.checklist_rtl,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(planRecordsProvider(vehicleId));
        await ref.read(planRecordsProvider(vehicleId).future);
      },
      builder: (records) {
        final sorted = [...records]
          ..sort((a, b) => _compareDates(b.dateCreated, a.dateCreated));
        return ResponsiveCardWrap(
          children: [
            for (final r in sorted)
              RecordCard(
                date: _date(r.dateCreated, units),
                headline: Formatters.currency(r.cost, symbol),
                headlineColor: t.accentGoldInk,
                description: r.description.isEmpty
                    ? _placeholder
                    : r.description,
                meta: [
                  RecordMetaItem(
                    Icons.flag_outlined,
                    _planPriority(r.priority, l10n),
                  ),
                  RecordMetaItem(
                    Icons.timelapse,
                    _planProgress(r.progress, l10n),
                  ),
                ],
                onTap: () => showAddPlanForm(context, vehicleId, existing: r),
              ),
          ],
        );
      },
    );
  }
}

/// Reminders as cards: the description leads, a color-coded urgency badge sits
/// at the right, and the due date / odometer follow in the meta row. Sorted
/// most-urgent first.
class ReminderTab extends ConsumerWidget {
  const ReminderTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final async = ref.watch(remindersProvider(vehicleId));

    return RecordsTabBody<ReminderRecord>(
      async: async,
      emptyIcon: Icons.notifications_active_outlined,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(remindersProvider(vehicleId));
        await ref.read(remindersProvider(vehicleId).future);
      },
      builder: (records) {
        final sorted = [...records]
          ..sort(
            (a, b) =>
                _urgencyRank(b.urgency).compareTo(_urgencyRank(a.urgency)),
          );
        return ResponsiveCardWrap(
          children: [
            for (final r in sorted)
              RecordCard(
                // Reminders have no date/cost; the description leads instead.
                date: r.description.isEmpty ? _placeholder : r.description,
                headline: _urgencyLabel(r.urgency, l10n),
                headlineColor: _urgencyColor(r.urgency, t),
                meta: [
                  if (r.showsDate)
                    RecordMetaItem(Icons.event, _date(r.dueDate, units)),
                  if (r.showsOdometer)
                    RecordMetaItem(
                      Icons.speed,
                      _odoUnit(r.dueOdometer, units),
                    ),
                ],
                onTap: () =>
                    showAddReminderForm(context, vehicleId, existing: r),
              ),
          ],
        );
      },
    );
  }
}

/// Notes as cards: the title leads with the body below; pinned notes are
/// flagged in the meta row and sorted to the top.
class NoteTab extends ConsumerWidget {
  const NoteTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(notesProvider(vehicleId));

    return RecordsTabBody<NoteRecord>(
      async: async,
      emptyIcon: Icons.sticky_note_2_outlined,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(notesProvider(vehicleId));
        await ref.read(notesProvider(vehicleId).future);
      },
      builder: (records) {
        // Pinned first, otherwise keep the server order (a stable sort).
        final sorted = [...records]
          ..sort((a, b) => (b.pinned ? 1 : 0).compareTo(a.pinned ? 1 : 0));
        return ResponsiveCardWrap(
          children: [
            for (final r in sorted)
              RecordCard(
                // Notes have no date/cost; the title leads instead.
                date: r.description.isEmpty ? _placeholder : r.description,
                headline: '',
                description: r.noteText.isEmpty ? null : r.noteText,
                meta: [
                  if (r.pinned) RecordMetaItem(Icons.push_pin, l10n.notePinned),
                ],
                onTap: () => showAddNoteForm(context, vehicleId, existing: r),
              ),
          ],
        );
      },
    );
  }
}

/// Equipment items as cards: the name leads, an equipped/removed badge sits at
/// the right, and the distance traveled while equipped follows in the meta row.
class EquipmentTab extends ConsumerWidget {
  const EquipmentTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final async = ref.watch(equipmentRecordsProvider(vehicleId));

    return RecordsTabBody<EquipmentRecord>(
      async: async,
      emptyIcon: Icons.handyman_outlined,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(equipmentRecordsProvider(vehicleId));
        await ref.read(equipmentRecordsProvider(vehicleId).future);
      },
      builder: (records) {
        return ResponsiveCardWrap(
          children: [
            for (final r in records)
              RecordCard(
                // Equipment has no date/cost; the name leads instead.
                date: r.description.isEmpty ? _placeholder : r.description,
                headline: r.isEquipped
                    ? l10n.equipmentEquipped
                    : l10n.equipmentRemoved,
                headlineColor: r.isEquipped ? _equippedGreen : t.textTertiary,
                description: r.notes.isEmpty ? null : r.notes,
                meta: [
                  if (r.distanceTraveled != null)
                    RecordMetaItem(
                      Icons.route,
                      _odoUnit(r.distanceTraveled, units),
                    ),
                ],
                onTap: () =>
                    showAddEquipmentForm(context, vehicleId, existing: r),
              ),
          ],
        );
      },
    );
  }
}

/// Positive-status green for an equipped item (matches the dashboard's OK green).
const _equippedGreen = Color(0xFF4CAF6E);

String _planPriority(PlanPriority p, AppLocalizations l10n) => switch (p) {
  PlanPriority.critical => l10n.planPriorityCritical,
  PlanPriority.normal => l10n.planPriorityNormal,
  PlanPriority.low => l10n.planPriorityLow,
  PlanPriority.unknown => _placeholder,
};

String _planProgress(PlanProgress p, AppLocalizations l10n) => switch (p) {
  PlanProgress.backlog => l10n.planProgressBacklog,
  PlanProgress.inProgress => l10n.planProgressInProgress,
  PlanProgress.testing => l10n.planProgressTesting,
  PlanProgress.done => l10n.planProgressDone,
  PlanProgress.unknown => _placeholder,
};

String _urgencyLabel(ReminderUrgency u, AppLocalizations l10n) => switch (u) {
  ReminderUrgency.notUrgent => l10n.urgencyNotUrgent,
  ReminderUrgency.urgent => l10n.urgencyUrgent,
  ReminderUrgency.veryUrgent => l10n.urgencyVeryUrgent,
  ReminderUrgency.pastDue => l10n.urgencyPastDue,
  ReminderUrgency.unknown => _placeholder,
};

Color _urgencyColor(ReminderUrgency u, DashTokens t) => switch (u) {
  ReminderUrgency.notUrgent => t.textTertiary,
  ReminderUrgency.urgent => t.accentOrange,
  ReminderUrgency.veryUrgent => t.danger,
  ReminderUrgency.pastDue => t.danger,
  ReminderUrgency.unknown => t.textTertiary,
};

/// Sort weight so the most pressing reminders float to the top.
int _urgencyRank(ReminderUrgency u) => switch (u) {
  ReminderUrgency.pastDue => 3,
  ReminderUrgency.veryUrgent => 2,
  ReminderUrgency.urgent => 1,
  ReminderUrgency.notUrgent => 0,
  ReminderUrgency.unknown => -1,
};

/// Chronological compare with nulls sorted last.
int _compareDates(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

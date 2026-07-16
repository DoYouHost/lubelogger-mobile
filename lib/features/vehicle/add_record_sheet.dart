import 'package:flutter/material.dart';
import '../../core/layout/responsive.dart';

import '../../core/models/vehicle_record.dart';
import '../../core/models/vehicle_tab.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../common/vehicle_tab_ui.dart';
import 'forms/add_equipment_form.dart';
import 'forms/add_fuel_form.dart';
import 'forms/add_generic_record_form.dart';
import 'forms/add_note_form.dart';
import 'forms/add_odometer_form.dart';
import 'forms/add_plan_form.dart';
import 'forms/add_reminder_form.dart';
import 'forms/add_supply_form.dart';

/// FAB action: pick a record type to add, then open its form. [tabs] is the
/// vehicle's visible record tabs in the user's chosen order (see
/// [tabOrderProvider]). Every record type has its own add form; a tab with no
/// form falls back to a "coming soon" notice.
Future<void> showAddRecordSheet(
  BuildContext context,
  int vehicleId,
  List<VehicleTab> tabs,
) async {
  if (tabs.isEmpty) return;

  final picked = await showModalBottomSheet<VehicleTab>(
    context: context,
    constraints: const BoxConstraints(maxWidth: kBottomSheetMaxWidth),
    showDragHandle: true,
    builder: (_) => _AddRecordGrid(options: tabs),
  );
  if (picked == null || !context.mounted) return;

  final kind = _recordKindForTab(picked);
  if (kind != null) {
    await showGenericRecordForm(context, vehicleId, kind);
    return;
  }
  switch (picked) {
    case VehicleTab.fuel:
      await showAddFuelForm(context, vehicleId);
    case VehicleTab.odometer:
      await showAddOdometerForm(context, vehicleId);
    case VehicleTab.supply:
      await showAddSupplyForm(context, vehicleId);
    case VehicleTab.plan:
      await showAddPlanForm(context, vehicleId);
    case VehicleTab.reminder:
      await showAddReminderForm(context, vehicleId);
    case VehicleTab.note:
      await showAddNoteForm(context, vehicleId);
    case VehicleTab.equipment:
      await showAddEquipmentForm(context, vehicleId);
    case VehicleTab.service ||
        VehicleTab.repair ||
        VehicleTab.upgrade ||
        VehicleTab.tax:
      // Handled by the generic-record branch above; unreachable here.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).comingSoon)),
      );
  }
}

/// The generic (date + cost) record kind a tab maps to, or null for tabs with
/// their own bespoke form (fuel/odometer/supply/plan/reminder/note/equipment).
RecordKind? _recordKindForTab(VehicleTab tab) => switch (tab) {
  VehicleTab.service => RecordKind.service,
  VehicleTab.repair => RecordKind.repair,
  VehicleTab.upgrade => RecordKind.upgrade,
  VehicleTab.tax => RecordKind.tax,
  _ => null,
};

/// The record types as a scrollable two-column grid of tiles.
class _AddRecordGrid extends StatelessWidget {
  const _AddRecordGrid({required this.options});

  final List<VehicleTab> options;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              l10n.addRecordTitle,
              style: TextStyle(
                fontFamily: DashTokens.fontUi,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
          ),
          // Scrolls when the grid is taller than the sheet's max height.
          Flexible(
            child: GridView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 60,
              ),
              children: [
                for (final tab in options)
                  _RecordTypeTile(
                    tab: tab,
                    onTap: () => Navigator.pop(context, tab),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One record-type cell: gold icon chip + label, styled like a subcard.
class _RecordTypeTile extends StatelessWidget {
  const _RecordTypeTile({required this.tab, required this.onTap});

  final VehicleTab tab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final radius = BorderRadius.circular(14);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.subCard,
        borderRadius: radius,
        border: Border.all(color: t.subCardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: t.accentGold.withValues(alpha: 0.16),
                foregroundColor: t.accentGoldInk,
                child: Icon(tab.icon, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tab.label(l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

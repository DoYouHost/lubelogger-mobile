import 'package:flutter/material.dart';

import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import 'forms/add_fuel_form.dart';

/// Selectable record types in the add sheet. Only [fuel] has a form so far; the
/// rest are listed but report "coming soon" until their forms land.
enum _AddType { odometer, service, repair, upgrade, fuel, tax }

/// FAB action: pick a record type to add, then open its form. Fuel opens the
/// working form; the others show a "coming soon" notice for now.
Future<void> showAddRecordSheet(BuildContext context, int vehicleId) async {
  final picked = await showModalBottomSheet<_AddType>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _AddRecordList(),
  );
  if (picked == null || !context.mounted) return;

  if (picked == _AddType.fuel) {
    await showAddFuelForm(context, vehicleId);
    return;
  }
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).comingSoon)));
}

class _AddRecordList extends StatelessWidget {
  const _AddRecordList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);

    final items = <(_AddType, IconData, String)>[
      (_AddType.odometer, Icons.speed, l10n.tabOdometer),
      (_AddType.service, Icons.build_circle_outlined, l10n.catService),
      (_AddType.repair, Icons.report_outlined, l10n.catRepairs),
      (_AddType.upgrade, Icons.upgrade, l10n.catUpgrades),
      (_AddType.fuel, Icons.local_gas_station, l10n.catFuel),
      (_AddType.tax, Icons.request_quote_outlined, l10n.catTax),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
          for (final (type, icon, label) in items)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: t.accentGold.withValues(alpha: 0.16),
                foregroundColor: t.accentGoldInk,
                child: Icon(icon, size: 20),
              ),
              title: Text(label),
              onTap: () => Navigator.pop(context, type),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

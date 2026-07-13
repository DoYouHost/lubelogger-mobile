import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/vehicle.dart';
import '../../core/models/vehicle_record.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../dashboard/dashboard_screen.dart';
import 'add_record_sheet.dart';
import 'widgets/record_tabs.dart';

/// One vehicle, with the dashboard and each record type as a tab. The vehicle
/// header + scrollable tab bar are shared chrome; each tab manages its own data
/// and pull-to-refresh. Reached at `/vehicle/:id`.
class VehicleScreen extends ConsumerWidget {
  const VehicleScreen({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vehicle = ref.watch(vehicleInfoProvider(vehicleId)).valueOrNull?.vehicle;
    final useHours = vehicle?.useHours ?? false;

    final tabs = <_VehicleTab>[
      _VehicleTab(l10n.tabDashboard, Icons.dashboard_rounded,
          DashboardTab(vehicleId: vehicleId)),
      _VehicleTab(l10n.tabOdometer, Icons.speed,
          OdometerTab(vehicleId: vehicleId, useHours: useHours)),
      _VehicleTab(l10n.catService, Icons.build_circle_outlined,
          GenericRecordsTab(
              vehicleId: vehicleId,
              kind: RecordKind.service,
              useHours: useHours)),
      _VehicleTab(l10n.catRepairs, Icons.report_outlined,
          GenericRecordsTab(
              vehicleId: vehicleId,
              kind: RecordKind.repair,
              useHours: useHours)),
      _VehicleTab(l10n.catUpgrades, Icons.upgrade,
          GenericRecordsTab(
              vehicleId: vehicleId,
              kind: RecordKind.upgrade,
              useHours: useHours)),
      _VehicleTab(l10n.catFuel, Icons.local_gas_station,
          FuelTab(vehicleId: vehicleId, useHours: useHours)),
      _VehicleTab(l10n.catTax, Icons.request_quote_outlined,
          GenericRecordsTab(
              vehicleId: vehicleId, kind: RecordKind.tax, useHours: useHours)),
    ];

    return DashBackground(
      child: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            backgroundColor: DashTokens.of(context).accentGold,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () => showAddRecordSheet(context, vehicleId),
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _VehicleHeader(vehicle: vehicle),
                _VehicleTabBar(tabs: tabs),
                Expanded(
                  child: TabBarView(
                    children: [for (final t in tabs) t.content],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tab's label, icon, and content pane.
class _VehicleTab {
  const _VehicleTab(this.label, this.icon, this.content);

  final String label;
  final IconData icon;
  final Widget content;
}

/// Back button + circular photo + name/plate row, with a hairline underline
/// (design #4/#5 vheader). Shared across all tabs.
class _VehicleHeader extends ConsumerWidget {
  const _VehicleHeader({required this.vehicle});

  final Vehicle? vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = DashTokens.of(context);
    final baseUrl = ref.watch(serverProfileProvider)?.baseUrl ?? '';
    final apiKey = ref.watch(apiKeyProvider).valueOrNull;
    final name = vehicle == null
        ? ''
        : [
            if (vehicle!.year > 0) '${vehicle!.year}',
            vehicle!.makeModel,
          ].where((s) => s.isNotEmpty).join(' ');

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.hairline)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          _Avatar(vehicle: vehicle, baseUrl: baseUrl, apiKey: apiKey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                  ),
                ),
                if (vehicle != null && vehicle!.licensePlate.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '(${vehicle!.licensePlate})',
                      style: TextStyle(
                        fontFamily: DashTokens.fontUi,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.vehicle, required this.baseUrl, this.apiKey});

  final Vehicle? vehicle;
  final String baseUrl;
  final String? apiKey;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final placeholder =
        Icon(Icons.directions_car, size: 22, color: t.textTertiary);
    final image = vehicle?.imageLocation ?? '';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: t.subCard,
        shape: BoxShape.circle,
        border: Border.all(color: t.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: image.isEmpty
          ? Center(child: placeholder)
          : Image.network(
              '$baseUrl$image',
              fit: BoxFit.cover,
              headers: apiKey == null ? null : {'x-api-key': apiKey!},
              errorBuilder: (_, _, _) => Center(child: placeholder),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const SizedBox.shrink(),
            ),
    );
  }
}

/// Scrollable tab strip: each tab is an icon + label; the selected tab gets a
/// rounded gold pill (design's active-accent language).
class _VehicleTabBar extends StatelessWidget {
  const _VehicleTabBar({required this.tabs});

  final List<_VehicleTab> tabs;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.hairline)),
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        overlayColor: WidgetStatePropertyAll(
            t.accentGold.withValues(alpha: 0.06)),
        indicator: BoxDecoration(
          color: t.accentGold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.accentGold.withValues(alpha: 0.5)),
        ),
        labelColor: t.accentGoldInk,
        unselectedLabelColor: t.textSecondary,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        labelStyle: const TextStyle(
          fontFamily: DashTokens.fontUi,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: DashTokens.fontUi,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          for (final tab in tabs)
            Tab(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.icon, size: 17),
                    const SizedBox(width: 7),
                    Text(tab.label),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

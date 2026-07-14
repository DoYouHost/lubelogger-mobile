import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/vehicle.dart';
import '../../core/models/vehicle_record.dart';
import '../../core/models/vehicle_tab.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../dashboard/dashboard_screen.dart';
import '../common/vehicle_tab_ui.dart';
import 'add_record_sheet.dart';
import 'widgets/record_tabs.dart';

/// One vehicle, with the dashboard and each record type as a tab. The vehicle
/// header + scrollable tab bar are shared chrome; each tab manages its own data
/// and pull-to-refresh. Reached at `/vehicle/:id`.
class VehicleScreen extends ConsumerStatefulWidget {
  const VehicleScreen({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  ConsumerState<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends ConsumerState<VehicleScreen>
    with TickerProviderStateMixin {
  // Recreated whenever the visible-tab count changes (settings toggles), so
  // TickerProviderStateMixin (not Single-) — we may hold successive controllers.
  TabController? _tabController;
  List<_VehicleTab> _tabs = const [];

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// Quietly re-fetches the newly-selected tab's data in the background.
  /// Invalidating alone is enough to trigger the refetch: the provider keeps
  /// serving its last value while it's in flight (Riverpod's default
  /// `skipLoadingOnRefresh`), so the tab repaints in place once fresh data
  /// arrives instead of flashing a full-screen spinner.
  void _onTabChanged() {
    final controller = _tabController;
    if (controller == null || controller.indexIsChanging) return;
    _tabs[controller.index].refresh(ref);
  }

  /// Returns a controller of the given [length], reusing the current one when
  /// the count is unchanged and otherwise rebuilding it (preserving the
  /// selected index where possible). Called from [build] because the visible
  /// tab set — and thus the length — can change while the screen is alive.
  TabController _controllerFor(int length) {
    final existing = _tabController;
    if (existing != null && existing.length == length) return existing;
    final initialIndex =
        existing == null ? 0 : existing.index.clamp(0, length - 1);
    existing?.removeListener(_onTabChanged);
    existing?.dispose();
    return _tabController =
        TabController(length: length, initialIndex: initialIndex, vsync: this)
          ..addListener(_onTabChanged);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vehicleId = widget.vehicleId;
    final vehicle =
        ref.watch(vehicleInfoProvider(vehicleId)).valueOrNull?.vehicle;
    final useHours = vehicle?.useHours ?? false;
    final visible = ref.watch(visibleTabsProvider);

    // Dashboard always leads; the record tabs follow in enum order, filtered to
    // the user's visible set.
    _tabs = <_VehicleTab>[
      _VehicleTab(
        l10n.tabDashboard,
        Icons.dashboard_rounded,
        DashboardTab(vehicleId: vehicleId),
        (ref) {
          ref.invalidate(vehicleInfoProvider(vehicleId));
          ref.invalidate(gasStatsProvider(vehicleId));
          ref.invalidate(monthlyBreakdownProvider(vehicleId));
        },
      ),
      for (final tab in VehicleTab.values)
        if (visible.contains(tab))
          _recordTab(tab, l10n, vehicleId, useHours: useHours),
    ];

    final controller = _controllerFor(_tabs.length);

    return DashBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          backgroundColor: DashTokens.of(context).accentGold,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () => showAddRecordSheet(context, vehicleId, visible),
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _VehicleHeader(vehicle: vehicle),
              _VehicleTabBar(tabs: _tabs, controller: controller),
              Expanded(
                child: TabBarView(
                  controller: controller,
                  children: [for (final t in _tabs) t.content],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the [_VehicleTab] (label, icon, content, background-refresh) for a
  /// single record [tab].
  _VehicleTab _recordTab(
    VehicleTab tab,
    AppLocalizations l10n,
    int vehicleId, {
    required bool useHours,
  }) {
    final (Widget content, void Function(WidgetRef) refresh) = switch (tab) {
      VehicleTab.odometer => (
          OdometerTab(vehicleId: vehicleId, useHours: useHours),
          (ref) => ref.invalidate(odometerRecordsProvider(vehicleId)),
        ),
      VehicleTab.service => _genericTab(vehicleId, RecordKind.service, useHours),
      VehicleTab.repair => _genericTab(vehicleId, RecordKind.repair, useHours),
      VehicleTab.upgrade => _genericTab(vehicleId, RecordKind.upgrade, useHours),
      VehicleTab.fuel => (
          FuelTab(vehicleId: vehicleId, useHours: useHours),
          (ref) {
            ref.invalidate(gasRecordsProvider(vehicleId));
            ref.invalidate(gasStatsProvider(vehicleId));
          },
        ),
      VehicleTab.tax => _genericTab(vehicleId, RecordKind.tax, useHours),
      VehicleTab.supply => (
          SupplyTab(vehicleId: vehicleId),
          (ref) => ref.invalidate(supplyRecordsProvider(vehicleId)),
        ),
      VehicleTab.plan => (
          PlanTab(vehicleId: vehicleId),
          (ref) => ref.invalidate(planRecordsProvider(vehicleId)),
        ),
      VehicleTab.reminder => (
          ReminderTab(vehicleId: vehicleId, useHours: useHours),
          (ref) => ref.invalidate(remindersProvider(vehicleId)),
        ),
      VehicleTab.note => (
          NoteTab(vehicleId: vehicleId),
          (ref) => ref.invalidate(notesProvider(vehicleId)),
        ),
      VehicleTab.equipment => (
          EquipmentTab(vehicleId: vehicleId, useHours: useHours),
          (ref) => ref.invalidate(equipmentRecordsProvider(vehicleId)),
        ),
    };
    return _VehicleTab(tab.label(l10n), tab.icon, content, refresh);
  }

  /// The generic (date + cost) record tab + its refresh, shared by
  /// service / repair / upgrade / tax.
  (Widget, void Function(WidgetRef)) _genericTab(
          int vehicleId, RecordKind kind, bool useHours) =>
      (
        GenericRecordsTab(vehicleId: vehicleId, kind: kind, useHours: useHours),
        (ref) => ref.invalidate(
            vehicleRecordsProvider((vehicleId: vehicleId, kind: kind))),
      );
}

/// A tab's label, icon, content pane, and the quiet background-refresh it
/// triggers when the user switches to it.
class _VehicleTab {
  const _VehicleTab(this.label, this.icon, this.content, this.refresh);

  final String label;
  final IconData icon;
  final Widget content;
  final void Function(WidgetRef ref) refresh;
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
  const _VehicleTabBar({required this.tabs, required this.controller});

  final List<_VehicleTab> tabs;
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.hairline)),
      ),
      child: TabBar(
        controller: controller,
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

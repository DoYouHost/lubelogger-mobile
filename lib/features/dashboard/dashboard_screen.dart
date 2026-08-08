import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/formatters.dart';
import '../../core/format/gas_stats.dart';
import '../../core/format/monthly_breakdown.dart';
import '../../core/layout/responsive.dart';
import '../../core/models/vehicle_info.dart';
import '../../core/format/vehicle_units.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../common/state_views.dart';
import 'widgets/dashboard_charts.dart';

/// Extra category colors used only by the dashboard charts (the shared palette
/// has no purple/pink/green). Taken verbatim from the design mockup.
const _repairsColor = Color(0xFF8A5FD1);
const _upgradesColor = Color(0xFFD1499A);
const _okGreen = Color(0xFF4CAF6E);

const _monthLabels = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Category → swatch, shared by the "Expenses by Type" donut and the combo
/// chart's dominant-category bar coloring.
Color _categoryColor(ExpenseCategory category, DashTokens t) =>
    switch (category) {
      ExpenseCategory.service => t.accentBlue,
      ExpenseCategory.repair => _repairsColor,
      ExpenseCategory.upgrade => _upgradesColor,
      ExpenseCategory.fuel => t.accentGold,
      ExpenseCategory.tax => t.danger,
    };

/// Vehicle dashboard (design screen #5): at-a-glance stats plus expense,
/// reminder, and fuel-mileage charts for one vehicle. Rendered as the first tab
/// of [VehicleScreen], which supplies the surrounding chrome and vehicle header.
class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final infoAsync = ref.watch(vehicleInfoProvider(vehicleId));

    Future<void> refresh() async {
      invalidateVehicleData(ref.invalidate, vehicleId);
      await ref.read(vehicleInfoProvider(vehicleId).future);
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: infoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AsyncErrorView(
          message: l10n.dashLoadError,
          onRetry: refresh,
          retryLabel: l10n.retry,
        ),
        data: (info) => _DashboardBody(vehicleId: vehicleId, info: info),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.vehicleId, required this.info});

  final int vehicleId;
  final VehicleInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final symbol = ref.watch(currencySymbolProvider);
    final stats = ref.watch(gasStatsProvider(vehicleId)).valueOrNull;
    final breakdown = ref
        .watch(monthlyBreakdownProvider(vehicleId))
        .valueOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _StatBlock(info: info, stats: stats, units: units, symbol: symbol),
        const SizedBox(height: 16),
        // Charts flow two-up on wider (landscape) screens, single column on
        // portrait phones.
        ResponsiveCardWrap(
          maxColumns: 2,
          spacing: 16,
          runSpacing: 16,
          children: [
            ChartCard(
              title: l10n.chartExpensesByType,
              child: DonutChart(
                emptyLabel: l10n.chartNoData,
                slices: [
                  ChartSlice(
                    label: l10n.catService,
                    value: info.serviceRecordCost,
                    color: DashTokens.of(context).accentBlue,
                    legendValue: Formatters.currency(
                      info.serviceRecordCost,
                      symbol,
                    ),
                  ),
                  ChartSlice(
                    label: l10n.catRepairs,
                    value: info.repairRecordCost,
                    color: _repairsColor,
                    legendValue: Formatters.currency(
                      info.repairRecordCost,
                      symbol,
                    ),
                  ),
                  ChartSlice(
                    label: l10n.catUpgrades,
                    value: info.upgradeRecordCost,
                    color: _upgradesColor,
                    legendValue: Formatters.currency(
                      info.upgradeRecordCost,
                      symbol,
                    ),
                  ),
                  ChartSlice(
                    label: l10n.catFuel,
                    value: info.gasRecordCost,
                    color: DashTokens.of(context).accentGold,
                    legendValue: Formatters.currency(
                      info.gasRecordCost,
                      symbol,
                    ),
                  ),
                  ChartSlice(
                    label: l10n.catTax,
                    value: info.taxRecordCost,
                    color: DashTokens.of(context).danger,
                    legendValue: Formatters.currency(
                      info.taxRecordCost,
                      symbol,
                    ),
                  ),
                ],
              ),
            ),
            ChartCard(
              title: l10n.chartExpensesDistanceByMonth,
              child: MonthlyComboChart(
                currencySymbol: symbol,
                expensesLegend: l10n.legendExpenses,
                distanceLegend:
                    '${l10n.legendDistance} (${units.distanceLabel})',
                emptyLabel: l10n.chartNoData,
                months: _comboMonths(context, breakdown, units),
              ),
            ),
            ChartCard(
              title: l10n.chartRemindersByUrgency,
              child: DonutChart(
                emptyLabel: l10n.chartNoReminders,
                slices: [
                  ChartSlice(
                    label: l10n.urgencyNotUrgent,
                    value: info.notUrgentReminderCount.toDouble(),
                    color: _okGreen,
                    legendValue: '${info.notUrgentReminderCount}',
                  ),
                  ChartSlice(
                    label: l10n.urgencyUrgent,
                    value: info.urgentReminderCount.toDouble(),
                    color: DashTokens.of(context).accentOrange,
                    legendValue: '${info.urgentReminderCount}',
                  ),
                  ChartSlice(
                    label: l10n.urgencyVeryUrgent,
                    value: info.veryUrgentReminderCount.toDouble(),
                    color: DashTokens.of(context).danger,
                    legendValue: '${info.veryUrgentReminderCount}',
                  ),
                  ChartSlice(
                    label: l10n.urgencyPastDue,
                    value: info.pastDueReminderCount.toDouble(),
                    color: DashTokens.of(context).textTertiary,
                    legendValue: '${info.pastDueReminderCount}',
                  ),
                ],
              ),
            ),
            ChartCard(
              title: '${units.isElectric ? l10n.chartConsumptionByMonth : l10n.chartFuelMileageByMonth}'
                  ' (${units.economyLabel})',
              child: MonthlyBars(
                lowerIsBetter: units.lowerIsBetter,
                emptyLabel: l10n.chartNoData,
                bars: _monthlyBars(stats, units),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Twelve months (Jan…Dec) of total expenses (colored by dominant category)
  /// and distance (converted to the display unit) for the combo chart.
  List<ComboMonth> _comboMonths(
    BuildContext context,
    MonthlyBreakdown? breakdown,
    VehicleUnits units,
  ) {
    final t = DashTokens.of(context);
    final byMonth = {
      for (final e in breakdown?.months ?? const <MonthlyEntry>[]) e.month: e,
    };
    return [
      for (var month = 1; month <= 12; month++)
        () {
          final entry = byMonth[month];
          final dominant = entry?.dominantCategory;
          return ComboMonth(
            label: _monthLabels[month - 1],
            cost: entry?.totalCost ?? 0,
            barColor: dominant == null
                ? t.accentGold
                : _categoryColor(dominant, t),
            distance: units.toDisplayDistance(entry?.distance ?? 0),
          );
        }(),
    ];
  }

  /// Twelve slots (Jan…Dec); each month's raw ratio converted to the display
  /// unit, or null when that month has no economy data.
  List<MonthlyBar> _monthlyBars(GasStats? stats, VehicleUnits units) {
    final byMonth = {
      for (final m in stats?.monthly ?? const <MonthlyEconomy>[])
        m.month: m.rawRatio,
    };
    return [
      for (var month = 1; month <= 12; month++)
        MonthlyBar(
          label: _monthLabels[month - 1],
          value: byMonth[month] == null
              ? null
              : units.economyValue(byMonth[month]!, 1),
        ),
    ];
  }
}

/// The four stacked headline stats: odometer, distance, total cost, avg economy.
class _StatBlock extends ConsumerWidget {
  const _StatBlock({
    required this.info,
    required this.stats,
    required this.units,
    required this.symbol,
  });

  final VehicleInfo info;
  final GasStats? stats;
  final VehicleUnits units;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final odometer = units.distance(info.lastReportedOdometer);

    final lastOdometerDate = ref
        .watch(lastOdometerDateProvider(info.vehicle.id))
        .valueOrNull;
    final lastOdometerDateLabel = lastOdometerDate == null
        ? null
        : units.formatDate(lastOdometerDate);

    final distance = stats == null ? '—' : units.distance(stats!.distanceSpan);

    final economy = stats == null
        ? '—'
        : units.economy(stats!.totalRawDistance, stats!.totalRawVolume);

    final rows = [
      _StatRow(value: odometer, secondary: lastOdometerDateLabel),
      _StatRow(value: distance, label: l10n.statDistanceTraveled),
      _StatRow(
        value: Formatters.currency(info.totalCost, symbol),
        label: l10n.statTotalCost,
      ),
      _StatRow(
        value: economy,
        label: units.isElectric ? l10n.statAvgConsumption : l10n.statAvgEconomy,
      ),
    ];

    // Side by side across the width in landscape/tablet; stacked in portrait.
    if (context.isWideLayout) {
      final t = DashTokens.of(context);
      return LayoutBuilder(
        builder: (context, constraints) {
          // Fit as many stat cells across as possible without the mono value
          // wrapping mid-number. Measure the widest value at its real style
          // (TextPainter) instead of guessing, so it adapts to font metrics,
          // locale and currency width. Falls back to two rows of two.
          final valueStyle = _StatRow.valueStyle(t);
          final scaler = MediaQuery.textScalerOf(context);
          var widest = 0.0;
          for (final row in rows) {
            final painter = TextPainter(
              text: TextSpan(text: row.value, style: valueStyle),
              textDirection: TextDirection.ltr,
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            widest = math.max(widest, painter.width);
          }
          const gap = 12.0;
          const cellSideRoom = 24.0; // breathing room around each value
          final perCell = widest + cellSideRoom;
          var columns = ((constraints.maxWidth + gap) / (perCell + gap))
              .floor()
              .clamp(1, rows.length);
          // Prefer a balanced 2×2 over a lopsided 3 + 1.
          if (columns == 3 && rows.length == 4) columns = 2;
          return Column(
            children: [
              for (var i = 0; i < rows.length; i += columns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var j = 0; j < columns; j++)
                      Expanded(
                        child: (i + j) < rows.length
                            ? rows[i + j]
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
            ],
          );
        },
      );
    }
    return Column(children: rows);
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.value, this.label, this.secondary});

  final String value;

  /// Caption under the value. Omitted for rows that carry only a [secondary]
  /// chip (the odometer date).
  final String? label;

  /// Optional small chip under the value (e.g. the date of the reading).
  final String? secondary;

  /// Style of the big mono value. Shared so the [_StatBlock] layout can measure
  /// value widths (TextPainter) with the exact metrics used to render them.
  static TextStyle valueStyle(DashTokens t) => TextStyle(
    fontFamily: DashTokens.fontMono,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: t.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(value, style: valueStyle(t)),
          if (secondary != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: t.subCard,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: t.subCardBorder),
              ),
              child: Text(
                secondary!,
                style: TextStyle(
                  fontFamily: DashTokens.fontMono,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: t.textTertiary,
                ),
              ),
            ),
          ],
          if (label != null) ...[
            SizedBox(height: secondary != null ? 6 : 2),
            Text(
              label!,
              style: TextStyle(
                fontFamily: DashTokens.fontUi,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: t.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:app_util/app_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format/chart_range.dart';
import '../../core/format/expense_timeline.dart';
import '../../core/format/formatters.dart';
import '../../core/format/gas_stats.dart';
import '../../core/layout/responsive.dart';
import '../../core/models/vehicle_info.dart';
import '../../core/format/vehicle_units.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../common/state_views.dart';
import 'widgets/chart_palette.dart';
import 'widgets/chart_range_sheet.dart';
import 'widgets/dashboard_charts.dart';

String _categoryLabel(ExpenseCategory category, AppLocalizations l10n) =>
    switch (category) {
      ExpenseCategory.service => l10n.catService,
      ExpenseCategory.repair => l10n.catRepairs,
      ExpenseCategory.upgrade => l10n.catUpgrades,
      ExpenseCategory.fuel => l10n.catFuel,
      ExpenseCategory.tax => l10n.catTax,
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
    final timeline = ref.watch(expenseTimelineProvider(vehicleId)).valueOrNull;
    final t = DashTokens.of(context);
    final now = DateTime.now();
    // MaterialLocalizations counts from Sunday = 0; DateTime from Monday = 1.
    final firstDayIndex = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final firstDayOfWeek = firstDayIndex == 0 ? DateTime.sunday : firstDayIndex;

    ({ChartRange range, ChartWindow window, Widget chip}) rangeOf(
      DashboardChart chart,
      String title,
    ) {
      final key = (vehicleId: vehicleId, chart: chart);
      final range = ref.watch(chartRangeProvider(key));
      final window = range.resolve(now, firstDayOfWeek: firstDayOfWeek);
      final label = chartRangeChipLabel(range, l10n, now);
      return (
        range: range,
        window: window,
        chip: ChartRangeChip(
          label: label,
          semanticLabel: l10n.chartRangeButton(label),
          custom: range is CustomRange,
          onTap: () async {
            final picked = await showChartRangeSheet(
              context,
              chartTitle: title,
              current: range,
              defaultPreset: ref.read(chartDefaultRangeProvider),
              currentWindow: window,
              formatDate: units.formatDate,
            );
            if (picked != null && context.mounted) {
              ref.read(chartRangeOverridesProvider.notifier).set(key, picked);
            }
          },
        ),
      );
    }

    final byTypeTitle = l10n.chartExpensesByType;
    final byType = rangeOf(DashboardChart.expensesByType, byTypeTitle);
    final byTypeTotals = timeline?.totalsIn(byType.window) ?? const {};

    final expensesTitle = l10n.chartExpensesDistance;
    final expenses = rangeOf(DashboardChart.expensesDistance, expensesTitle);
    final expenseBuckets = timeline?.bucketed(expenses.window);

    final economyTitle =
        '${units.isElectric ? l10n.chartConsumption : l10n.chartFuelMileage}'
        ' (${units.economyLabel})';
    final economy = rangeOf(DashboardChart.economy, economyTitle);

    double? toEconomy(double? raw) =>
        raw == null ? null : units.economyValue(raw, 1);

    final categoryLabels = {
      for (final c in ExpenseCategory.values) c: _categoryLabel(c, l10n),
    };
    final today = dateOnly(now);

    // Charts flow two-up on wider (landscape) screens, single column on
    // portrait phones. Off-screen ones are left unbuilt: a chart is expensive to
    // lay out and paint, and on a phone at most two are ever in view.
    final charts = <Widget>[
      ChartCard(
        title: byTypeTitle,
        trailing: byType.chip,
        child: CategoryShareChart(
          emptyLabel: l10n.chartNoDataInRange,
          items: [
            for (final c in chartCategoryOrder)
              ShareItem(
                label: categoryLabels[c]!,
                value: byTypeTotals[c] ?? 0,
                color: categoryColor(c, t),
                valueLabel: Formatters.currency(byTypeTotals[c] ?? 0, symbol),
              ),
          ],
        ),
      ),
      ChartCard(
        title: expensesTitle,
        trailing: expenses.chip,
        child: ExpenseDistanceChart(
          slots: _slots(expenses.window, l10n),
          data: [
            for (final b in expenseBuckets ?? const <ExpenseBucket>[])
              ExpenseSlot(
                costs: b.byCategory,
                distance: units.toDisplayDistance(b.distance),
              ),
            if (expenseBuckets == null)
              for (final _ in expenses.window.bucketStarts)
                const ExpenseSlot(costs: {}, distance: 0),
          ],
          categoryLabels: categoryLabels,
          currencySymbol: symbol,
          expensesLabel: l10n.legendExpenses,
          distanceLabel: l10n.legendDistance,
          distanceUnit: units.distanceLabel,
          totalLabel: l10n.chartTotal,
          emptyLabel: l10n.chartNoDataInRange,
          emphasizeLast: expenses.window.end == today,
        ),
      ),
      ChartCard(
        title: l10n.chartRemindersByUrgency,
        trailing: Text(
          l10n.chartRemindersTotal(
            info.pastDueReminderCount +
                info.veryUrgentReminderCount +
                info.urgentReminderCount +
                info.notUrgentReminderCount,
          ),
          style: TextStyle(
            fontFamily: DashTokens.fontUi,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: t.textTertiary,
          ),
        ),
        child: UrgencyChart(
          emptyLabel: l10n.chartNoReminders,
          items: [
            UrgencyItem(
              label: l10n.urgencyPastDue,
              count: info.pastDueReminderCount,
              color: t.danger,
            ),
            UrgencyItem(
              label: l10n.urgencyVeryUrgent,
              count: info.veryUrgentReminderCount,
              color: t.accentOrange,
            ),
            UrgencyItem(
              label: l10n.urgencyUrgent,
              count: info.urgentReminderCount,
              color: t.warning,
            ),
            UrgencyItem(
              label: l10n.urgencyNotUrgent,
              count: info.notUrgentReminderCount,
              color: okStatusColor(t),
            ),
          ],
        ),
      ),
      ChartCard(
        title: economyTitle,
        trailing: economy.chip,
        child: EconomyChart(
          slots: _slots(economy.window, l10n),
          values: [
            for (final raw
                in stats?.economyByBucket(economy.window) ??
                    List<double?>.filled(
                      economy.window.bucketStarts.length,
                      null,
                    ))
              toEconomy(raw),
          ],
          average: toEconomy(stats?.averageRatioIn(economy.window)),
          unitLabel: units.economyLabel,
          averageLabel: l10n.chartAverage,
          emptyLabel: l10n.chartNoDataInRange,
          emphasizeLast: economy.window.end == today,
        ),
      ),
    ];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          sliver: SliverToBoxAdapter(
            child: _StatBlock(
              info: info,
              stats: stats,
              units: units,
              symbol: symbol,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, fabScrollClearance(context)),
          sliver: SliverResponsiveCards(
            maxColumns: 2,
            spacing: 16,
            runSpacing: 16,
            itemCount: charts.length,
            itemBuilder: (context, index) => charts[index],
          ),
        ),
      ],
    );
  }

  /// Axis and tooltip names for every slot of [window]. Week slots carry the
  /// year in their tooltip only.
  List<TimeSlot> _slots(ChartWindow window, AppLocalizations l10n) {
    final locale = l10n.localeName;
    final starts = window.bucketStarts;
    return [
      for (final start in starts)
        switch (window.bucket) {
          ChartBucket.week => () {
            final days = window.daysOf(start);
            return TimeSlot(
              axisLabel: DateFormat.Md(locale).format(days.first),
              title: days.first == days.last
                  ? DateFormat.yMMMd(locale).format(days.first)
                  : '${DateFormat.MMMd(locale).format(days.first)} – '
                        '${DateFormat.yMMMd(locale).format(days.last)}',
            );
          }(),
          ChartBucket.month => TimeSlot(
            axisLabel: DateFormat.LLL(locale).format(start),
            year: start.year,
            title: DateFormat.yMMMM(locale).format(start),
          ),
          ChartBucket.quarter => () {
            final quarter = (start.month - 1) ~/ 3 + 1;
            return TimeSlot(
              axisLabel: l10n.chartQuarter(quarter),
              year: start.year,
              title: '${l10n.chartQuarter(quarter)} ${start.year}',
            );
          }(),
        },
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
          // instead of guessing, so it adapts to font metrics, locale and
          // currency width. Falls back to two rows of two.
          final valueStyle = _StatRow.valueStyle(t);
          var widest = 0.0;
          for (final row in rows) {
            widest = math.max(widest, textWidth(context, row.value, valueStyle));
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
  /// value widths with the exact metrics used to render them.
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

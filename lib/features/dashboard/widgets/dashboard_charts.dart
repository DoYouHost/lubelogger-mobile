import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/dash_theme.dart';

/// One slice of a donut chart: its value, color, and legend label.
class ChartSlice {
  const ChartSlice({
    required this.label,
    required this.value,
    required this.color,
    this.legendValue,
  });

  final String label;
  final double value;
  final Color color;

  /// Formatted value shown after the label in the legend (e.g. a cost or count).
  final String? legendValue;
}

/// Card chrome shared by every chart block: translucent card gradient, hairline
/// border, centered bold title above the [child].
class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: t.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: DashTokens.fontUi,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Donut chart with a side/below legend. Slices with a zero value are dropped
/// from the ring but kept in the legend so the categories stay stable.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.emptyLabel,
  });

  final List<ChartSlice> slices;

  /// Shown in place of the ring when every slice is zero.
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: total <= 0
              ? Center(
                  child: Text(
                    emptyLabel,
                    style: TextStyle(
                      fontFamily: DashTokens.fontUi,
                      fontSize: 12.5,
                      color: t.textTertiary,
                    ),
                  ),
                )
              : PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 42,
                    startDegreeOffset: -90,
                    sections: [
                      for (final s in slices)
                        if (s.value > 0)
                          PieChartSectionData(
                            value: s.value,
                            color: s.color,
                            radius: 26,
                            showTitle: false,
                          ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 14),
        _Legend(slices: slices),
      ],
    );
  }
}

/// Two-column legend of colored dots + labels (and optional values).
class _Legend extends StatelessWidget {
  const _Legend({required this.slices});

  final List<ChartSlice> slices;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final s in slices)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                s.label,
                style: TextStyle(
                  fontFamily: DashTokens.fontUi,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.textSecondary,
                ),
              ),
              if (s.legendValue != null) ...[
                const SizedBox(width: 5),
                Text(
                  s.legendValue!,
                  style: TextStyle(
                    fontFamily: DashTokens.fontMono,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// A single bar in [MonthlyBars]: the month label and its value (already in the
/// display unit), or null value for a month with no data.
class MonthlyBar {
  const MonthlyBar({required this.label, required this.value});

  final String label;
  final double? value;
}

/// Twelve-month bar chart (Jan…Dec) with efficiency coloring: each bar is tinted
/// on a red→orange→green scale by how good its value is relative to the others,
/// respecting whether smaller or larger is better ([lowerIsBetter]).
class MonthlyBars extends StatelessWidget {
  const MonthlyBars({
    super.key,
    required this.bars,
    required this.lowerIsBetter,
    required this.emptyLabel,
  });

  final List<MonthlyBar> bars;
  final bool lowerIsBetter;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final values = [
      for (final b in bars)
        if (b.value != null) b.value!,
    ];
    if (values.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            emptyLabel,
            style: TextStyle(
              fontFamily: DashTokens.fontUi,
              fontSize: 12.5,
              color: t.textTertiary,
            ),
          ),
        ),
      );
    }

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);

    // Crop the axis to the data instead of anchoring at 0, so month-to-month
    // differences are legible. Pad above/below, then snap the bounds to whole
    // multiples of a "nice" step for clean labels.
    final rawSpan = maxV - minV;
    final pad = rawSpan == 0 ? (maxV == 0 ? 1 : maxV * 0.15) : rawSpan * 0.4;
    final interval = niceAxisInterval((maxV + pad) - math.max(0.0, minV - pad));
    final minY = math.max(0.0, ((minV - pad) / interval).floorToDouble() * interval);
    final maxY = ((maxV + pad) / interval).ceilToDouble() * interval;
    // Integer axis labels once the step is >= 1, else one decimal (small units).
    final decimals = interval < 1 ? 1 : 0;

    return SizedBox(
      height: 170,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: minY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: t.hairline, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => t.overlaySurface,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                rod.toY.toStringAsFixed(1),
                TextStyle(
                  fontFamily: DashTokens.fontMono,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                ),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  // Skip the very top edge (avoids a clipped label overlapping
                  // the chart title); keep the cropped baseline label.
                  if (value >= meta.max) return const SizedBox.shrink();
                  return Text(
                    value.toStringAsFixed(decimals),
                    style: TextStyle(
                      fontFamily: DashTokens.fontMono,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: t.textTertiary,
                    ),
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= bars.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      bars[i].label,
                      style: TextStyle(
                        fontFamily: DashTokens.fontUi,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: t.textTertiary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < bars.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: bars[i].value ?? minY,
                    fromY: minY,
                    width: 9,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                    color: bars[i].value == null
                        ? Colors.transparent
                        : _efficiencyColor(bars[i].value!, minV, maxV, t),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Lerp red→orange→green by the value's "goodness" (0 worst … 1 best).
  Color _efficiencyColor(double value, double minV, double maxV, DashTokens t) {
    final span = maxV - minV;
    var goodness = span <= 0 ? 0.5 : (value - minV) / span;
    if (lowerIsBetter) goodness = 1 - goodness;
    return goodness <= 0.5
        ? Color.lerp(t.danger, t.accentOrange, goodness * 2)!
        : Color.lerp(t.accentOrange, const Color(0xFF4CAF6E), (goodness - 0.5) * 2)!;
  }
}

/// A "nice" grid step (1, 2, or 5 × a power of ten) giving ~4 lines up to
/// [maxY], so axis labels land on round numbers across any unit.
double niceAxisInterval(double maxY) {
  if (maxY <= 0) return 1;
  final rough = maxY / 4;
  final magnitude =
      math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  final normalized = rough / magnitude;
  final step = normalized < 1.5
      ? 1
      : normalized < 3
          ? 2
          : normalized < 7
              ? 5
              : 10;
  return step * magnitude;
}

/// One month in [MonthlyComboChart]: an expense bar (already summed, colored by
/// its dominant category) and a distance value (already in the display unit).
class ComboMonth {
  const ComboMonth({
    required this.label,
    required this.cost,
    required this.barColor,
    required this.distance,
  });

  final String label;
  final double cost;
  final Color barColor;
  final double distance;
}

/// Combo chart (design screen #5): monthly expense bars on the left axis, a
/// distance line on the right axis. Both share one plot area — the line chart's
/// x-range (-0.5…11.5) makes its points land on the bar centers. The right axis
/// and line are hidden when there's no distance data (no odometer records).
class MonthlyComboChart extends StatelessWidget {
  const MonthlyComboChart({
    super.key,
    required this.months,
    required this.currencySymbol,
    required this.expensesLegend,
    required this.distanceLegend,
    required this.emptyLabel,
  });

  final List<ComboMonth> months;
  final String currencySymbol;

  /// Legend labels for the expense bars and the distance line.
  final String expensesLegend;
  final String distanceLegend;
  final String emptyLabel;

  static const double _reservedSide = 40;
  static const double _reservedBottom = 20;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final maxCost = months.fold<double>(0, (m, e) => math.max(m, e.cost));
    final maxDistance = months.fold<double>(0, (m, e) => math.max(m, e.distance));
    final hasDistance = maxDistance > 0;

    if (maxCost <= 0 && !hasDistance) {
      return SizedBox(
        height: 170,
        child: Center(
          child: Text(
            emptyLabel,
            style: TextStyle(
              fontFamily: DashTokens.fontUi,
              fontSize: 12.5,
              color: t.textTertiary,
            ),
          ),
        ),
      );
    }

    final costInterval = niceAxisInterval(maxCost);
    final costMax = maxCost <= 0
        ? costInterval
        : (maxCost / costInterval).ceilToDouble() * costInterval;
    final distInterval = niceAxisInterval(maxDistance);
    final distMax = maxDistance <= 0
        ? distInterval
        : (maxDistance / distInterval).ceilToDouble() * distInterval;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
            children: [
              _bars(t, costMax, costInterval, hasDistance),
              if (hasDistance) _line(t, distMax, distInterval),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _legend(t, hasDistance),
      ],
    );
  }

  Widget _bars(DashTokens t, double costMax, double interval, bool hasDistance) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: costMax,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: t.hairline, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => t.overlaySurface,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '$currencySymbol${rod.toY.toStringAsFixed(0)}',
              TextStyle(
                fontFamily: DashTokens.fontMono,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          // Reserve the right gutter so the plot area matches the line chart's.
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: hasDistance,
              reservedSize: _reservedSide,
              getTitlesWidget: (_, _) => const SizedBox.shrink(),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _reservedSide,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value <= 0 || value >= meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '$currencySymbol${_compact(value)}',
                  style: _axisStyle(t),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _reservedBottom,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= months.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(months[i].label, style: _axisStyle(t)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < months.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: months[i].cost,
                  width: 9,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                  color: months[i].cost > 0
                      ? months[i].barColor
                      : Colors.transparent,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _line(DashTokens t, double distMax, double interval) {
    return LineChart(
      LineChartData(
        minX: -0.5,
        maxX: months.length - 0.5,
        minY: 0,
        maxY: distMax,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(
            sideTitles:
                SideTitles(showTitles: true, reservedSize: _reservedBottom),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _reservedSide,
              getTitlesWidget: (_, _) => const SizedBox.shrink(),
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _reservedSide,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value <= 0 || value >= meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(_compact(value), style: _axisStyle(t));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < months.length; i++)
                FlSpot(i.toDouble(), months[i].distance),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            color: t.accentBlue,
            barWidth: 2,
            dotData: FlDotData(
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: 2.5,
                color: t.accentBlue,
                strokeWidth: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(DashTokens t, bool hasDistance) {
    Widget item(Color color, String label, {bool line = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: line ? 14 : 9,
              height: line ? 2.5 : 9,
              decoration: BoxDecoration(
                color: color,
                shape: line ? BoxShape.rectangle : BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: DashTokens.fontUi,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
          ],
        );
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        item(t.textSecondary, expensesLegend),
        if (hasDistance) item(t.accentBlue, distanceLegend, line: true),
      ],
    );
  }

  TextStyle _axisStyle(DashTokens t) => TextStyle(
        fontFamily: DashTokens.fontMono,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: t.textTertiary,
      );

  /// Compact axis number: `1.2k` / `15k` for thousands, rounded otherwise.
  String _compact(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
    }
    return v.toStringAsFixed(0);
  }
}

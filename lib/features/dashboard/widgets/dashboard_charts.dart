import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
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

  static const double _height = 150;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);

    return Column(
      children: [
        if (total <= 0)
          _NoData(label: emptyLabel, height: _height)
        else
          SizedBox(
            height: _height,
            child: PieChart(
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
        _Legend(
          items: [
            for (final s in slices)
              _LegendItem(color: s.color, label: s.label, value: s.legendValue),
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

/// Per-month bar chart with efficiency coloring: each bar is tinted on a
/// red→orange→green scale by how good its value is relative to the others,
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
    if (values.isEmpty) return _NoData(label: emptyLabel, height: 150);

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);

    // Crop the axis to the data instead of anchoring at 0, so month-to-month
    // differences are legible. Pad above/below, then snap the bounds to whole
    // multiples of a "nice" step for clean labels.
    final rawSpan = maxV - minV;
    final pad = rawSpan == 0 ? (maxV == 0 ? 1 : maxV * 0.15) : rawSpan * 0.4;
    final interval = niceAxisInterval((maxV + pad) - math.max(0.0, minV - pad));
    final minY = math.max(0.0, ((minV - pad) / interval).floorToDouble() * interval);
    final maxY = _roundUp(maxV + pad, interval);
    // Integer axis labels once the step is >= 1, else one decimal (small units).
    final decimals = interval < 1 ? 1 : 0;

    return SizedBox(
      height: 170,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: minY,
          gridData: _horizontalGrid(t, interval),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: _barTooltip(
              t,
              (y) => Formatters.number(y, decimals: 1),
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
                    Formatters.number(value, decimals: decimals),
                    style: _axisStyle(t),
                  );
                },
              ),
            ),
            rightTitles: _hiddenTitles,
            topTitles: _hiddenTitles,
            bottomTitles: _monthTitles(t, [for (final b in bars) b.label], 22),
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
                    borderRadius: _barRadius,
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

/// A "nice" grid step (1, 2, or 5 × a power of ten) giving roughly [divisions]
/// lines up to [maxY], so axis labels land on round numbers across any unit.
double niceAxisInterval(double maxY, {int divisions = 4}) {
  if (maxY <= 0) return 1;
  final rough = maxY / divisions;
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
      return _NoData(label: emptyLabel, height: 170);
    }

    final costInterval = niceAxisInterval(maxCost, divisions: 3);
    final distInterval = niceAxisInterval(maxDistance, divisions: 3);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
            children: [
              _bars(t, _roundUp(maxCost, costInterval), costInterval, hasDistance),
              if (hasDistance)
                _line(t, _roundUp(maxDistance, distInterval), distInterval),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Legend(
          items: [
            _LegendItem(color: t.textSecondary, label: expensesLegend),
            if (hasDistance)
              _LegendItem(color: t.accentBlue, label: distanceLegend, line: true),
          ],
        ),
      ],
    );
  }

  Widget _bars(DashTokens t, double costMax, double interval, bool hasDistance) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: costMax,
        minY: 0,
        gridData: _horizontalGrid(t, interval),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: _barTooltip(
            t,
            (y) => Formatters.currencyRounded(y, currencySymbol),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: _hiddenTitles,
          // Reserve the right gutter so the plot area matches the line chart's.
          rightTitles: _blankTitles(_reservedSide, show: hasDistance),
          leftTitles: _valueTitles(t, interval),
          bottomTitles: _monthTitles(
            t,
            [for (final m in months) m.label],
            _reservedBottom,
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
                  borderRadius: _barRadius,
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
          topTitles: _hiddenTitles,
          // Reserve the bottom/left gutters to match the bar chart's plot area,
          // but draw nothing (the bar chart owns the month + cost labels).
          bottomTitles: _blankTitles(_reservedBottom),
          leftTitles: _blankTitles(_reservedSide),
          rightTitles: _valueTitles(t, interval),
        ),
        lineBarsData: [
          LineChartBarData(
            // Break the line over months with no odometer data instead of
            // dragging it down to zero, so it spans only the active range.
            spots: [
              for (var i = 0; i < months.length; i++)
                months[i].distance > 0
                    ? FlSpot(i.toDouble(), months[i].distance)
                    : FlSpot.nullSpot,
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

  /// Compact value axis for either side, labelling neither the zero baseline
  /// nor the top edge.
  AxisTitles _valueTitles(DashTokens t, double interval) => AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: _reservedSide,
          interval: interval,
          getTitlesWidget: (value, meta) {
            if (value <= 0 || value >= meta.max) {
              return const SizedBox.shrink();
            }
            // No currency symbol on the cost side — the "Expenses" legend
            // already names that axis, and repeating the symbol adds clutter.
            return Text(_compact(value), style: _axisStyle(t));
          },
        ),
      );

  /// Compact axis number: `1.2k` / `15k` for thousands, rounded otherwise.
  String _compact(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '${Formatters.number(k, decimals: k >= 10 ? 0 : 1)}k';
    }
    return Formatters.number(v);
  }
}

/// Placeholder standing in for a chart with nothing to plot, at the chart's
/// height so the card doesn't jump when data arrives.
class _NoData extends StatelessWidget {
  const _NoData({required this.label, required this.height});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DashTokens.fontUi,
            fontSize: 12.5,
            color: DashTokens.of(context).textTertiary,
          ),
        ),
      ),
    );
  }
}

/// Centered, wrapping row of legend entries.
class _Legend extends StatelessWidget {
  const _Legend({required this.items});

  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items,
    );
  }
}

/// A color swatch (a dot, or a short stroke for a [line] series), its label and
/// an optional value.
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.value,
    this.line = false,
  });

  final Color color;
  final String label;
  final String? value;
  final bool line;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Row(
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
        if (value != null) ...[
          const SizedBox(width: 5),
          Text(
            value!,
            style: TextStyle(
              fontFamily: DashTokens.fontMono,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

const _barRadius = BorderRadius.vertical(top: Radius.circular(3));

const _hiddenTitles = AxisTitles(sideTitles: SideTitles(showTitles: false));

/// An axis that takes up [reservedSize] but draws no labels, so charts stacked
/// on one plot area line up.
AxisTitles _blankTitles(double reservedSize, {bool show = true}) => AxisTitles(
      sideTitles: SideTitles(
        showTitles: show,
        reservedSize: reservedSize,
        getTitlesWidget: (_, _) => const SizedBox.shrink(),
      ),
    );

/// Bottom axis naming each bar group by its index into [labels].
AxisTitles _monthTitles(
  DashTokens t,
  List<String> labels,
  double reservedSize,
) =>
    AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: reservedSize,
        getTitlesWidget: (value, meta) {
          final i = value.toInt();
          if (i < 0 || i >= labels.length) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(labels[i], style: _axisStyle(t)),
          );
        },
      ),
    );

FlGridData _horizontalGrid(DashTokens t, double interval) => FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (_) => FlLine(color: t.hairline, strokeWidth: 1),
    );

/// Tooltip over a touched bar, showing its value through [format].
BarTouchTooltipData _barTooltip(
  DashTokens t,
  String Function(double y) format,
) =>
    BarTouchTooltipData(
      getTooltipColor: (_) => t.overlaySurface,
      getTooltipItem: (group, _, rod, _) => BarTooltipItem(
        format(rod.toY),
        TextStyle(
          fontFamily: DashTokens.fontMono,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: t.textPrimary,
        ),
      ),
    );

TextStyle _axisStyle(DashTokens t) => TextStyle(
      fontFamily: DashTokens.fontMono,
      fontSize: 9,
      fontWeight: FontWeight.w600,
      color: t.textTertiary,
    );

/// [value] rounded up to a whole multiple of [interval]; one step when there
/// is nothing to fit.
double _roundUp(double value, double interval) => value <= 0
    ? interval
    : (value / interval).ceilToDouble() * interval;

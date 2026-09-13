import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/features/dashboard/widgets/dashboard_charts.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget chart) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: chart)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  const months = ['Oct', 'Nov', 'Dec', 'Jan'];

  testWidgets('donut keeps every category in the legend, even at zero',
      (tester) async {
    await pump(
      tester,
      const DonutChart(
        emptyLabel: 'nothing',
        slices: [
          ChartSlice(label: 'Fuel', value: 30, color: Colors.amber, legendValue: r'$30'),
          ChartSlice(label: 'Tax', value: 0, color: Colors.red, legendValue: r'$0'),
        ],
      ),
    );
    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Tax'), findsOneWidget);
    expect(find.text(r'$0'), findsOneWidget);
    expect(find.text('nothing'), findsNothing);
  });

  testWidgets('a donut with only zero slices shows the empty label',
      (tester) async {
    await pump(
      tester,
      const DonutChart(
        emptyLabel: 'nothing',
        slices: [ChartSlice(label: 'Tax', value: 0, color: Colors.red)],
      ),
    );
    expect(find.text('nothing'), findsOneWidget);
    expect(find.text('Tax'), findsOneWidget);
  });

  testWidgets('monthly bars label each month and skip empty ones',
      (tester) async {
    await pump(
      tester,
      MonthlyBars(
        lowerIsBetter: true,
        emptyLabel: 'nothing',
        bars: [
          for (final (i, label) in months.indexed)
            MonthlyBar(label: label, value: i.isEven ? 6.5 + i : null),
        ],
      ),
    );
    for (final label in months) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('nothing'), findsNothing);
  });

  testWidgets('monthly bars without a value show the empty label',
      (tester) async {
    await pump(
      tester,
      MonthlyBars(
        lowerIsBetter: false,
        emptyLabel: 'nothing',
        bars: [for (final label in months) MonthlyBar(label: label, value: null)],
      ),
    );
    expect(find.text('nothing'), findsOneWidget);
  });

  testWidgets('combo chart names the distance series only when there is one',
      (tester) async {
    ComboMonth month(String label, double distance) => ComboMonth(
          label: label,
          cost: 120,
          barColor: Colors.blue,
          distance: distance,
        );
    Widget chart(double distance) => MonthlyComboChart(
          currencySymbol: r'$',
          expensesLegend: 'Expenses',
          distanceLegend: 'Distance (km)',
          emptyLabel: 'nothing',
          months: [for (final label in months) month(label, distance)],
        );

    await pump(tester, chart(800));
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Distance (km)'), findsOneWidget);
    expect(find.text('Oct'), findsOneWidget);

    await pump(tester, chart(0));
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Distance (km)'), findsNothing);
  });

  testWidgets('combo chart with no cost and no distance shows the empty label',
      (tester) async {
    await pump(
      tester,
      MonthlyComboChart(
        currencySymbol: r'$',
        expensesLegend: 'Expenses',
        distanceLegend: 'Distance',
        emptyLabel: 'nothing',
        months: [
          for (final label in months)
            ComboMonth(label: label, cost: 0, barColor: Colors.blue, distance: 0),
        ],
      ),
    );
    expect(find.text('nothing'), findsOneWidget);
    expect(find.text('Expenses'), findsNothing);
  });
}

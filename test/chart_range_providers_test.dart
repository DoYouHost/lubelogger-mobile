import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/chart_range.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const economy = (vehicleId: 1, chart: DashboardChart.economy);
const expensesByType = (vehicleId: 1, chart: DashboardChart.expensesByType);
const expensesDistance = (vehicleId: 1, chart: DashboardChart.expensesDistance);

void main() {
  Future<ProviderContainer> container([
    Map<String, Object> prefs = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(prefs);
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('charts open on three months until Settings says otherwise', () async {
    final c = await container();
    expect(
      c.read(chartRangeProvider(economy)),
      const PresetRange(ChartRangePreset.threeMonths),
    );

    await c.read(chartDefaultRangeProvider.notifier).set(ChartRangePreset.year);
    expect(
      c.read(chartRangeProvider(economy)),
      const PresetRange(ChartRangePreset.year),
    );
    final reloaded = await container({'chart_default_range': 'year'});
    expect(reloaded.read(chartDefaultRangeProvider), ChartRangePreset.year);
  });

  test(
    'a stored name the app no longer knows falls back to the default',
    () async {
      final c = await container({'chart_default_range': 'decade'});
      expect(c.read(chartDefaultRangeProvider), ChartRangePreset.threeMonths);
    },
  );

  test(
    'a range picked on one chart leaves other charts and vehicles alone',
    () async {
      final c = await container();
      final custom = CustomRange(DateTime(2020, 7, 1), DateTime(2020, 8, 1));
      c.read(chartRangeOverridesProvider.notifier).set(economy, custom);

      expect(c.read(chartRangeProvider(economy)), custom);
      expect(
        c.read(chartRangeProvider(expensesByType)),
        const PresetRange(ChartRangePreset.threeMonths),
      );
      expect(
        c.read(
          chartRangeProvider((vehicleId: 2, chart: DashboardChart.economy)),
        ),
        const PresetRange(ChartRangePreset.threeMonths),
      );
    },
  );

  test('picking the default preset drops the override', () async {
    final c = await container();
    final overrides = c.read(chartRangeOverridesProvider.notifier);
    overrides.set(economy, const PresetRange(ChartRangePreset.oneMonth));
    overrides.set(economy, const PresetRange(ChartRangePreset.threeMonths));
    expect(c.read(chartRangeOverridesProvider), isEmpty);
  });

  test('changing the default resets every chart to it', () async {
    final c = await container();
    c
        .read(chartRangeOverridesProvider.notifier)
        .set(expensesDistance, const PresetRange(ChartRangePreset.oneMonth));
    await c
        .read(chartDefaultRangeProvider.notifier)
        .set(ChartRangePreset.sixMonths);
    expect(
      c.read(chartRangeProvider(expensesDistance)),
      const PresetRange(ChartRangePreset.sixMonths),
    );
  });
}

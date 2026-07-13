import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/formatters.dart';
import 'package:lubelogger_mobile/core/settings/units_settings.dart';

void main() {
  group('Formatters.fuelEconomyValue', () {
    // Real record from the live server: 626 km on 50.370 L, whose server-computed
    // metric fuel economy is 8.0463 L/100 km. Verifies our conversions line up.
    const distanceKm = 626.0;
    const litres = 50.370;
    const metric = MeasurementSystem.metric;

    test('L/100km matches the server-computed value', () {
      final v = Formatters.fuelEconomyValue(
          distanceKm, litres, metric, FuelEconomyUnit.l100km);
      expect(v, closeTo(8.0463, 0.001));
    });

    test('km/L is distance over volume', () {
      final v = Formatters.fuelEconomyValue(
          distanceKm, litres, metric, FuelEconomyUnit.kmPerL);
      expect(v, closeTo(12.428, 0.001));
    });

    test('US and UK MPG convert from the metric base', () {
      final us = Formatters.fuelEconomyValue(
          distanceKm, litres, metric, FuelEconomyUnit.mpg)!;
      final uk = Formatters.fuelEconomyValue(
          distanceKm, litres, metric, FuelEconomyUnit.mpgUk)!;
      // 8.05 L/100km ≈ 29.2 US MPG ≈ 35.1 UK MPG.
      expect(us, closeTo(29.23, 0.1));
      expect(uk, closeTo(35.10, 0.1));
      expect(uk, greaterThan(us)); // UK gallon is larger.
    });

    test('imperial base treats raw values as miles + US gallons', () {
      // Same raw numbers, but interpreted as 626 mi on 50.37 US gal.
      final mpg = Formatters.fuelEconomyValue(
          626, 50.370, MeasurementSystem.imperial, FuelEconomyUnit.mpg);
      expect(mpg, closeTo(626 / 50.370, 0.001)); // raw miles / raw gallons
    });

    test('returns null for zero distance or volume', () {
      expect(
        Formatters.fuelEconomyValue(0, 10, metric, FuelEconomyUnit.l100km),
        isNull,
      );
      expect(
        Formatters.fuelEconomyValue(100, 0, metric, FuelEconomyUnit.l100km),
        isNull,
      );
    });
  });

  group('Formatters.distance', () {
    test('metric base shows km as-is and converts to mi', () {
      expect(Formatters.distance(320775, MeasurementSystem.metric,
          DistanceUnit.km), '320,775 km');
      expect(Formatters.distance(320775, MeasurementSystem.metric,
          DistanceUnit.mi), '199,320 mi');
    });

    test('imperial base treats the raw value as miles', () {
      expect(Formatters.distance(100000, MeasurementSystem.imperial,
          DistanceUnit.mi), '100,000 mi');
    });
  });
}

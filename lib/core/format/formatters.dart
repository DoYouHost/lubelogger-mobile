import 'package:intl/intl.dart';

import '../settings/units_settings.dart';

/// Number/currency formatting for readouts. Grouping uses the `en` pattern
/// (thousands separators), which matches the design's sample data; the
/// server's currency symbol is prepended verbatim.
class Formatters {
  Formatters._();

  static final NumberFormat _integer = NumberFormat('#,##0');
  static final NumberFormat _money = NumberFormat('#,##0.00');
  static final NumberFormat _economy = NumberFormat('#,##0.0');

  // Canonical-unit conversion constants (from km / litres).
  static const double _miPerKm = 0.621371;
  static const double _usGalPerL = 0.264172;
  static const double _ukGalPerL = 0.219969;

  /// Odometer / distance value as a grouped integer, e.g. `320,775`.
  static String odometer(double value) => _integer.format(value.round());

  /// Money value with the currency [symbol], e.g. `$5,728.01`.
  static String currency(double value, String symbol) =>
      '$symbol${_money.format(value)}';

  /// Raw stored distance [rawValue] (in [base]'s distance unit) converted to the
  /// display [unit] and labelled, e.g. `320,775 km` or `199,316 mi`.
  static String distance(
    double rawValue,
    MeasurementSystem base,
    DistanceUnit unit,
  ) {
    final km = rawValue * base.kmPerUnit;
    return '${_integer.format((km * unit.fromKm).round())} ${unit.label}';
  }

  /// Fuel-economy value from raw stored distance + volume (each in [base]'s
  /// units), expressed in [unit]. Returns null when inputs can't yield a rate
  /// (zero distance/volume). See [fuelEconomy] for the labelled string.
  static double? fuelEconomyValue(
    double rawDistance,
    double rawVolume,
    MeasurementSystem base,
    FuelEconomyUnit unit,
  ) {
    final km = rawDistance * base.kmPerUnit;
    final litres = rawVolume * base.litresPerUnit;
    if (km <= 0 || litres <= 0) return null;
    return switch (unit) {
      FuelEconomyUnit.l100km => litres / km * 100,
      FuelEconomyUnit.kmPerL => km / litres,
      FuelEconomyUnit.mpg => (km * _miPerKm) / (litres * _usGalPerL),
      FuelEconomyUnit.mpgUk => (km * _miPerKm) / (litres * _ukGalPerL),
    };
  }

  /// Labelled fuel economy, e.g. `8.0 L/100 km`, or `—` when not computable.
  static String fuelEconomy(
    double rawDistance,
    double rawVolume,
    MeasurementSystem base,
    FuelEconomyUnit unit,
  ) {
    final value = fuelEconomyValue(rawDistance, rawVolume, base, unit);
    if (value == null) return '—';
    return '${_economy.format(value)} ${unit.label}';
  }
}

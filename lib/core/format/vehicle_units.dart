import '../settings/units_settings.dart';
import 'formatters.dart';

const _hours = 'h';
const _kilowattHours = 'kWh';

/// The user's display units, narrowed by the two vehicle flags LubeLogger also
/// branches on before labelling anything (`StaticHelper.GetFuelEconomyUnit`):
/// an hour-metered vehicle logs engine hours where others log distance, and an
/// electric one logs kWh where others log litres or gallons.
class VehicleUnits {
  const VehicleUnits(
    this.settings, {
    this.isElectric = false,
    this.useHours = false,
  });

  final UnitsSettings settings;
  final bool isElectric;
  final bool useHours;

  /// `km`, `mi` or `h`.
  String get distanceLabel => useHours ? _hours : settings.distance.label;

  /// Unit of a single fill-up or charging session: `L`, `gal` or `kWh`.
  String get consumptionLabel =>
      isElectric ? _kilowattHours : settings.base.volumeLabel;

  /// `L/100 km`, `MPG`, `kWh/100 km`, `h/gal`, …
  String get economyLabel {
    if (!isElectric && !useHours) return settings.economy.label;
    final distance = useHours
        ? _hours
        : (settings.economy == FuelEconomyUnit.mpg ||
                settings.economy == FuelEconomyUnit.mpgUk)
            ? DistanceUnit.mi.label
            : DistanceUnit.km.label;
    final consumption = isElectric
        ? _kilowattHours
        : switch (settings.economy) {
            FuelEconomyUnit.mpg => 'gal',
            FuelEconomyUnit.mpgUk => 'gal (UK)',
            _ => 'L',
          };
    return settings.economy == FuelEconomyUnit.l100km
        ? '$consumption/100 $distance'
        : '$distance/$consumption';
  }

  bool get lowerIsBetter => settings.economy.lowerIsBetter;

  String formatDate(DateTime date) => settings.formatDate(date);

  /// A stored odometer reading in the unit the user picked. Engine hours are
  /// stored and shown as hours, so nothing converts.
  double toDisplayDistance(double stored) => useHours
      ? stored
      : Formatters.distanceValue(stored, settings.base, settings.distance);

  /// [toDisplayDistance] rounded, for the odometer form fields, which accept
  /// whole numbers only. Converting back therefore lands within a unit of the
  /// original — exactly on it when the display unit matches the stored one.
  double toDisplayOdometer(double stored) =>
      toDisplayDistance(stored).roundToDouble();

  /// The inverse of [toDisplayDistance], for what a form sends back.
  double toStoredDistance(double display) => useHours
      ? display
      : Formatters.storedDistance(display, settings.base, settings.distance);

  double? economyValue(double storedDistance, double storedConsumption) =>
      Formatters.fuelEconomyValue(
        storedDistance,
        storedConsumption,
        settings.base,
        settings.economy,
        isElectric: isElectric,
        useHours: useHours,
      );

  /// A stored odometer reading, converted, grouped and labelled.
  String distance(double stored) =>
      '${Formatters.odometer(toDisplayDistance(stored))} $distanceLabel';

  /// Labelled economy, or `—` when the inputs can't yield a rate.
  String economy(double storedDistance, double storedConsumption) {
    final value = economyValue(storedDistance, storedConsumption);
    return value == null
        ? '—'
        : '${Formatters.number(value, decimals: 1)} $economyLabel';
  }
}

// User-selectable display units. LubeLogger's API does NOT expose (nor let us
// read) the units the server stores values in — its fuel-economy endpoints only
// take useMPG/useUKMPG as request params and never convert the distance base.
// So the app keeps two independent settings: [MeasurementSystem] (how to
// interpret the raw stored numbers) and the display units below. Raw values are
// normalized to a canonical base (km, litres) via the measurement system, then
// converted to the chosen display unit. Currency is a pure symbol relabel —
// amounts are never converted, matching how LubeLogger itself works.

/// How the LubeLogger server stores raw distance/volume values. [imperial]
/// assumes miles + US gallons (UK-gallon storage is an unsupported edge case;
/// pick metric or use MPG (UK) as the display unit instead).
enum MeasurementSystem {
  metric(kmPerUnit: 1, litresPerUnit: 1),
  imperial(kmPerUnit: 1.609344, litresPerUnit: 3.785411784);

  const MeasurementSystem({required this.kmPerUnit, required this.litresPerUnit});

  /// Kilometres per one stored distance unit.
  final double kmPerUnit;

  /// Litres per one stored volume unit.
  final double litresPerUnit;
}

/// Currency symbol shown next to money values. [auto] defers to the server's
/// `currencySymbol` from `GET /api/info`; the others force a fixed symbol.
enum CurrencyOption {
  auto(null),
  usd(r'$'),
  eur('€'),
  gbp('£'),
  pln('zł');

  const CurrencyOption(this.fixedSymbol);

  /// The forced symbol, or null for [auto] (resolved against the server info).
  final String? fixedSymbol;
}

/// Distance / odometer unit. [fromKm] converts a metric-base value to this unit.
enum DistanceUnit {
  km('km', 1),
  mi('mi', 0.621371);

  const DistanceUnit(this.label, this.fromKm);

  final String label;
  final double fromKm;
}

/// Fuel-economy readout unit. Labels use conventional notation (not localized).
enum FuelEconomyUnit {
  l100km('L/100 km'),
  mpg('MPG'),
  mpgUk('MPG (UK)'),
  kmPerL('km/L');

  const FuelEconomyUnit(this.label);

  final String label;
}

/// The user's display-unit preferences. Persisted locally (SharedPreferences),
/// independent of the server's own locale settings.
class UnitsSettings {
  const UnitsSettings({
    this.base = MeasurementSystem.metric,
    this.currency = CurrencyOption.auto,
    this.distance = DistanceUnit.km,
    this.economy = FuelEconomyUnit.l100km,
  });

  factory UnitsSettings.fromJson(Map<String, dynamic> json) => UnitsSettings(
        base: _byName(MeasurementSystem.values, json['base']) ??
            MeasurementSystem.metric,
        currency: _byName(CurrencyOption.values, json['currency']) ??
            CurrencyOption.auto,
        distance: _byName(DistanceUnit.values, json['distance']) ??
            DistanceUnit.km,
        economy: _byName(FuelEconomyUnit.values, json['economy']) ??
            FuelEconomyUnit.l100km,
      );

  /// How the server stores raw values (metric km/L vs imperial mi/US-gal).
  final MeasurementSystem base;
  final CurrencyOption currency;
  final DistanceUnit distance;
  final FuelEconomyUnit economy;

  Map<String, dynamic> toJson() => {
        'base': base.name,
        'currency': currency.name,
        'distance': distance.name,
        'economy': economy.name,
      };

  UnitsSettings copyWith({
    MeasurementSystem? base,
    CurrencyOption? currency,
    DistanceUnit? distance,
    FuelEconomyUnit? economy,
  }) =>
      UnitsSettings(
        base: base ?? this.base,
        currency: currency ?? this.currency,
        distance: distance ?? this.distance,
        economy: economy ?? this.economy,
      );

  static T? _byName<T extends Enum>(List<T> values, Object? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

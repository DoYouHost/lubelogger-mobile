import 'package:intl/intl.dart';

import '../settings/units_settings.dart';

/// Number/currency formatting for readouts.
///
/// Plain numbers (odometer, fuel economy, chart axes) follow the locale set via
/// [useLocale] — the device locale at startup, or `intl`'s default (`en_US`)
/// when unset. Money follows the *currency* instead: the symbol decides the
/// whole layout, so `zł` always reads `5 728,01 zł` and `$` always `$5,728.01`,
/// whatever the device is set to. See [_currencyLocales].
class Formatters {
  Formatters._();

  /// Locale whose number conventions belong to each currency — symbol side,
  /// grouping and decimal separator. Keyed by the trimmed, lower-cased symbol
  /// or ISO code the server reports (`currencySymbol` from `/api/info`, which is
  /// free text, hence both spellings). Unlisted currencies fall back to the
  /// device locale.
  static const Map<String, String> _currencyLocales = {
    r'$': 'en_US', 'usd': 'en_US', r'us$': 'en_US',
    r'ca$': 'en_CA', 'cad': 'en_CA',
    r'a$': 'en_AU', 'aud': 'en_AU',
    r'r$': 'pt_BR', 'brl': 'pt_BR',
    '£': 'en_GB', 'gbp': 'en_GB',
    '€': 'de_DE', 'eur': 'de_DE',
    'zł': 'pl_PL', 'pln': 'pl_PL',
    'kč': 'cs_CZ', 'czk': 'cs_CZ',
    'ft': 'hu_HU', 'huf': 'hu_HU',
    'lei': 'ro_RO', 'ron': 'ro_RO',
    'лв': 'bg_BG', 'bgn': 'bg_BG',
    // Suffixed, space-grouped, comma decimal — same shape for SEK/NOK/DKK.
    'kr': 'sv_SE', 'sek': 'sv_SE', 'nok': 'nb_NO', 'dkk': 'da_DK',
    'chf': 'de_CH',
    '₽': 'ru_RU', 'rub': 'ru_RU',
    '₴': 'uk_UA', 'uah': 'uk_UA',
    '₺': 'tr_TR', 'try': 'tr_TR',
    '¥': 'ja_JP', 'jpy': 'ja_JP',
    '₩': 'ko_KR', 'krw': 'ko_KR',
    '₹': 'en_IN', 'inr': 'en_IN',
  };

  static String? _locale;
  static final Map<int, NumberFormat> _plainFormats = {};
  static final Map<String, NumberFormat> _moneyFormats = {};

  /// Adopts [locale] (e.g. `pl_PL`) for every readout; an unknown locale falls
  /// back to `intl`'s default. Cached formats are dropped so they rebuild.
  static void useLocale(String? locale) {
    _locale = _resolve(locale);
    _plainFormats.clear();
    _moneyFormats.clear();
  }

  /// The closest locale `intl` has number data for, or null for its default.
  /// `intl` throws rather than falling back, so region-only variants are
  /// narrowed to the language (`pl_PL` → `pl`) and anything unknown dropped.
  static String? _resolve(String? locale) {
    if (locale == null || locale.isEmpty) return null;
    final canonical = Intl.canonicalizedLocale(locale);
    if (NumberFormat.localeExists(canonical)) return canonical;
    final language = canonical.split('_').first;
    return NumberFormat.localeExists(language) ? language : null;
  }

  /// Grouped format with exactly [decimals] decimal places.
  static NumberFormat _plain(int decimals) => _plainFormats.putIfAbsent(
        decimals,
        () => NumberFormat(
          decimals == 0 ? '#,##0' : '#,##0.${'0' * decimals}',
          _locale,
        ),
      );

  /// Money format for [symbol] with [decimalDigits] decimals, laid out by the
  /// currency's own locale ([_currencyLocales]) — its currency pattern decides
  /// the symbol's side (`$5,728.01` vs `5 728,01 zł`).
  static NumberFormat _money(String symbol, int decimalDigits) =>
      _moneyFormats.putIfAbsent(
        '$decimalDigits|$symbol',
        () => NumberFormat.currency(
          locale: _localeForCurrency(symbol),
          symbol: symbol,
          decimalDigits: decimalDigits,
        ),
      );

  /// The currency's own locale, or the device locale for an unlisted symbol.
  static String? _localeForCurrency(String symbol) =>
      _resolve(_currencyLocales[symbol.trim().toLowerCase()]) ?? _locale;

  // Canonical-unit conversion constants (from km / litres).
  static const double _miPerKm = 0.621371;
  static const double _usGalPerL = 0.264172;
  static const double _ukGalPerL = 0.219969;

  /// Grouped number with [decimals] decimal places, e.g. `1,234.5` / `1 234,5`.
  /// For bare readouts (fuel economy, chart axes) that carry no currency.
  static String number(double value, {int decimals = 0}) =>
      _plain(decimals).format(value);

  /// Odometer / distance value as a grouped integer, e.g. `320,775`.
  static String odometer(double value) => _plain(0).format(value.round());

  /// Money value with the currency [symbol], e.g. `$5,728.01` or `5728,01 zł`.
  static String currency(double value, String symbol) =>
      _money(symbol, 2).format(value);

  /// Money value rounded to whole units — for tight spots like chart tooltips.
  static String currencyRounded(double value, String symbol) =>
      _money(symbol, 0).format(value);

  /// Raw stored distance [rawValue] (in [base]'s distance unit) converted to the
  /// numeric display [unit] value (unlabelled) — for charts.
  static double distanceValue(
    double rawValue,
    MeasurementSystem base,
    DistanceUnit unit,
  ) =>
      rawValue * base.kmPerUnit * unit.fromKm;

  /// Raw stored distance [rawValue] (in [base]'s distance unit) converted to the
  /// display [unit] and labelled, e.g. `320,775 km` or `199,316 mi`.
  static String distance(
    double rawValue,
    MeasurementSystem base,
    DistanceUnit unit,
  ) =>
      '${_plain(0).format(distanceValue(rawValue, base, unit).round())} '
      '${unit.label}';

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
    return '${_plain(1).format(value)} ${unit.label}';
  }
}

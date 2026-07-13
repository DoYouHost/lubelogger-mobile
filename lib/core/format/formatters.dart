import 'package:intl/intl.dart';

/// Number/currency formatting for readouts. Grouping uses the `en` pattern
/// (thousands separators), which matches the design's sample data; the
/// server's currency symbol is prepended verbatim.
class Formatters {
  Formatters._();

  static final NumberFormat _integer = NumberFormat('#,##0');
  static final NumberFormat _money = NumberFormat('#,##0.00');

  /// Odometer / distance value as a grouped integer, e.g. `320,775`.
  static String odometer(double value) => _integer.format(value.round());

  /// Money value with the server's currency [symbol], e.g. `$5,728.01`.
  static String currency(double value, String symbol) =>
      '$symbol${_money.format(value)}';
}

// Numeric record-form entry: plain free-form typing, no leading zeros and no
// fixed decimal places.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/features/vehicle/forms/form_fields.dart';

/// Runs [text] through the decimal formatters as if typed char by char, so a
/// rejected edit leaves the field on its previous value.
String typeDecimal(String text) {
  var value = TextEditingValue.empty;
  for (final ch in text.split('')) {
    final next = TextEditingValue(
      text: value.text + ch,
      selection: TextSelection.collapsed(offset: value.text.length + 1),
    );
    value = decimalInputFormatters.first.formatEditUpdate(value, next);
  }
  return value.text;
}

void main() {
  group('decimal entry', () {
    test('keeps digits and one separator exactly as typed', () {
      expect(typeDecimal('213.79'), '213.79');
      expect(typeDecimal('45,6'), '45,6');
      expect(typeDecimal('7'), '7');
      expect(typeDecimal('.5'), '.5');
    });

    test('rejects a second separator and any non-numeric character', () {
      expect(typeDecimal('1.2.3'), '1.23');
      expect(typeDecimal('1,2.3'), '1,23');
      expect(typeDecimal('12a3'), '123');
      expect(typeDecimal('-5'), '5');
    });

    test('never pads or shifts digits', () {
      expect(typeDecimal('2'), '2');
      expect(typeDecimal('21'), '21');
    });
  });

  group('formatFormNumber', () {
    test('whole values carry no decimals', () {
      expect(formatFormNumber(320775.0), '320775');
      expect(formatFormNumber(0), '0');
      expect(formatFormNumber(12), '12');
    });

    test('fractions keep only the digits they need', () {
      expect(formatFormNumber(45.5), '45.5');
      expect(formatFormNumber(213.79), '213.79');
      expect(formatFormNumber(0.05), '0.05');
    });

    test('round-trips through the form parser', () {
      for (final v in [0, 7, 45.5, 213.79, 320775.0]) {
        expect(parseFormNumber(formatFormNumber(v)), v);
      }
    });
  });
}

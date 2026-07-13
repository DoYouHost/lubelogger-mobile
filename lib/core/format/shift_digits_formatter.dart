import 'package:flutter/services.dart';

/// Digit-entry formatter that behaves like a mechanical odometer / cash
/// register tape: each typed digit shifts in from the right and existing
/// digits shift left, rather than being inserted at the cursor position (e.g.
/// typing 2, 1, 3, 7, 9 with [decimalDigits] = 2 produces 0.02, 0.21, 2.13,
/// 21.37, 213.79). [minIntegerDigits] zero-pads the whole part while short,
/// mimicking a fixed-width mechanical display.
///
/// Stateless by design: the running value is recovered from `oldValue.text`
/// (always our own last output) rather than an instance field, so a fresh
/// formatter instance on every build (the common case, since widgets rebuild)
/// can't lose track of what's been typed so far.
class ShiftDigitsFormatter extends TextInputFormatter {
  const ShiftDigitsFormatter({this.decimalDigits = 0, this.minIntegerDigits = 1});

  final int decimalDigits;
  final int minIntegerDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final previous = _rawOf(oldValue.text);
    BigInt raw;

    if (newValue.text.length > oldValue.text.length &&
        newValue.text.startsWith(oldValue.text)) {
      // Typed (or pasted at the end): shift each new digit in from the right.
      raw = previous;
      final added = newValue.text.substring(oldValue.text.length);
      for (final ch in added.split('')) {
        final d = int.tryParse(ch);
        if (d != null) raw = raw * BigInt.from(10) + BigInt.from(d);
      }
    } else if (newValue.text.length < oldValue.text.length &&
        oldValue.text.startsWith(newValue.text)) {
      // Backspace: drop one least-significant digit per removed character.
      final removed = oldValue.text.length - newValue.text.length;
      raw = previous;
      for (var i = 0; i < removed; i++) {
        raw = raw ~/ BigInt.from(10);
      }
    } else {
      // Selection replace / autofill: reparse from scratch.
      raw = _rawOf(newValue.text);
    }

    final text = _format(raw);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Recovers the raw digit value behind a previously-formatted string (or any
  /// pasted text) by stripping non-digits.
  static BigInt _rawOf(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? BigInt.zero : BigInt.parse(digits);
  }

  /// Canonical display text for a known [value] (e.g. prefilling an edit
  /// form), matching exactly what typing its digits would have produced.
  String seed(num value) {
    final fixed = value.toStringAsFixed(decimalDigits);
    final digits = fixed.replaceAll(RegExp(r'[^0-9]'), '');
    final raw = digits.isEmpty ? BigInt.zero : BigInt.parse(digits);
    return _format(raw);
  }

  String _format(BigInt raw) {
    var digits = raw.toString();
    final minLength = decimalDigits + minIntegerDigits;
    if (digits.length < minLength) digits = digits.padLeft(minLength, '0');
    if (decimalDigits == 0) return digits;
    final splitAt = digits.length - decimalDigits;
    return '${digits.substring(0, splitAt)}.${digits.substring(splitAt)}';
  }
}

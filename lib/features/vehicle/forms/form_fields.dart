import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Parse a user-entered number, tolerating a comma decimal separator. Shared by
/// the record forms' numeric field validators/submitters.
num? parseFormNumber(String? raw) {
  if (raw == null) return null;
  return num.tryParse(raw.trim().replaceAll(',', '.'));
}

/// Digits with at most one decimal separator (`.` or `,`) — nothing else.
final _decimalEntry = RegExp(r'^\d*[.,]?\d*$');

/// Free-form decimal entry: the field keeps whatever the user types as long as
/// it stays a plain number — no forced width, leading zeros or fixed decimals.
/// Edits that would break that are rejected outright.
final List<TextInputFormatter> decimalInputFormatters = [
  TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        _decimalEntry.hasMatch(newValue.text) ? newValue : oldValue,
  ),
];

/// Free-form whole-number entry (odometers, quantities of whole units).
final List<TextInputFormatter> integerInputFormatters = [
  FilteringTextInputFormatter.digitsOnly,
];

/// Keyboard for a numeric field — decimal point included when [decimal].
TextInputType numberKeyboard({required bool decimal}) =>
    TextInputType.numberWithOptions(decimal: decimal);

/// Renders [value] the way a person would type it, for prefilling a numeric
/// field on edit: no grouping, no padding, no trailing zeros.
String formatFormNumber(num value) {
  if (value == value.truncateToDouble()) return value.toInt().toString();
  // toStringAsFixed avoids exponent notation; drop the zeros it pads with.
  return value
      .toStringAsFixed(4)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'[.,]$'), '');
}

/// Read-only date display with a gold calendar button (design #3). Shared across
/// the record forms. [label] overrides the default "Date" field label.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.text,
    required this.onPick,
    this.label,
  });

  final String text;
  final VoidCallback? onPick;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: dashFieldDecoration(
              t,
              labelText: label ?? l10n.colDate,
            ),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: DashTokens.fontMono,
                fontSize: 13.5,
                color: t.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          height: 48,
          child: FilledButton(
            style: dashPrimaryButtonStyle(
              t,
            ).copyWith(padding: const WidgetStatePropertyAll(EdgeInsets.zero)),
            onPressed: onPick,
            child: const Icon(Icons.calendar_month, size: 20),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Parse a user-entered number, tolerating a comma decimal separator. Shared by
/// the record forms' numeric field validators/submitters.
num? parseFormNumber(String? raw) {
  if (raw == null) return null;
  return num.tryParse(raw.trim().replaceAll(',', '.'));
}

/// Read-only date display with a gold calendar button (design #3). Shared across
/// the record forms.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.text, required this.onPick});

  final String text;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: dashFieldDecoration(t, labelText: l10n.colDate),
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
            style: dashPrimaryButtonStyle(t).copyWith(
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            ),
            onPressed: onPick,
            child: const Icon(Icons.calendar_month, size: 20),
          ),
        ),
      ],
    );
  }
}

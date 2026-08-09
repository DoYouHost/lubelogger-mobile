import 'package:flutter/material.dart';

import '../../core/diagnostics/diagnostic_recorder.dart';
import '../../core/diagnostics/log_event.dart';
import '../../core/diagnostics/log_tag.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';

/// The app's destructive confirmation: cancel, and a red confirm.
///
/// One implementation for every delete in the app — the eight record forms and
/// both steps of the vehicle delete used to carry byte-identical copies of it.
/// That matters for more than duplication: a dialog is its own route, so it sits
/// outside the surface of the form that opened it, and naming its two buttons
/// here is the only way a log can tell "the user confirmed" from "the user
/// backed out". The answer is recorded too, since the alternative — inferring it
/// from whether a DELETE followed — is exactly the reasoning a report should not
/// need.
///
/// [what] names the thing being deleted for the log (`record`, `vehicle`); the
/// title and message are user-facing text and never go in.
Future<bool> confirmDelete(
  BuildContext context, {
  required String what,
  String? title,
  String? message,
  String? confirmLabel,
}) {
  final l10n = AppLocalizations.of(context);
  return _confirm(
    context,
    what: what,
    title: title ?? l10n.confirmDeleteTitle,
    message: message ?? l10n.confirmDeleteMessage,
    confirmLabel: confirmLabel ?? l10n.actionDelete,
  );
}

/// The same dialog for something that is questionable rather than destructive —
/// an odometer reading below the previous one, say. Nothing is lost either way,
/// so the confirm is not painted as a danger.
Future<bool> confirmRisky(
  BuildContext context, {
  required String what,
  required String title,
  required String message,
  required String confirmLabel,
}) =>
    _confirm(
      context,
      what: what,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      danger: false,
    );

Future<bool> _confirm(
  BuildContext context, {
  required String what,
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = true,
}) async {
  final l10n = AppLocalizations.of(context);
  final t = DashTokens.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => logSurface(
      'confirm.$what',
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.actionCancel),
          ).tagged('confirm.cancel'),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              confirmLabel,
              style: danger ? TextStyle(color: t.danger) : null,
            ),
          ).tagged('confirm.ok'),
        ],
      ),
    ),
  );

  DiagnosticRecorder.active?.add(
    LogSource.ui,
    'confirm',
    fields: {
      'id': 'confirm.$what',
      'reason': (confirmed ?? false) ? 'confirmed' : 'cancelled',
    },
  );
  return confirmed ?? false;
}

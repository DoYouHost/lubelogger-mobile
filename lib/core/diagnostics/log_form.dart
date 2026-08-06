import 'package:flutter/widgets.dart';

import 'diagnostic_recorder.dart';
import 'log_event.dart';
import 'log_tag.dart';

/// Runs [form]'s validators and records the verdict under the surface the form
/// is on.
///
/// A submit the form refuses is the one user action that leaves no trace
/// anywhere else. The tap is logged, and then nothing happens: no request, no
/// route change, no error — the same shape as a button whose handler is broken,
/// as a request that never left, and as an app that froze. What the user saw was
/// a red line under a field, and only the form knows that.
///
/// The field that failed is deliberately not named. Validation messages are
/// localized sentences and the values behind them are the user's; `invalid` plus
/// the form's own name places it well enough to reproduce.
bool validateAndLog(BuildContext context, GlobalKey<FormState> form) {
  final valid = form.currentState?.validate() ?? true;
  DiagnosticRecorder.active?.add(
    LogSource.ui,
    'submit',
    lvl: valid ? LogLevel.info : LogLevel.warn,
    fields: {
      'id': LogSurface.of(context),
      'reason': valid ? null : 'invalid',
    },
  );
  return valid;
}

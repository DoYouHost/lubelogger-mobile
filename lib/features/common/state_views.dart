import 'package:flutter/material.dart';

import '../../core/diagnostics/diagnostic_recorder.dart';
import '../../core/diagnostics/log_event.dart';
import '../../core/diagnostics/log_tag.dart';
import '../../core/theme/dash_theme.dart';

/// Records that a screen gave up and showed one of these instead of content.
///
/// This is the only lane that says what the user actually *saw*. Everything else
/// in the log is what the app did: the HTTP probe reports the failed request,
/// the navigation probe the screen — but "the garage says it cannot load" and
/// "the garage is empty" are two different reports, and from a request alone
/// they are indistinguishable (a 200 with an empty list produces the second).
///
/// Both views are stateful only for this: `initState` fires when the screen
/// enters the state, not on every rebuild, so a rebuilding screen contributes
/// one record rather than one per frame.
///
/// The screen's name comes from the enclosing [logSurface] unless the caller
/// names it outright; the message never goes in — it is localized text, and the
/// route already says where the user was.
void _logState(String evt, BuildContext context, String? surface) =>
    DiagnosticRecorder.active?.add(
      LogSource.ui,
      evt,
      lvl: LogLevel.warn,
      fields: {'surface': surface ?? LogSurface.of(context)},
    );

/// Shared "failed to load, tap to retry" view. Built as a scrollable so an
/// enclosing [RefreshIndicator] can still pull-to-retry.
class AsyncErrorView extends StatefulWidget {
  const AsyncErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.retryLabel,
    this.icon = Icons.cloud_off,
    this.surface,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;
  final IconData icon;

  /// Which screen failed, for the log — defaults to the enclosing surface.
  final String? surface;

  @override
  State<AsyncErrorView> createState() => _AsyncErrorViewState();
}

class _AsyncErrorViewState extends State<AsyncErrorView> {
  @override
  void initState() {
    super.initState();
    _logState('error_view', context, widget.surface);
  }

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 48, color: t.textTertiary),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(widget.message, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: widget.onRetry,
                  child: Text(widget.retryLabel),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared empty-state view (icon + centered message). Built as a [ListView] so
/// an enclosing [RefreshIndicator] still works while the list is empty.
class EmptyStateView extends StatefulWidget {
  const EmptyStateView({
    super.key,
    required this.message,
    required this.icon,
    this.surface,
  });

  final String message;
  final IconData icon;

  /// Which screen is empty, for the log — defaults to the enclosing surface.
  final String? surface;

  @override
  State<EmptyStateView> createState() => _EmptyStateViewState();
}

class _EmptyStateViewState extends State<EmptyStateView> {
  @override
  void initState() {
    super.initState();
    _logState('empty_view', context, widget.surface);
  }

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(widget.icon, size: 48, color: t.textTertiary),
              const SizedBox(height: 12),
              Text(widget.message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}

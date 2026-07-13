import 'package:flutter/material.dart';

import '../../core/theme/dash_theme.dart';

/// Shared "failed to load, tap to retry" view. Built as a scrollable so an
/// enclosing [RefreshIndicator] can still pull-to-retry.
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.retryLabel,
    this.icon = Icons.cloud_off,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;
  final IconData icon;

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
                Icon(icon, size: 48, color: t.textTertiary),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(message, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: onRetry, child: Text(retryLabel)),
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
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key, required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(icon, size: 48, color: t.textTertiary),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}

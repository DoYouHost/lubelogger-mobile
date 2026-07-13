import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';

/// Placeholder landing screen shown after login. The real Garage vehicle list
/// replaces this in a later step — for now it confirms the connection works and
/// offers a way to disconnect.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final profile = ref.watch(serverProfileProvider);
    final name = profile?.label ?? '';

    return DashBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: dashAppBar(
          context,
          titleWidget: const LubeLoggerWordmark(),
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  ref.read(serverProfileProvider.notifier).clear(),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.garage_outlined, size: 64, color: t.accentGold),
              const SizedBox(height: 16),
              if (name.isNotEmpty)
                Text(
                  l10n.signedInAs(name),
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                profile?.baseUrl ?? '',
                style: TextStyle(
                  fontFamily: DashTokens.fontMono,
                  fontSize: 12,
                  color: t.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

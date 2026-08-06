import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/dash_theme.dart';
import 'features/bug_report/recording_banner.dart';
import 'features/quick_actions/quick_action_handler.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';

class LubeLoggerApp extends ConsumerWidget {
  const LubeLoggerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'LubeLogger',
      theme: buildDashThemeData(Brightness.light),
      darkTheme: buildDashThemeData(Brightness.dark),
      // Follow the system setting; the design is dark-first.
      themeMode: ThemeMode.system,
      // Locale auto-detected from the system; en is the fallback.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      // Always-mounted hosts: launcher quick actions (see QuickActionHandler),
      // and the diagnostic recording controls, which have to outlive the report
      // screen — the bug is reproduced somewhere else in the app.
      builder: (context, child) => QuickActionHandler(
        child: RecordingBannerScaffold(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

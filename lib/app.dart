import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/dash_theme.dart';
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
    );
  }
}

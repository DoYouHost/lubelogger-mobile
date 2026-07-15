import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart' show Locale;

import '../l10n/app_localizations.dart';

/// Loads [AppLocalizations] for the current system locale outside the widget
/// tree — needed by the notification code, which runs before `MaterialApp` (app
/// start) and inside the WorkManager background isolate, where there is no
/// `BuildContext`. Falls back to English for an unsupported system language.
Future<AppLocalizations> loadAppLocalizations() {
  final system = PlatformDispatcher.instance.locale;
  final match = AppLocalizations.supportedLocales.firstWhere(
    (l) => l.languageCode == system.languageCode,
    orElse: () => const Locale('en'),
  );
  return AppLocalizations.delegate.load(match);
}

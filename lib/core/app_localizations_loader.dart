import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart' show Locale, basicLocaleListResolution;

import '../l10n/app_localizations.dart';

/// Loads [AppLocalizations] for the current system locale outside the widget
/// tree — needed by the notification code, which runs before `MaterialApp` (app
/// start) and inside the WorkManager background isolate, where there is no
/// `BuildContext`.
Future<AppLocalizations> loadAppLocalizations() => AppLocalizations.delegate
    .load(resolveAppLocale(PlatformDispatcher.instance.locales));

/// The same resolution `MaterialApp` applies to `supportedLocales`, so text
/// built outside the tree speaks the language of the screen it opens. Matching
/// on `languageCode` alone read only the first preferred language, so a phone
/// set to Italian then Polish got English notifications.
Locale resolveAppLocale(List<Locale> preferred) =>
    basicLocaleListResolution(preferred, AppLocalizations.supportedLocales);

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/app_localizations_loader.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';

void main() {
  test('every translated language resolves to itself', () {
    for (final supported in AppLocalizations.supportedLocales) {
      expect(resolveAppLocale([supported]), supported);
    }
  });

  test('a regional system locale resolves to the bare supported locale', () {
    expect(resolveAppLocale([const Locale('pl', 'PL')]), const Locale('pl'));
    expect(resolveAppLocale([const Locale('en', 'GB')]), const Locale('en'));
  });

  test('an untranslated first choice falls through to the next one', () {
    expect(
      resolveAppLocale([const Locale('it', 'IT'), const Locale('pl', 'PL')]),
      const Locale('pl'),
    );
  });

  test('an untranslated language falls back to English', () {
    expect(resolveAppLocale([const Locale('it', 'IT')]), const Locale('en'));
    expect(resolveAppLocale([const Locale('cs')]), const Locale('en'));
  });

  test('no reported locale falls back to English', () {
    expect(resolveAppLocale(const []), const Locale('en'));
  });

  test('the resolved locale always has a translation to look up', () {
    expect(
      () => lookupAppLocalizations(resolveAppLocale([const Locale('ja')])),
      returnsNormally,
    );
  });
}

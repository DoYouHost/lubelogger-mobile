// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'LubeLogger';

  @override
  String get connectToServer => 'Połącz z serwerem';

  @override
  String get setupIntro =>
      'Podaj adres serwera LubeLogger i klucz API, aby rozpocząć.';

  @override
  String get serverAddressLabel => 'Adres serwera';

  @override
  String get serverAddressHint => 'https://lubelogger.example.com';

  @override
  String get serverAddressHelper =>
      'Pełny adres URL Twojej instancji LubeLogger.';

  @override
  String get apiKeyExplain =>
      'Wygeneruj klucz API w LubeLogger w Ustawieniach. Zalecane: bez wygasania, z ograniczonym zakresem.';

  @override
  String get apiKeyLabel => 'Klucz API';

  @override
  String get connect => 'Połącz';

  @override
  String get connecting => 'Łączenie…';

  @override
  String get logout => 'Wyloguj';

  @override
  String get retry => 'Ponów';

  @override
  String get comingSoon => 'Wkrótce';

  @override
  String get garageEmpty => 'Brak pojazdów. Dodaj pierwszy, aby rozpocząć.';

  @override
  String get garageLoadError =>
      'Nie udało się wczytać garażu. Pociągnij, aby ponowić.';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsUnits => 'Jednostki';

  @override
  String get settingsCurrency => 'Waluta';

  @override
  String get settingsDistance => 'Dystans';

  @override
  String get settingsFuelEconomy => 'Zużycie paliwa';

  @override
  String get settingsServer => 'Serwer';

  @override
  String get settingsStorageBase => 'Dane serwera';

  @override
  String get baseMetric => 'Metryczne';

  @override
  String get baseImperial => 'Imperialne';

  @override
  String currencyAuto(String symbol) {
    return 'Automatyczna ($symbol)';
  }

  @override
  String get settingsUnitsMetricNote =>
      'Ustaw jednostki, w jakich Twój serwer LubeLogger zapisuje dane (metryczne = km i litry). Aplikacja przeliczy je do wybranych jednostek wyświetlania.';

  @override
  String get dashLoadError =>
      'Nie udało się wczytać pojazdu. Pociągnij, aby ponowić.';

  @override
  String get statLastOdometer => 'Ostatni przebieg';

  @override
  String get statDistanceTraveled => 'Przejechany dystans';

  @override
  String get statTotalCost => 'Koszt całkowity';

  @override
  String get statAvgEconomy => 'Średnie spalanie';

  @override
  String get chartExpensesByType => 'Wydatki wg typu';

  @override
  String get chartExpensesDistanceByMonth => 'Wydatki i dystans wg miesiąca';

  @override
  String get chartRemindersByUrgency => 'Przypomnienia wg pilności';

  @override
  String get chartFuelMileageByMonth => 'Spalanie wg miesiąca';

  @override
  String get chartNoData => 'Brak danych';

  @override
  String get chartNoReminders => 'Brak przypomnień';

  @override
  String get legendExpenses => 'Wydatki';

  @override
  String get legendDistance => 'Dystans';

  @override
  String get catService => 'Serwis';

  @override
  String get catRepairs => 'Naprawy';

  @override
  String get catUpgrades => 'Ulepszenia';

  @override
  String get catFuel => 'Paliwo';

  @override
  String get catTax => 'Podatki';

  @override
  String get urgencyNotUrgent => 'Niepilne';

  @override
  String get urgencyUrgent => 'Pilne';

  @override
  String get urgencyVeryUrgent => 'Bardzo pilne';

  @override
  String get urgencyPastDue => 'Po terminie';

  @override
  String signedInAs(String name) {
    return 'Zalogowano jako $name';
  }

  @override
  String get errMissingUrl => 'Podaj adres serwera.';

  @override
  String get errMissingApiKey => 'Podaj klucz API.';

  @override
  String get errServerUnreachable =>
      'Nie można połączyć się z serwerem. Sprawdź adres i sieć.';

  @override
  String get errUnauthorized =>
      'Uwierzytelnianie nie powiodło się lub klucz nie ma wymaganych uprawnień.';

  @override
  String get errForbidden => 'Brak uprawnień do tej operacji.';

  @override
  String errBadResponse(int status) {
    return 'Nieoczekiwana odpowiedź serwera (HTTP $status).';
  }

  @override
  String get errBadCertificate =>
      'Nie udało się zweryfikować certyfikatu serwera.';

  @override
  String get errConnection => 'Błąd połączenia. Spróbuj ponownie.';

  @override
  String get errMalformedResponse =>
      'Nie udało się odczytać odpowiedzi serwera.';

  @override
  String get errInvalidCredentials =>
      'Nieprawidłowa nazwa użytkownika lub hasło.';

  @override
  String get errApiKeyRejected => 'Klucz API został odrzucony przez serwer.';
}

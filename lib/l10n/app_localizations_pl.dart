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
  String get settingsDateFormat => 'Format daty';

  @override
  String get settingsDateSeparator => 'Separator daty';

  @override
  String get settingsServer => 'Serwer';

  @override
  String get settingsAbout => 'O aplikacji';

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
  String get settingsVisibleTabs => 'Widoczne zakładki';

  @override
  String get settingsVisibleTabsNote =>
      'Wybierz, które zakładki mają się pojawiać na ekranie pojazdu i w menu dodawania.';

  @override
  String get dashLoadError =>
      'Nie udało się wczytać pojazdu. Pociągnij, aby ponowić.';

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
  String get catSupply => 'Zaopatrzenie';

  @override
  String get catPlan => 'Planer';

  @override
  String get catReminder => 'Przypomnienia';

  @override
  String get catNote => 'Notatki';

  @override
  String get catEquipment => 'Wyposażenie';

  @override
  String get planPriorityCritical => 'Krytyczny';

  @override
  String get planPriorityNormal => 'Normalny';

  @override
  String get planPriorityLow => 'Niski';

  @override
  String get planProgressBacklog => 'Zaległe';

  @override
  String get planProgressInProgress => 'W toku';

  @override
  String get planProgressTesting => 'Testowanie';

  @override
  String get planProgressDone => 'Gotowe';

  @override
  String get equipmentEquipped => 'Zamontowane';

  @override
  String get equipmentRemoved => 'Zdjęte';

  @override
  String get notePinned => 'Przypięta';

  @override
  String get tabDashboard => 'Pulpit';

  @override
  String get tabOdometer => 'Licznik kilometrów';

  @override
  String get colDate => 'Data';

  @override
  String get colOdometer => 'Licznik';

  @override
  String get colDescription => 'Opis';

  @override
  String get colCost => 'Koszt';

  @override
  String get recordsEmpty => 'Brak wpisów.';

  @override
  String fuelPillRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wpisu',
      many: '$count wpisów',
      few: '$count wpisy',
      one: '1 wpis',
    );
    return '$_temp0';
  }

  @override
  String fuelPillAvg(String value) {
    return 'Śr. $value';
  }

  @override
  String fuelPillMin(String value) {
    return 'Min $value';
  }

  @override
  String fuelPillMax(String value) {
    return 'Maks. $value';
  }

  @override
  String fuelPillDistance(String value) {
    return 'Dystans $value';
  }

  @override
  String fuelPillFuel(String value) {
    return 'Paliwo $value';
  }

  @override
  String fuelPillCost(String value) {
    return 'Koszt $value';
  }

  @override
  String get addRecordTitle => 'Dodaj wpis';

  @override
  String get formFuelTitle => 'Dodaj tankowanie';

  @override
  String get formFuelEditTitle => 'Edytuj tankowanie';

  @override
  String get formOdometerTitle => 'Dodaj odczyt licznika';

  @override
  String get formOdometerEditTitle => 'Edytuj odczyt licznika';

  @override
  String get formServiceTitle => 'Dodaj wpis serwisowy';

  @override
  String get formServiceEditTitle => 'Edytuj wpis serwisowy';

  @override
  String get formRepairTitle => 'Dodaj naprawę';

  @override
  String get formRepairEditTitle => 'Edytuj naprawę';

  @override
  String get formUpgradeTitle => 'Dodaj ulepszenie';

  @override
  String get formUpgradeEditTitle => 'Edytuj ulepszenie';

  @override
  String get formTaxTitle => 'Dodaj podatek';

  @override
  String get formTaxEditTitle => 'Edytuj podatek';

  @override
  String get formSupplyTitle => 'Dodaj zaopatrzenie';

  @override
  String get formSupplyEditTitle => 'Edytuj zaopatrzenie';

  @override
  String get formSupplyPartNumber => 'Numer części (opcjonalnie)';

  @override
  String get formSupplyPartSupplier => 'Dostawca (opcjonalnie)';

  @override
  String get formSupplyQuantity => 'Ilość';

  @override
  String get formPlanTitle => 'Dodaj pozycję planera';

  @override
  String get formPlanEditTitle => 'Edytuj pozycję planera';

  @override
  String get formPlanType => 'Typ';

  @override
  String get formPlanPriority => 'Priorytet';

  @override
  String get formPlanProgress => 'Postęp';

  @override
  String get formReminderTitle => 'Dodaj przypomnienie';

  @override
  String get formReminderEditTitle => 'Edytuj przypomnienie';

  @override
  String get formReminderMetric => 'Przypomnij wg';

  @override
  String get formReminderMetricDate => 'Data';

  @override
  String get formReminderMetricOdometer => 'Licznik';

  @override
  String get formReminderMetricBoth => 'Data i licznik';

  @override
  String get formReminderDueDate => 'Termin';

  @override
  String formReminderDueOdometer(String unit) {
    return 'Licznik docelowy ($unit)';
  }

  @override
  String get formNoteTitle => 'Dodaj notatkę';

  @override
  String get formNoteEditTitle => 'Edytuj notatkę';

  @override
  String get formNoteTitleLabel => 'Tytuł';

  @override
  String get formNoteBodyLabel => 'Notatka';

  @override
  String get formNotePinned => 'Przypięta';

  @override
  String get formEquipmentTitle => 'Dodaj wyposażenie';

  @override
  String get formEquipmentEditTitle => 'Edytuj wyposażenie';

  @override
  String get formEquipmentNameLabel => 'Nazwa';

  @override
  String get formEquipmentEquipped => 'Zamontowane';

  @override
  String formOdometerLabel(String unit) {
    return 'Stan licznika ($unit)';
  }

  @override
  String formFuelLabel(String unit) {
    return 'Zatankowane paliwo ($unit)';
  }

  @override
  String get formFillToFull => 'Do pełna';

  @override
  String get formMissedFuelUp => 'Pominięte tankowanie (bez spalania)';

  @override
  String get formTagsOptional => 'Tagi (opcjonalnie)';

  @override
  String get formNotesOptional => 'Notatki (opcjonalnie)';

  @override
  String get actionCancel => 'Anuluj';

  @override
  String get actionAdd => 'Dodaj';

  @override
  String get actionSave => 'Zapisz';

  @override
  String get actionDelete => 'Usuń';

  @override
  String get validationRequired => 'Wymagane';

  @override
  String get validationNumber => 'Podaj poprawną liczbę';

  @override
  String get recordAdded => 'Dodano wpis';

  @override
  String get recordAddError => 'Nie udało się dodać wpisu. Spróbuj ponownie.';

  @override
  String get recordUpdated => 'Zapisano zmiany';

  @override
  String get recordUpdateError =>
      'Nie udało się zapisać wpisu. Spróbuj ponownie.';

  @override
  String get recordDeleted => 'Usunięto wpis';

  @override
  String get recordDeleteError =>
      'Nie udało się usunąć wpisu. Spróbuj ponownie.';

  @override
  String get confirmDeleteTitle => 'Usunąć ten wpis?';

  @override
  String get confirmDeleteMessage => 'Tej operacji nie można cofnąć.';

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

  @override
  String appVersion(String version, String build) {
    return 'Wersja $version ($build)';
  }

  @override
  String get openSourceLicenses => 'Licencje open source';
}

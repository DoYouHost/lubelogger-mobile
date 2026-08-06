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
  String get tryDemo => 'Wypróbuj wersję demo';

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
      'Wybierz, które zakładki mają się pojawiać na ekranie pojazdu i w menu dodawania, oraz przeciągnij, aby zmienić ich kolejność. Pulpit jest zawsze pokazywany jako pierwszy.';

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
  String get formVehicleTitle => 'Dodaj pojazd';

  @override
  String get formVehicleEditTitle => 'Edytuj pojazd';

  @override
  String get formVehicleYear => 'Rok';

  @override
  String get formVehicleMake => 'Marka';

  @override
  String get formVehicleModel => 'Model';

  @override
  String get formVehicleLicensePlate => 'Numer rejestracyjny';

  @override
  String get formVehicleFuelType => 'Rodzaj paliwa';

  @override
  String get formVehicleUseHours => 'Śledź motogodziny zamiast licznika';

  @override
  String get formVehicleOdometerOptional => 'Licznik opcjonalny';

  @override
  String get fuelTypeGasoline => 'Benzyna';

  @override
  String get fuelTypeDiesel => 'Diesel';

  @override
  String get fuelTypeElectric => 'Elektryczny';

  @override
  String get vehicleAdded => 'Dodano pojazd';

  @override
  String get vehicleAddError =>
      'Nie udało się dodać pojazdu. Spróbuj ponownie.';

  @override
  String get vehicleUpdated => 'Zapisano zmiany pojazdu';

  @override
  String get vehicleUpdateError =>
      'Nie udało się zapisać pojazdu. Spróbuj ponownie.';

  @override
  String get vehicleDeleted => 'Usunięto pojazd';

  @override
  String get vehicleDeleteError =>
      'Nie udało się usunąć pojazdu. Spróbuj ponownie.';

  @override
  String get confirmDeleteVehicleTitle => 'Usunąć ten pojazd?';

  @override
  String get confirmDeleteVehicleMessage =>
      'Spowoduje to trwałe usunięcie pojazdu i wszystkich jego wpisów. Tej operacji nie można cofnąć.';

  @override
  String confirmDeleteVehicleFinalTitle(String vehicle) {
    return 'Trwale usunąć $vehicle?';
  }

  @override
  String get confirmDeleteVehicleFinalMessage =>
      'To ostatnia szansa, aby anulować. Pojazd i wszystkie jego wpisy zostaną bezpowrotnie usunięte.';

  @override
  String get actionDeletePermanently => 'Usuń trwale';

  @override
  String get vehicleDeleteUnsupportedTitle => 'Wymagana aktualizacja serwera';

  @override
  String vehicleDeleteUnsupportedMessage(String required, String current) {
    return 'Usuwanie pojazdu wymaga LubeLogger $required lub nowszego, a Twój serwer działa w wersji $current. Zaktualizuj serwer, aby z tego korzystać.';
  }

  @override
  String get actionOk => 'OK';

  @override
  String get actionEdit => 'Edytuj';

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
  String get attachmentsLabel => 'Załączniki (opcjonalnie)';

  @override
  String get attachmentAddButton => 'Dodaj plik';

  @override
  String get attachmentUploadError =>
      'Nie udało się przesłać pliku. Spróbuj ponownie.';

  @override
  String get attachmentOpenError => 'Nie udało się otworzyć pliku.';

  @override
  String get quickActionAddFuel => 'Dodaj tankowanie';

  @override
  String get quickActionAddOdometer => 'Dodaj licznik';

  @override
  String get quickActionSelectVehicle => 'Wybierz pojazd';

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

  @override
  String serverVersionLabel(String version) {
    return 'Wersja serwera $version';
  }

  @override
  String updateAvailable(String version) {
    return 'Dostępna aktualizacja: $version';
  }

  @override
  String get settingsBackup => 'Utwórz kopię zapasową';

  @override
  String get backupCreated => 'Kopia zapasowa utworzona na serwerze.';

  @override
  String get backupError =>
      'Nie udało się utworzyć kopii zapasowej. Spróbuj ponownie.';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleRoot => 'Root';

  @override
  String get settingsNotifications => 'Powiadomienia';

  @override
  String get settingsNotificationsNote =>
      'Sprawdzaj w tle przypomnienia po terminie (mniej więcej co 3 godziny) i wysyłaj powiadomienie. Każde przypomnienie powiadamia raz, dopóki nie zostanie rozwiązane.';

  @override
  String get notifRemindersToggle => 'Przypomnienia po terminie';

  @override
  String get notifPermissionDenied =>
      'Wymagane jest pozwolenie na powiadomienia. Włącz je w ustawieniach systemu.';

  @override
  String get notifReminderChannelName => 'Przypomnienia';

  @override
  String get notifReminderChannelDescription =>
      'Przypomnienia serwisowe po terminie';

  @override
  String get notifReminderTitle => 'Przypomnienie po terminie';

  @override
  String notifReminderBody(String vehicle, String description) {
    return '$vehicle: $description';
  }

  @override
  String get settingsDiagnostics => 'Diagnostyka';

  @override
  String get settingsDiagnosticsNote =>
      'Nagraj, co robi aplikacja, gdy odtwarzasz problem, a potem przejrzyj log i zapisz go albo zgłoś.';

  @override
  String get bugReportTitle => 'Zgłoś błąd';

  @override
  String get bugReportIntroHeader => 'Jak to działa';

  @override
  String get bugReportIntroBody =>
      'Włącz nagrywanie, odtwórz problem i wróć tutaj, żeby je zakończyć. Aplikacja zapisuje, co robi — otwierane ekrany, naciskane przyciski, zapytania do serwera i błędy — żeby zgłoszenie mówiło więcej niż „nie działa”.';

  @override
  String get bugReportPrivacyHeader => 'Co trafia do logu';

  @override
  String get bugReportPrivacyBody =>
      'Nigdy klucz API, hasło ani tekst, który wpisujesz. Adres serwera zostaje sprowadzony do kształtu: http czy https, nazwa czy IP, i port. Z tego, co idzie do serwera i wraca, zostają nazwy pól, liczby i daty — tablice rejestracyjne, notatki i wszystko, co wpisujesz, zastępuje ich długość. Zapisuje też model telefonu i wersję Androida oraz Twoje ustawienia jednostek i formatu daty, bo zwykle od nich zależy poprawka. Wszystko przeglądasz, zanim opuści telefon.';

  @override
  String get bugReportStart => 'Rozpocznij nagrywanie';

  @override
  String get bugReportRecordingHeader => 'Nagrywanie trwa';

  @override
  String get bugReportRecordingBody =>
      'Wróć do aplikacji i odtwórz problem. Pasek nagrywania zostaje z Tobą — przesuń go albo zwiń, jeśli zasłania. Oznacz nim moment awarii i zakończ nagrywanie.';

  @override
  String bugReportLimit(int minutes) {
    return 'Nagrywanie zatrzyma się samo po $minutes min.';
  }

  @override
  String bugReportLimitReached(int minutes) {
    return 'Nagrywanie zakończone — minął limit $minutes min.';
  }

  @override
  String bugReportSizeLimitReached(int megabytes) {
    return 'Nagrywanie zakończone — log osiągnął limit $megabytes MB.';
  }

  @override
  String get bugReportMark => 'Oznacz moment';

  @override
  String get bugReportMarked => 'Moment oznaczony';

  @override
  String get bugReportStop => 'Zakończ nagrywanie';

  @override
  String get bugReportStopShort => 'Zakończ';

  @override
  String get bugReportShow => 'Pokaż';

  @override
  String get bugReportBannerLabel => 'Nagrywanie';

  @override
  String get bugReportBarMove => 'Przesuń pasek nagrywania';

  @override
  String get bugReportBarCollapse => 'Zwiń pasek nagrywania';

  @override
  String get bugReportBarExpand => 'Rozwiń pasek nagrywania';

  @override
  String get bugReportRecoveredHeader => 'Nagranie przetrwało awarię';

  @override
  String get bugReportRecoveredBody =>
      'Aplikacja zamknęła się w trakcie nagrywania. To, co zdążyła zapisać, jest nadal w telefonie — obejrzyj albo wyrzuć.';

  @override
  String get bugReportReviewHeader => 'Przejrzyj przed wysłaniem';

  @override
  String get bugReportReviewBody =>
      'To wszystko, co zostało nagrane. Przejrzyj to — poniżej wybierasz, czy log zostaje w telefonie, czy idzie jako publiczne zgłoszenie.';

  @override
  String bugReportSummary(int records, int errors, int warnings) {
    return '$records rekordów · $errors błędów · $warnings ostrzeżeń';
  }

  @override
  String bugReportMarkers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oznaczonych momentów',
      few: '$count oznaczone momenty',
      one: '1 oznaczony moment',
    );
    return '$_temp0';
  }

  @override
  String get bugReportTruncated =>
      'Sesja była długa — najstarsze rekordy zostały odrzucone.';

  @override
  String get bugReportEmpty => 'Nic nie zostało nagrane.';

  @override
  String get bugReportShowRaw => 'Pokaż surowy log';

  @override
  String get bugReportHideRaw => 'Ukryj surowy log';

  @override
  String bugReportRawClipped(int kb) {
    return 'Pierwsze $kb kB nie są tu pokazane. Zapisany plik zawiera całą sesję.';
  }

  @override
  String get bugReportDestinationFile => 'Zapisz do pliku';

  @override
  String get bugReportDestinationIssue => 'Zgłoś na GitHubie';

  @override
  String get bugReportDestinationFileBody =>
      'Log zapisze się tam, gdzie wskażesz, i zostanie w telefonie. Sam decydujesz, czy gdziekolwiek go wyślesz.';

  @override
  String get bugReportDestinationIssueBody =>
      'Log i Twój opis trafią jako publiczne zgłoszenie na GitHuba — każdy będzie mógł je przeczytać i zostaną tam na zawsze. Przejrzyj najpierw log poniżej.';

  @override
  String get bugReportDescriptionLabel => 'Co poszło nie tak?';

  @override
  String get bugReportDescriptionHint =>
      'Co robiłeś, czego się spodziewałeś, co stało się zamiast tego.';

  @override
  String get bugReportDescriptionRequired =>
      'Napisz, co poszło nie tak — log bez opisu jest prawie bezużyteczny.';

  @override
  String get bugReportSave => 'Zapisz do pliku';

  @override
  String get bugReportSaveShort => 'Zapisz';

  @override
  String get bugReportSaved => 'Log zapisany do pliku';

  @override
  String get bugReportSaveFailed => 'Nie udało się zapisać logu.';

  @override
  String get bugReportSend => 'Zgłoś';

  @override
  String get bugReportSending => 'Wysyłanie…';

  @override
  String bugReportSendWaiting(String clock) {
    return 'Wysyłka za $clock';
  }

  @override
  String get bugReportSendWaitingBody =>
      'Relay rozkłada zgłoszenia w czasie. Możesz zamknąć ten ekran — wyśle się samo.';

  @override
  String get bugReportSent => 'Zgłoszenie wysłane';

  @override
  String get bugReportSentBody =>
      'Dzięki. Zgłoszenie jest otwarte, a log do niego dołączony.';

  @override
  String get bugReportOpenIssue => 'Otwórz zgłoszenie';

  @override
  String get bugReportDone => 'Gotowe';

  @override
  String get bugReportSendFailedNotYet =>
      'Relay w tej chwili nie przyjmuje zgłoszeń. Spróbuj później albo zapisz log do pliku.';

  @override
  String get bugReportSendFailedRefused =>
      'Relay odmówił przyjęcia tego zgłoszenia. Zapisz log do pliku i dołącz go sam.';

  @override
  String get bugReportSendFailedDuplicate => 'To już zostało zgłoszone.';

  @override
  String get bugReportSendFailedUnreachable =>
      'Nie udało się połączyć z relayem. Sprawdź połączenie albo zapisz log do pliku.';

  @override
  String get bugReportSendFailedRejected =>
      'Relay odrzucił to zgłoszenie. Zapisz log do pliku i dołącz go sam.';

  @override
  String get bugReportSendFailedDemo =>
      'Tryb demo nie publikuje zgłoszeń. Zapisz log do pliku.';

  @override
  String get bugReportDiscard => 'Odrzuć';

  @override
  String get bugReportDiscardQuestion => 'Odrzucić to nagranie?';

  @override
  String get bugReportDiscardBody => 'Log zostanie usunięty z telefonu.';

  @override
  String get bugReportDiscardBodyQueued =>
      'Log zostanie usunięty z telefonu, a zakolejkowana wysyłka anulowana.';
}

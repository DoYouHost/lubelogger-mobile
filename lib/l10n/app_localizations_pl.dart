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

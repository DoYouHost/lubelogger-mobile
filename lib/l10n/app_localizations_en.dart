// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LubeLogger';

  @override
  String get connectToServer => 'Connect to server';

  @override
  String get setupIntro =>
      'Enter your LubeLogger server address and API key to get started.';

  @override
  String get serverAddressLabel => 'Server address';

  @override
  String get serverAddressHint => 'https://lubelogger.example.com';

  @override
  String get serverAddressHelper => 'Full URL of your LubeLogger instance.';

  @override
  String get apiKeyExplain =>
      'Generate an API key in LubeLogger under Settings. Recommended: no expiry and scoped access.';

  @override
  String get apiKeyLabel => 'API key';

  @override
  String get connect => 'Connect';

  @override
  String get connecting => 'Connecting…';

  @override
  String signedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get errMissingUrl => 'Enter the server address.';

  @override
  String get errMissingApiKey => 'Enter your API key.';

  @override
  String get errServerUnreachable =>
      'Cannot reach the server. Check the address and your network.';

  @override
  String get errUnauthorized =>
      'Authentication failed or the key lacks the required permission.';

  @override
  String get errForbidden => 'You do not have permission for this action.';

  @override
  String errBadResponse(int status) {
    return 'Unexpected server response (HTTP $status).';
  }

  @override
  String get errBadCertificate =>
      'The server\'s security certificate could not be verified.';

  @override
  String get errConnection => 'Connection error. Please try again.';

  @override
  String get errMalformedResponse =>
      'The server response could not be understood.';

  @override
  String get errInvalidCredentials => 'Invalid username or password.';

  @override
  String get errApiKeyRejected => 'The API key was rejected by the server.';
}

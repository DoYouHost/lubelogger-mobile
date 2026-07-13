import '../../core/api/api_exceptions.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/error_messages.dart';
import 'providers.dart';

/// Translates a setup error — an [AppApiException] from the network layer or a
/// local [SetupErrorCode] validation error — into a message in the UI language.
String setupErrorText(AppLocalizations l10n, Object error) {
  if (error is AppApiException) return error.localized(l10n);
  if (error is SetupErrorCode) {
    return switch (error) {
      SetupErrorCode.missingUrl => l10n.errMissingUrl,
      SetupErrorCode.missingApiKey => l10n.errMissingApiKey,
    };
  }
  return error.toString();
}

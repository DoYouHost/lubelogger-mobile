import '../core/api/api_exceptions.dart';
import 'app_localizations.dart';

/// Translates an API-layer error code into a message in the UI language. Keeps
/// the code→string mapping out of the core, which stays l10n-independent.
extension AppApiExceptionL10n on AppApiException {
  String localized(AppLocalizations l10n) => switch (code) {
        AppErrorCode.serverUnreachable => l10n.errServerUnreachable,
        AppErrorCode.unauthorized => l10n.errUnauthorized,
        AppErrorCode.forbidden => l10n.errForbidden,
        AppErrorCode.badResponse => l10n.errBadResponse(statusCode ?? 0),
        AppErrorCode.badCertificate => l10n.errBadCertificate,
        AppErrorCode.connectionError => l10n.errConnection,
        AppErrorCode.malformedResponse => l10n.errMalformedResponse,
        AppErrorCode.invalidCredentials => l10n.errInvalidCredentials,
        AppErrorCode.apiKeyRejected => l10n.errApiKeyRejected,
      };
}

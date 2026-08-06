import 'package:dio/dio.dart';

import '../diagnostics/diagnostic_recorder.dart';
import '../diagnostics/log_event.dart';

/// Error codes for the API/auth layer. The core layer is UI-independent:
/// translation to text happens at display time (see `lib/l10n/error_messages.dart`).
enum AppErrorCode {
  serverUnreachable,

  /// 401. LubeLogger OVERLOADS this: it means *either* missing/invalid
  /// credentials *or* a valid key/user with insufficient scope (the server
  /// returns 401 + a `{success:false}` body for both, never 403 for scope).
  /// So a 401 must NOT trigger an automatic logout — the credentials may be
  /// fine and only the permission is lacking. See `reference/LUBELOGGER-API.md`.
  unauthorized,

  /// 403 — reserved. LubeLogger's API rarely uses it (scope denial comes back
  /// as 401), but a reverse proxy in front of the server may return it.
  forbidden,
  badResponse,
  badCertificate,
  connectionError,
  malformedResponse,
  invalidCredentials,
  apiKeyRejected,
}

/// Base exception for the API layer. Carries an error code (for localization)
/// and optional technical details for logs.
sealed class AppApiException implements Exception {
  const AppApiException(this.code, {this.statusCode, this.detail});

  final AppErrorCode code;

  /// HTTP status code for [AppErrorCode.badResponse] (null for others).
  final int? statusCode;

  /// Raw, user-invisible detail (e.g. `DioException.message`).
  final String? detail;

  @override
  String toString() =>
      '$runtimeType($code${statusCode == null ? '' : ', status=$statusCode'}'
      '${detail == null ? '' : ', detail=$detail'})';
}

/// Server responded with an error (4xx/5xx except 401/403) or the response had
/// an unexpected shape.
class ApiException extends AppApiException {
  const ApiException(super.code, {super.statusCode, super.detail});
}

/// Authentication problem: bad credentials, rejected key, or insufficient scope.
class AuthException extends AppApiException {
  const AuthException(super.code, {super.detail});
}

/// Server unreachable: timeout, connection refused, or no network.
class NetworkException extends AppApiException {
  const NetworkException(super.code, {super.detail});
}

/// Runs [body], mapping any [DioException] to an [AppApiException] via
/// [mapDioException]. Centralizes the `try { ... } on DioException` boilerplate
/// repeated across repositories.
Future<T> guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on DioException catch (e) {
    throw mapDioException(e);
  }
}

/// Like [guard], but non-auth failures degrade to `null` instead of rethrowing
/// — for single-entity fetches where one unreachable resource shouldn't break a
/// composite view. Auth errors still bubble up so the UI can react.
///
/// Every swallow leaves a record. This is the one failure the app makes
/// invisible on purpose: the screen renders without the missing piece and says
/// nothing, so "the card shows no odometer" reaches a report as a screenshot of
/// a working app. The HTTP probe sees the failed request but not the decision to
/// carry on without it — and a `TypeError` from a response the parser could not
/// read never reaches the probe at all.
Future<T?> guardOrNull<T>(Future<T?> Function() body) async {
  try {
    return await body();
  } on DioException catch (e) {
    final mapped = mapDioException(e);
    if (mapped is AuthException) throw mapped;
    _logDegraded(mapped.code.name, mapped.statusCode);
    return null;
  } on Object catch (error) {
    _logDegraded(error.runtimeType.toString(), null);
    return null;
  }
}

void _logDegraded(String cause, int? status) =>
    DiagnosticRecorder.active?.add(
      LogSource.http,
      'degraded',
      lvl: LogLevel.warn,
      fields: {'cause': cause, 'status': status},
    );

/// Maps a [DioException] to a typed application exception.
AppApiException mapDioException(DioException e) {
  if (e.error is AppApiException) {
    return e.error! as AppApiException;
  }
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return NetworkException(AppErrorCode.serverUnreachable,
          detail: e.message);
    case DioExceptionType.badResponse:
      final code = e.response?.statusCode;
      if (code == 401) {
        return const AuthException(AppErrorCode.unauthorized);
      }
      if (code == 403) {
        return const AuthException(AppErrorCode.forbidden);
      }
      return ApiException(AppErrorCode.badResponse, statusCode: code);
    case DioExceptionType.badCertificate:
      return const NetworkException(AppErrorCode.badCertificate);
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      return NetworkException(AppErrorCode.connectionError, detail: e.message);
  }
}

import 'package:dio/dio.dart';

import '../auth/credentials_store.dart';
import '../settings/server_profile.dart';

/// Header LubeLogger uses to return culture-invariant payloads: typed JSON and
/// ISO-8601 dates instead of locale-formatted strings. Sent on every request so
/// parsing never depends on the server's locale. See `reference/LUBELOGGER-API.md`.
const String kCultureInvariantHeader = 'culture-invariant';

/// Bare Dio for calls without auth and as the base for [ApiClient]. Single place
/// for timeouts.
Dio createBareDio() => Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

/// Authenticated HTTP client for a single [ServerProfile].
class ApiClient {
  ApiClient({
    required ServerProfile profile,
    required CredentialsStore credentials,
    Dio? dio,
  }) : dio = dio ?? createBareDio() {
    this.dio.options.baseUrl = profile.baseUrl;
    this.dio.interceptors.add(AuthInterceptor(credentials: credentials));
  }

  final Dio dio;
}

/// Attaches the `x-api-key` auth header and the culture-invariant header on
/// every request.
///
/// It deliberately does NOT react to 401: LubeLogger returns 401 both for a bad
/// key AND for a valid key lacking the required scope, so an automatic logout on
/// 401 would be wrong. Callers inspect the failure and decide (see
/// [AppErrorCode.unauthorized]).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.credentials});

  final CredentialsStore credentials;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers[kCultureInvariantHeader] = 'true';
    final key = await credentials.readApiKey();
    if (key != null) {
      options.headers['x-api-key'] = key;
    }
    handler.next(options);
  }
}

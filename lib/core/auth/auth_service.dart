import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/endpoints.dart';
import '../settings/server_profile.dart';
import 'credentials_store.dart';
import 'whoami.dart';

/// Result of a successful credential check. [baseUrl] is the URL actually
/// reached — it may differ from what the user typed if the server redirected
/// (e.g. `http://host` → `https://host`), so the caller persists this one.
typedef AuthProbeResult = ({WhoAmI who, String baseUrl});

/// Validates a LubeLogger API key and persists it on success.
///
/// Uses bare Dio (no auth interceptor): the probe attaches the candidate key
/// itself, so it can validate it before it is ever stored. On success the key
/// is written to [CredentialsStore]; the caller then saves the matching
/// [ServerProfile].
class AuthService {
  AuthService({required Dio bareDio, required this._credentials})
      : _dio = bareDio;

  final Dio _dio;
  final CredentialsStore _credentials;

  /// Validate an API key with `GET /api/whoami` and store it on success.
  /// Throws [AuthException] if the key is rejected (401/403).
  Future<AuthProbeResult> verifyAndStoreApiKey({
    required String baseUrl,
    required String apiKey,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$baseUrl${Endpoints.whoami}',
        options: Options(headers: {
          kCultureInvariantHeader: 'true',
          'x-api-key': apiKey,
        }),
      );
      final body = res.data;
      if (body == null) {
        throw const ApiException(AppErrorCode.malformedResponse);
      }
      await _credentials.writeApiKey(apiKey);
      return (
        who: WhoAmI.fromJson(body),
        baseUrl: ServerProfile.baseUrlFromReached(
          res.realUri,
          requested: baseUrl,
          endpointSuffix: Endpoints.whoami,
        ),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        throw const AuthException(AppErrorCode.apiKeyRejected);
      }
      throw mapDioException(e);
    }
  }
}

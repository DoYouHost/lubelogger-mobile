import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secrets store. An abstraction so the pure-Dart core (AuthService, the auth
/// interceptor) stays testable with a mock, without the platform plugin.
abstract class CredentialsStore {
  /// The LubeLogger API key (`x-api-key`).
  Future<String?> readApiKey();
  Future<void> writeApiKey(String key);

  Future<void> clearAll();
}

/// Implementation backed by the Android Keystore via flutter_secure_storage.
class SecureCredentialsStore implements CredentialsStore {
  SecureCredentialsStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _apiKeyKey = 'api_key';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readApiKey() => _storage.read(key: _apiKeyKey);

  @override
  Future<void> writeApiKey(String key) =>
      _storage.write(key: _apiKeyKey, value: key);

  @override
  Future<void> clearAll() => _storage.deleteAll();
}

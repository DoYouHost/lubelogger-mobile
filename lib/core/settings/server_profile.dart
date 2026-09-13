import 'package:app_util/app_util.dart' as util;

import '../demo/demo_config.dart';

/// Connection profile for a LubeLogger server. Holds no secrets — the API key
/// lives in [CredentialsStore] (secure storage). Authentication is always via
/// the `x-api-key` header (the only method the app supports).
class ServerProfile {
  const ServerProfile({required this.baseUrl, this.label});

  factory ServerProfile.fromJson(Map<String, dynamic> json) => ServerProfile(
        baseUrl: json['baseUrl'] as String,
        label: json['label'] as String?,
      );

  /// E.g. `https://lubelogger.example.com` — without a trailing `/` or `/api`.
  final String baseUrl;

  /// Human label for the connection (e.g. the signed-in username). Optional.
  final String? label;

  /// Demo profile (store-review mode): all data comes from the in-process
  /// `DemoBackend`, no network traffic. See [DemoConfig].
  bool get isDemo => DemoConfig.isDemoUrl(baseUrl);

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        if (label != null) 'label': label,
      };

  ServerProfile copyWith({String? baseUrl, String? label}) => ServerProfile(
        baseUrl: baseUrl ?? this.baseUrl,
        label: label ?? this.label,
      );

  /// Normalizes raw user input: adds `https://` if no scheme, strips a trailing
  /// `/` and a trailing `/api`.
  ///
  /// The `https://` default suits LubeLogger, which is commonly reverse-proxied
  /// behind TLS. A plain-http LAN server still works: the user can type
  /// `http://…` explicitly, and `baseUrlFromReached` adopts whatever URL the
  /// probe actually reached after any redirect.
  static String normalizeBaseUrl(String raw) =>
      util.normalizeBaseUrl(raw, defaultScheme: 'https', apiPath: '/api');
}

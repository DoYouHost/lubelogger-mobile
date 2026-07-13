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
  /// `http://…` explicitly, and [baseUrlFromReached] adopts whatever URL the
  /// probe actually reached after any redirect.
  static String normalizeBaseUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/api')) {
      url = url.substring(0, url.length - '/api'.length);
    }
    return url;
  }

  /// Recover the base URL actually reached by a probe request, honoring any
  /// http→https (or host) redirect the HTTP client followed transparently.
  ///
  /// [reached] is the final URI of the probe (e.g. `Response.realUri`);
  /// [endpointSuffix] is the path that was appended to the base (e.g.
  /// `/api/whoami`). Strips that suffix off `origin + path` so any base-path
  /// prefix survives. Falls back to [requested] when [reached] is null or
  /// doesn't end with the suffix.
  static String baseUrlFromReached(
    Uri? reached, {
    required String requested,
    required String endpointSuffix,
  }) {
    if (reached == null) return requested;
    final full = reached.origin + reached.path;
    if (full.endsWith(endpointSuffix)) {
      return full.substring(0, full.length - endpointSuffix.length);
    }
    return requested;
  }
}

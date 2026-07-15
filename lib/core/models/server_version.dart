/// Server version info from `GET /api/version` (`?checkForUpdate=1` fills in
/// [latestVersion] from GitHub; otherwise it equals [currentVersion]).
class ServerVersion {
  const ServerVersion({
    required this.currentVersion,
    required this.latestVersion,
  });

  factory ServerVersion.fromJson(Map<String, dynamic> json) => ServerVersion(
        currentVersion: (json['currentVersion'] as String?) ?? '',
        latestVersion: (json['latestVersion'] as String?) ?? '',
      );

  final String currentVersion;
  final String latestVersion;

  /// True when a newer release than the running one is available. Compares the
  /// two tags after trimming and dropping a leading `v` (GitHub tags are like
  /// `v1.6.9`, the server reports `1.6.9`), so a pure formatting difference
  /// isn't mistaken for an update.
  bool get updateAvailable {
    final current = _normalize(currentVersion);
    final latest = _normalize(latestVersion);
    return latest.isNotEmpty && current.isNotEmpty && latest != current;
  }

  static String _normalize(String v) {
    final trimmed = v.trim();
    final noPrefix =
        trimmed.startsWith('v') ? trimmed.substring(1) : trimmed;
    return noPrefix.toLowerCase();
  }
}

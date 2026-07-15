/// Comparison of LubeLogger-style dotted version strings (e.g. `1.7.0`).
library;

/// Whether [version] is the same as or newer than [minimum].
///
/// Both are read as dot-separated integer components; a leading `v` and any
/// non-numeric suffix (e.g. `-beta`) are ignored, and missing trailing
/// components count as 0 so `1.7` is treated as `1.7.0`. Returns `null` when
/// [version] holds no parseable number at all (empty / not yet loaded) — the
/// caller decides how to treat an unknown server version rather than this
/// silently blocking or allowing a feature.
bool? versionAtLeast(String version, String minimum) {
  final actual = _components(version);
  if (actual == null) return null;
  final required = _components(minimum) ?? const <int>[];
  final length = actual.length > required.length ? actual.length : required.length;
  for (var i = 0; i < length; i++) {
    final a = i < actual.length ? actual[i] : 0;
    final b = i < required.length ? required[i] : 0;
    if (a != b) return a > b;
  }
  return true; // all components equal
}

/// Leading integer of each dot-separated component (dropping suffixes like
/// `-rc1`), stopping at the first non-numeric component. `null` if none parse.
List<int>? _components(String raw) {
  final trimmed = raw.trim();
  final noPrefix = trimmed.startsWith('v') ? trimmed.substring(1) : trimmed;
  final out = <int>[];
  for (final part in noPrefix.split('.')) {
    final digits = RegExp(r'^\d+').firstMatch(part.trim());
    if (digits == null) break;
    out.add(int.parse(digits.group(0)!));
  }
  return out.isEmpty ? null : out;
}

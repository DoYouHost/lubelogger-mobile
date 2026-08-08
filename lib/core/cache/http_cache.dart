import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

/// A response body kept on disk, and when it was stored.
class CachedBody {
  const CachedBody({required this.body, required this.storedAt});

  final Object? body;
  final DateTime storedAt;
}

/// Where one server's offline copy lives: the lists this class stores, and the
/// vehicle photos [PhotoCache] stores in a subdirectory of it.
///
/// One directory per server, named after a digest of the base URL, so two
/// households can't see each other's data through one cache and logging out
/// drops the lot by removing a single directory.
Future<Directory> serverCacheDirectory(
  String baseUrl,
  Future<Directory> Function() supportDirectory,
) async {
  final support = await supportDirectory();
  return Directory('${support.path}/http_cache/${cacheDigest(baseUrl)}');
}

/// Names a file after what it holds, without the length or the characters a
/// path can't take.
String cacheDigest(String value) =>
    sha256.convert(utf8.encode(value)).toString().substring(0, 32);

/// The last successful body of every list the app has read, on disk.
///
/// Entries never expire on their own. Staleness is the reader's decision — the
/// app shows what it has and refreshes behind it — and an entry the user can
/// still see beats an empty screen while the server is unreachable.
///
/// Sizing and clearing cover the whole server directory, photos included: they
/// are one offline copy as far as the user (and logging out) is concerned.
class HttpCache {
  HttpCache({
    required this.baseUrl,
    Future<Directory> Function()? supportDirectory,
  }) : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  final String baseUrl;
  final Future<Directory> Function() _supportDirectory;
  Future<Directory>? _directory;

  /// Identifies one request: method, path and query, with parameters sorted so
  /// two calls that differ only in their order share an entry.
  static String keyFor({
    required String method,
    required String path,
    Map<String, dynamic>? query,
  }) {
    final params = [
      for (final e in (query ?? const {}).entries) '${e.key}=${e.value}',
    ]..sort();
    final suffix = params.isEmpty ? '' : '?${params.join('&')}';
    return '${method.toUpperCase()} $path$suffix';
  }

  Future<CachedBody?> read(String key) async {
    final file = await _fileFor(key);
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return CachedBody(
        body: json['body'],
        storedAt: DateTime.fromMillisecondsSinceEpoch(json['storedAt'] as int),
      );
    } on Object {
      // A half-written or older-format entry is simply a miss.
      return null;
    }
  }

  /// Stores [body], reporting whether it differs from what was there.
  ///
  /// The answer drives whether a refresh behind the user's back is allowed to
  /// rebuild the screen: revalidating a list that hasn't changed is the common
  /// case, and it must not flicker.
  Future<bool> write(String key, Object? body) async {
    final file = await _fileFor(key);
    final previous = await read(key);
    final changed =
        previous == null || jsonEncode(previous.body) != jsonEncode(body);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'request': key,
        'storedAt': DateTime.now().millisecondsSinceEpoch,
        'body': body,
      }),
      flush: true,
    );
    return changed;
  }

  /// Total bytes on disk, for the Settings entry that offers to clear it.
  Future<int> sizeInBytes() async {
    final dir = await _open();
    if (!dir.existsSync()) return 0;
    var total = 0;
    await for (final entry in dir.list(recursive: true)) {
      if (entry is File) total += await entry.length();
    }
    return total;
  }

  Future<void> clear() async {
    final dir = await _open();
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  Future<File> _fileFor(String key) async {
    final dir = await _open();
    return File('${dir.path}/${cacheDigest(key)}.json');
  }

  /// Locates the directory without creating it — only [write] needs it to
  /// exist, and a profile that never stores anything (demo mode) should leave
  /// nothing behind.
  Future<Directory> _open() =>
      _directory ??= serverCacheDirectory(baseUrl, _supportDirectory);
}

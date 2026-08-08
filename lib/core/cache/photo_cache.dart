import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show NetworkImageLoadException;
import 'package:path_provider/path_provider.dart';

import 'http_cache.dart';

/// One fetched photo: its bytes and what the server called them.
typedef FetchedPhoto = ({Uint8List bytes, String? contentType});

/// Fetches one photo. Injected so a test can answer without a network.
typedef PhotoFetcher = Future<FetchedPhoto> Function(
  Uri url,
  Map<String, String> headers,
);

/// Vehicle photos on disk, beside the lists in [HttpCache].
///
/// The lists survive an unreachable server on their own, but the garage is a
/// wall of photos: without this, every card offline is an empty cover.
///
/// A stored photo is never revalidated. LubeLogger moves an upload into
/// `/images/<guid>.<ext>`, so replacing a car's picture gives it a path this
/// cache has never seen — the entry under the old path can't be shown in place
/// of a newer photo, only alongside a car that no longer points at it.
class PhotoCache {
  PhotoCache({
    required this.baseUrl,
    this.apiKey,
    Future<Directory> Function()? supportDirectory,
    PhotoFetcher? fetch,
  })  : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
        _fetch = fetch ?? httpGetPhoto;

  final String baseUrl;

  /// Photos sit behind the same auth as everything else.
  final String? apiKey;

  final Future<Directory> Function() _supportDirectory;
  final PhotoFetcher _fetch;
  Future<Directory>? _directory;

  /// The photo at server-relative [path], from disk when it is there and from
  /// the server otherwise. Throws what the fetch threw when neither has it.
  Future<Uint8List> bytes(String path) async {
    final file = await _fileFor(path);
    if (file.existsSync()) {
      try {
        return await file.readAsBytes();
      } on IOException {
        // Unreadable entry: ask the server as if there had been none.
      }
    }
    final photo = await _fetch(Uri.parse('$baseUrl$path'), _headers);
    // Store only what is actually a picture. A proxy that answers a login page
    // with 200 would otherwise become that car's cover for good, and returning
    // the bytes anyway leaves the decode failure the bug report expects.
    if (photo.contentType?.startsWith('image/') ?? false) {
      await _store(file, photo.bytes);
    }
    return photo.bytes;
  }

  /// Stores [path] unless it is stored already, reporting whether it fetched.
  ///
  /// For the background pass: a vehicle added on the web is in the refreshed
  /// list before the app has ever drawn its card, so nothing else would have
  /// asked for its photo.
  Future<bool> prefetch(String path) async {
    if (path.isEmpty) return false;
    final file = await _fileFor(path);
    if (file.existsSync()) return false;
    try {
      await bytes(path);
      return true;
    } on Object {
      // Housekeeping: a photo that won't come down is fetched again next pass,
      // or by the card that needs it.
      return false;
    }
  }

  Map<String, String> get _headers => {'x-api-key': ?apiKey};

  Future<void> _store(File file, Uint8List bytes) async {
    await file.parent.create(recursive: true);
    // Written aside and renamed: an interrupted fetch that left a truncated
    // file in place would decode as a broken cover from then on.
    final partial = File('${file.path}.part');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(file.path);
  }

  Future<File> _fileFor(String path) async {
    final dir = await _open();
    return File('${dir.path}/${cacheDigest(path)}');
  }

  Future<Directory> _open() => _directory ??= () async {
        final root = await serverCacheDirectory(baseUrl, _supportDirectory);
        return Directory('${root.path}/photos');
      }();
}

/// Default [PhotoFetcher]: a plain GET, outside dio.
///
/// Photos are static files rather than API calls — nothing here wants the
/// offline interceptor's caching or its write queue, and this runs on the image
/// loading path, which the rest of the client knows nothing about.
Future<FetchedPhoto> httpGetPhoto(Uri url, Map<String, String> headers) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final request = await client.getUrl(url);
    for (final header in headers.entries) {
      request.headers.set(header.key, header.value);
    }
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      // The exception `Image.network` raises for the same failure, so a bug
      // report reads the same as it did before photos were cached.
      throw NetworkImageLoadException(
        statusCode: response.statusCode,
        uri: url,
      );
    }
    return (
      bytes: await consolidateHttpClientResponseBytes(response),
      contentType: response.headers.contentType?.mimeType,
    );
  } finally {
    client.close();
  }
}

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../core/cache/photo_cache.dart';

/// [ImageProvider] for a vehicle photo, shared by every widget that shows one
/// (garage card, vehicle header, quick-action picker).
///
/// Demo-mode vehicles carry a bundled asset path (`assets/...`) so their photos
/// render fully offline; real vehicles carry a server-relative path resolved
/// against [baseUrl] with the api key attached. Real server paths always start
/// with `/`, so the `assets/` prefix is an unambiguous discriminator.
///
/// Pair it with `ImageProbe.errorBuilder`, which is what makes a photo that will
/// not load visible in a bug report — these requests go out through
/// [PhotoCache], so the HTTP probe never sees them.
ImageProvider vehicleImageProvider({
  required String imageLocation,
  required String baseUrl,
  String? apiKey,
}) {
  if (imageLocation.startsWith('assets/')) {
    return AssetImage(imageLocation);
  }
  return CachedPhotoImage(
    path: imageLocation,
    cache: PhotoCache(baseUrl: baseUrl, apiKey: apiKey),
  );
}

/// A photo painted from [PhotoCache]: off the disk when it is there, off the
/// server otherwise — which is what leaves the garage its covers when the
/// server is gone.
///
/// Replaces `NetworkImage`, whose only cache is in memory and dies with the
/// process.
@immutable
class CachedPhotoImage extends ImageProvider<CachedPhotoImage> {
  const CachedPhotoImage({required this.path, required this.cache});

  /// Server-relative location of the photo (`/images/<guid>.jpg`).
  final String path;

  final PhotoCache cache;

  @override
  Future<CachedPhotoImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    CachedPhotoImage key,
    ImageDecoderCallback decode,
  ) =>
      MultiFrameImageStreamCompleter(
        codec: _load(decode),
        scale: 1,
        debugLabel: path,
        informationCollector: () => [DiagnosticsProperty('Photo', path)],
      );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await cache.bytes(path);
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  /// The photo identifies the key, not the store: [vehicleImageProvider] builds
  /// a fresh [PhotoCache] on every rebuild, and a key that changed with it would
  /// miss in Flutter's image cache and re-decode the garage frame after frame.
  @override
  bool operator ==(Object other) =>
      other is CachedPhotoImage &&
      other.path == path &&
      other.cache.baseUrl == cache.baseUrl;

  @override
  int get hashCode => Object.hash(path, cache.baseUrl);
}

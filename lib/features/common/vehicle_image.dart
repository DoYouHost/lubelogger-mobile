import 'package:flutter/widgets.dart';

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
/// `Image.network`, so the HTTP probe never sees them.
ImageProvider vehicleImageProvider({
  required String imageLocation,
  required String baseUrl,
  String? apiKey,
}) {
  if (imageLocation.startsWith('assets/')) {
    return AssetImage(imageLocation);
  }
  return NetworkImage(
    '$baseUrl$imageLocation',
    headers: apiKey == null ? null : {'x-api-key': apiKey},
  );
}

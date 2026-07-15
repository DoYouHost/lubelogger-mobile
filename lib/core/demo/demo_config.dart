/// Demo mode ("store review" mode) constants.
///
/// Google Play review requires full app access, but the app only works against
/// a self-hosted LubeLogger server. Instead of exposing a real server, the app
/// recognizes a magic address + token and serves a fabricated dataset entirely
/// in-process (see `DemoBackend`); no network traffic ever leaves the device in
/// demo mode.
///
/// Reviewer instructions (Play Console → App access):
///   server address: `demo`, API key: `demodemodemo`.
abstract final class DemoConfig {
  /// Canonical profile base URL saved after a demo login. A single-label host
  /// never resolves publicly, so even an accidentally un-intercepted request
  /// fails locally without leaking anything.
  static const baseUrl = 'http://demo';

  /// The magic token entered in the API-key field to unlock demo mode.
  static const token = 'demodemodemo';

  /// Whether the user-typed (normalized) server URL selects demo mode. Accepts
  /// `demo` and `demo.lubelogger.app` with any scheme.
  static bool isDemoUrl(String normalizedUrl) {
    final host = Uri.tryParse(normalizedUrl)?.host.toLowerCase();
    return host == 'demo' || host == 'demo.lubelogger.app';
  }
}

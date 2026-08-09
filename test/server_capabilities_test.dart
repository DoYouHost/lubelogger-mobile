import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/api/server_capabilities.dart';

/// The app targets LubeLogger 1.6.9 and 1.7.0. Only one endpoint separates
/// them, so this asserts the gate that decides whether it may be called — and,
/// as importantly, that an unread version does not silently disable it.
void main() {
  group('ServerCapabilities', () {
    test('1.7.0 and newer have vehicle delete', () {
      for (final version in ['1.7.0', '1.7.1', '1.8.0', '2.0.0']) {
        expect(
          ServerCapabilities.forVersion(version).vehicleDelete,
          isTrue,
          reason: version,
        );
      }
    });

    test('1.6.9 and older do not', () {
      for (final version in ['1.6.9', '1.6.10', '1.5.0']) {
        expect(
          ServerCapabilities.forVersion(version).vehicleDelete,
          isFalse,
          reason: version,
        );
      }
    });

    test('an unread version enables everything', () {
      // /api/info may not have answered yet. Hiding the action then would be a
      // permanent-looking "your server is old" for a server that isn't; the
      // request itself still fails safely with unsupportedByServer.
      for (final version in ['', '   ', 'unknown']) {
        expect(
          ServerCapabilities.forVersion(version).vehicleDelete,
          isTrue,
          reason: '"$version"',
        );
      }
    });

    test('carries the version it was read from, for the message', () {
      expect(ServerCapabilities.forVersion('1.6.9').version, '1.6.9');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/util/version.dart';

void main() {
  group('versionAtLeast', () {
    test('equal versions are at least the minimum', () {
      expect(versionAtLeast('1.7.0', '1.7.0'), isTrue);
    });

    test('newer versions clear the minimum', () {
      expect(versionAtLeast('1.7.1', '1.7.0'), isTrue);
      expect(versionAtLeast('1.8.0', '1.7.0'), isTrue);
      expect(versionAtLeast('2.0.0', '1.7.0'), isTrue);
    });

    test('older versions do not', () {
      expect(versionAtLeast('1.6.9', '1.7.0'), isFalse);
      expect(versionAtLeast('1.6.10', '1.7.0'), isFalse);
      expect(versionAtLeast('0.9.9', '1.7.0'), isFalse);
    });

    test('missing trailing components count as zero', () {
      expect(versionAtLeast('1.7', '1.7.0'), isTrue);
      expect(versionAtLeast('1.7.0', '1.7'), isTrue);
      expect(versionAtLeast('2', '1.7.0'), isTrue);
    });

    test('a leading v and non-numeric suffixes are ignored', () {
      expect(versionAtLeast('v1.7.0', '1.7.0'), isTrue);
      expect(versionAtLeast('1.7.0-beta', '1.7.0'), isTrue);
      expect(versionAtLeast('1.6.9-rc1', '1.7.0'), isFalse);
    });

    test('an unparseable or empty version is unknown (null)', () {
      expect(versionAtLeast('', '1.7.0'), isNull);
      expect(versionAtLeast('   ', '1.7.0'), isNull);
      expect(versionAtLeast('dev', '1.7.0'), isNull);
    });
  });
}

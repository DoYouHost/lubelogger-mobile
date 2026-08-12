import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/files/upload_prep.dart';

/// `prepareForUpload` promises never to lose a file. These cover the paths that
/// return before any platform channel is touched — the ones a unit test can
/// reach, and the ones that would fail silently, since a caller cannot tell an
/// untouched file from a downscaled one.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('lubelogger_prep'));
  tearDown(() => dir.deleteSync(recursive: true));

  UploadFile write(String name, int bytes) {
    final file = File('${dir.path}/$name')
      ..writeAsBytesSync(List.filled(bytes, 0x41));
    return (path: file.path, name: name);
  }

  test('a PDF is never re-encoded', () async {
    final picked = write('invoice.pdf', kUploadCompressThreshold * 2);

    expect(await prepareForUpload([picked]), [picked]);
  });

  test('a file with no extension is left alone', () async {
    final picked = write('scan', kUploadCompressThreshold * 2);

    expect(await prepareForUpload([picked]), [picked]);
  });

  test('an image below the threshold is left alone', () async {
    final picked = write('receipt.jpg', kUploadCompressThreshold - 1);

    expect(await prepareForUpload([picked]), [picked]);
  });

  test('an unreadable path falls back to the picked file', () async {
    const picked = (path: '/nonexistent/photo.jpg', name: 'photo.jpg');

    expect(await prepareForUpload([picked]), [picked]);
  });

  test('extension matching ignores case', () async {
    // Some Android camera apps hand back `IMG_0001.JPG`.
    final picked = write('IMG_0001.JPG', kUploadCompressThreshold - 1);

    expect(await prepareForUpload([picked]), [picked]);
  });

  test('order is preserved across a mixed selection', () async {
    // The result goes straight to the upload, so a reordering would pair the
    // wrong names with the wrong bytes.
    final files = [
      write('a.pdf', 10),
      write('b.txt', 10),
      write('c.pdf', 10),
    ];

    expect(await prepareForUpload(files), files);
  });
}

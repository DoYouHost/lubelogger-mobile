import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/cache/http_cache.dart';
import 'package:lubelogger_mobile/core/cache/photo_cache.dart';
import 'package:lubelogger_mobile/features/common/vehicle_image.dart';

/// A server holding one photo, which can be switched off.
class _Photos {
  bool up = true;
  String contentType = 'image/jpeg';
  int requests = 0;

  final Uint8List bytes = Uint8List.fromList([1, 2, 3, 4]);

  Future<FetchedPhoto> fetch(Uri url, Map<String, String> headers) async {
    requests++;
    if (!up) throw const SocketException('test: server is off');
    return (bytes: bytes, contentType: contentType);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late _Photos server;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('lubelogger_photo_test');
    server = _Photos();
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  PhotoCache cacheFor({
    String baseUrl = 'https://one.example',
    String? apiKey = 'key',
  }) =>
      PhotoCache(
        baseUrl: baseUrl,
        apiKey: apiKey,
        supportDirectory: () async => root,
        fetch: server.fetch,
      );

  const photo = '/images/abc.jpg';

  test('fetches once, then answers off the disk', () async {
    final cache = cacheFor();
    expect(await cache.bytes(photo), server.bytes);
    expect(await cache.bytes(photo), server.bytes);
    expect(server.requests, 1);
  });

  test('a photo fetched before survives the server going away', () async {
    await cacheFor().bytes(photo);
    server.up = false;
    // A cold instance, as after a restart: the bytes come off the disk.
    expect(await cacheFor().bytes(photo), server.bytes);
  });

  test('without a stored copy an unreachable server still fails', () async {
    server.up = false;
    expect(cacheFor().bytes(photo), throwsA(isA<SocketException>()));
  });

  test('sends the api key, and nothing when there is none', () async {
    final sent = <Map<String, String>>[];
    Future<FetchedPhoto> record(Uri url, Map<String, String> headers) {
      sent.add(headers);
      return server.fetch(url, headers);
    }

    for (final key in ['key', null]) {
      await PhotoCache(
        baseUrl: 'https://one.example',
        apiKey: key,
        supportDirectory: () async => root,
        fetch: record,
      ).bytes('/images/$key.jpg');
    }
    expect(sent, [
      {'x-api-key': 'key'},
      isEmpty,
    ]);
  });

  test('a body that is not a picture is shown but not stored', () async {
    // The proxy login page a server behind SSO answers with 200.
    server.contentType = 'text/html';
    final cache = cacheFor();
    expect(await cache.bytes(photo), server.bytes);
    await cache.bytes(photo);
    expect(server.requests, 2, reason: 'the page must not become the cover');
  });

  test("one server cannot see another's photos", () async {
    await cacheFor().bytes(photo);
    server.up = false;
    expect(
      cacheFor(baseUrl: 'https://two.example').bytes(photo),
      throwsA(isA<SocketException>()),
    );
  });

  group('prefetch', () {
    test('stores what is missing and skips what is stored', () async {
      final cache = cacheFor();
      expect(await cache.prefetch(photo), isTrue);
      expect(await cache.prefetch(photo), isFalse);
      expect(server.requests, 1);
    });

    test('reports nothing stored rather than throwing', () async {
      server.up = false;
      expect(await cacheFor().prefetch(photo), isFalse);
      expect(await cacheFor().prefetch(''), isFalse);
    });
  });

  test('photos are sized and cleared with the rest of the offline copy',
      () async {
    await cacheFor().bytes(photo);
    final lists = HttpCache(
      baseUrl: 'https://one.example',
      supportDirectory: () async => root,
    );

    expect(await lists.sizeInBytes(), server.bytes.length);
    await lists.clear();

    server.up = false;
    expect(cacheFor().bytes(photo), throwsA(isA<SocketException>()));
  });

  test('the image key holds across rebuilds', () {
    // Every rebuild hands the provider a fresh PhotoCache; a key that changed
    // with it would re-decode the whole garage frame after frame.
    providerFor(String path) => vehicleImageProvider(
          imageLocation: path,
          baseUrl: 'https://one.example',
          apiKey: 'key',
        );

    expect(providerFor(photo), providerFor(photo));
    expect(providerFor(photo), isNot(providerFor('/images/other.jpg')));
    expect(
      providerFor(photo),
      isNot(
        vehicleImageProvider(
          imageLocation: photo,
          baseUrl: 'https://two.example',
          apiKey: 'key',
        ),
      ),
    );
    expect(
      vehicleImageProvider(
        imageLocation: 'assets/demo/car.jpg',
        baseUrl: 'https://one.example',
      ),
      isA<AssetImage>(),
    );
  });
}

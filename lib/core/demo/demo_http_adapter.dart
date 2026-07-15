import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'demo_backend.dart';

/// Dio [HttpClientAdapter] for demo mode: routes every request into
/// [DemoBackend] instead of the network. Installed by [ApiClient] when the
/// active profile is the demo profile, so every consumer of the authenticated
/// Dio (repositories, background reminder isolate) is covered without further
/// changes.
class DemoHttpClientAdapter implements HttpClientAdapter {
  DemoHttpClientAdapter({this.latency = const Duration(milliseconds: 140)});

  /// Simulated network latency so the UI's loading states stay visible.
  final Duration latency;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(latency);

    // Attachment uploads arrive as multipart FormData, which the backend can't
    // route — answer them here with a fabricated `UploadedFiles` array so the
    // add/edit-with-attachment flow still completes.
    if (options.data is FormData) {
      return _json(_fakeUploads(options.data as FormData), 200);
    }

    final result = DemoBackend.instance.handle(
      options.method.toUpperCase(),
      options.uri,
      _decodedBody(options.data),
    );
    return _json(result.body, result.status);
  }

  ResponseBody _json(Object? body, int status) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  /// One `UploadedFiles` entry per uploaded file, echoing its name so the
  /// record shows the file the reviewer picked.
  List<Map<String, dynamic>> _fakeUploads(FormData form) => [
        for (final entry in form.files)
          {
            'name': entry.value.filename ?? 'attachment',
            'location': '/documents/demo-${entry.value.filename ?? 'file'}',
            'isPending': false,
          },
      ];

  /// Request payloads arrive as the original Dio `data` (map/list/JSON string).
  Object? _decodedBody(Object? data) {
    if (data is String && data.isNotEmpty) {
      try {
        return jsonDecode(data);
      } on FormatException {
        return null;
      }
    }
    return data;
  }

  @override
  void close({bool force = false}) {}
}

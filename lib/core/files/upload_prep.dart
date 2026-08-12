import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../diagnostics/diagnostic_recorder.dart';
import '../diagnostics/log_event.dart';

/// A picked file on its way to `POST /api/documents/upload`.
typedef UploadFile = ({String path, String name});

/// The plugin treats this as a floor on *both* edges, so the shorter one lands
/// here and a 4:3 photo comes out around 2133x1600.
const int kUploadImageShorterEdge = 1600;

const int kUploadImageQuality = 85;

/// Below this, re-encoding costs quality and saves nothing.
const int kUploadCompressThreshold = 512 * 1024;

/// HEIC becomes JPEG because LubeLogger serves `/documents` byte-for-byte and
/// no desktop browser renders HEIC. PNG stays PNG so a screenshot keeps its
/// alpha instead of gaining a black background.
const Map<String, CompressFormat> _recompressible = {
  'jpg': CompressFormat.jpeg,
  'jpeg': CompressFormat.jpeg,
  'heic': CompressFormat.jpeg,
  'heif': CompressFormat.jpeg,
  'png': CompressFormat.png,
};

/// Downscales large photos before upload, in order.
///
/// Never fails a file: anything that cannot be re-encoded comes back exactly as
/// picked, so the worst case is the behaviour from before this step existed.
Future<List<UploadFile>> prepareForUpload(List<UploadFile> files) async {
  final prepared = <UploadFile>[];
  for (final file in files) {
    prepared.add(await _downscale(file));
  }
  return prepared;
}

Future<UploadFile> _downscale(UploadFile file) async {
  final format = _recompressible[_extensionOf(file.name)];
  if (format == null) return file;

  try {
    final original = await File(file.path).length();
    if (original <= kUploadCompressThreshold) return file;

    final dir = await getTemporaryDirectory();
    final extension = format == CompressFormat.png ? 'png' : 'jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      '${dir.path}/upload_${DateTime.now().microsecondsSinceEpoch}.$extension',
      format: format,
      quality: kUploadImageQuality,
      minWidth: kUploadImageShorterEdge,
      minHeight: kUploadImageShorterEdge,
    );
    if (result == null) return file;

    // An optimised export can survive the round trip larger than it went in.
    final shrunk = await result.length();
    if (shrunk >= original) {
      await File(result.path).delete();
      return file;
    }

    _log(original: original, shrunk: shrunk);
    return (path: result.path, name: _renamed(file.name, extension));
  } on Object catch (error) {
    DiagnosticRecorder.active?.add(
      LogSource.app,
      'attachment_downscale_failed',
      lvl: LogLevel.warn,
      fields: {'type': error.runtimeType.toString()},
    );
    return file;
  }
}

/// Sizes only — a file name is the user's.
void _log({required int original, required int shrunk}) =>
    DiagnosticRecorder.active?.add(
      LogSource.app,
      'attachment_downscaled',
      fields: {'from': original, 'to': shrunk},
    );

String? _extensionOf(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return null;
  return name.substring(dot + 1).toLowerCase();
}

/// The server stores the file under `Path.GetExtension(FileName)`, so JPEG
/// bytes announced as `.heic` get saved — and served back — as HEIC.
String _renamed(String name, String extension) {
  final dot = name.lastIndexOf('.');
  final stem = dot < 0 ? name : name.substring(0, dot);
  return '$stem.$extension';
}

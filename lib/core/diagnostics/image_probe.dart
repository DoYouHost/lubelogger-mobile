import 'package:flutter/widgets.dart';

import 'diagnostic_recorder.dart';
import 'log_event.dart';

/// Records vehicle photos that will not load.
///
/// Photos are the one thing the app fetches outside dio — `Image.network` with
/// the api key as a header — so [HttpProbe] never sees them. A proxy that strips
/// the header, or a server that answers HTML for `/documents`, reads on screen
/// as a car with no picture and, without this, appears nowhere in the log.
///
/// A probe in `core` rather than a helper next to the widgets, so the recorder
/// can reset it at the start of a session without `core` reaching into
/// `features`.
abstract final class ImageProbe {
  /// Failures already reported this session, by exception type.
  ///
  /// `errorBuilder` runs on every rebuild of a broken image, and a garage of ten
  /// cars would otherwise write a record per card per frame. The type carries
  /// the diagnosis (`NetworkImageLoadException` versus a decode failure); which
  /// of the cars it was is not a question anybody asks.
  static final Set<String> _reported = {};

  /// Shows [placeholder] when an image fails, and reports the failure once.
  static ImageErrorWidgetBuilder errorBuilder(Widget placeholder) =>
      (context, error, stack) {
        _report(error);
        return placeholder;
      };

  /// Called when a recording opens, so a failure seen in an earlier session does
  /// not silence the first one of this session.
  static void openSession() => _reported.clear();

  static void _report(Object error) {
    final type = error.runtimeType.toString();
    if (!_reported.add(type)) return;
    DiagnosticRecorder.active?.add(
      LogSource.ui,
      'image_failed',
      lvl: LogLevel.warn,
      fields: {'type': type},
    );
  }
}

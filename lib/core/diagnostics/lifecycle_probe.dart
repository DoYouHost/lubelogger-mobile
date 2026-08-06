import 'package:flutter/widgets.dart';

import 'log_event.dart';
import 'log_store.dart';

/// Records the app going to the background and coming back.
///
/// Without it every such gap reads as a hang: a log that goes quiet for forty
/// seconds and then resumes mid-fetch looks exactly like an app that froze,
/// while what usually happened is that the screen turned off. One record per
/// transition turns "it stopped responding" into a timeline.
class LifecycleProbe {
  LifecycleProbe({required this.store});

  final LogStore store;

  /// What earns a record. `inactive` and `hidden` also fire for a pulled-down
  /// notification shade, a permission dialog or the app switcher — states the
  /// user does not experience as leaving the app, and which would put three
  /// records where the interesting one is `paused`.
  static const _reported = {
    AppLifecycleState.resumed,
    AppLifecycleState.paused,
    AppLifecycleState.detached,
  };

  AppLifecycleListener? _listener;

  void attach() {
    _listener ??= AppLifecycleListener(onStateChange: _onStateChange);
  }

  void detach() {
    _listener?.dispose();
    _listener = null;
  }

  void _onStateChange(AppLifecycleState state) {
    if (!_reported.contains(state)) return;
    store.add(LogSource.app, 'lifecycle', fields: {'state': state.name});
  }
}

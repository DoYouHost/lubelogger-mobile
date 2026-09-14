import 'dart:io';

import 'package:app_diagnostics/app_diagnostics.dart';

import '../settings/settings_repository.dart';
import 'image_probe.dart';
import 'report_config.dart';

/// The app's one recorder configuration. Tests pass an in-memory
/// [resolveDirectory] and their own facts; everything else is what ships.
DiagnosticRecorder lubeloggerRecorder({
  required SettingsRepository settings,
  required Future<SessionFacts> Function() loadFacts,
  Future<Directory?> Function() resolveDirectory = diagnosticsDirectory,
}) => DiagnosticRecorder(
  sessions: settings.diagnosticsSessions,
  redactor: lubeloggerRedactor,
  loadFacts: loadFacts,
  sessionDuration: recordingLimit,
  sessionBytes: recordingSizeLimit,
  listeners: [LubeloggerSessionListener(settings)],
  resolveDirectory: resolveDirectory,
);

/// What LubeLogger adds when a recording opens.
class LubeloggerSessionListener implements DiagnosticSessionListener {
  const LubeloggerSessionListener(this.settings);

  final SettingsRepository settings;

  @override
  void onSessionStart() {
    // A record rather than a header field: the user can change any of it
    // mid-session, and each change writes its own `setting` record.
    final snapshot = settings.diagnosticsSnapshot();
    if (snapshot.isNotEmpty) {
      DiagnosticRecorder.active?.add(
        LogSource.app,
        'settings',
        fields: snapshot,
      );
    }
    ImageProbe.openSession();
  }

  /// Nothing here aggregates, so nothing is left to write out.
  @override
  void onSessionFlush() {}
}

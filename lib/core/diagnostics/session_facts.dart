import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:package_info_plus/package_info_plus.dart';

import '../auth/credentials_store.dart';
import '../settings/server_profile.dart';
import 'log_event.dart';

/// Everything the recorder needs to describe a session, plus the exact secrets
/// it must never let through. Gathered once when recording starts — package info
/// and secure storage are both async, and neither changes mid-session.
class SessionFacts {
  const SessionFacts({
    required this.app,
    this.os,
    this.locale,
    this.server,
    this.serverUrl,
    this.demo = false,
    this.secrets = const {},
  });

  final String app;
  final String? os;
  final String? locale;

  /// LubeLogger version, as the server reports it at `/api/version`. Empty when
  /// the server could not be reached or answered something unparseable — which
  /// is itself worth seeing in a report.
  final String? server;

  final ServerFingerprint? serverUrl;

  /// Store-review demo mode.
  final bool demo;

  /// Exact value → redaction label, handed to the session's redactor.
  final Map<String, String> secrets;

  LogHeader toHeader({
    required DateTime ts,
    required String session,
    LogStream stream = LogStream.ui,
  }) => LogHeader(
    ts: ts,
    session: session,
    app: app,
    stream: stream,
    os: os,
    locale: locale,
    server: server,
    serverUrl: serverUrl,
    demo: demo,
  );
}

/// The exact values a session's redactor must never let through.
///
/// Split out of [loadSessionFacts] for the background isolate: it inherits the
/// UI stream's header off disk, so it needs none of the facts — but it does need
/// these, and with an empty redactor the first records it writes are the ones
/// that carry secrets. A `SocketException` reads "Failed host lookup:
/// 'lube.example'", which is not a URL, so only an exact value catches it.
///
/// Deliberately without `PackageInfo`: this runs on a background isolate's path
/// to doing its actual job, and one platform channel is one more thing that can
/// hang or throw there.
Future<Map<String, String>> sessionSecrets({
  required ServerProfile? profile,
  required CredentialsStore credentials,
}) async {
  final secrets = <String, String>{};

  // Registered as an exact value so it is cut even when it surfaces inside a
  // message we did not format, e.g. a server error echoing the key back.
  final apiKey = await _quietly(credentials.readApiKey);
  if (apiKey != null) secrets[apiKey] = '[APIKEY]';

  // Not in demo mode: the demo host is a constant shipped in the APK, there is
  // nothing to protect, and registering `demo` would mask that word everywhere
  // it legitimately appears — starting with every control id on the setup screen.
  if (profile != null && !profile.isDemo) {
    final host = Uri.tryParse(profile.baseUrl)?.host;
    if (host != null && host.isNotEmpty) secrets[host] = '[HOST]';
  }

  return secrets;
}

/// Reads the real facts off the device and the stored profile.
///
/// [readServerVersion] is awaited for the header's `server` field. It is a
/// callback rather than a value because the version comes off the network, and
/// the header is written once at the top of the log: which LubeLogger build
/// produced the behaviour below is the first question every report raises. A
/// failure to read it is swallowed — a recording must start regardless.
Future<SessionFacts> loadSessionFacts({
  required ServerProfile? profile,
  required CredentialsStore credentials,
  Future<String?> Function()? readServerVersion,
}) async {
  final info = await PackageInfo.fromPlatform();
  final secrets = await sessionSecrets(
    profile: profile,
    credentials: credentials,
  );

  return SessionFacts(
    app: '${info.version}+${info.buildNumber}',
    os: Platform.operatingSystemVersion,
    locale: PlatformDispatcher.instance.locale.toLanguageTag(),
    server: readServerVersion == null
        ? null
        : await _quietly(readServerVersion),
    serverUrl: ServerFingerprint.tryParse(profile?.baseUrl),
    demo: profile?.isDemo ?? false,
    secrets: secrets,
  );
}

/// Secure storage can throw on a wiped keystore; a missing secret must not
/// stop a recording from starting.
Future<String?> _quietly(Future<String?> Function() read) async {
  try {
    return await read();
  } on Object {
    return null;
  }
}

import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:app_diagnostics/app_diagnostics.dart';

import '../auth/credentials_store.dart';
import '../settings/server_profile.dart';

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
  final app = await readAppVersion();
  final secrets = await sessionSecrets(
    profile: profile,
    credentials: credentials,
  );

  return SessionFacts(
    app: app,
    os: Platform.operatingSystemVersion,
    locale: PlatformDispatcher.instance.locale.toLanguageTag(),
    server: readServerVersion == null
        ? null
        : await _quietly(readServerVersion),
    serverUrl: ServerFingerprint.tryParse(profile?.baseUrl),
    secrets: secrets,
    extra: {
      if (profile?.isDemo ?? false) 'demo': true,
      ...await deviceEnvironment(),
    },
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

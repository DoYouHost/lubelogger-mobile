import 'dart:io';
import 'dart:ui' show Brightness, PlatformDispatcher;

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart' show MediaQueryData;
import 'package:package_info_plus/package_info_plus.dart';

import '../auth/credentials_store.dart';
import '../settings/server_profile.dart';

/// When the process started, stamped by `main()`.
///
/// The header's `ts` is when *recording* started, which says nothing about how
/// long the app had been up — and that is the difference between a screen a
/// second after launch and the same screen showing a list fetched four hours
/// ago, because every list in this app is cached by a provider for the life of
/// the run. "Have you tried restarting the app" stops being a question.
abstract final class AppStart {
  static DateTime? at;

  static int? get uptimeSeconds {
    final started = at;
    if (started == null) return null;
    final seconds = DateTime.now().difference(started).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }
}

/// The device, the screen and the clock — everything that is true of the phone
/// rather than of the app, as flat scalars for the session header.
///
/// None of it identifies anybody: a make and model are shared by millions, and
/// the UTC offset is coarser than the locale already in the header. What they
/// buy is the follow-up question that otherwise always gets asked. In order of
/// how often that is:
///
/// * `device` / `sdk` — whether a background task survives is the OEM battery
///   manager's decision, so a reminder that never arrives is usually answered by
///   the make of the phone;
/// * `tz` — this app is a log of dates, and "the date is one day off" is a UTC
///   offset until proven otherwise;
/// * `screen` / `text_scale` — a control pushed off the edge is a layout report
///   that is unreproducible without both;
/// * `emulator` — present only when true, and then it is the whole context.
///
/// Every step is guarded: a missing fact costs a line in the header, and a
/// recording must start whatever the platform channel says.
Future<Map<String, Object?>> deviceEnvironment() async => {
  'tz': _utcOffset(DateTime.now()),
  ..._screenFacts(),
  ...await _deviceFacts(),
  'uptime_s': AppStart.uptimeSeconds,
};

/// `+02:00`, the notation a reader already knows from an ISO timestamp.
String _utcOffset(DateTime now) {
  final offset = now.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final minutes = offset.inMinutes.abs();
  final hh = '${minutes ~/ 60}'.padLeft(2, '0');
  final mm = '${minutes % 60}'.padLeft(2, '0');
  return '$sign$hh:$mm';
}

/// Size in logical pixels — what layout code actually works in — plus the
/// density it was scaled from. Text scale and dark mode appear only when they
/// are not the default, so a header stays short for the common case.
Map<String, Object?> _screenFacts() {
  try {
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) return const {};
    final media = MediaQueryData.fromView(view);
    // `scale` is defined at a font size, so read the factor off one: a non-linear
    // scaler has no single multiplier, and this is the one that matters for body
    // text.
    final textScale = media.textScaler.scale(14) / 14;
    return {
      'screen':
          '${media.size.width.round()}x${media.size.height.round()}'
          '@${media.devicePixelRatio.toStringAsFixed(2)}',
      if ((textScale - 1).abs() > 0.01)
        'text_scale': double.parse(textScale.toStringAsFixed(2)),
      if (media.platformBrightness == Brightness.dark) 'dark': true,
    };
  } on Object {
    return const {};
  }
}

Future<Map<String, Object?>> _deviceFacts() async {
  if (!Platform.isAndroid) return const {};
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    return {
      'device': '${info.manufacturer} ${info.model}',
      'sdk': info.version.sdkInt,
      if (!info.isPhysicalDevice) 'emulator': true,
    };
  } on Object {
    return const {};
  }
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

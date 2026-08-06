import 'dart:convert';
import 'dart:math';

/// Source of a record. The enum names are wire values — they end up in the
/// JSONL a bug report carries, so renaming one breaks every log already
/// attached to an issue. Declaration order is the order the review screen lists
/// them in.
enum LogSource { http, ui, notif, err, app }

/// Severity. [LogLevel.info] is the default and is omitted from the encoded
/// record; most lines are info, so spelling it out would just pad the upload.
enum LogLevel { debug, info, warn, error }

/// Which isolate produced the stream. Each has its own heap, so each writes its
/// own file with its own header; the export merges them on absolute time
/// (`ts` + `t`), never on `t` alone.
///
/// [worker] is the WorkManager isolate that runs the past-due reminder check —
/// it does real HTTP and posts notifications, and it is invisible from the UI.
/// The name is a wire value: it lands in a header and in every merged record's
/// `iso`.
enum LogStream { ui, worker }

/// Shape of the server host. A bare IP means a direct LAN setup, a name means
/// DNS or a reverse proxy in front — that distinction explains a good share of
/// TLS and connectivity reports and says nothing about who the user is.
enum HostKind { ip, name }

/// What we keep from the server URL: enough to reason about the setup, nothing
/// that identifies the user's network. The address itself is the user's private
/// host and never enters a log.
class ServerFingerprint {
  const ServerFingerprint({
    required this.scheme,
    required this.hostKind,
    this.port,
  });

  /// Returns null for anything unparseable — a fingerprint is a nice-to-have,
  /// never a reason to fail the recording.
  static ServerFingerprint? tryParse(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return null;
    return ServerFingerprint(
      scheme: uri.scheme,
      hostKind: _looksLikeIp(uri.host) ? HostKind.ip : HostKind.name,
      // Effective port, so 443 vs 8080 tells us whether a proxy is in play.
      port: uri.hasPort ? uri.port : _defaultPorts[uri.scheme],
    );
  }

  static const _defaultPorts = {'http': 80, 'https': 443};

  static final _ipish = RegExp(r'^[0-9.]+$|:');

  /// Digits-and-dots or anything with a colon (IPv6 literal). Deliberately
  /// loose — a wrong guess here only mislabels a hint, it can't leak.
  static bool _looksLikeIp(String host) => _ipish.hasMatch(host);

  final String scheme;
  final HostKind hostKind;
  final int? port;

  Map<String, Object?> toJson() => {
    'scheme': scheme,
    'host_kind': hostKind.name,
    if (port != null) 'port': port,
  };
}

/// First line of every log file: everything that is true for the whole session.
class LogHeader {
  const LogHeader({
    required this.ts,
    required this.session,
    required this.app,
    this.stream = LogStream.ui,
    this.os,
    this.locale,
    this.server,
    this.serverUrl,
    this.demo = false,
    this.extra = const {},
  });

  /// Bumped when the record shape changes in a way a parser must know about.
  ///
  /// Adding a key to [extra] is not such a change: readers ignore what they do
  /// not know, and the relay accepts a fixed window of versions, so a bump costs
  /// a deployment before any build that sends one.
  static const formatVersion = 1;

  /// Keys this class owns. Everything else on a header line belongs to [extra]
  /// and is carried through untouched.
  static const _ownKeys = {
    'v',
    'ts',
    'session',
    'stream',
    'app',
    'os',
    'locale',
    'server',
    'scheme',
    'host_kind',
    'port',
    'demo',
  };

  /// Reads a header line back, or null when the line is not the header of
  /// [session].
  ///
  /// Exists for the background isolate: it does not build a header of its own,
  /// it continues the one the UI wrote, so it has to read it off disk. The
  /// checks are the point — a header write is allowed to fail silently while the
  /// writes after it succeed, so the first line of a stream is not guaranteed to
  /// be a header at all, and accepting a *record* as one yields a header with no
  /// `ts`, which makes the merge drop the whole background stream.
  static LogHeader? tryParse(String line, {required String session}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on Object {
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;
    final fields = decoded;
    if (fields.containsKey('t')) return null;
    if (fields['session'] != session) return null;
    final ts = DateTime.tryParse('${fields['ts']}');
    final app = fields['app'];
    if (ts == null || app is! String) return null;
    return LogHeader(
      ts: ts,
      session: session,
      app: app,
      stream: LogStream.values.firstWhere(
        (s) => s.name == fields['stream'],
        orElse: () => LogStream.ui,
      ),
      os: fields['os'] as String?,
      locale: fields['locale'] as String?,
      server: fields['server'] as String?,
      serverUrl: switch (fields['scheme']) {
        final String scheme => ServerFingerprint(
          scheme: scheme,
          hostKind: fields['host_kind'] == HostKind.ip.name
              ? HostKind.ip
              : HostKind.name,
          port: fields['port'] as int?,
        ),
        _ => null,
      },
      demo: fields['demo'] == true,
      extra: {
        for (final e in fields.entries)
          if (!_ownKeys.contains(e.key)) e.key: e.value,
      },
    );
  }

  /// The same session, tagged as a different stream — what the background
  /// isolate writes at the top of its own file.
  LogHeader copyWith({LogStream? stream}) => LogHeader(
    ts: ts,
    session: session,
    app: app,
    stream: stream ?? this.stream,
    os: os,
    locale: locale,
    server: server,
    serverUrl: serverUrl,
    demo: demo,
    extra: extra,
  );

  /// Session identifier shared by every stream file of one recording.
  /// 128 random bits as hex — no uuid dependency for what is just a join key.
  static String newSessionId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
  }

  /// Wall-clock start of this stream; every record's `t` is an offset from it.
  final DateTime ts;
  final String session;

  /// Full app version, e.g. `0.2.7+207`.
  final String app;

  final LogStream stream;

  /// OS build string, e.g. what `Platform.operatingSystemVersion` reports.
  final String? os;

  final String? locale;

  /// LubeLogger version as the server reports it — never the server URL, which
  /// is the user's private host. Half of the wire-format reports come down to
  /// which build is answering.
  final String? server;

  /// Scheme / host shape / port of the server URL. http-vs-https alone explains
  /// a whole class of reports, so it is a first-class header field rather than
  /// something to dig out of redacted strings.
  final ServerFingerprint? serverUrl;

  /// Store-review demo mode: every response came from the in-process fake, so
  /// nothing below describes a real server.
  final bool demo;

  /// Everything else that is true for the whole session — the device, the time
  /// zone, the screen. Kept as an open map rather than as fields so a new fact
  /// survives the one round trip that would otherwise silently drop it: the
  /// background isolate reads this header off disk and writes it back out at the
  /// top of its own stream.
  ///
  /// **Scalars only.** The relay renders this map into the issue and rejects
  /// anything else; see `SessionFacts.environment` for what goes in.
  final Map<String, Object?> extra;

  Map<String, Object?> toJson() => {
    'v': formatVersion,
    'ts': ts.toUtc().toIso8601String(),
    'session': session,
    'stream': stream.name,
    'app': app,
    if (os != null) 'os': os,
    if (locale != null) 'locale': locale,
    if (server != null) 'server': server,
    if (serverUrl != null) ...serverUrl!.toJson(),
    if (demo) 'demo': true,
    // Last, and never over an own key: a fact that collided with `session` or
    // `ts` would change what the line means rather than add to it.
    for (final e in extra.entries)
      if (!_ownKeys.contains(e.key) && e.value != null) e.key: e.value,
  };

  String toJsonLine() => jsonEncode(toJson());
}

/// One event line. Extra [fields] are spread flat into the record so a reader
/// can find `status` or `code` without unwrapping a payload object.
class LogEvent {
  LogEvent({
    required this.t,
    required this.src,
    required this.evt,
    this.lvl = LogLevel.info,
    Map<String, Object?> fields = const {},
  }) : fields = _usableFields(fields);

  /// Keys the record owns. A caller-supplied `t` or `evt` would silently
  /// overwrite the record's own, so those are dropped rather than nested.
  ///
  /// `iso` is here although no record ever sets it: [mergeSessions] stamps it on
  /// the way out, and a probe that used the same name for a field of its own
  /// would make a record claim to come from an isolate it did not.
  static const reservedKeys = {'t', 'src', 'lvl', 'evt', 'iso'};

  /// Milliseconds since the header's `ts`.
  final int t;
  final LogSource src;
  final String evt;
  final LogLevel lvl;
  final Map<String, Object?> fields;

  static Map<String, Object?> _usableFields(Map<String, Object?> fields) {
    if (fields.isEmpty) return const {};
    return {
      for (final e in fields.entries)
        // Nulls are dropped so call sites can pass optional values
        // unconditionally without padding every line with `"x":null`.
        if (e.value != null && !reservedKeys.contains(e.key)) e.key: e.value,
    };
  }

  Map<String, Object?> toJson() => {
    't': t,
    'src': src.name,
    if (lvl != LogLevel.info) 'lvl': lvl.name,
    'evt': evt,
    ...fields,
  };

  String toJsonLine() => jsonEncode(toJson());
}

/// Strips secrets from records **at write time**. Redacting at export would
/// leave keys sitting in memory and in the worker's file until the user hits
/// send — a crash in between would ship them anyway.
///
/// Three layers:
///
/// * exact values the app knows it holds (the API key, the server host),
///   registered via [remember];
/// * shape-based passes for whatever slipped in through a message we do not
///   control — a URL, a JWT, an e-mail, an IP;
/// * [scrubSample], for the one sampled response record the HTTP probe keeps.
///   That one is the user's own data (plates, notes, custom fields), so it is
///   allowlisted by shape instead of denylisted by name — see there.
class LogRedactor {
  LogRedactor({this.maxStringLength = 2000});

  /// Ceiling for a single string value. Stack traces are the only field that
  /// reaches it; ~2000 chars is roughly 25 frames, enough to place the failure
  /// while keeping one bad record from eating the whole ring buffer.
  final int maxStringLength;

  /// Exact values → replacement label, longest first at scrub time so
  /// "lube.example.com" wins over "lube".
  final Map<String, String> _known = {};

  /// Below this length an exact match is more likely to be a coincidence
  /// inside an unrelated word than a real secret.
  static const _minKnownLength = 4;

  /// Fields whose value comes from the app's own vocabulary, never from the
  /// user or the server: control identifiers, route paths, roles, enum names.
  ///
  /// They skip the scrub because scrubbing them costs more than it protects: a
  /// server called `garage` would turn `garage.card` into `[HOST].card` and
  /// every `/garage` route into `[HOST]`, i.e. mangle exactly the fields that
  /// make a log readable.
  ///
  /// Each value still has to look like what it claims to be, so a stray
  /// `logTag('vehicle.card.$plate')` is caught by the scrub anyway.
  static final ourKeys = {
    // Control identifiers, and the screen a shared widget found itself on —
    // both dotted names this app writes itself (`garage.card`, `vehicle.fuel`).
    'id': RegExp(r'^\w+(\.\w+)*$'),
    'surface': RegExp(r'^\w+(\.\w+)*$'),
    // Route locations: `/vehicle/12`, `/settings/bug-report`. And the request
    // path, which is the API's own vocabulary — a server called `vehicle` would
    // otherwise turn every `/api/vehicle/...` into `/api/[HOST]/...`.
    'to': RegExp(r'^/[\w\-/:]*$'),
    'from': RegExp(r'^/[\w\-/:]*$'),
    'path': RegExp(r'^/[\w\-/.]*$'),
    'role': RegExp(r'^[a-zA-Z]+$'),
    'kind': RegExp(r'^[a-zA-Z]+$'),
    'state': RegExp(r'^[a-zA-Z]+$'),
    'reason': RegExp(r'^[a-zA-Z]+$'),
    'method': RegExp(r'^[A-Z]+$'),
    'dir': RegExp(r'^[a-z]+$'),
    // Launcher shortcut names, straight out of `QuickActionsService`.
    'action': RegExp(r'^[a-z]+(_[a-z]+)*$'),
    // A class or enum name: a Dart exception type, a dio error type, an
    // `AppErrorCode`. Never a value.
    'type': RegExp(r'^[A-Za-z_][A-Za-z0-9_<>, ]*$'),
    // Where an uncaught error came from — `flutter` or `async`.
    'via': RegExp(r'^[a-z]+$'),
    // An attachment's extension, which is what decides how the app opens it.
    // The name it came off is the user's and never reaches a record.
    'ext': RegExp(r'^[a-z0-9]{1,8}$'),
    // Which ceiling ended a recording, `time` or `size` — both short enough to
    // be eaten by a server that happens to be named one of them.
    'limit': RegExp(r'^[a-z]+$'),
  };

  /// Field names whose value is secret whatever its shape.
  ///
  /// A standalone `key` is fenced by non-alphanumerics so it catches `key`,
  /// `api-key` and `x-api-key` while leaving `keyboard` and `monkey` alone.
  /// `username` and `email` are in here because a LubeLogger instance is often
  /// shared by a household or a small fleet, and naming the other accounts in a
  /// public issue has never been the diagnosis.
  static final _secretKey = RegExp(
    r'(token|api_?key|(?:^|[^a-z0-9])key(?:$|[^a-z0-9])|secret|password|passwd'
    r'|authorization|cookie|username|email)',
    caseSensitive: false,
  );

  /// Splits a URL into scheme / optional userinfo / host / optional port so the
  /// host can go while the rest stays. What the user actually picked — http vs
  /// https, 443 vs 8080 — is half the diagnosis; the address is theirs.
  static final _urlAuthority = RegExp(
    r'((?:https?)://)([^@/\s]+@)?([^:/\s?#]+)(:\d+)?',
    caseSensitive: false,
  );
  static final _jwt = RegExp(
    r'\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*',
  );
  static final _queryToken = RegExp(
    r'([?&](?:token|access_token|api_?key|key)=)[^&\s]+',
    caseSensitive: false,
  );
  static final _email = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
  );

  /// IPv4, skipping version shapes like `1.4.9.0` — the `[1-9]\d|\d`
  /// alternations reject leading-zero octets, and a server version is matched
  /// as a whole string by [_isTechnical] before this ever runs on it.
  static final _ipv4 = RegExp(
    r'\b(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)\.){3}'
    r'(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)\b',
  );

  /// Registers a value the app holds and must never log. Safe to call with
  /// null or a short value — both are ignored.
  void remember(String? value, String label) {
    if (value == null || value.length < _minKnownLength) return;
    _known[value] = label;
  }

  /// Registers the server host so it is masked even where it appears without a
  /// scheme — "Failed host lookup: 'lube.lan'" is a socket error message, not a
  /// URL, so the authority pass would never see it.
  ///
  /// Only the host goes in: registering `host:port` too would swallow the port
  /// before the authority pass gets a chance to keep it.
  void rememberServerUrl(String? url) {
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return;
    remember(uri.host, '[HOST]');
  }

  void forget(String? value) {
    if (value != null) _known.remove(value);
  }

  void forgetAll() => _known.clear();

  /// The value of a secret-named field, which is the label — except for `null`,
  /// which stays `null`: whether a field is set at all is often the diagnosis,
  /// and `[REDACTED]` on an absent value reads as "configured".
  static Object? _redacted(Object? value) =>
      value == null ? null : '[REDACTED]';

  Map<String, Object?> scrubFields(Map<String, Object?> fields) {
    if (fields.isEmpty) return const {};
    return {
      for (final e in fields.entries)
        e.key: _secretKey.hasMatch(e.key)
            ? _redacted(e.value)
            : _isOurs(e.key, e.value)
            ? e.value
            : scrub(e.value),
    };
  }

  static bool _isOurs(String key, Object? value) {
    final shape = ourKeys[key];
    return shape != null && value is String && shape.hasMatch(value);
  }

  /// Recursively scrubs strings inside maps and lists; other scalars pass
  /// through untouched (an int can't carry a key).
  Object? scrub(Object? value) {
    if (value is String) return scrubString(value);
    if (value is Map) {
      return {
        for (final e in value.entries)
          '${e.key}': _secretKey.hasMatch('${e.key}')
              ? _redacted(e.value)
              : _isOurs('${e.key}', e.value)
              ? e.value
              : scrub(e.value),
      };
    }
    if (value is List) return [for (final v in value) scrub(v)];
    return value;
  }

  String scrubString(String input) {
    if (input.isEmpty) return input;
    var out = input;

    // Longest first: a shorter known value may be a prefix of a longer one.
    final values = _known.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final value in values) {
      if (out.contains(value)) out = out.replaceAll(value, _known[value]!);
    }

    out = out
        .replaceAllMapped(
          _urlAuthority,
          (m) =>
              '${m[1]}${m[2] == null ? '' : '[CREDENTIALS]@'}'
              '[HOST]${m[4] ?? ''}',
        )
        .replaceAll(_jwt, '[JWT]')
        .replaceAllMapped(_queryToken, (m) => '${m[1]}[REDACTED]')
        .replaceAll(_email, '[EMAIL]')
        .replaceAll(_ipv4, '[IP]');

    if (out.length > maxStringLength) {
      out = '${out.substring(0, maxStringLength)}…[clipped]';
    }
    return out;
  }

  /// A sampled response record, with the user's data taken out of it.
  ///
  /// This is the one place the log carries something the server sent back, and
  /// in LubeLogger that is the user's own life: plates, notes, part numbers,
  /// and `extraFields`, whose keys *and* values the user invents. A denylist of
  /// field names can never cover a schema the user extends at runtime, so the
  /// rule is inverted — a string survives only if it looks *technical*
  /// ([_isTechnical]); anything else becomes `<str:N>`.
  ///
  /// [_freeTextKeys] then takes the shape rule back off the fields that are
  /// known to be the user's, because "one word of letters" is the shape of an
  /// enum value and of a one-word note alike.
  ///
  /// That keeps what a bug report is actually read for — which fields the
  /// server sent, in what types, and how it formatted its dates and numbers
  /// (`"01/15/2024"` versus `"2024-01-15"` is the single most common
  /// wire-format report) — while the content of a note never leaves the phone.
  /// Field *names* are kept: they are the API's schema, not the user's data,
  /// except where [_secretKey] says otherwise.
  /// [key] is the field the value came off, which decides whether the shape rule
  /// gets a say at all — see [_freeTextKeys].
  Object? scrubSample(Object? value, {String? key}) {
    if (value is String) {
      if (value.isEmpty) return value;
      final field = key?.toLowerCase();
      if (field != null && _schemaKeys.contains(field)) {
        return scrubString(value);
      }
      return field != null && _freeTextKeys.contains(field)
          ? '<str:${value.length}>'
          : _isTechnical(value)
          ? scrubString(value)
          : '<str:${value.length}>';
    }
    if (value is Map) {
      return {
        for (final e in value.entries)
          '${e.key}': _secretKey.hasMatch('${e.key}')
              ? _redacted(e.value)
              : scrubSample(e.value, key: '${e.key}'),
      };
    }
    // Only the head of a nested list: a vehicle's `extraFields` or a record's
    // `files` can be long, and the second entry says nothing the first did not.
    // The key travels with it — `tags` is a list, and each entry is as much the
    // user's as the field is.
    if (value is List) {
      return [for (final v in value.take(3)) scrubSample(v, key: key)];
    }
    return value;
  }

  /// Fields the user writes into, whose value is therefore theirs whatever it
  /// looks like.
  ///
  /// This is the counterweight to [_enumish], which keeps any single word of
  /// letters because that is the shape of `Gasoline` and `PastDue` — and also
  /// the shape of a one-word note. The schema is closed enough to name where
  /// that matters: the record text fields, the vehicle's identity, and the
  /// `name`/`value` pair of an `extraFields` entry, which is the one place the
  /// user invents the key as well as the content.
  ///
  /// Exact names, lower-cased, rather than substrings: `partNumber` is theirs
  /// and `partQuantity` is a number, and a substring rule that caught the first
  /// would have to be argued about for every field added later.
  ///
  /// What this cannot cover is a free-text field a future LubeLogger version
  /// adds and this app does not model yet. The residual is one word, and only on
  /// the way *in* — every key the app sends is a key the app chose.
  static const _freeTextKeys = {
    'description',
    'identifier',
    'imagelocation',
    'licenseplate',
    'location',
    'make',
    'model',
    'name',
    'notes',
    'notetext',
    'partnumber',
    'partsupplier',
    'tags',
    'value',
    'vehicleidentifier',
  };

  /// Fields holding the *server's* configuration, kept exactly as it sent them.
  ///
  /// These are the fields a formatting report is read for, and none of them
  /// survives the shape rule on its own: `MM/dd/yyyy` is not a date, `zł` is not
  /// a word, and `1.4.9.0` is not a number. Measuring them would leave a report
  /// that says the server sent `<str:10>` where the whole question was which ten
  /// characters.
  static const _schemaKeys = {
    'currencysymbol',
    'currentversion',
    'dateformat',
    'decimalseparator',
    'latestversion',
    'locale',
  };

  /// Whether a string is the machine's own vocabulary rather than the user's.
  ///
  /// Numbers, booleans (LubeLogger sends `"True"`/`"False"` as text), dates in
  /// any separator the server might use, and short bare identifiers made of
  /// letters only — a fuel type, a status, an enum name. Deliberately **not**
  /// "short alphanumeric": that is the shape of a licence plate.
  static bool _isTechnical(String value) =>
      value.length <= 40 &&
      (_number.hasMatch(value) ||
          _boolean.hasMatch(value) ||
          _dateish.hasMatch(value) ||
          (value.length <= 24 && _enumish.hasMatch(value)));

  static final _number = RegExp(r'^-?[\d]+([.,][\d]+)?$');
  static final _boolean = RegExp(r'^(true|false)$', caseSensitive: false);

  /// Any `d/d/d`-shaped date with an optional time after it, whatever the
  /// separator — the point is to see the format the server chose, including the
  /// wrong one.
  static final _dateish = RegExp(
    r'^\d{1,4}[-/.]\d{1,2}[-/.]\d{1,4}([ T][\d:.+Zz-]*)?$',
  );

  /// A bare enum-ish token: one word of letters, optionally joined by a dash or
  /// an underscore (`Gasoline`, `PastDue`, `fill-to-full`). No digits, which
  /// keeps plates, VINs and part numbers out, and no spaces, which keeps a
  /// sentence the user typed from passing as a status name.
  static final _enumish = RegExp(r'^[A-Za-z]+([_-][A-Za-z]+)*$');
}

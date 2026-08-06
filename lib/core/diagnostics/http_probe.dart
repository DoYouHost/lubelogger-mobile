import 'dart:convert';

import 'package:dio/dio.dart';

import 'diagnostic_recorder.dart';
import 'log_event.dart';
import 'log_store.dart';

/// Records every call the app makes to LubeLogger: method, path, status and how
/// long it took, plus what failed when it failed.
///
/// This is the layer where "the app is broken" usually turns out to mean the
/// server answered 401 for a key that lacks a scope, or the connection never got
/// past the TLS handshake — and neither is visible from the UI, which shows the
/// same empty card either way.
///
/// Installed by `createBareDio`, so it covers the authenticated client, the
/// login probe that runs before there is a profile, and the reminder worker's
/// own client. Nothing here is built unless a recording runs, so an idle app
/// pays for one clock reading per request and nothing else.
///
/// What deliberately never enters a record: headers (the API key lives there),
/// the query string except its two numeric ids, and the host (the user's private
/// network — the session header carries scheme, port and whether it was a name
/// or an IP).
///
/// ## What a write contributes
///
/// Its body, scrubbed — see [_requestSample]. Reading and writing are not
/// symmetric here: an answer is sampled only on the endpoints that carry
/// content, while every request body is kept, because a request body is
/// something this app built.
///
/// ## What a successful answer contributes
///
/// Its record count ([_countOf]) plus **one** record, sampled from the endpoints
/// that carry the app's content ([_sampledPaths]). A status code cannot separate
/// "the screen is empty" from "the screen shows the wrong thing": a 200 with
/// twenty records the app then hides looks exactly like a 200 with nothing in
/// it. The sample settles both, and names the field when the server sent a type
/// or a date format the app did not expect — which is the most common shape of a
/// LubeLogger bug.
///
/// The sample is not the record as it arrived: `LogRedactor.scrubSample` keeps
/// the field names, the numbers, the booleans and the date strings, and replaces
/// everything the user wrote with its length. See there for why the rule is an
/// allowlist by shape rather than a denylist by name.
class HttpProbe extends Interceptor {
  /// Where the clock reading for `ms` is parked. `extra` survives redirects and
  /// re-sends of the very same [RequestOptions].
  static const _startedAtKey = 'diagnosticsStartedAt';

  /// Error bodies are clipped hard: LubeLogger answers with a short message, and
  /// anything longer is a proxy's HTML error page or an ASP.NET stack page,
  /// which says which one it is in its first few tags.
  static const _maxBodyChars = 300;

  /// Ceiling on one sampled record while it stays a map. Past it the record goes
  /// in as clipped text — a record carrying an inline document must not put a
  /// file in the log.
  static const _maxSampleChars = 4 * 1024;
  static const _maxClippedChars = 1500;

  /// Endpoints whose answers are the app's content, and therefore the answer to
  /// "it shows nothing" and "it shows the wrong thing".
  ///
  /// An allowlist, not a denylist: `whoami` answers with a person, and
  /// `documents/upload` echoes the stored file name. Forgetting an endpoint here
  /// costs a diagnosis; forgetting one in a denylist costs someone's data.
  static final _sampledPaths = RegExp(
    r'/api/(vehicles|vehicle/\w+|info|version)$',
  );

  /// The last record sampled per request, so a screen that keeps re-fetching the
  /// same list says `same` instead of repeating itself.
  ///
  /// Keyed by method, path and vehicle: `gasrecords?vehicleId=1` and
  /// `?vehicleId=2` are one path with two different answers, and they have to
  /// dedupe against themselves rather than against each other.
  static final Map<String, String> _lastSample = {};

  /// Called when a recording opens. Fingerprints left by the previous session
  /// would silence the first answer of this one.
  static void openSession() => _lastSample.clear();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Stamped whether or not a recording runs. Starting one mid-flight is the
    // normal case, and a response whose request was never stamped would have to
    // log itself without a duration.
    options.extra[_startedAtKey] = DateTime.now().millisecondsSinceEpoch;
    // Only calls that change something on the server. A GET that never comes
    // back stands out as a response missing from the traffic around it, but "did
    // my save even leave the phone" has no other witness — and that is the
    // request whose answer goes missing when the app dies mid-call.
    final store = DiagnosticRecorder.active;
    if (store != null && !_isRead(options.method)) {
      store.add(
        LogSource.http,
        'request',
        lvl: LogLevel.debug,
        fields: {
          'method': options.method,
          'path': _pathOf(options),
          'vid': _vehicleIdOf(options),
          'rid': _recordIdOf(options),
          'body': _requestSample(store, options.data),
        },
      );
    }
    handler.next(options);
  }

  /// What the app is asking the server to store, with the user's own text taken
  /// out of it — the same treatment the sampled response gets, for the same
  /// reason and with the same rule (`LogRedactor.scrubSample`).
  ///
  /// The outgoing body is the more valuable of the two: it is the app's own
  /// construction, so it is the thing under suspicion. "I saved a fuel-up and the
  /// date came back a day early" is answered by what left the phone — every write
  /// in this app goes out as strings the app formatted itself, and whether the
  /// mistake is in the formatting, in the server, or in the reading back is not
  /// decidable from the response alone.
  ///
  /// Not sampled by path, unlike responses: everything the app *sends* is
  /// something the app built, so there is no endpoint here whose body belongs to
  /// somebody else.
  static Object? _requestSample(LogStore store, Object? data) {
    if (data == null) return null;
    if (data is FormData) return _uploadSummary(data);
    final sample = store.redactor.scrubSample(data);
    final encoded = _encoded(sample);
    return encoded.length > _maxSampleChars
        ? '${encoded.substring(0, _maxClippedChars)}…'
        : sample;
  }

  /// A multipart upload, described rather than sampled: the parts *are* the
  /// user's files. Field names are the API's (`documents`), the count and the
  /// byte total say whether the phone even had the file, and the extensions are
  /// what decides whether the server accepts it. Names never appear.
  static Map<String, Object?> _uploadSummary(FormData data) => {
    if (data.fields.isNotEmpty)
      'fields': [for (final f in data.fields) f.key],
    'files': data.files.length,
    'bytes': data.files.fold<int>(0, (sum, f) => sum + f.value.length),
    'exts': [
      for (final f in data.files) _extensionOf(f.value.filename) ?? '?',
    ],
  };

  static String? _extensionOf(String? filename) {
    final dot = filename?.lastIndexOf('.') ?? -1;
    if (filename == null || dot < 0 || dot == filename.length - 1) return null;
    return filename.substring(dot + 1).toLowerCase();
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // A local null check rather than `?.`: the sample below has to be built
    // (and the fingerprint kept) only while something is recording.
    final store = DiagnosticRecorder.active;
    if (store != null) {
      final status = response.statusCode;
      store.add(
        LogSource.http,
        'response',
        // A 4xx normally arrives as a DioException; it only reaches here when
        // the call opted out of status validation, and it is still not good news.
        lvl: status != null && status >= 400 ? LogLevel.warn : LogLevel.info,
        fields: {
          'method': response.requestOptions.method,
          'path': _pathOf(response.requestOptions),
          'vid': _vehicleIdOf(response.requestOptions),
          'rid': _recordIdOf(response.requestOptions),
          'status': status,
          'ms': _elapsedMs(response.requestOptions),
          // How many records a list endpoint answered with. "This vehicle has no
          // fuel-ups" and "the server sent forty and the app dropped all of
          // them" are the same 200 without this.
          'n': _countOf(response.data),
          // A GET that answered 200 with nothing in it. dio hands back a null
          // body for an empty response that claims to be JSON, and the data
          // layer reads that as an empty list — the one way a truncated answer
          // reaches a screen as "there is nothing here" instead of as an error.
          'empty':
              _isRead(response.requestOptions.method) && response.data == null
              ? true
              : null,
          ..._sampleOf(store, response),
        },
      );
    }
    handler.next(response);
  }

  /// One record of the answer, or `same` when it matches the last one sampled
  /// for this request. Empty for anything outside [_sampledPaths].
  static Map<String, Object?> _sampleOf(
    LogStore store,
    Response<dynamic> response,
  ) {
    final options = response.requestOptions;
    final path = _pathOf(options);
    if (!_sampledPaths.hasMatch(path)) return const {};
    final record = _firstRecord(response.data);
    if (record == null) return const {};

    // Scrubbed before it is measured or compared: what is fingerprinted has to
    // be what actually goes into the log, or a change the redactor removes would
    // still count as a change.
    final sample = store.redactor.scrubSample(record);
    final encoded = _encoded(sample);
    final key = '${options.method} $path#${_vehicleIdOf(options)}';
    // The count belongs in the comparison too: a list that grew from one record
    // to two answers with the same first record, and reporting that as `same`
    // beside `n:2` reads as "nothing happened" at the moment something did.
    final fingerprint = '${_countOf(response.data)}:$encoded';
    if (_lastSample[key] == fingerprint) return const {'same': true};
    _lastSample[key] = fingerprint;
    return {
      'first': encoded.length > _maxSampleChars
          ? '${encoded.substring(0, _maxClippedChars)}…'
          : sample,
    };
  }

  /// The record a body is sampled by: a list's first entry, or the object
  /// itself. Anything else — an empty list, a list of scalars, a downloaded
  /// file, a bare string — has no record to show.
  static Map<String, dynamic>? _firstRecord(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is List && data is! List<int>) {
      final first = data.isEmpty ? null : data.first;
      return first is Map<String, dynamic> ? first : null;
    }
    return null;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    // The class of what actually broke: `HandshakeException` versus
    // `SocketException` separates "TLS refused" from "nothing listening there",
    // which dio lumps together as `connectionError`.
    final cause = err.error?.runtimeType.toString();
    DiagnosticRecorder.active?.add(
      LogSource.http,
      'error',
      lvl: _levelOf(err),
      fields: {
        'method': err.requestOptions.method,
        'path': _pathOf(err.requestOptions),
        'vid': _vehicleIdOf(err.requestOptions),
        'rid': _recordIdOf(err.requestOptions),
        'type': err.type.name,
        'status': status,
        'ms': _elapsedMs(err.requestOptions),
        'cause': cause,
        // dio's message only restates the status when there is a response, so
        // it earns its place exactly when there is none.
        'msg': status == null ? _reasonOf(err, cause) : null,
        'body': status == null ? null : _bodyPreview(err.response?.data),
      },
    );
    handler.next(err);
  }

  /// What failed, in as few characters as the truth allows.
  ///
  /// The underlying exception before dio's wrapper: `SocketException` carries
  /// the OS error and errno, which dio drops when it reformats the message. The
  /// class name is stripped off the front because it is already `cause`, and
  /// dio's closing sentence goes because repeating "cannot be solved by the
  /// library" once per failed request is, in an offline session, the largest
  /// thing in the log.
  static String? _reasonOf(DioException err, String? cause) {
    final text = (err.error?.toString() ?? err.message)?.trim();
    if (text == null || text.isEmpty) return null;
    final withoutClass = cause != null && text.startsWith('$cause: ')
        ? text.substring(cause.length + 2)
        : text;
    return withoutClass.replaceFirst(_dioBoilerplate, '').trimRight();
  }

  /// dio appends this to every message it builds itself.
  static final _dioBoilerplate = RegExp(
    r'\s*This indicates an error which most likely cannot be solved by the '
    r'library\.?$',
  );

  /// Element count for a JSON array body, null for anything else — an object
  /// body's shape is the endpoint's business, and counting its keys would say
  /// nothing.
  ///
  /// A downloaded document is a `List<int>` and is excluded: its length is a
  /// byte count, and reported as `n` it would read as "the server sent 34 000
  /// records".
  static int? _countOf(Object? data) =>
      data is List && data is! List<int> ? data.length : null;

  static bool _isRead(String method) {
    final upper = method.toUpperCase();
    return upper == 'GET' || upper == 'HEAD';
  }

  /// Path only. `uri` resolves the relative path against the base URL, and
  /// taking `.path` off it drops both the host and the query string.
  static String _pathOf(RequestOptions options) => options.uri.path;

  /// The one query parameter worth keeping. Nearly every LubeLogger endpoint is
  /// scoped by `vehicleId`, so without it a log of ten list fetches cannot say
  /// which vehicle any of them was for. An internal row id names nobody.
  static int? _vehicleIdOf(RequestOptions options) =>
      int.tryParse(options.uri.queryParameters['vehicleId'] ?? '');

  /// The other query parameter worth keeping: `?id=` is how every delete names
  /// its target, and without it the log says a record was deleted but not which
  /// one — so "it removed the wrong entry" cannot be told from "it removed the
  /// one I picked". An internal row id names nobody.
  static int? _recordIdOf(RequestOptions options) =>
      int.tryParse(options.uri.queryParameters['id'] ?? '');

  static int? _elapsedMs(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey];
    if (startedAt is! int) return null;
    final ms = DateTime.now().millisecondsSinceEpoch - startedAt;
    // A clock moved backwards mid-request must not produce a negative duration
    // that reads as a response arriving before it was asked for.
    return ms < 0 ? 0 : ms;
  }

  static LogLevel _levelOf(DioException err) {
    // A cancelled request is usually the app's own doing (a screen closed while
    // loading) and says nothing about a failure.
    if (err.type == DioExceptionType.cancel) return LogLevel.info;
    // No response at all is ours to explain; a status means the server did
    // answer, and the status is then the headline.
    return err.response == null ? LogLevel.error : LogLevel.warn;
  }

  static String? _bodyPreview(Object? data) {
    if (data == null) return null;
    // Bytes, i.e. a download that failed. Encoding those would spell out an
    // array of numbers; the size is the only useful thing in them.
    if (data is List<int>) return '<${data.length} bytes>';
    final text = data is String ? data : _encoded(data);
    if (text.isEmpty) return null;
    return text.length > _maxBodyChars
        ? '${text.substring(0, _maxBodyChars)}…'
        : text;
  }

  static String _encoded(Object? data) {
    try {
      return jsonEncode(data);
    } on Object {
      // A streamed or otherwise unencodable body: its type is all we can say
      // about it, and a failing body must not fail the request it describes.
      return '<${data.runtimeType}>';
    }
  }
}

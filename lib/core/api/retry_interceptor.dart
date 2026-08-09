import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import '../cache/offline_interceptor.dart';
import '../diagnostics/diagnostic_recorder.dart';
import '../diagnostics/log_event.dart';

/// How many times a request may be sent in total, first attempt included.
const int kDefaultMaxAttempts = 3;

/// Delay before the second attempt; each further one triples it.
const Duration kDefaultRetryDelay = Duration(milliseconds: 400);

/// Re-sends a read that failed in a way the next attempt could plausibly
/// survive: a dropped connection, a wifi-to-mobile handover, or a proxy that
/// answered 502/503 while LubeLogger was restarting.
///
/// Sits **before** [OfflineInterceptor], so a blip is retried before it is
/// allowed to become "you are offline" — otherwise one lost packet swaps the
/// list for its stored copy and lights the offline banner.
///
/// Two deliberate limits:
///
/// - **Reads only.** A `POST /add` that timed out may well have been executed;
///   re-sending it writes the record twice. Writes have their own answer
///   already — [OfflineInterceptor] queues the ones that don't land and flushes
///   them when the server is back, which is a retry with an idempotency story.
/// - **Timeouts are not retried** ([worthRetrying]). A request that spent its
///   whole 8s connect or 15s receive budget just demonstrated the server is not
///   answering in time; a second and third attempt turn a 15-second failure
///   into a 45-second one, and the stale-cache fallback the user could have had
///   immediately arrives three times later.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.status,
    this.maxAttempts = kDefaultMaxAttempts,
    this.baseDelay = kDefaultRetryDelay,
    Random? random,
    this.sleep = _wait,
  }) : _random = random ?? Random();

  /// The client to re-send through — the whole chain runs again, so a retried
  /// attempt is cached, probed and counted like any other request.
  final Dio dio;

  /// When the app already knows the server is unreachable, one more round of
  /// attempts only makes every screen slower to give up. Null disables the
  /// check (there is nothing tracking reachability).
  final OfflineStatus? status;

  final int maxAttempts;
  final Duration baseDelay;

  /// Injected so a test can assert the backoff without waiting through it.
  final Future<void> Function(Duration) sleep;

  final Random _random;

  /// Attempt number of this request, carried on the options so the re-sent
  /// request — which runs through this interceptor again — can count.
  static const _attemptKey = 'lubelogger.attempt';

  static Future<void> _wait(Duration d) => Future<void>.delayed(d);

  /// Whether [err] is the kind of failure a second attempt could survive.
  ///
  /// Narrower than [isUnreachable], which answers a different question ("is a
  /// stored copy the best answer available?"): a timeout means both "unreachable"
  /// and "do not try again", see the class comment.
  static bool worthRetrying(DioException err) => switch (err.type) {
        DioExceptionType.connectionError => true,
        DioExceptionType.badResponse => (err.response?.statusCode ?? 0) >= 500,
        DioExceptionType.unknown =>
          err.error is SocketException || err.error is HttpException,
        _ => false,
      };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (options.method.toUpperCase() != 'GET' ||
        (status?.offline ?? false) ||
        !worthRetrying(err)) {
      return handler.next(err);
    }

    final attempt = options.extra[_attemptKey] as int? ?? 1;
    if (attempt >= maxAttempts) {
      _log('retry_exhausted', {'path': options.path, 'attempts': attempt});
      return handler.next(err);
    }

    final delay = _delayFor(attempt);
    _log('retry', {
      'path': options.path,
      'attempt': attempt + 1,
      'delayMs': delay.inMilliseconds,
      'cause': err.response?.statusCode ?? err.type.name,
    });
    await sleep(delay);

    options.extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Exponential backoff with jitter over the lower half of each step, so a
  /// screen that fired six list requests at once does not retry all six in the
  /// same millisecond and re-create the burst that may have caused the failure.
  Duration _delayFor(int attempt) {
    final step = baseDelay * pow(3, attempt - 1).toDouble();
    return step * (0.5 + _random.nextDouble() * 0.5);
  }

  void _log(String event, Map<String, Object?> fields) =>
      DiagnosticRecorder.active?.add(
        LogSource.http,
        event,
        lvl: LogLevel.warn,
        fields: fields,
      );
}

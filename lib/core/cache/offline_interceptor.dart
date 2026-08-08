import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../diagnostics/diagnostic_recorder.dart';
import '../diagnostics/log_event.dart';
import 'http_cache.dart';
import 'write_queue.dart';

/// Request `extra` flags. They ride on the client rather than on each call, so
/// the repository's forty-odd methods know nothing about any of this.
const kCacheProbe = 'lubelogger.cacheProbe';
const kCacheFirst = 'lubelogger.cacheFirst';
const kRevalidate = 'lubelogger.revalidate';
const kNoQueue = 'lubelogger.noQueue';

/// Marks a response the queue accepted instead of the server.
const kQueued = 'lubelogger.queued';

/// What the cache did with one request, reported back to whoever made it.
class CacheProbe {
  String? key;

  /// The answer came off the disk; no request left the device.
  bool servedFromCache = false;

  /// Worth asking the server as well — false when the stored copy is already
  /// the answer to that question (see [OfflineInterceptor]).
  bool shouldRevalidate = false;

  /// The server's answer differed from the stored one.
  bool changed = false;
}

/// Whether the server is currently answering, and when it last did.
///
/// A screen showing month-old records looks exactly like a screen showing
/// current ones, so something has to say which it is.
class OfflineStatus extends ChangeNotifier {
  bool _offline = false;
  DateTime? _lastContact;

  bool get offline => _offline;
  DateTime? get lastContact => _lastContact;

  /// Every successful response lands here, so the timestamp is updated quietly
  /// and only the change of state is announced — otherwise a screen with six
  /// lists on it would rebuild six times for nothing.
  void reachable() {
    _lastContact = DateTime.now();
    if (!_offline) return;
    _offline = false;
    notifyListeners();
  }

  void unreachable() {
    if (_offline) return;
    _offline = true;
    notifyListeners();
  }
}

/// Keeps the app usable without the server: stores every list it reads, answers
/// from that store when the network is gone, and holds writes that couldn't be
/// delivered until they can be.
///
/// Sits last in the chain, so the diagnostic probe still sees the real failure
/// before this turns it into an answer.
class OfflineInterceptor extends Interceptor {
  OfflineInterceptor({
    required this.cache,
    required this.queue,
    required this.status,
  });

  final HttpCache cache;
  final WriteQueue queue;
  final OfflineStatus status;

  /// Keys whose stored copy is what the server said moments ago, put here by a
  /// revalidation that found a change. The read it triggers would otherwise
  /// revalidate again, and so on forever; consuming the mark ends the chain
  /// after exactly one refresh.
  final Set<String> _justRefreshed = {};

  /// When the app last changed something on the server.
  ///
  /// Anything stored before that predates the change, so it may still be shown
  /// when the server is gone — but it must not be shown *instead of asking*, or
  /// the list a form returns to would be missing the record just saved.
  DateTime? _lastWrite;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final probe = options.extra[kCacheProbe] as CacheProbe?;
    if (!_isCacheable(options)) return handler.next(options);

    final key = HttpCache.keyFor(
      method: options.method,
      path: options.path,
      query: options.queryParameters,
    );
    probe?.key = key;

    if (options.extra[kCacheFirst] != true) return handler.next(options);

    final stored = await cache.read(key);
    final lastWrite = _lastWrite;
    if (stored == null ||
        (lastWrite != null && !stored.storedAt.isAfter(lastWrite))) {
      return handler.next(options);
    }

    probe?.servedFromCache = true;
    probe?.shouldRevalidate = !_justRefreshed.remove(key);
    _log('cache_hit', {'path': options.path});
    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: stored.body,
        extra: {'storedAt': stored.storedAt.toIso8601String()},
      ),
      // The body came from us, not from the server: re-running the response
      // interceptors would write it straight back and log a request that never
      // happened.
      false,
    );
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    status.reachable();
    final options = response.requestOptions;
    if (!_isCacheable(options)) {
      // A write the server took: every stored list that predates it may be
      // missing what it did.
      if (options.method.toUpperCase() != 'GET') _lastWrite = DateTime.now();
      return handler.next(response);
    }
    if (response.statusCode != 200) return handler.next(response);

    final key = HttpCache.keyFor(
      method: options.method,
      path: options.path,
      query: options.queryParameters,
    );
    final changed = await cache.write(key, response.data);
    final probe = options.extra[kCacheProbe] as CacheProbe?;
    probe?.changed = changed;
    // Only a refresh that found something new is followed by a re-read, so only
    // that one needs stopping.
    if (changed && options.extra[kRevalidate] == true) _justRefreshed.add(key);
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!isUnreachable(err)) {
      // The server answered, it just didn't like the request. Nothing offline
      // about that.
      status.reachable();
      return handler.next(err);
    }
    status.unreachable();

    final options = err.requestOptions;
    if (_isCacheable(options)) {
      final stored = await cache.read(
        HttpCache.keyFor(
          method: options.method,
          path: options.path,
          query: options.queryParameters,
        ),
      );
      if (stored != null) {
        _log('cache_stale', {'path': options.path});
        return handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: stored.body,
            extra: {'storedAt': stored.storedAt.toIso8601String()},
          ),
        );
      }
      return handler.next(err);
    }

    if (!_queueable(options)) return handler.next(err);

    final write = await queue.add(
      method: options.method,
      path: options.path,
      query: options.queryParameters,
      body: options.data,
    );
    _log('write_queued', {'path': options.path, 'method': options.method});
    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        statusCode: 202,
        // The shape every write returns, so `_ensureSuccess` reads it as the
        // acceptance it is. The record exists as far as the user is concerned;
        // what is pending is its delivery.
        data: {'success': true, 'message': ''},
        extra: {kQueued: write.id},
      ),
    );
  }

  /// Reads worth keeping: JSON list endpoints. File downloads stream to disk
  /// and would be cached as a stream object, not a body.
  bool _isCacheable(RequestOptions options) =>
      options.method.toUpperCase() == 'GET' &&
      options.responseType == ResponseType.json;

  /// Writes worth holding. An attachment upload is excluded: its body is a file
  /// handle, and a queue that outlives the process cannot promise the file is
  /// still there to read.
  bool _queueable(RequestOptions options) =>
      const {'POST', 'PUT', 'DELETE'}.contains(options.method.toUpperCase()) &&
      options.extra[kNoQueue] != true &&
      options.data is! FormData;

  void _log(String event, Map<String, Object?> fields) =>
      DiagnosticRecorder.active?.add(LogSource.http, event, fields: fields);
}

/// Whether the request failed to reach a working server, as opposed to reaching
/// one that refused it. Only the former is worth retrying, and only the former
/// means a stored copy is the best answer available.
///
/// 5xx counts: a server that is up but broken (or a proxy with nothing behind
/// it) is no more able to take a write than one that is off.
bool isUnreachable(DioException err) => switch (err.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout =>
        true,
      DioExceptionType.badResponse => (err.response?.statusCode ?? 0) >= 500,
      DioExceptionType.unknown =>
        err.error is SocketException || err.error is HttpException,
      DioExceptionType.badCertificate || DioExceptionType.cancel => false,
    };

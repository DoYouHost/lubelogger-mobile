import 'package:dio/dio.dart';

import '../../data/vehicles_repository.dart';
import '../diagnostics/diagnostic_recorder.dart';
import '../diagnostics/log_event.dart';
import '../models/vehicle_record.dart';
import 'offline_interceptor.dart';
import 'write_queue.dart';

/// What one pass achieved. [stopped] means the server went away again, so the
/// rest of the queue is still waiting rather than done.
typedef SyncOutcome = ({
  int delivered,
  int refused,
  int remaining,
  bool stopped,
});

/// Delivers what the queue is holding and refreshes what the app will read.
///
/// Runs both in the app (on resume, or when the user asks) and in the
/// WorkManager isolate, which is why it takes its dependencies rather than
/// reaching for providers.
class SyncService {
  SyncService({required this.dio, required this.queue, required this.repository});

  final Dio dio;
  final WriteQueue queue;
  final VehiclesRepository repository;

  /// Sends the queue front to back, stopping at the first write the server
  /// can't take. Order is preserved on purpose: an update that follows an add
  /// is meaningless if it arrives first.
  Future<SyncOutcome> drain() async {
    await queue.reload();
    var delivered = 0;
    var refused = 0;
    var stopped = false;

    for (final write in queue.pending) {
      final String? refusal;
      try {
        refusal = _refusal(await _send(write));
      } on DioException catch (error) {
        if (isUnreachable(error)) {
          await queue.recordAttempt(write, error.message ?? error.type.name);
          stopped = true;
          break;
        }
        // The server answered and said no. Retrying would say no again.
        await queue.reject(write, _describe(error));
        refused++;
        continue;
      }

      if (refusal != null) {
        await queue.reject(write, refusal);
        refused++;
        continue;
      }
      await queue.remove(write.id);
      delivered++;
    }

    final remaining = queue.pending.length;
    if (delivered > 0 || refused > 0) {
      _log('queue_drained', {
        'sent': delivered,
        'refused': refused,
        'left': remaining,
      });
    }
    return (
      delivered: delivered,
      refused: refused,
      remaining: remaining,
      stopped: stopped,
    );
  }

  /// Re-reads what the app opens onto, so the next launch has something current
  /// to show before its own requests come back. Failures are ignored — this is
  /// housekeeping, and an unreachable server simply leaves the stored copy be.
  ///
  /// Deliberately not every endpoint: the tabs a user may never open would
  /// triple the traffic for data nobody is waiting on.
  Future<int> warmCache() async {
    var refreshed = 0;
    Future<void> refresh(Future<void> Function() read) async {
      try {
        await read();
        refreshed++;
      } on Object {
        return;
      }
    }

    final List<int> vehicleIds;
    try {
      await repository.serverInfo();
      vehicleIds = [for (final v in await repository.allInfo()) v.vehicle.id];
      refreshed += 2;
    } on Object {
      return refreshed;
    }

    for (final id in vehicleIds) {
      await refresh(() => repository.info(id));
      await refresh(() => repository.gasRecords(id));
      await refresh(() => repository.odometerRecords(id));
      await refresh(() => repository.reminders(id));
      for (final kind in RecordKind.values) {
        await refresh(() => repository.records(kind, id));
      }
    }
    _log('cache_warmed', {'n': refreshed});
    return refreshed;
  }

  Future<Response<dynamic>> _send(PendingWrite write) => dio.request<dynamic>(
        write.path,
        data: write.body,
        queryParameters: write.query,
        options: Options(
          method: write.method,
          contentType: Headers.jsonContentType,
          // Whatever happens to a retry, it must not be queued again — that is
          // this loop's job to decide.
          extra: {kNoQueue: true},
        ),
      );

  /// A write endpoint reports failure in-band with HTTP 200; that is a refusal,
  /// not a delivery problem.
  String? _refusal(Response<dynamic> response) {
    final body = response.data;
    if (body is Map && body['success'] == false) {
      return (body['message'] as String?) ?? 'rejected';
    }
    return null;
  }

  String _describe(DioException error) {
    final body = error.response?.data;
    if (body is Map && body['message'] is String) return body['message'] as String;
    return 'HTTP ${error.response?.statusCode ?? error.type.name}';
  }

  void _log(String event, Map<String, Object?> fields) =>
      DiagnosticRecorder.active?.add(LogSource.app, event, fields: fields);
}

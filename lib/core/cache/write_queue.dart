import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A write the server never confirmed, kept verbatim until it can be delivered.
///
/// Stored as the raw request rather than as a typed record so the queue stays
/// indifferent to what is being written: any endpoint the repository gains is
/// queueable without touching this file.
class PendingWrite {
  const PendingWrite({
    required this.id,
    required this.method,
    required this.path,
    required this.query,
    required this.body,
    required this.queuedAt,
    this.attempts = 0,
    this.lastError,
  });

  factory PendingWrite.fromJson(Map<String, dynamic> json) => PendingWrite(
        id: json['id'] as String,
        method: json['method'] as String,
        path: json['path'] as String,
        query: Map<String, dynamic>.from(json['query'] as Map? ?? const {}),
        body: json['body'],
        queuedAt: DateTime.fromMillisecondsSinceEpoch(json['queuedAt'] as int),
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        lastError: json['lastError'] as String?,
      );

  final String id;
  final String method;
  final String path;
  final Map<String, dynamic> query;
  final Object? body;
  final DateTime queuedAt;

  /// Delivery attempts so far — shown in the sync sheet, so a write that keeps
  /// bouncing is visible rather than silently looping.
  final int attempts;

  /// Why the server refused it. Set only on a rejected write.
  final String? lastError;

  PendingWrite copyWith({int? attempts, String? lastError}) => PendingWrite(
        id: id,
        method: method,
        path: path,
        query: query,
        body: body,
        queuedAt: queuedAt,
        attempts: attempts ?? this.attempts,
        lastError: lastError ?? this.lastError,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'query': query,
        'body': body,
        'queuedAt': queuedAt.millisecondsSinceEpoch,
        'attempts': attempts,
        if (lastError != null) 'lastError': lastError,
      };
}

/// Writes waiting for a server that wasn't there, in the order they were made.
///
/// Order is the whole point: an update that follows an add has to reach the
/// server after it, so the queue is drained strictly front to back and stops at
/// the first entry that can't be delivered.
///
/// Lives in SharedPreferences because the WorkManager isolate drains it too and
/// shares no Dart state with the app — hence [reload], which re-reads what the
/// other isolate left behind.
///
/// Announces its own changes: the thing that queues a write is an interceptor
/// buried under the repository, far from anything that could tell the screen a
/// save is now pending.
class WriteQueue extends ChangeNotifier {
  WriteQueue(this._prefs);

  static const _pendingKey = 'write_queue_pending';
  static const _rejectedKey = 'write_queue_rejected';

  /// Refused writes are kept only so the user can read why one was lost.
  static const _maxRejected = 20;

  final SharedPreferences _prefs;
  int _sequence = 0;

  List<PendingWrite> get pending => _load(_pendingKey);

  /// Writes the server answered with a refusal. They are never retried: a body
  /// it called invalid stays invalid, and retrying would loop forever.
  List<PendingWrite> get rejected => _load(_rejectedKey);

  bool get isEmpty => pending.isEmpty;

  /// Picks up what the background isolate left behind — it has its own
  /// SharedPreferences instance, so the app's copy can be a pass out of date.
  Future<void> reload() async {
    await _prefs.reload();
    notifyListeners();
  }

  Future<PendingWrite> add({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    final now = DateTime.now();
    final write = PendingWrite(
      // The counter breaks ties between writes queued in the same millisecond,
      // which is what a form that saves several records does.
      id: '${now.microsecondsSinceEpoch}-${_sequence++}',
      method: method.toUpperCase(),
      path: path,
      query: {...?query},
      body: body,
      queuedAt: now,
    );
    await _save(_pendingKey, [...pending, write]);
    return write;
  }

  Future<void> remove(String id) =>
      _save(_pendingKey, [for (final w in pending) if (w.id != id) w]);

  Future<void> recordAttempt(PendingWrite write, String error) => _save(
        _pendingKey,
        [
          for (final w in pending)
            if (w.id == write.id)
              w.copyWith(attempts: w.attempts + 1, lastError: error)
            else
              w,
        ],
      );

  /// Moves a write the server refused out of the queue, keeping its reason.
  Future<void> reject(PendingWrite write, String reason) async {
    await remove(write.id);
    final kept = [
      write.copyWith(attempts: write.attempts + 1, lastError: reason),
      ...rejected,
    ];
    await _save(
      _rejectedKey,
      kept.length > _maxRejected ? kept.sublist(0, _maxRejected) : kept,
    );
  }

  /// Forgets one refused write, or all of them when [id] is null.
  Future<void> discardRejected([String? id]) => _save(
        _rejectedKey,
        id == null ? const [] : [for (final w in rejected) if (w.id != id) w],
      );

  Future<void> clear() async {
    await _prefs.remove(_pendingKey);
    await _prefs.remove(_rejectedKey);
    notifyListeners();
  }

  List<PendingWrite> _load(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    try {
      return [
        for (final e in jsonDecode(raw) as List)
          PendingWrite.fromJson(e as Map<String, dynamic>),
      ];
    } on Object {
      // Never let a corrupted queue take the app down on launch; the writes are
      // unrecoverable either way.
      return const [];
    }
  }

  Future<void> _save(String key, List<PendingWrite> writes) async {
    await _prefs.setString(key, jsonEncode([for (final w in writes) w.toJson()]));
    notifyListeners();
  }
}

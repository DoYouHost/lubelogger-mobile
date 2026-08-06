import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/diagnostics/log_event.dart';
import 'package:lubelogger_mobile/core/diagnostics/log_store.dart';

LogHeader _header(DateTime ts) =>
    LogHeader(ts: ts, session: 'abc', app: '0.2.7+207');

List<Map<String, Object?>> _records(String jsonl) => [
      for (final line in const LineSplitter().convert(jsonl).skip(1))
        jsonDecode(line) as Map<String, Object?>,
    ];

void main() {
  final start = DateTime.utc(2026, 8, 6, 12);

  test('the header comes first and records carry an offset', () {
    var now = start;
    final store = LogStore(header: _header(start), clock: () => now);

    now = start.add(const Duration(milliseconds: 1500));
    store.add(LogSource.ui, 'tap', fields: {'id': 'garage.card'});

    final lines = const LineSplitter().convert(store.export());
    expect(jsonDecode(lines.first), containsPair('session', 'abc'));
    final record = jsonDecode(lines[1]) as Map<String, Object?>;
    expect(record['t'], 1500);
    expect(record['src'], 'ui');
    expect(record['evt'], 'tap');
    expect(record['id'], 'garage.card');
  });

  test('info is the default level and is left out of the record', () {
    final store = LogStore(header: _header(start), clock: () => start);
    store.add(LogSource.app, 'recording_started');
    store.add(LogSource.err, 'uncaught', lvl: LogLevel.error);

    final records = _records(store.export());
    expect(records.first.containsKey('lvl'), isFalse);
    expect(records.last['lvl'], 'error');
  });

  test('records are exported in the order things happened, not of arrival', () {
    var now = start.add(const Duration(seconds: 5));
    final store = LogStore(header: _header(start), clock: () => now);

    store.add(LogSource.http, 'response');
    // A tap stamped with the moment the finger went down, written afterwards.
    store.add(LogSource.ui, 'tap', at: 1000);

    final records = _records(store.export());
    expect(records.map((r) => r['evt']), ['tap', 'response']);
  });

  test('eviction is reported as one truncation marker', () {
    final store = LogStore(
      header: _header(start),
      clock: () => start,
      maxRecords: 2,
    );
    for (var i = 0; i < 5; i++) {
      store.add(LogSource.app, 'x$i');
    }

    final records = _records(store.export());
    expect(records.first['evt'], 'truncated');
    expect(records.first['dropped'], 3);
    expect(store.recordCount, 2);
  });

  test('past the time ceiling the session closes and says which one', () {
    var now = start;
    var closedBy = '';
    final store = LogStore(
      header: _header(start),
      clock: () => now,
      maxDuration: const Duration(minutes: 1),
      onClosed: (limit) => closedBy = limit,
    );
    store.add(LogSource.app, 'before');

    now = start.add(const Duration(minutes: 2));
    store.add(LogSource.app, 'after');

    expect(closedBy, 'time');
    expect(store.isClosed, isTrue);
    final records = _records(store.export());
    expect(records.map((r) => r['evt']), ['before', 'limit_reached']);
    expect(records.last['limit'], 'time');
  });

  test('a stalled clock is caught by the size ceiling instead', () {
    var closedBy = '';
    final store = LogStore(
      header: _header(start),
      clock: () => start,
      maxBytes: 200,
      onClosed: (limit) => closedBy = limit,
    );
    for (var i = 0; i < 50; i++) {
      store.add(LogSource.app, 'x$i');
    }

    expect(closedBy, 'size');
    expect(_records(store.export()).last['limit'], 'size');
  });

  test('every record is redacted on the way in', () {
    final store = LogStore(header: _header(start), clock: () => start);
    store.redactor.remember('secret-key-value', '[APIKEY]');
    store.add(LogSource.http, 'error', fields: {'msg': 'bad secret-key-value'});

    expect(_records(store.export()).single['msg'], 'bad [APIKEY]');
  });

  test('a clock moved backwards cannot produce a negative offset', () {
    var now = start;
    final store = LogStore(header: _header(start), clock: () => now);
    now = start.subtract(const Duration(minutes: 5));
    store.add(LogSource.app, 'x');

    expect(_records(store.export()).single['t'], 0);
  });
}

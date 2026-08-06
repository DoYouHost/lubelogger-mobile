import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/diagnostics/log_merge.dart';

String _stream({
  required String ts,
  required String name,
  required List<Map<String, Object?>> records,
}) {
  final buf = StringBuffer()
    ..writeln(jsonEncode({
      'v': 1,
      'ts': ts,
      'session': 'abc',
      'stream': name,
      'app': '0.2.7+207',
    }));
  for (final record in records) {
    buf.writeln(jsonEncode(record));
  }
  return buf.toString();
}

List<Map<String, Object?>> _records(String jsonl) => [
      for (final line in const LineSplitter().convert(jsonl).skip(1))
        jsonDecode(line) as Map<String, Object?>,
    ];

void main() {
  group('mergeSessions', () {
    test('rebases both streams onto the earliest header', () {
      final ui = _stream(
        ts: '2026-08-06T12:00:00.000Z',
        name: 'ui',
        records: [
          {'t': 0, 'src': 'app', 'evt': 'recording_started'},
          {'t': 9000, 'src': 'ui', 'evt': 'tap'},
        ],
      );
      // Started five seconds later, so its `t: 1000` is really t=6000.
      final worker = _stream(
        ts: '2026-08-06T12:00:05.000Z',
        name: 'worker',
        records: [
          {'t': 1000, 'src': 'notif', 'evt': 'posted'},
        ],
      );

      final records = _records(mergeSessions(ui, worker));
      expect(records.map((r) => r['evt']),
          ['recording_started', 'posted', 'tap']);
      expect(records[1]['t'], 6000);
    });

    test('records from the secondary stream say where they came from', () {
      final ui = _stream(
        ts: '2026-08-06T12:00:00.000Z',
        name: 'ui',
        records: [
          {'t': 0, 'src': 'http', 'evt': 'response', 'path': '/api/vehicles'},
        ],
      );
      final worker = _stream(
        ts: '2026-08-06T12:00:00.000Z',
        name: 'worker',
        records: [
          {'t': 1, 'src': 'http', 'evt': 'response', 'path': '/api/vehicles'},
        ],
      );

      final records = _records(mergeSessions(ui, worker));
      expect(records.first['iso'], isNull);
      expect(records.last['iso'], 'worker');
    });

    test('the merged header keeps the earliest ts and says merged', () {
      final ui = _stream(
        ts: '2026-08-06T12:00:10.000Z',
        name: 'ui',
        records: [
          {'t': 0, 'src': 'app', 'evt': 'x'},
        ],
      );
      final worker = _stream(
        ts: '2026-08-06T12:00:00.000Z',
        name: 'worker',
        records: [
          {'t': 0, 'src': 'app', 'evt': 'y'},
        ],
      );

      final header = jsonDecode(
        const LineSplitter().convert(mergeSessions(ui, worker)).first,
      ) as Map<String, Object?>;
      expect(header['ts'], '2026-08-06T12:00:00.000Z');
      expect(header['stream'], 'merged');
    });

    test('a broken secondary stream costs nothing', () {
      final ui = _stream(
        ts: '2026-08-06T12:00:00.000Z',
        name: 'ui',
        records: [
          {'t': 0, 'src': 'app', 'evt': 'x'},
        ],
      );
      expect(mergeSessions(ui, 'not json at all\n{"t":1}'), ui);
      expect(mergeSessions(ui, ''), ui);
    });

    test('a stray header left mid-file by a restarted isolate is dropped', () {
      final ui = _stream(
        ts: '2026-08-06T12:00:00.000Z',
        name: 'ui',
        records: [
          {'t': 0, 'src': 'app', 'evt': 'x'},
        ],
      );
      final worker = '${_stream(
        ts: '2026-08-06T12:00:00.000Z',
        name: 'worker',
        records: [
          {'t': 10, 'src': 'app', 'evt': 'worker_started'},
        ],
      )}${jsonEncode({
            'v': 1,
            'ts': '2026-08-06T12:00:00.000Z',
            'session': 'abc',
            'stream': 'worker',
            'app': '0.2.7+207',
          })}\n';

      final records = _records(mergeSessions(ui, worker));
      expect(records.map((r) => r['evt']), ['x', 'worker_started']);
    });
  });

  group('orderSession', () {
    test('puts a file back into the order things happened', () {
      final jsonl = _stream(
        ts: '2026-08-06T12:00:00.000Z',
        name: 'ui',
        records: [
          {'t': 5000, 'src': 'http', 'evt': 'response'},
          {'t': 4000, 'src': 'ui', 'evt': 'tap'},
        ],
      );
      expect(
        _records(orderSession(jsonl)).map((r) => r['evt']),
        ['tap', 'response'],
      );
    });

    test('a torn last line is dropped, the rest survives', () {
      final jsonl = '${_stream(
        ts: '2026-08-06T12:00:00.000Z',
        name: 'ui',
        records: [
          {'t': 1, 'src': 'app', 'evt': 'x'},
        ],
      )}{"t":2,"src":"app","ev';

      expect(_records(orderSession(jsonl)).single['evt'], 'x');
    });

    test('a file with only a header comes back untouched', () {
      final jsonl = _stream(
        ts: '2026-08-06T12:00:00.000Z',
        name: 'ui',
        records: const [],
      );
      expect(orderSession(jsonl), jsonl);
    });
  });
}

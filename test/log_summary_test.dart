import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/diagnostics/log_summary.dart';
import 'package:lubelogger_mobile/core/diagnostics/report_envelope.dart';
import 'package:lubelogger_mobile/features/bug_report/log_export.dart';
import 'package:lubelogger_mobile/features/bug_report/log_preview.dart';

String _log(List<Map<String, Object?>> rows) =>
    rows.map(jsonEncode).map((l) => '$l\n').join();

const _header = {
  'v': 1,
  'ts': '2026-08-06T12:00:00.000Z',
  'session': 'abc',
  'stream': 'ui',
  'app': '0.2.7+207',
  'scheme': 'https',
};

void main() {
  group('LogSummary', () {
    test('counts records per source, plus errors, warnings and markers', () {
      final summary = LogSummary.parse(_log([
        _header,
        {'t': 0, 'src': 'app', 'evt': 'recording_started'},
        {'t': 10, 'src': 'ui', 'evt': 'tap', 'id': 'garage.card'},
        {'t': 20, 'src': 'http', 'evt': 'error', 'lvl': 'warn', 'status': 401},
        {'t': 30, 'src': 'err', 'evt': 'uncaught', 'lvl': 'error'},
        {'t': 40, 'src': 'app', 'evt': 'user_marker'},
      ]));

      expect(summary.lines.length, 5);
      expect(summary.errors, 1);
      expect(summary.warnings, 1);
      expect(summary.markers, 1);
      expect(summary.bySource, {'app': 2, 'ui': 1, 'http': 1, 'err': 1});
      // Chips follow the enum order, not the order sources first appeared.
      expect(
        summary.sourceCounts.map((e) => e.key),
        ['http', 'ui', 'err', 'app'],
      );
    });

    test('the header is kept out of the record list', () {
      final summary = LogSummary.parse(_log([
        _header,
        {'t': 0, 'src': 'app', 'evt': 'x'},
      ]));
      expect(summary.header['app'], '0.2.7+207');
      expect(summary.lines.single.evt, 'x');
    });

    test('a half-written last line does not fail the review', () {
      final summary = LogSummary.parse(
        '${_log([
              _header,
              {'t': 0, 'src': 'app', 'evt': 'x'},
            ])}{"t":1,"src":"ap',
      );
      expect(summary.lines.length, 1);
    });

    test('truncation is reported', () {
      final summary = LogSummary.parse(_log([
        _header,
        {'t': 0, 'src': 'app', 'evt': 'truncated', 'lvl': 'warn', 'dropped': 9},
      ]));
      expect(summary.truncated, isTrue);
    });

    test('a line renders its offset and its extra fields', () {
      final line = LogSummary.parse(_log([
        _header,
        {
          't': 65400,
          'src': 'http',
          'evt': 'response',
          'iso': 'worker',
          'status': 502,
          'ms': 1204,
        },
      ])).lines.single;

      expect(line.offset, '1:05.4');
      expect(line.detail, 'status=502 · ms=1204');
      expect(line.iso, 'worker');
    });
  });

  group('reportEnvelope', () {
    test('reads the header and the schema off the log itself', () {
      final envelope = reportEnvelope(_log([
        _header,
        {'t': 0, 'src': 'app', 'evt': 'x'},
      ]));
      expect(envelope.logSchema, 1);
      expect(envelope.header['app'], '0.2.7+207');
      expect(envelope.header['scheme'], 'https');
    });

    test('a log whose header write failed yields an empty header', () {
      final envelope = reportEnvelope(_log([
        {'t': 0, 'src': 'app', 'evt': 'x'},
      ]));
      expect(envelope.header, isEmpty);
      expect(envelope.logSchema, reportLogSchema);
    });
  });

  group('logPreview', () {
    test('a short log is shown whole', () {
      const log = 'header\nrecord\n';
      expect(logPreview(log), (text: log, hiddenChars: 0));
    });

    test('the header survives the clip and the window starts on a record', () {
      final log = 'HEADER\n${List.generate(50, (i) => 'record-$i').join('\n')}';
      final preview = logPreview(log, maxChars: 40);

      expect(preview.text.startsWith('HEADER\n'), isTrue);
      expect(preview.hiddenChars, greaterThan(0));
      // Whole records only — a half line reads as corruption.
      for (final line in preview.text.split('\n').skip(1)) {
        expect(line.isEmpty || RegExp(r'^record-\d+$').hasMatch(line), isTrue);
      }
    });
  });

  test('the saved file is named after the moment it was saved', () {
    expect(
      logFileName(DateTime(2026, 8, 6, 14, 30, 5)),
      'lubelogger-log-20260806-143005.txt',
    );
  });
}

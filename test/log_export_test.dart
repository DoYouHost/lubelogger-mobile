import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/features/bug_report/log_export.dart';
import 'package:lubelogger_mobile/features/bug_report/log_preview.dart';

void main() {
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

import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/chart_range.dart';

void main() {
  // A Monday.
  final now = DateTime(2026, 9, 14, 17, 30);

  group('preset ranges', () {
    test('three months are whole weeks ending with the current one', () {
      final w = const PresetRange(ChartRangePreset.threeMonths).resolve(now);
      expect(w.bucket, ChartBucket.week);
      expect(w.start, DateTime(2026, 6, 15));
      expect(w.end, DateTime(2026, 9, 14));
      expect(w.bucketStarts, hasLength(14));
      expect(w.bucketStarts.last, DateTime(2026, 9, 14));
    });

    test('the week start follows the locale', () {
      final w = const PresetRange(
        ChartRangePreset.oneMonth,
      ).resolve(now, firstDayOfWeek: DateTime.sunday);
      expect(w.bucketStarts.every((d) => d.weekday == DateTime.sunday), isTrue);
      expect(w.bucketStarts.last, DateTime(2026, 9, 13));
    });

    test('a year is twelve calendar months including this one', () {
      final w = const PresetRange(ChartRangePreset.year).resolve(now);
      expect(w.bucket, ChartBucket.month);
      expect(w.bucketStarts.first, DateTime(2025, 10));
      expect(w.bucketStarts.last, DateTime(2026, 9));
      expect(w.bucketStarts, hasLength(12));
    });

    test('six months cross into the previous year', () {
      final w = const PresetRange(
        ChartRangePreset.sixMonths,
      ).resolve(DateTime(2026, 2, 3));
      expect(w.bucketStarts.first, DateTime(2025, 9));
      expect(w.bucketStarts, hasLength(6));
    });
  });

  group('custom ranges', () {
    test('pick the slot size from their length', () {
      ChartBucket bucket(String a, String b) =>
          CustomRange(DateTime.parse(a), DateTime.parse(b)).resolve(now).bucket;
      expect(bucket('2026-07-15', '2026-09-14'), ChartBucket.week);
      expect(bucket('2025-01-01', '2026-09-14'), ChartBucket.month);
      expect(bucket('2023-01-01', '2026-09-14'), ChartBucket.quarter);
    });

    test('edge slots are clipped to the chosen days', () {
      final w = CustomRange(
        DateTime(2025, 11, 20),
        DateTime(2026, 5, 10),
      ).resolve(now);
      expect(w.daysOf(w.bucketStarts.first), (
        first: DateTime(2025, 11, 20),
        last: DateTime(2025, 11, 30),
      ));
      expect(w.daysOf(w.bucketStarts.last).last, DateTime(2026, 5, 10));
    });

    test('both ends are inclusive whatever the time of day', () {
      final w = CustomRange(
        DateTime(2026, 7, 1, 23),
        DateTime(2026, 7, 31, 1),
      ).resolve(now);
      expect(w.contains(DateTime(2026, 7, 1)), isTrue);
      expect(w.contains(DateTime(2026, 7, 31, 23, 59)), isTrue);
      expect(w.contains(DateTime(2026, 8, 1)), isFalse);
    });
  });

  group('quarters', () {
    test('start in January, April, July and October', () {
      final w = CustomRange(
        DateTime(2023, 5, 1),
        DateTime(2026, 2, 1),
      ).resolve(now);
      expect(w.bucketStarts.first, DateTime(2023, 4));
      expect(w.bucketStarts.last, DateTime(2026, 1));
    });
  });

  test('adding months clamps the day to the shorter month', () {
    expect(addMonths(DateTime(2026, 3, 31), -1), DateTime(2026, 2, 28));
    expect(addMonths(DateTime(2026, 1, 15), -3), DateTime(2025, 10, 15));
  });
}

/// The fixed spans a chart can be switched to, and the one Settings stores as
/// the default. A custom range is never a default: it names specific dates.
enum ChartRangePreset {
  oneMonth(1),
  threeMonths(3),
  sixMonths(6),
  year(12);

  const ChartRangePreset(this.months);

  final int months;

  static ChartRangePreset? byName(String name) {
    for (final p in values) {
      if (p.name == name) return p;
    }
    return null;
  }
}

/// How a window is split into chart slots.
enum ChartBucket { week, month, quarter }

/// What a chart was asked to show: a preset span ending today, or two dates.
sealed class ChartRange {
  const ChartRange();

  /// The concrete days this range covers as of [now].
  ChartWindow resolve(DateTime now, {int firstDayOfWeek = DateTime.monday});
}

class PresetRange extends ChartRange {
  const PresetRange(this.preset);

  final ChartRangePreset preset;

  /// Snaps the start to a bucket boundary so the first slot isn't a sliver: a
  /// week range starts on the first week start inside the span, a month range
  /// covers whole calendar months including the current one.
  @override
  ChartWindow resolve(DateTime now, {int firstDayOfWeek = DateTime.monday}) {
    final today = dateOnly(now);
    final roughStart = addMonths(today, -preset.months);
    final bucket = bucketFor(roughStart, today);
    final start = bucket == ChartBucket.week
        ? startOfWeek(
            DateTime(roughStart.year, roughStart.month, roughStart.day + 6),
            firstDayOfWeek,
          )
        : DateTime(today.year, today.month - (preset.months - 1));
    return ChartWindow(
      start: start,
      end: today,
      bucket: bucket,
      firstDayOfWeek: firstDayOfWeek,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PresetRange && other.preset == preset;

  @override
  int get hashCode => preset.hashCode;
}

class CustomRange extends ChartRange {
  /// Either order is accepted, so a window always has at least one slot.
  CustomRange(DateTime a, DateTime b)
    : start = dateOnly(a.isAfter(b) ? b : a),
      end = dateOnly(a.isAfter(b) ? a : b);

  final DateTime start;
  final DateTime end;

  @override
  ChartWindow resolve(DateTime now, {int firstDayOfWeek = DateTime.monday}) =>
      ChartWindow(
        start: start,
        end: end,
        bucket: bucketFor(start, end),
        firstDayOfWeek: firstDayOfWeek,
      );

  @override
  bool operator ==(Object other) =>
      other is CustomRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// A resolved span of calendar days, [start] and [end] both inclusive, with
/// the slot size its length calls for.
class ChartWindow {
  const ChartWindow({
    required this.start,
    required this.end,
    required this.bucket,
    this.firstDayOfWeek = DateTime.monday,
  });

  final DateTime start;
  final DateTime end;
  final ChartBucket bucket;

  /// [DateTime.monday] … [DateTime.sunday].
  final int firstDayOfWeek;

  bool contains(DateTime date) {
    final day = dateOnly(date);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  /// The first day of the slot [date] falls in.
  DateTime bucketOf(DateTime date) => switch (bucket) {
    ChartBucket.week => startOfWeek(date, firstDayOfWeek),
    ChartBucket.month => DateTime(date.year, date.month),
    ChartBucket.quarter => DateTime(date.year, (date.month - 1) ~/ 3 * 3 + 1),
  };

  DateTime _next(DateTime bucketStart) => switch (bucket) {
    ChartBucket.week => DateTime(
      bucketStart.year,
      bucketStart.month,
      bucketStart.day + 7,
    ),
    ChartBucket.month => DateTime(bucketStart.year, bucketStart.month + 1),
    ChartBucket.quarter => DateTime(bucketStart.year, bucketStart.month + 3),
  };

  /// First day of every slot, oldest first.
  List<DateTime> get bucketStarts => [
    for (var b = bucketOf(start); !b.isAfter(end); b = _next(b)) b,
  ];

  /// The days of the slot starting at [bucketStart] that lie inside the
  /// window: the edge slots of a custom range are partial.
  ({DateTime first, DateTime last}) daysOf(DateTime bucketStart) {
    final next = _next(bucketStart);
    final last = DateTime(next.year, next.month, next.day - 1);
    return (
      first: bucketStart.isBefore(start) ? start : bucketStart,
      last: last.isAfter(end) ? end : last,
    );
  }

  /// Slot index of [date], or null when it lies outside the window.
  int? indexOf(DateTime date, List<DateTime> starts) {
    if (!contains(date)) return null;
    final i = starts.indexOf(bucketOf(date));
    return i < 0 ? null : i;
  }
}

/// Weeks up to about a quarter, months up to two years, quarters beyond, so a
/// chart never has a handful of slots or several dozen.
ChartBucket bucketFor(DateTime start, DateTime end) {
  final days =
      DateTime.utc(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
      1;
  if (days <= 93) return ChartBucket.week;
  final months = (end.year - start.year) * 12 + end.month - start.month + 1;
  return months <= 24 ? ChartBucket.month : ChartBucket.quarter;
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime startOfWeek(DateTime date, int firstDayOfWeek) {
  final back = (date.weekday - firstDayOfWeek) % 7;
  return DateTime(date.year, date.month, date.day - back);
}

/// [date] moved by [months], with the day clamped to the target month's length
/// (31 March minus a month is 28 or 29 February, not 3 March).
DateTime addMonths(DateTime date, int months) {
  final firstOfTarget = DateTime(date.year, date.month + months);
  final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
  return DateTime(
    firstOfTarget.year,
    firstOfTarget.month,
    date.day > lastDay ? lastDay : date.day,
  );
}

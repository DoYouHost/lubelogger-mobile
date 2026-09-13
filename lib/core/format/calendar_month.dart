/// The first day of [date]'s month: the key per-month aggregates are bucketed
/// under, so the same month of different years stays apart.
DateTime monthOf(DateTime date) => DateTime(date.year, date.month);

/// The [count] months ending with [now]'s month, oldest first.
List<DateTime> trailingMonths(DateTime now, {int count = 12}) => [
  // DateTime normalizes a month below 1 into the previous year.
  for (var back = count - 1; back >= 0; back--)
    DateTime(now.year, now.month - back),
];

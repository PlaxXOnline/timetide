/// Strips time-of-day from a [DateTime] returning the day-only
/// representation in the local time zone.
///
/// Used internally by the shift planner widgets and controller to
/// normalize calendar dates for comparisons and predicate checks.
DateTime dayOnly(DateTime input) =>
    DateTime(input.year, input.month, input.day);

/// Returns `true` when [date] is considered closed according to any of the
/// three sources: a weekday set, a concrete date set, or a custom predicate.
///
/// Uses OR semantics: any source returning `true` makes the day closed.
/// When all three sources are `null` or empty the result is always `false`.
///
/// * [daysOfWeek] — weekdays (`DateTime.monday` .. `DateTime.sunday`,
///   i.e. `1..7`) that should be treated as closed.
/// * [dates] — concrete calendar days that should be treated as closed.
///   Comparisons ignore the time component on both sides, so a date entry
///   carrying a time (for example `DateTime(2026, 12, 25, 14, 30)`) still
///   matches any moment on that calendar day.
/// * [predicate] — custom closure invoked with [date]; returning `true`
///   marks the day closed.
bool isDayClosed(
  DateTime date, {
  Set<int>? daysOfWeek,
  Set<DateTime>? dates,
  bool Function(DateTime date)? predicate,
}) {
  if (daysOfWeek != null && daysOfWeek.contains(date.weekday)) {
    return true;
  }

  if (dates != null && dates.isNotEmpty) {
    for (final entry in dates) {
      if (entry.year == date.year &&
          entry.month == date.month &&
          entry.day == date.day) {
        return true;
      }
    }
  }

  if (predicate != null && predicate(date)) {
    return true;
  }

  return false;
}

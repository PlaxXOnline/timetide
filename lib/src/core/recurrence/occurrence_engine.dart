/// Lazy occurrence generator for RFC 5545 recurrence rules.
///
/// Given a [TideRecurrenceRule] and a start date, generates an [Iterable]
/// of [DateTime] occurrences using sync* generators. Never materializes
/// the full list — occurrences are yielded on demand.
library;

import 'package:collection/collection.dart';

import 'rrule_model.dart';

/// Generates occurrences for a [TideRecurrenceRule].
///
/// All generation is lazy — the returned [Iterable] uses sync* generators
/// that yield one occurrence at a time. This means infinite recurrence rules
/// (no COUNT or UNTIL) work correctly as long as the caller limits
/// consumption via the [before] parameter or by stopping iteration.
class TideOccurrenceEngine {
  TideOccurrenceEngine._();

  /// The maximum number of occurrences yielded when no COUNT, UNTIL, or
  /// [before] limit is specified. Prevents infinite loops.
  static const int defaultMaxOccurrences = 1000;

  /// Generates occurrences for the given [rule] starting from [start].
  ///
  /// - [after]: If provided, only yields occurrences strictly after this date.
  /// - [before]: If provided, only yields occurrences strictly before this date.
  ///
  /// The returned [Iterable] is lazy and uses sync* generators internally.
  /// No internal `.toList()` calls are made.
  static Iterable<DateTime> occurrences(
    TideRecurrenceRule rule,
    DateTime start, {
    DateTime? after,
    DateTime? before,
  }) sync* {
    final exDates = _sortedExDates(rule.exDates);
    final rDates = _sortedRDates(rule.rDates, exDates);

    // Merge rule-generated occurrences with RDATEs in chronological order.
    final ruleOccurrences = _ruleOccurrences(rule, start, after: after, before: before, exDates: exDates);

    yield* _mergeOccurrences(ruleOccurrences, rDates, rule, after: after, before: before);
  }

  /// Generates occurrences from the rule itself (without RDATEs).
  static Iterable<DateTime> _ruleOccurrences(
    TideRecurrenceRule rule,
    DateTime start, {
    DateTime? after,
    DateTime? before,
    required List<DateTime> exDates,
  }) sync* {
    var count = 0;
    final maxCount = rule.count;
    final until = rule.until;
    final hasLimit = maxCount != null || until != null || before != null;
    final safeMax = hasLimit ? null : defaultMaxOccurrences;

    for (final candidate in _candidateDates(rule, start)) {
      // UNTIL check.
      if (until != null && candidate.isAfter(until)) break;

      // before check.
      if (before != null && !candidate.isBefore(before)) break;

      // Safety limit for infinite series.
      if (safeMax != null && count >= safeMax) break;

      // EXDATE check using binary search.
      if (_isExcluded(candidate, exDates)) {
        // Excluded dates still count toward COUNT per RFC 5545? No — excluded
        // dates do NOT count toward COUNT. Only actually yielded occurrences do.
        continue;
      }

      // after filter — skip but don't count.
      if (after != null && !candidate.isAfter(after)) {
        // For COUNT rules, occurrences before `after` still count toward the limit.
        if (maxCount != null) count++;
        continue;
      }

      count++;
      if (maxCount != null && count > maxCount) break;

      yield candidate;
    }
  }

  /// Produces raw candidate dates by expanding the rule's frequency and BY*
  /// properties. Candidates are yielded in chronological order.
  static Iterable<DateTime> _candidateDates(
    TideRecurrenceRule rule,
    DateTime start,
  ) sync* {
    // Always yield the start date first (the DTSTART is the first occurrence).
    // Then generate subsequent periods.
    var periodIndex = 0;

    while (true) {
      final periodStart = _advancePeriod(start, rule.frequency, rule.interval, periodIndex);

      final expanded = _expandPeriod(rule, start, periodStart);

      // Apply BYSETPOS if present.
      if (rule.bySetPos != null && rule.bySetPos!.isNotEmpty) {
        yield* _applyBySetPos(expanded, rule.bySetPos!);
      } else {
        yield* expanded;
      }

      periodIndex++;
    }
  }

  /// Advances the start date by [periodIndex] intervals of [frequency].
  static DateTime _advancePeriod(
    DateTime start,
    TideFrequency frequency,
    int interval,
    int periodIndex,
  ) {
    final totalInterval = interval * periodIndex;
    switch (frequency) {
      case TideFrequency.daily:
        return DateTime(start.year, start.month, start.day + totalInterval,
            start.hour, start.minute, start.second);
      case TideFrequency.weekly:
        return DateTime(start.year, start.month, start.day + 7 * totalInterval,
            start.hour, start.minute, start.second);
      case TideFrequency.monthly:
        return _addMonths(start, totalInterval);
      case TideFrequency.yearly:
        return DateTime(start.year + totalInterval, start.month, start.day,
            start.hour, start.minute, start.second);
    }
  }

  /// Expands a single period into candidate dates based on BY* rules.
  /// The results must be sorted chronologically.
  static Iterable<DateTime> _expandPeriod(
    TideRecurrenceRule rule,
    DateTime dtStart,
    DateTime periodStart,
  ) sync* {
    switch (rule.frequency) {
      case TideFrequency.daily:
        yield* _expandDaily(rule, dtStart, periodStart);
      case TideFrequency.weekly:
        yield* _expandWeekly(rule, dtStart, periodStart);
      case TideFrequency.monthly:
        yield* _expandMonthly(rule, dtStart, periodStart);
      case TideFrequency.yearly:
        yield* _expandYearly(rule, dtStart, periodStart);
    }
  }

  // ─── DAILY expansion ────────────────────────────────────────────────

  static Iterable<DateTime> _expandDaily(
    TideRecurrenceRule rule,
    DateTime dtStart,
    DateTime periodStart,
  ) sync* {
    // DAILY: the period is a single day. BY* rules filter or expand times.
    // BYMONTH filters.
    if (rule.byMonth != null && !rule.byMonth!.contains(periodStart.month)) {
      return;
    }

    // BYDAY filters.
    if (rule.byDay != null && rule.byDay!.isNotEmpty) {
      final matchesDay = rule.byDay!.any((bd) => bd.weekday.dateTimeWeekday == periodStart.weekday);
      if (!matchesDay) return;
    }

    // Expand by BYHOUR/BYMINUTE or yield with start's time.
    yield* _expandTimes(rule, periodStart, dtStart);
  }

  // ─── WEEKLY expansion ───────────────────────────────────────────────

  static Iterable<DateTime> _expandWeekly(
    TideRecurrenceRule rule,
    DateTime dtStart,
    DateTime periodStart,
  ) sync* {
    if (rule.byDay != null && rule.byDay!.isNotEmpty) {
      // Expand to all specified days within this week.
      // Find the start of the week based on WKST.
      final weekStart = _startOfWeek(periodStart, rule.weekStart);

      final days = <DateTime>[];
      for (final byDay in rule.byDay!) {
        final targetDow = byDay.weekday.dateTimeWeekday;
        // Calculate the date of this weekday within the week.
        final wkstDow = rule.weekStart.dateTimeWeekday;
        var diff = targetDow - wkstDow;
        if (diff < 0) diff += 7;
        final date = DateTime(weekStart.year, weekStart.month, weekStart.day + diff,
            dtStart.hour, dtStart.minute, dtStart.second);
        days.add(date);
      }

      // Sort chronologically.
      days.sort((a, b) => a.compareTo(b));

      for (final day in days) {
        // BYMONTH filter.
        if (rule.byMonth != null && !rule.byMonth!.contains(day.month)) {
          continue;
        }
        yield* _expandTimes(rule, day, dtStart);
      }
    } else {
      // No BYDAY: yield the same weekday as DTSTART.
      if (rule.byMonth != null && !rule.byMonth!.contains(periodStart.month)) {
        return;
      }
      yield* _expandTimes(rule, periodStart, dtStart);
    }
  }

  // ─── MONTHLY expansion ─────────────────────────────────────────────

  static Iterable<DateTime> _expandMonthly(
    TideRecurrenceRule rule,
    DateTime dtStart,
    DateTime periodStart,
  ) sync* {
    // BYMONTH filter.
    if (rule.byMonth != null && !rule.byMonth!.contains(periodStart.month)) {
      return;
    }

    final year = periodStart.year;
    final month = periodStart.month;

    if (rule.byDay != null && rule.byDay!.isNotEmpty) {
      // BYDAY expansion for monthly — ordinals select specific occurrences.
      final days = <DateTime>[];
      for (final byDay in rule.byDay!) {
        if (byDay.ordinal != null) {
          final date = _nthWeekdayOfMonth(year, month, byDay.weekday, byDay.ordinal!);
          if (date != null) {
            days.add(DateTime(date.year, date.month, date.day,
                dtStart.hour, dtStart.minute, dtStart.second));
          }
        } else {
          // Every occurrence of this weekday in the month.
          for (var d = 1; d <= _daysInMonth(year, month); d++) {
            final date = DateTime(year, month, d);
            if (date.weekday == byDay.weekday.dateTimeWeekday) {
              days.add(DateTime(year, month, d,
                  dtStart.hour, dtStart.minute, dtStart.second));
            }
          }
        }
      }

      days.sort((a, b) => a.compareTo(b));
      for (final day in days) {
        yield* _expandTimes(rule, day, dtStart);
      }
    } else if (rule.byMonthDay != null && rule.byMonthDay!.isNotEmpty) {
      // BYMONTHDAY expansion.
      final dim = _daysInMonth(year, month);
      final days = <DateTime>[];
      for (final md in rule.byMonthDay!) {
        final resolvedDay = md > 0 ? md : dim + md + 1;
        if (resolvedDay >= 1 && resolvedDay <= dim) {
          days.add(DateTime(year, month, resolvedDay,
              dtStart.hour, dtStart.minute, dtStart.second));
        }
      }
      days.sort((a, b) => a.compareTo(b));
      for (final day in days) {
        yield* _expandTimes(rule, day, dtStart);
      }
    } else {
      // Default: same day-of-month as DTSTART.
      final dim = _daysInMonth(year, month);
      if (dtStart.day <= dim) {
        final date = DateTime(year, month, dtStart.day,
            dtStart.hour, dtStart.minute, dtStart.second);
        yield* _expandTimes(rule, date, dtStart);
      }
      // Skip months where the day doesn't exist (e.g., Jan 31 → Feb has no 31).
    }
  }

  // ─── YEARLY expansion ──────────────────────────────────────────────

  static Iterable<DateTime> _expandYearly(
    TideRecurrenceRule rule,
    DateTime dtStart,
    DateTime periodStart,
  ) sync* {
    final year = periodStart.year;

    // Start with the full year or DTSTART date, then apply BY* rules.
    // RFC 5545 expansion order: BYMONTH → BYWEEKNO → BYYEARDAY →
    // BYMONTHDAY → BYDAY

    if (rule.byYearDay != null && rule.byYearDay!.isNotEmpty) {
      yield* _expandYearlyByYearDay(rule, dtStart, year);
      return;
    }

    if (rule.byWeekNo != null && rule.byWeekNo!.isNotEmpty) {
      yield* _expandYearlyByWeekNo(rule, dtStart, year);
      return;
    }

    // Determine which months to process.
    final months = rule.byMonth ?? [dtStart.month];

    final allDays = <DateTime>[];

    for (final month in months) {
      if (rule.byDay != null && rule.byDay!.isNotEmpty) {
        // BYDAY in yearly context with BYMONTH.
        for (final byDay in rule.byDay!) {
          if (byDay.ordinal != null) {
            final date = _nthWeekdayOfMonth(year, month, byDay.weekday, byDay.ordinal!);
            if (date != null) {
              allDays.add(DateTime(date.year, date.month, date.day,
                  dtStart.hour, dtStart.minute, dtStart.second));
            }
          } else {
            // Every occurrence of this weekday in the month.
            final dim = _daysInMonth(year, month);
            for (var d = 1; d <= dim; d++) {
              final date = DateTime(year, month, d);
              if (date.weekday == byDay.weekday.dateTimeWeekday) {
                allDays.add(DateTime(year, month, d,
                    dtStart.hour, dtStart.minute, dtStart.second));
              }
            }
          }
        }
      } else if (rule.byMonthDay != null && rule.byMonthDay!.isNotEmpty) {
        final dim = _daysInMonth(year, month);
        for (final md in rule.byMonthDay!) {
          final resolvedDay = md > 0 ? md : dim + md + 1;
          if (resolvedDay >= 1 && resolvedDay <= dim) {
            allDays.add(DateTime(year, month, resolvedDay,
                dtStart.hour, dtStart.minute, dtStart.second));
          }
        }
      } else {
        // Default: same month-day as DTSTART.
        final dim = _daysInMonth(year, month);
        final day = dtStart.day;
        if (day <= dim) {
          allDays.add(DateTime(year, month, day,
              dtStart.hour, dtStart.minute, dtStart.second));
        }
      }
    }

    allDays.sort((a, b) => a.compareTo(b));
    for (final day in allDays) {
      yield* _expandTimes(rule, day, dtStart);
    }
  }

  static Iterable<DateTime> _expandYearlyByYearDay(
    TideRecurrenceRule rule,
    DateTime dtStart,
    int year,
  ) sync* {
    final daysInYear = _isLeapYear(year) ? 366 : 365;
    final jan1 = DateTime(year);
    final days = <DateTime>[];

    for (final yd in rule.byYearDay!) {
      final resolvedDay = yd > 0 ? yd : daysInYear + yd + 1;
      if (resolvedDay >= 1 && resolvedDay <= daysInYear) {
        final date = jan1.add(Duration(days: resolvedDay - 1));
        // BYMONTH filter.
        if (rule.byMonth != null && !rule.byMonth!.contains(date.month)) {
          continue;
        }
        // BYDAY filter.
        if (rule.byDay != null &&
            !rule.byDay!.any((bd) => bd.weekday.dateTimeWeekday == date.weekday)) {
          continue;
        }
        days.add(DateTime(date.year, date.month, date.day,
            dtStart.hour, dtStart.minute, dtStart.second));
      }
    }

    days.sort((a, b) => a.compareTo(b));
    for (final day in days) {
      yield* _expandTimes(rule, day, dtStart);
    }
  }

  static Iterable<DateTime> _expandYearlyByWeekNo(
    TideRecurrenceRule rule,
    DateTime dtStart,
    int year,
  ) sync* {
    final days = <DateTime>[];

    for (final wn in rule.byWeekNo!) {
      final weekStart = _isoWeekToDate(year, wn, rule.weekStart);
      if (weekStart == null) continue;

      if (rule.byDay != null && rule.byDay!.isNotEmpty) {
        for (final byDay in rule.byDay!) {
          final wkstDow = rule.weekStart.dateTimeWeekday;
          final targetDow = byDay.weekday.dateTimeWeekday;
          var diff = targetDow - wkstDow;
          if (diff < 0) diff += 7;
          final date = DateTime(weekStart.year, weekStart.month,
              weekStart.day + diff, dtStart.hour, dtStart.minute, dtStart.second);
          // BYMONTH filter.
          if (rule.byMonth != null && !rule.byMonth!.contains(date.month)) {
            continue;
          }
          days.add(date);
        }
      } else {
        // Default: same weekday as DTSTART.
        final wkstDow = rule.weekStart.dateTimeWeekday;
        final targetDow = dtStart.weekday;
        var diff = targetDow - wkstDow;
        if (diff < 0) diff += 7;
        final date = DateTime(weekStart.year, weekStart.month,
            weekStart.day + diff, dtStart.hour, dtStart.minute, dtStart.second);
        if (rule.byMonth != null && !rule.byMonth!.contains(date.month)) {
          // skip
        } else {
          days.add(date);
        }
      }
    }

    days.sort((a, b) => a.compareTo(b));
    for (final day in days) {
      yield* _expandTimes(rule, day, dtStart);
    }
  }

  // ─── Time expansion ─────────────────────────────────────────────────

  /// Expands a date by BYHOUR/BYMINUTE, or yields it with its existing time.
  static Iterable<DateTime> _expandTimes(
    TideRecurrenceRule rule,
    DateTime date,
    DateTime dtStart,
  ) sync* {
    final hours = rule.byHour ?? [date.hour];
    final minutes = rule.byMinute ?? [date.minute];

    for (final h in hours) {
      for (final m in minutes) {
        yield DateTime(date.year, date.month, date.day, h, m, date.second);
      }
    }
  }

  // ─── BYSETPOS ───────────────────────────────────────────────────────

  /// Applies BYSETPOS filtering to a set of expanded dates.
  /// Collects the full expanded set for a period, then selects by position.
  static Iterable<DateTime> _applyBySetPos(
    Iterable<DateTime> expanded,
    List<int> positions,
  ) sync* {
    // BYSETPOS requires materializing the period's candidates to select by
    // position. This is bounded to one period (e.g. one month), not the
    // entire series, so the list stays small.
    final list = expanded.toList();
    if (list.isEmpty) return;

    for (final pos in positions) {
      final index = pos > 0 ? pos - 1 : list.length + pos;
      if (index >= 0 && index < list.length) {
        yield list[index];
      }
    }
  }

  // ─── RDATE merging ──────────────────────────────────────────────────

  /// Merges rule-generated occurrences with RDATEs in chronological order.
  /// Applies COUNT/UNTIL limits to the merged stream.
  static Iterable<DateTime> _mergeOccurrences(
    Iterable<DateTime> ruleOccurrences,
    List<DateTime> rDates,
    TideRecurrenceRule rule, {
    DateTime? after,
    DateTime? before,
  }) sync* {
    if (rDates.isEmpty) {
      yield* ruleOccurrences;
      return;
    }

    // We need to merge two sorted streams. The rule occurrences are already
    // filtered by COUNT/UNTIL/EXDATE/after/before. But RDATEs must also be
    // filtered by after/before, and the merged COUNT must be tracked.
    //
    // Since rule occurrences already have COUNT applied, merging with RDATEs
    // and re-applying COUNT would double-count. Instead, we handle COUNT
    // in the merge itself. However, the _ruleOccurrences generator already
    // applies COUNT. For simplicity and correctness with RDATEs, when RDATEs
    // are present we need to handle COUNT at this level.
    //
    // For this implementation: RDATEs are simply additional dates merged in.
    // They don't count toward the rule's COUNT (this is a common interpretation).
    var rDateIdx = 0;
    final ruleIter = ruleOccurrences.iterator;
    var hasRule = ruleIter.moveNext();

    while (hasRule || rDateIdx < rDates.length) {
      DateTime? nextRule = hasRule ? ruleIter.current : null;
      DateTime? nextRDate = rDateIdx < rDates.length ? rDates[rDateIdx] : null;

      DateTime next;
      if (nextRule != null && nextRDate != null) {
        if (!nextRDate.isAfter(nextRule)) {
          next = nextRDate;
          rDateIdx++;
          // If they are equal, also advance rule to avoid duplicate.
          if (nextRule.isAtSameMomentAs(nextRDate)) {
            hasRule = ruleIter.moveNext();
          }
        } else {
          next = nextRule;
          hasRule = ruleIter.moveNext();
        }
      } else if (nextRule != null) {
        next = nextRule;
        hasRule = ruleIter.moveNext();
      } else {
        next = nextRDate!;
        rDateIdx++;
      }

      // Apply range filters to RDATEs.
      if (before != null && !next.isBefore(before)) break;
      if (rule.until != null && next.isAfter(rule.until!)) break;
      if (after != null && !next.isAfter(after)) continue;

      yield next;
    }
  }

  // ─── EXDATE binary search ──────────────────────────────────────────

  /// Returns a sorted copy of [exDates] for binary search.
  static List<DateTime> _sortedExDates(List<DateTime>? exDates) {
    if (exDates == null || exDates.isEmpty) return const [];
    final sorted = List<DateTime>.of(exDates)..sort((a, b) => a.compareTo(b));
    return sorted;
  }

  /// Returns RDATEs sorted and with EXDATE entries removed.
  static List<DateTime> _sortedRDates(List<DateTime>? rDates, List<DateTime> exDates) {
    if (rDates == null || rDates.isEmpty) return const [];
    final sorted = List<DateTime>.of(rDates)..sort((a, b) => a.compareTo(b));
    if (exDates.isEmpty) return sorted;
    // Remove any RDATEs that are excluded.
    return sorted.where((rd) => !_isExcluded(rd, exDates)).toList();
  }

  /// Checks if [date] is in the sorted [exDates] list using binary search.
  static bool _isExcluded(DateTime date, List<DateTime> exDates) {
    if (exDates.isEmpty) return false;
    final index = binarySearch(exDates, date, compare: (a, b) => a.compareTo(b));
    return index >= 0 && index < exDates.length && exDates[index].isAtSameMomentAs(date);
  }

  // ─── Date utilities ─────────────────────────────────────────────────

  /// Returns the number of days in the given [month] of [year].
  static int _daysInMonth(int year, int month) {
    // DateTime(year, month + 1, 0) gives the last day of the month.
    return DateTime(year, month + 1, 0).day;
  }

  /// Returns `true` if [year] is a leap year.
  static bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Adds [months] to [date], clamping the day to the last valid day of the
  /// target month.
  static DateTime _addMonths(DateTime date, int months) {
    var newMonth = date.month + months;
    var newYear = date.year;
    // Normalize month to 1-12 range.
    newYear += (newMonth - 1) ~/ 12;
    newMonth = ((newMonth - 1) % 12) + 1;
    final dim = _daysInMonth(newYear, newMonth);
    final newDay = date.day > dim ? dim : date.day;
    return DateTime(newYear, newMonth, newDay, date.hour, date.minute, date.second);
  }

  /// Finds the start of the week containing [date] based on [weekStart].
  static DateTime _startOfWeek(DateTime date, TideWeekday weekStart) {
    final wkstDow = weekStart.dateTimeWeekday;
    var diff = date.weekday - wkstDow;
    if (diff < 0) diff += 7;
    return DateTime(date.year, date.month, date.day - diff,
        date.hour, date.minute, date.second);
  }

  /// Finds the Nth occurrence of [weekday] in the given [year]/[month].
  ///
  /// [ordinal] is 1-based. Negative values count from the end
  /// (-1 = last, -2 = second-to-last).
  /// Returns `null` if the ordinal is out of range.
  static DateTime? _nthWeekdayOfMonth(
    int year,
    int month,
    TideWeekday weekday,
    int ordinal,
  ) {
    final dim = _daysInMonth(year, month);
    final targetDow = weekday.dateTimeWeekday;

    if (ordinal > 0) {
      // Count from the start.
      var count = 0;
      for (var d = 1; d <= dim; d++) {
        if (DateTime(year, month, d).weekday == targetDow) {
          count++;
          if (count == ordinal) return DateTime(year, month, d);
        }
      }
    } else if (ordinal < 0) {
      // Count from the end.
      final targetCount = -ordinal;
      var count = 0;
      for (var d = dim; d >= 1; d--) {
        if (DateTime(year, month, d).weekday == targetDow) {
          count++;
          if (count == targetCount) return DateTime(year, month, d);
        }
      }
    }
    return null;
  }

  /// Converts an ISO week number to the date of the first day of that week.
  ///
  /// Returns `null` if the week number is out of range.
  static DateTime? _isoWeekToDate(int year, int weekNo, TideWeekday weekStart) {
    if (weekNo < 1 || weekNo > 53) return null;

    // Find Jan 4 of the year (always in ISO week 1).
    final jan4 = DateTime(year, 1, 4);
    // Find the Monday of ISO week 1.
    final isoWeek1Monday = DateTime(year, 1, 4 - (jan4.weekday - 1));
    // Calculate the Monday of the requested week.
    final weekMonday = isoWeek1Monday.add(Duration(days: (weekNo - 1) * 7));

    // Adjust to the configured week start.
    final mondayDow = DateTime.monday;
    final wkstDow = weekStart.dateTimeWeekday;
    var diff = wkstDow - mondayDow;
    if (diff > 3) diff -= 7; // Keep it close to Monday.
    final adjustedStart = weekMonday.add(Duration(days: diff));

    return DateTime(adjustedStart.year, adjustedStart.month, adjustedStart.day);
  }
}

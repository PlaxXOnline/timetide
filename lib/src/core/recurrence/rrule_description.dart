/// Generates human-readable descriptions of [TideRecurrenceRule] instances.
///
/// Supports English (`en`) and German (`de`) locales.
library;

import 'rrule_model.dart';

/// Generates localized, human-readable descriptions of recurrence rules.
///
/// Example:
/// ```dart
/// final rule = TideRecurrenceRule(
///   frequency: TideFrequency.weekly,
///   byDay: [TideByDay(weekday: TideWeekday.monday),
///           TideByDay(weekday: TideWeekday.wednesday)],
/// );
/// TideRRuleDescription.describe(rule); // "Every week on Monday, Wednesday"
/// TideRRuleDescription.describe(rule, locale: 'de'); // "Jede Woche am Montag, Mittwoch"
/// ```
class TideRRuleDescription {
  TideRRuleDescription._();

  /// Returns a human-readable description of [rule] in the given [locale].
  ///
  /// Supported locales: `'en'` (default), `'de'`.
  static String describe(TideRecurrenceRule rule, {String locale = 'en'}) {
    final l = _locales[locale] ?? _locales['en']!;

    final base = _describeBase(rule, l);
    final suffix = _describeSuffix(rule, l);

    return suffix.isEmpty ? base : '$base$suffix';
  }

  /// Builds the main description (frequency + BY* rules).
  static String _describeBase(TideRecurrenceRule rule, _L10n l) {
    switch (rule.frequency) {
      case TideFrequency.daily:
        return _describeDaily(rule, l);
      case TideFrequency.weekly:
        return _describeWeekly(rule, l);
      case TideFrequency.monthly:
        return _describeMonthly(rule, l);
      case TideFrequency.yearly:
        return _describeYearly(rule, l);
    }
  }

  // ─── DAILY ──────────────────────────────────────────────────────────

  static String _describeDaily(TideRecurrenceRule rule, _L10n l) {
    if (rule.interval == 1) {
      return l.everyDay;
    }
    return l.everyNDays(rule.interval);
  }

  // ─── WEEKLY ─────────────────────────────────────────────────────────

  static String _describeWeekly(TideRecurrenceRule rule, _L10n l) {
    final dayNames = _dayNames(rule.byDay, l);

    if (rule.interval == 1) {
      if (dayNames == null) return l.everyWeek;
      return l.everyWeekOn(dayNames);
    }
    if (dayNames == null) return l.everyNWeeks(rule.interval);
    return l.everyNWeeksOn(rule.interval, dayNames);
  }

  // ─── MONTHLY ────────────────────────────────────────────────────────

  static String _describeMonthly(TideRecurrenceRule rule, _L10n l) {
    // BYDAY with ordinal — e.g., "the 3rd Friday of every month".
    if (rule.byDay != null && rule.byDay!.isNotEmpty) {
      final byDay = rule.byDay!.first;
      if (byDay.ordinal != null) {
        return l.ordinalWeekdayOfEveryMonth(
          byDay.ordinal!,
          l.weekdayName(byDay.weekday),
          rule.interval,
        );
      }
    }

    // BYSETPOS with BYDAY — e.g., "the 3rd Friday of every month".
    if (rule.bySetPos != null &&
        rule.bySetPos!.isNotEmpty &&
        rule.byDay != null &&
        rule.byDay!.isNotEmpty) {
      final pos = rule.bySetPos!.first;
      final byDay = rule.byDay!.first;
      return l.ordinalWeekdayOfEveryMonth(
        pos,
        l.weekdayName(byDay.weekday),
        rule.interval,
      );
    }

    // BYMONTHDAY — e.g., "every month on the 15th".
    if (rule.byMonthDay != null && rule.byMonthDay!.isNotEmpty) {
      final dayStr = rule.byMonthDay!.map((d) => l.ordinalDay(d)).join(', ');
      if (rule.interval == 1) {
        return l.everyMonthOnDay(dayStr);
      }
      return l.everyNMonthsOnDay(rule.interval, dayStr);
    }

    if (rule.interval == 1) return l.everyMonth;
    return l.everyNMonths(rule.interval);
  }

  // ─── YEARLY ─────────────────────────────────────────────────────────

  static String _describeYearly(TideRecurrenceRule rule, _L10n l) {
    // BYMONTH + BYMONTHDAY or BYMONTH + BYDAY.
    if (rule.byMonth != null && rule.byMonth!.isNotEmpty) {
      final month = rule.byMonth!.first;
      final monthName = l.monthName(month);

      if (rule.byDay != null && rule.byDay!.isNotEmpty) {
        final byDay = rule.byDay!.first;
        if (byDay.ordinal != null) {
          if (rule.interval == 1) {
            return l.everyYearOrdinalWeekdayOfMonth(
              byDay.ordinal!,
              l.weekdayName(byDay.weekday),
              monthName,
            );
          }
          return l.everyNYearsOrdinalWeekdayOfMonth(
            rule.interval,
            byDay.ordinal!,
            l.weekdayName(byDay.weekday),
            monthName,
          );
        }
      }

      if (rule.byMonthDay != null && rule.byMonthDay!.isNotEmpty) {
        final day = rule.byMonthDay!.first;
        if (rule.interval == 1) {
          return l.everyYearOnDate(monthName, day);
        }
        return l.everyNYearsOnDate(rule.interval, monthName, day);
      }

      // Just BYMONTH, use a generic description.
      if (rule.interval == 1) {
        return l.everyYearIn(monthName);
      }
      return l.everyNYearsIn(rule.interval, monthName);
    }

    if (rule.interval == 1) return l.everyYear;
    return l.everyNYears(rule.interval);
  }

  // ─── Suffix (COUNT / UNTIL) ─────────────────────────────────────────

  static String _describeSuffix(TideRecurrenceRule rule, _L10n l) {
    if (rule.count != null) {
      return l.countSuffix(rule.count!);
    }
    if (rule.until != null) {
      return l.untilSuffix(rule.until!);
    }
    return '';
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  /// Joins weekday names from BYDAY list. Returns null if no BYDAY.
  static String? _dayNames(List<TideByDay>? byDay, _L10n l) {
    if (byDay == null || byDay.isEmpty) return null;
    return byDay.map((bd) => l.weekdayName(bd.weekday)).join(', ');
  }

  static final Map<String, _L10n> _locales = {
    'en': const _EnL10n(),
    'de': const _DeL10n(),
  };
}

// ─── Localization contracts ───────────────────────────────────────────

abstract class _L10n {
  const _L10n();

  String get everyDay;
  String everyNDays(int n);
  String get everyWeek;
  String everyWeekOn(String days);
  String everyNWeeks(int n);
  String everyNWeeksOn(int n, String days);
  String get everyMonth;
  String everyNMonths(int n);
  String everyMonthOnDay(String day);
  String everyNMonthsOnDay(int n, String day);
  String ordinalWeekdayOfEveryMonth(int ordinal, String weekday, int interval);
  String get everyYear;
  String everyNYears(int n);
  String everyYearOnDate(String month, int day);
  String everyNYearsOnDate(int n, String month, int day);
  String everyYearIn(String month);
  String everyNYearsIn(int n, String month);
  String everyYearOrdinalWeekdayOfMonth(int ordinal, String weekday, String month);
  String everyNYearsOrdinalWeekdayOfMonth(int n, int ordinal, String weekday, String month);
  String countSuffix(int count);
  String untilSuffix(DateTime until);
  String ordinalDay(int day);
  String weekdayName(TideWeekday weekday);
  String monthName(int month);
}

// ─── English ──────────────────────────────────────────────────────────

class _EnL10n extends _L10n {
  const _EnL10n();

  @override
  String get everyDay => 'Every day';

  @override
  String everyNDays(int n) => 'Every $n days';

  @override
  String get everyWeek => 'Every week';

  @override
  String everyWeekOn(String days) => 'Every week on $days';

  @override
  String everyNWeeks(int n) => 'Every $n weeks';

  @override
  String everyNWeeksOn(int n, String days) => 'Every $n weeks on $days';

  @override
  String get everyMonth => 'Every month';

  @override
  String everyNMonths(int n) => 'Every $n months';

  @override
  String everyMonthOnDay(String day) => 'Every month on the $day';

  @override
  String everyNMonthsOnDay(int n, String day) => 'Every $n months on the $day';

  @override
  String ordinalWeekdayOfEveryMonth(int ordinal, String weekday, int interval) {
    final ord = _ordinalWord(ordinal);
    if (interval == 1) {
      return 'The $ord $weekday of every month';
    }
    return 'The $ord $weekday of every $interval months';
  }

  @override
  String get everyYear => 'Every year';

  @override
  String everyNYears(int n) => 'Every $n years';

  @override
  String everyYearOnDate(String month, int day) => 'Every year on $month $day';

  @override
  String everyNYearsOnDate(int n, String month, int day) =>
      'Every $n years on $month $day';

  @override
  String everyYearIn(String month) => 'Every year in $month';

  @override
  String everyNYearsIn(int n, String month) => 'Every $n years in $month';

  @override
  String everyYearOrdinalWeekdayOfMonth(
      int ordinal, String weekday, String month) {
    final ord = _ordinalWord(ordinal);
    return 'The $ord $weekday of $month every year';
  }

  @override
  String everyNYearsOrdinalWeekdayOfMonth(
      int n, int ordinal, String weekday, String month) {
    final ord = _ordinalWord(ordinal);
    return 'The $ord $weekday of $month every $n years';
  }

  @override
  String countSuffix(int count) => ', $count times';

  @override
  String untilSuffix(DateTime until) {
    final month = monthName(until.month);
    return ', until $month ${until.day}, ${until.year}';
  }

  @override
  String ordinalDay(int day) {
    if (day < 0) return 'last';
    if (day == 1 || day == 21 || day == 31) return '${day}st';
    if (day == 2 || day == 22) return '${day}nd';
    if (day == 3 || day == 23) return '${day}rd';
    return '${day}th';
  }

  @override
  String weekdayName(TideWeekday weekday) {
    switch (weekday) {
      case TideWeekday.monday:
        return 'Monday';
      case TideWeekday.tuesday:
        return 'Tuesday';
      case TideWeekday.wednesday:
        return 'Wednesday';
      case TideWeekday.thursday:
        return 'Thursday';
      case TideWeekday.friday:
        return 'Friday';
      case TideWeekday.saturday:
        return 'Saturday';
      case TideWeekday.sunday:
        return 'Sunday';
    }
  }

  @override
  String monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month];
  }

  String _ordinalWord(int ordinal) {
    if (ordinal == -1) return 'last';
    if (ordinal == -2) return 'second to last';
    if (ordinal < -2) return '${-ordinal}th to last';
    if (ordinal == 1) return '1st';
    if (ordinal == 2) return '2nd';
    if (ordinal == 3) return '3rd';
    return '${ordinal}th';
  }
}

// ─── German ───────────────────────────────────────────────────────────

class _DeL10n extends _L10n {
  const _DeL10n();

  @override
  String get everyDay => 'Jeden Tag';

  @override
  String everyNDays(int n) => 'Alle $n Tage';

  @override
  String get everyWeek => 'Jede Woche';

  @override
  String everyWeekOn(String days) => 'Jede Woche am $days';

  @override
  String everyNWeeks(int n) => 'Alle $n Wochen';

  @override
  String everyNWeeksOn(int n, String days) => 'Alle $n Wochen am $days';

  @override
  String get everyMonth => 'Jeden Monat';

  @override
  String everyNMonths(int n) => 'Alle $n Monate';

  @override
  String everyMonthOnDay(String day) => 'Jeden Monat am $day';

  @override
  String everyNMonthsOnDay(int n, String day) => 'Alle $n Monate am $day';

  @override
  String ordinalWeekdayOfEveryMonth(int ordinal, String weekday, int interval) {
    final ord = _ordinalWord(ordinal);
    if (interval == 1) {
      return 'Der $ord $weekday jeden Monats';
    }
    return 'Der $ord $weekday alle $interval Monate';
  }

  @override
  String get everyYear => 'Jedes Jahr';

  @override
  String everyNYears(int n) => 'Alle $n Jahre';

  @override
  String everyYearOnDate(String month, int day) => 'Jedes Jahr am $day. $month';

  @override
  String everyNYearsOnDate(int n, String month, int day) =>
      'Alle $n Jahre am $day. $month';

  @override
  String everyYearIn(String month) => 'Jedes Jahr im $month';

  @override
  String everyNYearsIn(int n, String month) => 'Alle $n Jahre im $month';

  @override
  String everyYearOrdinalWeekdayOfMonth(
      int ordinal, String weekday, String month) {
    final ord = _ordinalWord(ordinal);
    return 'Der $ord $weekday im $month jedes Jahr';
  }

  @override
  String everyNYearsOrdinalWeekdayOfMonth(
      int n, int ordinal, String weekday, String month) {
    final ord = _ordinalWord(ordinal);
    return 'Der $ord $weekday im $month alle $n Jahre';
  }

  @override
  String countSuffix(int count) => ', $count Mal';

  @override
  String untilSuffix(DateTime until) {
    final month = monthName(until.month);
    return ', bis ${until.day}. $month ${until.year}';
  }

  @override
  String ordinalDay(int day) {
    if (day < 0) return 'letzten';
    return '$day.';
  }

  @override
  String weekdayName(TideWeekday weekday) {
    switch (weekday) {
      case TideWeekday.monday:
        return 'Montag';
      case TideWeekday.tuesday:
        return 'Dienstag';
      case TideWeekday.wednesday:
        return 'Mittwoch';
      case TideWeekday.thursday:
        return 'Donnerstag';
      case TideWeekday.friday:
        return 'Freitag';
      case TideWeekday.saturday:
        return 'Samstag';
      case TideWeekday.sunday:
        return 'Sonntag';
    }
  }

  @override
  String monthName(int month) {
    const months = [
      '', 'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
    ];
    return months[month];
  }

  String _ordinalWord(int ordinal) {
    if (ordinal == -1) return 'letzte';
    if (ordinal == -2) return 'vorletzte';
    if (ordinal < -2) return '${-ordinal}.-letzte';
    return '$ordinal.';
  }
}

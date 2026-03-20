/// Data model for RFC 5545 RRULE recurrence rules.
///
/// Provides [TideFrequency], [TideWeekday], [TideByDay], and
/// [TideRecurrenceRule] — all immutable value types used throughout
/// the timetide recurrence subsystem.
library;

/// Recurrence frequency as defined by RFC 5545.
enum TideFrequency {
  /// Repeats every day (or every N days with interval).
  daily,

  /// Repeats every week (or every N weeks with interval).
  weekly,

  /// Repeats every month (or every N months with interval).
  monthly,

  /// Repeats every year (or every N years with interval).
  yearly;

  /// Returns the RFC 5545 string representation (e.g. `DAILY`, `WEEKLY`).
  String toRfcString() => name.toUpperCase();

  /// Parses an RFC 5545 frequency string.
  ///
  /// Returns `null` if [value] does not match a known frequency.
  static TideFrequency? fromRfcString(String value) {
    switch (value.toUpperCase()) {
      case 'DAILY':
        return TideFrequency.daily;
      case 'WEEKLY':
        return TideFrequency.weekly;
      case 'MONTHLY':
        return TideFrequency.monthly;
      case 'YEARLY':
        return TideFrequency.yearly;
      default:
        return null;
    }
  }
}

/// Days of the week, used in BYDAY rules.
enum TideWeekday {
  /// Monday.
  monday,

  /// Tuesday.
  tuesday,

  /// Wednesday.
  wednesday,

  /// Thursday.
  thursday,

  /// Friday.
  friday,

  /// Saturday.
  saturday,

  /// Sunday.
  sunday;

  /// The two-letter RFC 5545 abbreviation (e.g. `MO`, `TU`).
  String get abbreviation {
    switch (this) {
      case TideWeekday.monday:
        return 'MO';
      case TideWeekday.tuesday:
        return 'TU';
      case TideWeekday.wednesday:
        return 'WE';
      case TideWeekday.thursday:
        return 'TH';
      case TideWeekday.friday:
        return 'FR';
      case TideWeekday.saturday:
        return 'SA';
      case TideWeekday.sunday:
        return 'SU';
    }
  }

  /// Parses a two-letter RFC 5545 weekday abbreviation.
  ///
  /// Returns `null` if [abbr] is not a valid weekday abbreviation.
  static TideWeekday? fromAbbreviation(String abbr) {
    switch (abbr.toUpperCase()) {
      case 'MO':
        return TideWeekday.monday;
      case 'TU':
        return TideWeekday.tuesday;
      case 'WE':
        return TideWeekday.wednesday;
      case 'TH':
        return TideWeekday.thursday;
      case 'FR':
        return TideWeekday.friday;
      case 'SA':
        return TideWeekday.saturday;
      case 'SU':
        return TideWeekday.sunday;
      default:
        return null;
    }
  }

  /// Returns the [DateTime.weekday] integer (1 = Monday … 7 = Sunday).
  int get dateTimeWeekday {
    switch (this) {
      case TideWeekday.monday:
        return DateTime.monday;
      case TideWeekday.tuesday:
        return DateTime.tuesday;
      case TideWeekday.wednesday:
        return DateTime.wednesday;
      case TideWeekday.thursday:
        return DateTime.thursday;
      case TideWeekday.friday:
        return DateTime.friday;
      case TideWeekday.saturday:
        return DateTime.saturday;
      case TideWeekday.sunday:
        return DateTime.sunday;
    }
  }

  /// Creates a [TideWeekday] from a [DateTime.weekday] integer.
  ///
  /// Returns `null` if [weekday] is not in range 1–7.
  static TideWeekday? fromDateTimeWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return TideWeekday.monday;
      case DateTime.tuesday:
        return TideWeekday.tuesday;
      case DateTime.wednesday:
        return TideWeekday.wednesday;
      case DateTime.thursday:
        return TideWeekday.thursday;
      case DateTime.friday:
        return TideWeekday.friday;
      case DateTime.saturday:
        return TideWeekday.saturday;
      case DateTime.sunday:
        return TideWeekday.sunday;
      default:
        return null;
    }
  }
}

/// A BYDAY component that pairs a [weekday] with an optional [ordinal].
///
/// When [ordinal] is `null`, the rule matches every occurrence of the weekday
/// within the relevant period (e.g. every Monday). When set, it selects a
/// specific occurrence: `1` = first, `2` = second, `−1` = last, etc.
///
/// Examples:
/// - `TideByDay(weekday: TideWeekday.friday)` — every Friday
/// - `TideByDay(weekday: TideWeekday.friday, ordinal: 3)` — 3rd Friday
/// - `TideByDay(weekday: TideWeekday.monday, ordinal: -1)` — last Monday
class TideByDay {
  /// Creates a [TideByDay] with the given [weekday] and optional [ordinal].
  const TideByDay({required this.weekday, this.ordinal});

  /// The day of the week.
  final TideWeekday weekday;

  /// Optional ordinal position within the period.
  ///
  /// Positive values count from the start (1 = first, 2 = second, …).
  /// Negative values count from the end (−1 = last, −2 = second-to-last, …).
  /// When `null`, every occurrence of [weekday] in the period is selected.
  final int? ordinal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TideByDay &&
          other.weekday == weekday &&
          other.ordinal == ordinal);

  @override
  int get hashCode => Object.hash(weekday, ordinal);

  @override
  String toString() {
    final prefix = ordinal != null ? '$ordinal' : '';
    return '$prefix${weekday.abbreviation}';
  }
}

/// An immutable RFC 5545 recurrence rule.
///
/// Use [TideRRuleParser] to create instances from RRULE strings,
/// or construct directly for programmatic use. Generate the RRULE string
/// representation with [TideRRuleGenerator].
class TideRecurrenceRule {
  /// Creates a [TideRecurrenceRule].
  ///
  /// Only [frequency] is required. All other fields default to `null`
  /// (or sensible defaults like `interval: 1` and `weekStart: monday`).
  const TideRecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.count,
    this.until,
    this.byDay,
    this.byMonthDay,
    this.byMonth,
    this.bySetPos,
    this.byHour,
    this.byMinute,
    this.byYearDay,
    this.byWeekNo,
    this.weekStart = TideWeekday.monday,
    this.exDates,
    this.rDates,
  });

  /// The recurrence frequency (daily, weekly, monthly, yearly).
  final TideFrequency frequency;

  /// How often the recurrence repeats. Defaults to `1`.
  ///
  /// For example, `interval: 2` with [TideFrequency.weekly] means
  /// "every 2 weeks".
  final int interval;

  /// Maximum number of occurrences. Mutually exclusive with [until].
  final int? count;

  /// End date of the recurrence (inclusive). Mutually exclusive with [count].
  final DateTime? until;

  /// Days of the week, optionally with ordinal position.
  final List<TideByDay>? byDay;

  /// Days of the month (1–31, or negative for counting from end).
  final List<int>? byMonthDay;

  /// Months of the year (1–12).
  final List<int>? byMonth;

  /// Set positions to select from the generated set.
  final List<int>? bySetPos;

  /// Hours of the day (0–23).
  final List<int>? byHour;

  /// Minutes of the hour (0–59).
  final List<int>? byMinute;

  /// Days of the year (1–366, or negative for counting from end).
  final List<int>? byYearDay;

  /// Week numbers of the year (1–53, or negative).
  final List<int>? byWeekNo;

  /// First day of the week for WEEKLY rules. Defaults to [TideWeekday.monday].
  final TideWeekday weekStart;

  /// Dates excluded from the recurrence pattern.
  final List<DateTime>? exDates;

  /// Additional dates added to the recurrence pattern.
  final List<DateTime>? rDates;

  /// Returns a copy of this rule with the given fields replaced.
  TideRecurrenceRule copyWith({
    TideFrequency? frequency,
    int? interval,
    int? count,
    DateTime? until,
    List<TideByDay>? byDay,
    List<int>? byMonthDay,
    List<int>? byMonth,
    List<int>? bySetPos,
    List<int>? byHour,
    List<int>? byMinute,
    List<int>? byYearDay,
    List<int>? byWeekNo,
    TideWeekday? weekStart,
    List<DateTime>? exDates,
    List<DateTime>? rDates,
  }) {
    return TideRecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      count: count ?? this.count,
      until: until ?? this.until,
      byDay: byDay ?? this.byDay,
      byMonthDay: byMonthDay ?? this.byMonthDay,
      byMonth: byMonth ?? this.byMonth,
      bySetPos: bySetPos ?? this.bySetPos,
      byHour: byHour ?? this.byHour,
      byMinute: byMinute ?? this.byMinute,
      byYearDay: byYearDay ?? this.byYearDay,
      byWeekNo: byWeekNo ?? this.byWeekNo,
      weekStart: weekStart ?? this.weekStart,
      exDates: exDates ?? this.exDates,
      rDates: rDates ?? this.rDates,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TideRecurrenceRule) return false;
    return frequency == other.frequency &&
        interval == other.interval &&
        count == other.count &&
        until == other.until &&
        _listEquals(byDay, other.byDay) &&
        _listEquals(byMonthDay, other.byMonthDay) &&
        _listEquals(byMonth, other.byMonth) &&
        _listEquals(bySetPos, other.bySetPos) &&
        _listEquals(byHour, other.byHour) &&
        _listEquals(byMinute, other.byMinute) &&
        _listEquals(byYearDay, other.byYearDay) &&
        _listEquals(byWeekNo, other.byWeekNo) &&
        weekStart == other.weekStart &&
        _listEquals(exDates, other.exDates) &&
        _listEquals(rDates, other.rDates);
  }

  @override
  int get hashCode => Object.hash(
        frequency,
        interval,
        count,
        until,
        byDay != null ? Object.hashAll(byDay!) : null,
        byMonthDay != null ? Object.hashAll(byMonthDay!) : null,
        byMonth != null ? Object.hashAll(byMonth!) : null,
        bySetPos != null ? Object.hashAll(bySetPos!) : null,
        byHour != null ? Object.hashAll(byHour!) : null,
        byMinute != null ? Object.hashAll(byMinute!) : null,
        byYearDay != null ? Object.hashAll(byYearDay!) : null,
        byWeekNo != null ? Object.hashAll(byWeekNo!) : null,
        weekStart,
        exDates != null ? Object.hashAll(exDates!) : null,
        rDates != null ? Object.hashAll(rDates!) : null,
      );

  @override
  String toString() {
    final parts = <String>['TideRecurrenceRule('];
    parts.add('frequency: $frequency');
    if (interval != 1) parts.add(', interval: $interval');
    if (count != null) parts.add(', count: $count');
    if (until != null) parts.add(', until: $until');
    if (byDay != null) parts.add(', byDay: $byDay');
    if (byMonthDay != null) parts.add(', byMonthDay: $byMonthDay');
    if (byMonth != null) parts.add(', byMonth: $byMonth');
    if (bySetPos != null) parts.add(', bySetPos: $bySetPos');
    if (byHour != null) parts.add(', byHour: $byHour');
    if (byMinute != null) parts.add(', byMinute: $byMinute');
    if (byYearDay != null) parts.add(', byYearDay: $byYearDay');
    if (byWeekNo != null) parts.add(', byWeekNo: $byWeekNo');
    if (weekStart != TideWeekday.monday) {
      parts.add(', weekStart: $weekStart');
    }
    if (exDates != null) parts.add(', exDates: $exDates');
    if (rDates != null) parts.add(', rDates: $rDates');
    parts.add(')');
    return parts.join();
  }
}

/// Compares two lists for deep equality.
bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

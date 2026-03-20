/// Public facade for the timetide recurrence system.
///
/// [TideRecurrence] provides a unified API for parsing, generating,
/// describing, and expanding RFC 5545 RRULE recurrence rules.
///
/// ```dart
/// final rule = TideRecurrence.parse('RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR');
/// final dates = rule!.occurrences(start: DateTime(2026, 3, 1));
/// final text = rule.describe(locale: 'de');
/// final rrule = rule.toRruleString();
/// ```
library;

import 'occurrence_engine.dart';
import 'rrule_description.dart';
import 'rrule_generator.dart';
import 'rrule_model.dart';
import 'rrule_parser.dart';

/// A thin facade around [TideRecurrenceRule] that delegates to the parser,
/// generator, occurrence engine, and description subsystems.
///
/// Wraps a [TideRecurrenceRule] and exposes convenience methods that mirror
/// the API shown in the specification.
class TideRecurrence {
  /// Creates a [TideRecurrence] from explicit parameters.
  ///
  /// All parameters are forwarded to [TideRecurrenceRule].
  TideRecurrence({
    required TideFrequency frequency,
    int interval = 1,
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
    TideWeekday weekStart = TideWeekday.monday,
    List<DateTime>? exDates,
    List<DateTime>? rDates,
  }) : rule = TideRecurrenceRule(
          frequency: frequency,
          interval: interval,
          count: count,
          until: until,
          byDay: byDay,
          byMonthDay: byMonthDay,
          byMonth: byMonth,
          bySetPos: bySetPos,
          byHour: byHour,
          byMinute: byMinute,
          byYearDay: byYearDay,
          byWeekNo: byWeekNo,
          weekStart: weekStart,
          exDates: exDates,
          rDates: rDates,
        );

  /// Creates a [TideRecurrence] wrapping an existing [TideRecurrenceRule].
  const TideRecurrence.fromRule(this.rule);

  /// The underlying recurrence rule.
  final TideRecurrenceRule rule;

  /// Parses an RRULE string and returns a [TideRecurrence], or `null` if
  /// the string is invalid.
  ///
  /// ```dart
  /// final recurrence = TideRecurrence.parse(
  ///   'RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR;UNTIL=20261231T235959Z',
  /// );
  /// ```
  static TideRecurrence? parse(String rruleString) {
    final parsed = TideRRuleParser.parse(rruleString);
    if (parsed == null) return null;
    return TideRecurrence.fromRule(parsed);
  }

  /// Generates the RFC 5545 RRULE string representation.
  ///
  /// ```dart
  /// recurrence.toRruleString(); // 'RRULE:FREQ=MONTHLY;BYMONTHDAY=1,15;COUNT=12'
  /// ```
  String toRruleString() => TideRRuleGenerator.generate(rule);

  /// Returns a human-readable description of this recurrence rule.
  ///
  /// Supported locales: `'en'` (default), `'de'`.
  ///
  /// ```dart
  /// recurrence.describe(locale: 'de'); // 'Jede Woche am Montag, Mittwoch, Freitag'
  /// ```
  String describe({String locale = 'en'}) =>
      TideRRuleDescription.describe(rule, locale: locale);

  /// Returns a human-readable description of the given RRULE [rruleString].
  ///
  /// Returns `null` if the string cannot be parsed.
  static String? describeString(String rruleString, {String locale = 'en'}) {
    final parsed = TideRRuleParser.parse(rruleString);
    if (parsed == null) return null;
    return TideRRuleDescription.describe(parsed, locale: locale);
  }

  /// Lazily generates occurrence dates for this recurrence rule.
  ///
  /// - [start]: The DTSTART of the recurring event (first occurrence).
  /// - [after]: If provided, only yields occurrences strictly after this date.
  /// - [before]: If provided, only yields occurrences strictly before this date.
  ///
  /// The returned [Iterable] is lazy — occurrences are computed on demand.
  ///
  /// ```dart
  /// final dates = recurrence.occurrences(
  ///   start: DateTime(2026, 3, 1),
  ///   after: DateTime(2026, 3, 19),
  ///   before: DateTime(2026, 6, 30),
  /// );
  /// ```
  Iterable<DateTime> occurrences({
    required DateTime start,
    DateTime? after,
    DateTime? before,
  }) {
    return TideOccurrenceEngine.occurrences(
      rule,
      start,
      after: after,
      before: before,
    );
  }

  /// Convenience shorthand for the recurrence frequency.
  TideFrequency get frequency => rule.frequency;

  /// Convenience shorthand for BYDAY.
  List<TideByDay>? get byDay => rule.byDay;

  /// Convenience shorthand for UNTIL.
  DateTime? get until => rule.until;

  /// Convenience shorthand for COUNT.
  int? get count => rule.count;

  /// Convenience shorthand for INTERVAL.
  int get interval => rule.interval;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TideRecurrence && other.rule == rule);

  @override
  int get hashCode => rule.hashCode;

  @override
  String toString() => 'TideRecurrence(${toRruleString()})';
}

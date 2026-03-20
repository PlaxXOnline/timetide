/// Generator for RFC 5545 RRULE strings.
///
/// Converts [TideRecurrenceRule] instances into their textual RRULE
/// representation.
library;

import 'rrule_model.dart';

/// Generates RFC 5545 RRULE strings from [TideRecurrenceRule] instances.
///
/// The output is round-trip safe with [TideRRuleParser]:
/// ```dart
/// TideRRuleParser.parse(TideRRuleGenerator.generate(rule)) == rule
/// ```
class TideRRuleGenerator {
  TideRRuleGenerator._();

  /// Generates an RRULE string from the given [rule].
  ///
  /// The returned string includes the `RRULE:` prefix.
  static String generate(TideRecurrenceRule rule) {
    final parts = <String>[];

    parts.add('FREQ=${rule.frequency.toRfcString()}');

    if (rule.interval != 1) {
      parts.add('INTERVAL=${rule.interval}');
    }

    if (rule.count != null) {
      parts.add('COUNT=${rule.count}');
    }

    if (rule.until != null) {
      parts.add('UNTIL=${_formatDateTime(rule.until!)}');
    }

    if (rule.byDay != null && rule.byDay!.isNotEmpty) {
      parts.add('BYDAY=${rule.byDay!.map(_formatByDay).join(',')}');
    }

    if (rule.byMonthDay != null && rule.byMonthDay!.isNotEmpty) {
      parts.add('BYMONTHDAY=${rule.byMonthDay!.join(',')}');
    }

    if (rule.byMonth != null && rule.byMonth!.isNotEmpty) {
      parts.add('BYMONTH=${rule.byMonth!.join(',')}');
    }

    if (rule.bySetPos != null && rule.bySetPos!.isNotEmpty) {
      parts.add('BYSETPOS=${rule.bySetPos!.join(',')}');
    }

    if (rule.byHour != null && rule.byHour!.isNotEmpty) {
      parts.add('BYHOUR=${rule.byHour!.join(',')}');
    }

    if (rule.byMinute != null && rule.byMinute!.isNotEmpty) {
      parts.add('BYMINUTE=${rule.byMinute!.join(',')}');
    }

    if (rule.byYearDay != null && rule.byYearDay!.isNotEmpty) {
      parts.add('BYYEARDAY=${rule.byYearDay!.join(',')}');
    }

    if (rule.byWeekNo != null && rule.byWeekNo!.isNotEmpty) {
      parts.add('BYWEEKNO=${rule.byWeekNo!.join(',')}');
    }

    if (rule.weekStart != TideWeekday.monday) {
      parts.add('WKST=${rule.weekStart.abbreviation}');
    }

    if (rule.exDates != null && rule.exDates!.isNotEmpty) {
      parts.add('EXDATE=${rule.exDates!.map(_formatDateTime).join(',')}');
    }

    if (rule.rDates != null && rule.rDates!.isNotEmpty) {
      parts.add('RDATE=${rule.rDates!.map(_formatDateTime).join(',')}');
    }

    return 'RRULE:${parts.join(';')}';
  }

  static String _formatByDay(TideByDay byDay) {
    final prefix = byDay.ordinal != null ? '${byDay.ordinal}' : '';
    return '$prefix${byDay.weekday.abbreviation}';
  }

  /// Formats a [DateTime] as an RFC 5545 date-time string.
  ///
  /// UTC dates get the `Z` suffix. Dates with no time component
  /// (midnight UTC) are still formatted as full datetimes to ensure
  /// round-trip fidelity.
  static String _formatDateTime(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final suffix = dt.isUtc ? 'Z' : '';
    return '$year$month${day}T$hour$minute$second$suffix';
  }
}

/// Parser for RFC 5545 RRULE strings.
///
/// Converts textual RRULE representations into [TideRecurrenceRule] instances.
library;

import 'rrule_model.dart';

/// Parses RFC 5545 RRULE strings into [TideRecurrenceRule] objects.
///
/// Handles the full set of supported RRULE properties including FREQ,
/// INTERVAL, COUNT, UNTIL, BYDAY (with ordinal prefixes), BYMONTHDAY,
/// BYMONTH, BYSETPOS, BYHOUR, BYMINUTE, BYYEARDAY, BYWEEKNO, WKST,
/// EXDATE, and RDATE.
///
/// ```dart
/// final rule = TideRRuleParser.parse('RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR');
/// ```
class TideRRuleParser {
  TideRRuleParser._();

  /// Parses an RRULE string into a [TideRecurrenceRule].
  ///
  /// The input may optionally start with the `RRULE:` prefix.
  /// Property names are treated case-insensitively.
  ///
  /// Returns `null` if the input is invalid or missing the required FREQ
  /// property.
  static TideRecurrenceRule? parse(String rruleString) {
    var input = rruleString.trim();
    if (input.isEmpty) return null;

    // Strip RRULE: prefix if present.
    final upperInput = input.toUpperCase();
    if (upperInput.startsWith('RRULE:')) {
      input = input.substring(6);
    }

    if (input.isEmpty) return null;

    final properties = <String, String>{};
    for (final part in input.split(';')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final eqIndex = trimmed.indexOf('=');
      if (eqIndex == -1) continue;
      final key = trimmed.substring(0, eqIndex).trim().toUpperCase();
      final value = trimmed.substring(eqIndex + 1).trim();
      properties[key] = value;
    }

    // FREQ is required.
    final freqStr = properties['FREQ'];
    if (freqStr == null) return null;
    final frequency = TideFrequency.fromRfcString(freqStr);
    if (frequency == null) return null;

    return TideRecurrenceRule(
      frequency: frequency,
      interval: _parseInt(properties['INTERVAL']) ?? 1,
      count: _parseInt(properties['COUNT']),
      until: _parseUntil(properties['UNTIL']),
      byDay: _parseByDay(properties['BYDAY']),
      byMonthDay: _parseIntList(properties['BYMONTHDAY']),
      byMonth: _parseIntList(properties['BYMONTH']),
      bySetPos: _parseIntList(properties['BYSETPOS']),
      byHour: _parseIntList(properties['BYHOUR']),
      byMinute: _parseIntList(properties['BYMINUTE']),
      byYearDay: _parseIntList(properties['BYYEARDAY']),
      byWeekNo: _parseIntList(properties['BYWEEKNO']),
      weekStart: _parseWeekStart(properties['WKST']),
      exDates: _parseDateList(properties['EXDATE']),
      rDates: _parseDateList(properties['RDATE']),
    );
  }

  static int? _parseInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value);
  }

  static List<int>? _parseIntList(String? value) {
    if (value == null) return null;
    final parts = value.split(',');
    final result = <int>[];
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final n = int.tryParse(trimmed);
      if (n != null) result.add(n);
    }
    return result.isEmpty ? null : result;
  }

  /// Parses an UNTIL date string in RFC 5545 format.
  ///
  /// Supports both `yyyyMMddTHHmmssZ` (UTC) and `yyyyMMdd` (date-only).
  static DateTime? _parseUntil(String? value) {
    if (value == null) return null;
    return _parseDateTime(value);
  }

  /// Parses a single RFC 5545 date/datetime string.
  static DateTime? _parseDateTime(String value) {
    final trimmed = value.trim();
    // Full datetime: 20261231T235959Z or 20261231T235959
    if (trimmed.length >= 15 && trimmed.contains('T')) {
      return _parseDateTimeValue(trimmed);
    }
    // Date only: 20261231
    if (trimmed.length == 8) {
      return _parseDateOnly(trimmed);
    }
    return null;
  }

  static DateTime? _parseDateTimeValue(String value) {
    final isUtc = value.toUpperCase().endsWith('Z');
    final clean = isUtc ? value.substring(0, value.length - 1) : value;

    final tIndex = clean.indexOf('T');
    if (tIndex == -1) return null;

    final datePart = clean.substring(0, tIndex);
    final timePart = clean.substring(tIndex + 1);

    if (datePart.length != 8 || timePart.length != 6) return null;

    final year = int.tryParse(datePart.substring(0, 4));
    final month = int.tryParse(datePart.substring(4, 6));
    final day = int.tryParse(datePart.substring(6, 8));
    final hour = int.tryParse(timePart.substring(0, 2));
    final minute = int.tryParse(timePart.substring(2, 4));
    final second = int.tryParse(timePart.substring(4, 6));

    if (year == null ||
        month == null ||
        day == null ||
        hour == null ||
        minute == null ||
        second == null) {
      return null;
    }

    return isUtc
        ? DateTime.utc(year, month, day, hour, minute, second)
        : DateTime(year, month, day, hour, minute, second);
  }

  static DateTime? _parseDateOnly(String value) {
    if (value.length != 8) return null;
    final year = int.tryParse(value.substring(0, 4));
    final month = int.tryParse(value.substring(4, 6));
    final day = int.tryParse(value.substring(6, 8));
    if (year == null || month == null || day == null) return null;
    return DateTime.utc(year, month, day);
  }

  /// Parses BYDAY values like `MO`, `3FR`, `-1MO`, etc.
  static List<TideByDay>? _parseByDay(String? value) {
    if (value == null) return null;
    final parts = value.split(',');
    final result = <TideByDay>[];
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final byDay = _parseSingleByDay(trimmed);
      if (byDay != null) result.add(byDay);
    }
    return result.isEmpty ? null : result;
  }

  /// Parses a single BYDAY token like `MO`, `3FR`, or `-1MO`.
  static TideByDay? _parseSingleByDay(String token) {
    if (token.length < 2) return null;

    // The last two characters are the weekday abbreviation.
    final weekdayStr = token.substring(token.length - 2).toUpperCase();
    final weekday = TideWeekday.fromAbbreviation(weekdayStr);
    if (weekday == null) return null;

    int? ordinal;
    if (token.length > 2) {
      ordinal = int.tryParse(token.substring(0, token.length - 2));
      if (ordinal == null) return null;
    }

    return TideByDay(weekday: weekday, ordinal: ordinal);
  }

  static TideWeekday _parseWeekStart(String? value) {
    if (value == null) return TideWeekday.monday;
    return TideWeekday.fromAbbreviation(value) ?? TideWeekday.monday;
  }

  /// Parses a comma-separated list of dates (EXDATE, RDATE).
  static List<DateTime>? _parseDateList(String? value) {
    if (value == null) return null;
    final parts = value.split(',');
    final result = <DateTime>[];
    for (final part in parts) {
      final dt = _parseDateTime(part);
      if (dt != null) result.add(dt);
    }
    return result.isEmpty ? null : result;
  }
}

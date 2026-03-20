import '../models/event.dart';

/// Exports [TideEvent] lists to iCalendar (.ics) format per RFC 5545.
class TideExport {
  TideExport._();

  static const String _crlf = '\r\n';

  /// Converts a list of [events] to a RFC 5545 compliant iCalendar string.
  ///
  /// [calendarName] sets the X-WR-CALNAME property.
  /// [timezone] sets the X-WR-TIMEZONE property (e.g. "America/New_York").
  static String toICalendar({
    required List<TideEvent> events,
    String calendarName = 'timetide',
    String? timezone,
  }) {
    final buf = StringBuffer();

    buf.write('BEGIN:VCALENDAR$_crlf');
    buf.write('VERSION:2.0$_crlf');
    buf.write('PRODID:-//timetide//EN$_crlf');
    buf.write('CALSCALE:GREGORIAN$_crlf');
    buf.write(_fold('X-WR-CALNAME:$calendarName'));
    if (timezone != null) {
      buf.write(_fold('X-WR-TIMEZONE:$timezone'));
    }

    for (final event in events) {
      buf.write(_encodeEvent(event, timezone));
    }

    buf.write('END:VCALENDAR$_crlf');
    return buf.toString();
  }

  static String _encodeEvent(TideEvent event, String? timezone) {
    final buf = StringBuffer();
    buf.write('BEGIN:VEVENT$_crlf');
    buf.write(_fold('UID:${event.id}'));

    if (event.isAllDay) {
      buf.write(_fold('DTSTART;VALUE=DATE:${_formatDate(event.startTime)}'));
      buf.write(_fold('DTEND;VALUE=DATE:${_formatDate(event.endTime)}'));
    } else if (timezone != null) {
      buf.write(_fold('DTSTART;TZID=$timezone:${_formatLocalDateTime(event.startTime)}'));
      buf.write(_fold('DTEND;TZID=$timezone:${_formatLocalDateTime(event.endTime)}'));
    } else if (event.startTime.isUtc) {
      buf.write(_fold('DTSTART:${_formatUtcDateTime(event.startTime)}'));
      buf.write(_fold('DTEND:${_formatUtcDateTime(event.endTime)}'));
    } else {
      buf.write(_fold('DTSTART:${_formatLocalDateTime(event.startTime)}'));
      buf.write(_fold('DTEND:${_formatLocalDateTime(event.endTime)}'));
    }

    buf.write(_fold('SUMMARY:${_escapeText(event.subject)}'));

    if (event.notes != null) {
      buf.write(_fold('DESCRIPTION:${_escapeText(event.notes!)}'));
    }
    if (event.location != null) {
      buf.write(_fold('LOCATION:${_escapeText(event.location!)}'));
    }

    if (event.recurrenceRule != null) {
      final rule = event.recurrenceRule!.startsWith('RRULE:')
          ? event.recurrenceRule!
          : 'RRULE:${event.recurrenceRule!}';
      buf.write(_fold(rule));
    }

    if (event.recurrenceExceptions != null &&
        event.recurrenceExceptions!.isNotEmpty) {
      final dates = event.recurrenceExceptions!
          .map(_formatLocalDateTime)
          .join(',');
      buf.write(_fold('EXDATE:$dates'));
    }

    buf.write('END:VEVENT$_crlf');
    return buf.toString();
  }

  /// Folds a property line per RFC 5545: lines > 75 octets are wrapped with
  /// CRLF followed by a single space.
  static String _fold(String line) {
    if (line.length <= 75) return '$line$_crlf';

    final result = StringBuffer();
    // First chunk: up to 75 octets
    result.write(line.substring(0, 75));
    var offset = 75;

    while (offset < line.length) {
      result.write(_crlf);
      result.write(' ');
      // Continuation lines: space (1) + up to 74 chars = 75 total
      final end = (offset + 74).clamp(0, line.length);
      result.write(line.substring(offset, end));
      offset = end;
    }

    result.write(_crlf);
    return result.toString();
  }

  static String _formatDate(DateTime dt) {
    return '${_pad4(dt.year)}${_pad2(dt.month)}${_pad2(dt.day)}';
  }

  static String _formatLocalDateTime(DateTime dt) {
    return '${_pad4(dt.year)}${_pad2(dt.month)}${_pad2(dt.day)}'
        'T${_pad2(dt.hour)}${_pad2(dt.minute)}${_pad2(dt.second)}';
  }

  static String _formatUtcDateTime(DateTime dt) {
    final utc = dt.toUtc();
    return '${_pad4(utc.year)}${_pad2(utc.month)}${_pad2(utc.day)}'
        'T${_pad2(utc.hour)}${_pad2(utc.minute)}${_pad2(utc.second)}Z';
  }

  static String _escapeText(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '');
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');
  static String _pad4(int n) => n.toString().padLeft(4, '0');
}

import '../models/event.dart';

/// Imports [TideEvent] objects from iCalendar (.ics) strings per RFC 5545.
class TideImport {
  TideImport._();

  /// Parses an iCalendar [icsString] and returns the contained events.
  ///
  /// Malformed events are silently skipped. Unknown properties are ignored.
  static List<TideEvent> fromICalendar(String icsString) {
    final unfolded = _unfold(icsString);
    final lines = unfolded.split('\n').map((l) => l.trimRight()).toList();

    final events = <TideEvent>[];
    var inEvent = false;
    var props = <String, String>{};

    for (final line in lines) {
      if (line == 'BEGIN:VEVENT') {
        inEvent = true;
        props = {};
      } else if (line == 'END:VEVENT') {
        inEvent = false;
        final event = _parseEvent(props);
        if (event != null) events.add(event);
      } else if (inEvent && line.isNotEmpty) {
        final colonIdx = line.indexOf(':');
        if (colonIdx == -1) continue;
        final key = line.substring(0, colonIdx).toUpperCase();
        final value = line.substring(colonIdx + 1);
        // For parameterized keys like DTSTART;VALUE=DATE, store base key + params
        props[key] = value;
      }
    }
    return events;
  }

  static TideEvent? _parseEvent(Map<String, String> props) {
    try {
      // Find DTSTART and DTEND including parameterized variants
      final dtStartKey = props.keys.firstWhere(
        (k) => k == 'DTSTART' || k.startsWith('DTSTART;'),
        orElse: () => '',
      );
      final dtEndKey = props.keys.firstWhere(
        (k) => k == 'DTEND' || k.startsWith('DTEND;'),
        orElse: () => '',
      );

      if (dtStartKey.isEmpty || dtEndKey.isEmpty) return null;

      final isAllDay = dtStartKey.contains('VALUE=DATE') &&
          !dtStartKey.contains('VALUE=DATE-TIME');

      final tzid = _extractTzid(dtStartKey);

      final startTime = _parseDateTime(props[dtStartKey]!, isAllDay, tzid);
      final endTime = _parseDateTime(props[dtEndKey]!, isAllDay, tzid);

      if (startTime == null || endTime == null) return null;

      final id = props['UID']?.trim().isNotEmpty == true
          ? props['UID']!.trim()
          : _generateUid();

      final subject = _unescapeText(props['SUMMARY'] ?? '');

      final notes = props.containsKey('DESCRIPTION')
          ? _unescapeText(props['DESCRIPTION']!)
          : null;

      final location = props.containsKey('LOCATION')
          ? _unescapeText(props['LOCATION']!)
          : null;

      String? recurrenceRule;
      final rruleKey = props.keys.firstWhere(
        (k) => k == 'RRULE',
        orElse: () => '',
      );
      if (rruleKey.isNotEmpty) {
        recurrenceRule = 'RRULE:${props[rruleKey]!}';
      }

      List<DateTime>? recurrenceExceptions;
      final exdateKey = props.keys.firstWhere(
        (k) => k == 'EXDATE' || k.startsWith('EXDATE;'),
        orElse: () => '',
      );
      if (exdateKey.isNotEmpty) {
        final exdateTzid = _extractTzid(exdateKey);
        final exdateIsAllDay =
            exdateKey.contains('VALUE=DATE') && !exdateKey.contains('VALUE=DATE-TIME');
        recurrenceExceptions = props[exdateKey]!
            .split(',')
            .map((d) => _parseDateTime(d.trim(), exdateIsAllDay, exdateTzid))
            .whereType<DateTime>()
            .toList();
        if (recurrenceExceptions.isEmpty) recurrenceExceptions = null;
      }

      return TideEvent(
        id: id,
        subject: subject,
        startTime: startTime,
        endTime: endTime,
        isAllDay: isAllDay,
        notes: notes,
        location: location,
        recurrenceRule: recurrenceRule,
        recurrenceExceptions: recurrenceExceptions,
      );
    } catch (_) {
      return null;
    }
  }

  /// Extracts TZID from a parameterized key like "DTSTART;TZID=America/New_York".
  static String? _extractTzid(String key) {
    final match = RegExp(r'TZID=([^;:]+)').firstMatch(key);
    return match?.group(1);
  }

  static DateTime? _parseDateTime(String value, bool isAllDay, String? tzid) {
    try {
      if (isAllDay) {
        // DATE format: YYYYMMDD
        if (value.length < 8) return null;
        return DateTime(
          int.parse(value.substring(0, 4)),
          int.parse(value.substring(4, 6)),
          int.parse(value.substring(6, 8)),
        );
      }

      // DATETIME format: YYYYMMDDTHHMMSS or YYYYMMDDTHHMMSSZ
      final clean = value.replaceAll(RegExp(r'[^0-9TZ]'), '');
      if (clean.length < 15) return null;

      final year = int.parse(clean.substring(0, 4));
      final month = int.parse(clean.substring(4, 6));
      final day = int.parse(clean.substring(6, 8));
      // skip 'T' at index 8
      final hour = int.parse(clean.substring(9, 11));
      final minute = int.parse(clean.substring(11, 13));
      final second = int.parse(clean.substring(13, 15));
      final isUtc = value.endsWith('Z');

      if (isUtc) {
        return DateTime.utc(year, month, day, hour, minute, second);
      }
      // With TZID we return a local DateTime (timezone conversion not in scope)
      return DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }

  /// Unfolds RFC 5545 line continuations: CRLF + space/tab = continuation.
  static String _unfold(String icsString) {
    return icsString
        .replaceAll('\r\n ', '')
        .replaceAll('\r\n\t', '')
        .replaceAll('\n ', '')
        .replaceAll('\n\t', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
  }

  static String _unescapeText(String text) {
    return text
        .replaceAll('\\n', '\n')
        .replaceAll('\\N', '\n')
        .replaceAll('\\;', ';')
        .replaceAll('\\,', ',')
        .replaceAll('\\\\', '\\');
  }

  /// Generates a simple unique ID when a UID property is absent.
  static String _generateUid() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}-timetide@local';
  }
}

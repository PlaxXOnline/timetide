import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/export/ical_export.dart';
import 'package:timetide/src/core/models/event.dart';

void main() {
  group('TideExport.toICalendar', () {
    const crlf = '\r\n';

    TideEvent baseEvent({
      String id = 'test-id-1',
      String subject = 'Team Meeting',
      DateTime? start,
      DateTime? end,
      bool isAllDay = false,
      String? notes,
      String? location,
      String? recurrenceRule,
      List<DateTime>? recurrenceExceptions,
    }) =>
        TideEvent(
          id: id,
          subject: subject,
          startTime: start ?? DateTime(2024, 3, 15, 10, 0),
          endTime: end ?? DateTime(2024, 3, 15, 11, 0),
          isAllDay: isAllDay,
          notes: notes,
          location: location,
          recurrenceRule: recurrenceRule,
          recurrenceExceptions: recurrenceExceptions,
        );

    test('produces valid VCALENDAR wrapper', () {
      final ics = TideExport.toICalendar(events: []);
      expect(ics, contains('BEGIN:VCALENDAR$crlf'));
      expect(ics, contains('VERSION:2.0$crlf'));
      expect(ics, contains('PRODID:-//timetide//EN$crlf'));
      expect(ics, contains('CALSCALE:GREGORIAN$crlf'));
      expect(ics, contains('END:VCALENDAR$crlf'));
    });

    test('uses CRLF line endings throughout', () {
      final ics = TideExport.toICalendar(events: [baseEvent()]);
      // Every line must end with CRLF
      for (final line in ics.split('\r\n')..removeLast()) {
        expect(line, isNot(contains('\n')));
      }
    });

    test('exports single event with required fields', () {
      final ics = TideExport.toICalendar(events: [baseEvent()]);
      expect(ics, contains('BEGIN:VEVENT$crlf'));
      expect(ics, contains('UID:test-id-1$crlf'));
      expect(ics, contains('SUMMARY:Team Meeting$crlf'));
      expect(ics, contains('END:VEVENT$crlf'));
    });

    test('formats DTSTART/DTEND for regular events', () {
      final event = baseEvent(
        start: DateTime(2024, 3, 15, 10, 30, 0),
        end: DateTime(2024, 3, 15, 11, 45, 0),
      );
      final ics = TideExport.toICalendar(events: [event]);
      expect(ics, contains('DTSTART:20240315T103000$crlf'));
      expect(ics, contains('DTEND:20240315T114500$crlf'));
    });

    test('formats DTSTART/DTEND with VALUE=DATE for all-day events', () {
      final event = baseEvent(
        start: DateTime(2024, 6, 1),
        end: DateTime(2024, 6, 2),
        isAllDay: true,
      );
      final ics = TideExport.toICalendar(events: [event]);
      expect(ics, contains('DTSTART;VALUE=DATE:20240601$crlf'));
      expect(ics, contains('DTEND;VALUE=DATE:20240602$crlf'));
    });

    test('appends Z suffix for UTC DateTimes', () {
      final event = baseEvent(
        start: DateTime.utc(2024, 3, 15, 10, 0),
        end: DateTime.utc(2024, 3, 15, 11, 0),
      );
      final ics = TideExport.toICalendar(events: [event]);
      expect(ics, contains('DTSTART:20240315T100000Z$crlf'));
      expect(ics, contains('DTEND:20240315T110000Z$crlf'));
    });

    test('includes RRULE for recurring events (without prefix)', () {
      final event = baseEvent(recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO');
      final ics = TideExport.toICalendar(events: [event]);
      expect(ics, contains('RRULE:FREQ=WEEKLY;BYDAY=MO$crlf'));
    });

    test('strips duplicate RRULE: prefix', () {
      final event = baseEvent(recurrenceRule: 'RRULE:FREQ=DAILY');
      final ics = TideExport.toICalendar(events: [event]);
      expect(ics, contains('RRULE:FREQ=DAILY$crlf'));
      expect(ics, isNot(contains('RRULE:RRULE:')));
    });

    test('includes EXDATE for recurrence exceptions', () {
      final event = baseEvent(
        recurrenceRule: 'FREQ=WEEKLY',
        recurrenceExceptions: [
          DateTime(2024, 3, 22, 10, 0),
          DateTime(2024, 3, 29, 10, 0),
        ],
      );
      final ics = TideExport.toICalendar(events: [event]);
      expect(ics, contains('EXDATE:20240322T100000,20240329T100000$crlf'));
    });

    test('includes DESCRIPTION when notes present', () {
      final event = baseEvent(notes: 'Bring your laptop');
      final ics = TideExport.toICalendar(events: [event]);
      expect(ics, contains('DESCRIPTION:Bring your laptop$crlf'));
    });

    test('includes LOCATION when location present', () {
      final event = baseEvent(location: 'Conference Room A');
      final ics = TideExport.toICalendar(events: [event]);
      expect(ics, contains('LOCATION:Conference Room A$crlf'));
    });

    test('includes X-WR-CALNAME', () {
      final ics = TideExport.toICalendar(
        events: [],
        calendarName: 'My Calendar',
      );
      expect(ics, contains('X-WR-CALNAME:My Calendar$crlf'));
    });

    test('includes X-WR-TIMEZONE when timezone provided', () {
      final ics = TideExport.toICalendar(
        events: [],
        timezone: 'Europe/Berlin',
      );
      expect(ics, contains('X-WR-TIMEZONE:Europe/Berlin$crlf'));
    });

    test('omits X-WR-TIMEZONE when timezone not provided', () {
      final ics = TideExport.toICalendar(events: []);
      expect(ics, isNot(contains('X-WR-TIMEZONE')));
    });

    test('uses TZID in DTSTART/DTEND when timezone is provided', () {
      final event = baseEvent(
        start: DateTime(2024, 3, 15, 10, 0),
        end: DateTime(2024, 3, 15, 11, 0),
      );
      final ics = TideExport.toICalendar(
        events: [event],
        timezone: 'America/New_York',
      );
      expect(ics, contains('DTSTART;TZID=America/New_York:20240315T100000$crlf'));
      expect(ics, contains('DTEND;TZID=America/New_York:20240315T110000$crlf'));
    });

    test('folds lines longer than 75 characters', () {
      final longSubject = 'A' * 100;
      final event = baseEvent(subject: longSubject);
      final ics = TideExport.toICalendar(events: [event]);
      for (final line in ics.split('\r\n')) {
        expect(line.length, lessThanOrEqualTo(75),
            reason: 'Line too long: $line');
      }
    });

    test('continuation lines start with a space', () {
      final longSubject = 'B' * 100;
      final event = baseEvent(subject: longSubject);
      final ics = TideExport.toICalendar(events: [event]);
      final lines = ics.split('\r\n');
      bool foundContinuation = false;
      for (final line in lines) {
        if (line.startsWith(' ')) {
          foundContinuation = true;
          break;
        }
      }
      expect(foundContinuation, isTrue);
    });

    test('escapes special characters in text fields', () {
      final event = baseEvent(
        subject: 'Meeting; Notes, Here\\There',
        notes: 'Line1\nLine2',
      );
      final ics = TideExport.toICalendar(events: [event]);
      expect(ics, contains('Meeting\\; Notes\\, Here\\\\There'));
      expect(ics, contains('Line1\\nLine2'));
    });

    test('exports multiple events', () {
      final events = [
        baseEvent(id: 'evt-1', subject: 'Event One'),
        baseEvent(id: 'evt-2', subject: 'Event Two'),
      ];
      final ics = TideExport.toICalendar(events: events);
      expect('BEGIN:VEVENT'.allMatches(ics).length, equals(2));
      expect(ics, contains('UID:evt-1'));
      expect(ics, contains('UID:evt-2'));
    });
  });
}

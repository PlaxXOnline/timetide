import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/export/ical_export.dart';
import 'package:timetide/src/core/export/ical_import.dart';
import 'package:timetide/src/core/models/event.dart';

void main() {
  group('TideImport.fromICalendar', () {
    String wrap(String vevent) => '''BEGIN:VCALENDAR\r
VERSION:2.0\r
PRODID:-//test//EN\r
$vevent\r
END:VCALENDAR\r
''';

    String basicVevent({
      String uid = 'uid-1',
      String summary = 'Test Event',
      String dtstart = '20240315T100000',
      String dtend = '20240315T110000',
    }) =>
        'BEGIN:VEVENT\r\n'
        'UID:$uid\r\n'
        'SUMMARY:$summary\r\n'
        'DTSTART:$dtstart\r\n'
        'DTEND:$dtend\r\n'
        'END:VEVENT';

    test('parses a single valid event', () {
      final ics = wrap(basicVevent());
      final events = TideImport.fromICalendar(ics);
      expect(events.length, equals(1));
      expect(events.first.id, equals('uid-1'));
      expect(events.first.subject, equals('Test Event'));
    });

    test('parses multiple events', () {
      final ics = wrap(
        '${basicVevent(uid: 'uid-1', summary: 'First')}\r\n'
        '${basicVevent(uid: 'uid-2', summary: 'Second')}',
      );
      final events = TideImport.fromICalendar(ics);
      expect(events.length, equals(2));
      expect(events[0].subject, equals('First'));
      expect(events[1].subject, equals('Second'));
    });

    test('parses DTSTART and DTEND correctly', () {
      final ics = wrap(basicVevent(
        dtstart: '20240315T103000',
        dtend: '20240315T114500',
      ));
      final events = TideImport.fromICalendar(ics);
      expect(events.first.startTime, equals(DateTime(2024, 3, 15, 10, 30, 0)));
      expect(events.first.endTime, equals(DateTime(2024, 3, 15, 11, 45, 0)));
    });

    test('parses UTC datetime with Z suffix', () {
      final ics = wrap(basicVevent(
        dtstart: '20240315T100000Z',
        dtend: '20240315T110000Z',
      ));
      final events = TideImport.fromICalendar(ics);
      expect(events.first.startTime, equals(DateTime.utc(2024, 3, 15, 10, 0)));
      expect(events.first.startTime.isUtc, isTrue);
    });

    test('parses all-day events with VALUE=DATE', () {
      final ics = wrap(
        'BEGIN:VEVENT\r\n'
        'UID:allday-1\r\n'
        'SUMMARY:All Day\r\n'
        'DTSTART;VALUE=DATE:20240601\r\n'
        'DTEND;VALUE=DATE:20240602\r\n'
        'END:VEVENT',
      );
      final events = TideImport.fromICalendar(ics);
      expect(events.first.isAllDay, isTrue);
      expect(events.first.startTime, equals(DateTime(2024, 6, 1)));
      expect(events.first.endTime, equals(DateTime(2024, 6, 2)));
    });

    test('parses DESCRIPTION as notes', () {
      final ics = wrap(
        'BEGIN:VEVENT\r\n'
        'UID:uid-1\r\n'
        'SUMMARY:Meeting\r\n'
        'DTSTART:20240315T100000\r\n'
        'DTEND:20240315T110000\r\n'
        'DESCRIPTION:Bring your laptop\r\n'
        'END:VEVENT',
      );
      final events = TideImport.fromICalendar(ics);
      expect(events.first.notes, equals('Bring your laptop'));
    });

    test('parses LOCATION', () {
      final ics = wrap(
        'BEGIN:VEVENT\r\n'
        'UID:uid-1\r\n'
        'SUMMARY:Meeting\r\n'
        'DTSTART:20240315T100000\r\n'
        'DTEND:20240315T110000\r\n'
        'LOCATION:Conference Room B\r\n'
        'END:VEVENT',
      );
      final events = TideImport.fromICalendar(ics);
      expect(events.first.location, equals('Conference Room B'));
    });

    test('parses RRULE for recurring events', () {
      final ics = wrap(
        'BEGIN:VEVENT\r\n'
        'UID:uid-1\r\n'
        'SUMMARY:Weekly Standup\r\n'
        'DTSTART:20240315T090000\r\n'
        'DTEND:20240315T091500\r\n'
        'RRULE:FREQ=WEEKLY;BYDAY=MO\r\n'
        'END:VEVENT',
      );
      final events = TideImport.fromICalendar(ics);
      expect(events.first.recurrenceRule, equals('RRULE:FREQ=WEEKLY;BYDAY=MO'));
      expect(events.first.isRecurring, isTrue);
    });

    test('parses EXDATE as recurrenceExceptions', () {
      final ics = wrap(
        'BEGIN:VEVENT\r\n'
        'UID:uid-1\r\n'
        'SUMMARY:Weekly\r\n'
        'DTSTART:20240315T090000\r\n'
        'DTEND:20240315T091500\r\n'
        'RRULE:FREQ=WEEKLY\r\n'
        'EXDATE:20240322T090000,20240329T090000\r\n'
        'END:VEVENT',
      );
      final events = TideImport.fromICalendar(ics);
      expect(events.first.recurrenceExceptions, hasLength(2));
      expect(events.first.recurrenceExceptions!.first,
          equals(DateTime(2024, 3, 22, 9, 0)));
    });

    test('unescapes text fields', () {
      final ics = wrap(
        'BEGIN:VEVENT\r\n'
        'UID:uid-1\r\n'
        'SUMMARY:Meeting\\; Notes\\, Here\\\\There\r\n'
        'DTSTART:20240315T100000\r\n'
        'DTEND:20240315T110000\r\n'
        'DESCRIPTION:Line1\\nLine2\r\n'
        'END:VEVENT',
      );
      final events = TideImport.fromICalendar(ics);
      expect(events.first.subject, equals('Meeting; Notes, Here\\There'));
      expect(events.first.notes, equals('Line1\nLine2'));
    });

    test('unfolds continuation lines', () {
      final ics = wrap(
        'BEGIN:VEVENT\r\n'
        'UID:uid-1\r\n'
        'SUMMARY:Long \r\n'
        ' Subject\r\n'
        'DTSTART:20240315T100000\r\n'
        'DTEND:20240315T110000\r\n'
        'END:VEVENT',
      );
      final events = TideImport.fromICalendar(ics);
      expect(events.first.subject, equals('Long Subject'));
    });

    test('generates UID when missing', () {
      final ics = wrap(
        'BEGIN:VEVENT\r\n'
        'SUMMARY:No UID\r\n'
        'DTSTART:20240315T100000\r\n'
        'DTEND:20240315T110000\r\n'
        'END:VEVENT',
      );
      final events = TideImport.fromICalendar(ics);
      expect(events.first.id, isNotEmpty);
    });

    test('skips malformed event missing DTSTART', () {
      final ics = wrap(
        'BEGIN:VEVENT\r\n'
        'UID:bad-event\r\n'
        'SUMMARY:Broken\r\n'
        'END:VEVENT',
      );
      final events = TideImport.fromICalendar(ics);
      expect(events, isEmpty);
    });

    test('gracefully handles empty input', () {
      expect(TideImport.fromICalendar(''), isEmpty);
    });

    test('gracefully handles completely malformed input', () {
      expect(TideImport.fromICalendar('not an ical file at all'), isEmpty);
    });

    test('skips invalid event but keeps valid ones', () {
      final ics = wrap(
        'BEGIN:VEVENT\r\n'
        'UID:bad\r\n'
        'SUMMARY:Broken\r\n'
        'END:VEVENT\r\n'
        '${basicVevent(uid: 'good-1', summary: 'Good Event')}',
      );
      final events = TideImport.fromICalendar(ics);
      expect(events.length, equals(1));
      expect(events.first.id, equals('good-1'));
    });

    group('round-trip export → import', () {
      test('basic event round-trip', () {
        final original = TideEvent(
          id: 'rt-1',
          subject: 'Round Trip',
          startTime: DateTime(2024, 4, 10, 9, 0),
          endTime: DateTime(2024, 4, 10, 10, 0),
        );
        final ics = TideExport.toICalendar(events: [original]);
        final imported = TideImport.fromICalendar(ics);
        expect(imported.length, equals(1));
        expect(imported.first.id, equals(original.id));
        expect(imported.first.subject, equals(original.subject));
        expect(imported.first.startTime, equals(original.startTime));
        expect(imported.first.endTime, equals(original.endTime));
      });

      test('all-day event round-trip', () {
        final original = TideEvent(
          id: 'rt-allday',
          subject: 'Holiday',
          startTime: DateTime(2024, 12, 25),
          endTime: DateTime(2024, 12, 26),
          isAllDay: true,
        );
        final ics = TideExport.toICalendar(events: [original]);
        final imported = TideImport.fromICalendar(ics);
        expect(imported.first.isAllDay, isTrue);
        expect(imported.first.subject, equals('Holiday'));
      });

      test('recurring event with exceptions round-trip', () {
        final original = TideEvent(
          id: 'rt-recur',
          subject: 'Weekly Meeting',
          startTime: DateTime(2024, 1, 8, 10, 0),
          endTime: DateTime(2024, 1, 8, 11, 0),
          recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
          recurrenceExceptions: [
            DateTime(2024, 1, 15, 10, 0),
            DateTime(2024, 1, 22, 10, 0),
          ],
        );
        final ics = TideExport.toICalendar(events: [original]);
        final imported = TideImport.fromICalendar(ics);
        expect(imported.first.isRecurring, isTrue);
        expect(imported.first.recurrenceRule, equals('RRULE:FREQ=WEEKLY;BYDAY=MO'));
        expect(imported.first.recurrenceExceptions, hasLength(2));
      });

      test('event with notes and location round-trip', () {
        final original = TideEvent(
          id: 'rt-full',
          subject: 'Full Event',
          startTime: DateTime(2024, 5, 20, 14, 0),
          endTime: DateTime(2024, 5, 20, 15, 0),
          notes: 'Agenda: planning session',
          location: 'Room 42',
        );
        final ics = TideExport.toICalendar(events: [original]);
        final imported = TideImport.fromICalendar(ics);
        expect(imported.first.notes, equals('Agenda: planning session'));
        expect(imported.first.location, equals('Room 42'));
      });

      test('event with special characters round-trip', () {
        final original = TideEvent(
          id: 'rt-special',
          subject: 'Meeting; Q&A, Wrap-up',
          startTime: DateTime(2024, 7, 1, 9, 0),
          endTime: DateTime(2024, 7, 1, 10, 0),
          notes: 'Notes: line1\nline2',
        );
        final ics = TideExport.toICalendar(events: [original]);
        final imported = TideImport.fromICalendar(ics);
        expect(imported.first.subject, equals(original.subject));
        expect(imported.first.notes, equals(original.notes));
      });
    });
  });
}

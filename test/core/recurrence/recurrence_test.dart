import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/recurrence/recurrence.dart';
import 'package:timetide/src/core/recurrence/rrule_model.dart';

void main() {
  group('TideRecurrence', () {
    group('parse', () {
      test('parses valid RRULE string', () {
        final r = TideRecurrence.parse('RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR');
        expect(r, isNotNull);
        expect(r!.frequency, TideFrequency.weekly);
        expect(r.byDay, hasLength(3));
      });

      test('returns null for invalid input', () {
        expect(TideRecurrence.parse('garbage'), isNull);
      });

      test('returns null for empty string', () {
        expect(TideRecurrence.parse(''), isNull);
      });
    });

    group('constructor', () {
      test('creates from explicit parameters', () {
        final r = TideRecurrence(
          frequency: TideFrequency.monthly,
          byMonthDay: [1, 15],
          count: 12,
        );
        expect(r.frequency, TideFrequency.monthly);
        expect(r.rule.byMonthDay, [1, 15]);
        expect(r.count, 12);
      });
    });

    group('fromRule', () {
      test('wraps existing TideRecurrenceRule', () {
        const rule = TideRecurrenceRule(frequency: TideFrequency.daily);
        final r = TideRecurrence.fromRule(rule);
        expect(r.rule, same(rule));
        expect(r.frequency, TideFrequency.daily);
      });
    });

    group('toRruleString', () {
      test('generates RRULE string', () {
        final r = TideRecurrence(
          frequency: TideFrequency.monthly,
          byMonthDay: [1, 15],
          count: 12,
        );
        expect(
          r.toRruleString(),
          'RRULE:FREQ=MONTHLY;COUNT=12;BYMONTHDAY=1,15',
        );
      });

      test('round-trips through parse', () {
        final original = TideRecurrence(
          frequency: TideFrequency.weekly,
          byDay: [
            TideByDay(weekday: TideWeekday.monday),
            TideByDay(weekday: TideWeekday.friday),
          ],
          interval: 2,
        );
        final rrule = original.toRruleString();
        final reparsed = TideRecurrence.parse(rrule);
        expect(reparsed, isNotNull);
        expect(reparsed!, equals(original));
      });
    });

    group('describe', () {
      test('returns English description by default', () {
        final r = TideRecurrence(frequency: TideFrequency.daily);
        expect(r.describe(), 'Every day');
      });

      test('returns German description', () {
        final r = TideRecurrence(frequency: TideFrequency.daily);
        expect(r.describe(locale: 'de'), 'Jeden Tag');
      });

      test('describes weekly with days', () {
        final r = TideRecurrence(
          frequency: TideFrequency.weekly,
          byDay: [
            TideByDay(weekday: TideWeekday.monday),
            TideByDay(weekday: TideWeekday.wednesday),
            TideByDay(weekday: TideWeekday.friday),
          ],
        );
        expect(r.describe(), 'Every week on Monday, Wednesday, Friday');
      });

      test('describes last Friday of month', () {
        final r = TideRecurrence(
          frequency: TideFrequency.monthly,
          bySetPos: [-1],
          byDay: [TideByDay(weekday: TideWeekday.friday)],
        );
        expect(r.describe(), 'The last Friday of every month');
      });
    });

    group('describeString', () {
      test('describes from RRULE string', () {
        final desc = TideRecurrence.describeString('FREQ=DAILY');
        expect(desc, 'Every day');
      });

      test('returns null for invalid input', () {
        expect(TideRecurrence.describeString('garbage'), isNull);
      });

      test('supports locale parameter', () {
        final desc = TideRecurrence.describeString(
          'FREQ=WEEKLY;BYDAY=MO',
          locale: 'de',
        );
        expect(desc, 'Jede Woche am Montag');
      });
    });

    group('occurrences', () {
      test('generates daily occurrences', () {
        final r = TideRecurrence(
          frequency: TideFrequency.daily,
          count: 5,
        );
        final dates = r.occurrences(start: DateTime(2026, 3, 1)).toList();
        expect(dates, hasLength(5));
        expect(dates[0], DateTime(2026, 3, 1));
        expect(dates[1], DateTime(2026, 3, 2));
        expect(dates[4], DateTime(2026, 3, 5));
      });

      test('generates weekly MO WE FR occurrences', () {
        final r = TideRecurrence(
          frequency: TideFrequency.weekly,
          byDay: [
            TideByDay(weekday: TideWeekday.monday),
            TideByDay(weekday: TideWeekday.wednesday),
            TideByDay(weekday: TideWeekday.friday),
          ],
          count: 6,
        );
        // 2026-03-02 is a Monday.
        final dates = r.occurrences(start: DateTime(2026, 3, 2)).toList();
        expect(dates, hasLength(6));
        // MO, WE, FR of week 1, then MO, WE, FR of week 2.
        expect(dates[0].weekday, DateTime.monday);
        expect(dates[1].weekday, DateTime.wednesday);
        expect(dates[2].weekday, DateTime.friday);
        expect(dates[3].weekday, DateTime.monday);
      });

      test('respects after parameter', () {
        final r = TideRecurrence(
          frequency: TideFrequency.daily,
          count: 10,
        );
        final dates = r
            .occurrences(
              start: DateTime(2026, 3, 1),
              after: DateTime(2026, 3, 5),
            )
            .toList();
        // Days 6-10 (after the 5th).
        expect(dates.first, DateTime(2026, 3, 6));
      });

      test('respects before parameter', () {
        final r = TideRecurrence(
          frequency: TideFrequency.daily,
          count: 30,
        );
        final dates = r
            .occurrences(
              start: DateTime(2026, 3, 1),
              before: DateTime(2026, 3, 6),
            )
            .toList();
        expect(dates, hasLength(5));
        expect(dates.last, DateTime(2026, 3, 5));
      });

      test('monthly on the 15th', () {
        final r = TideRecurrence(
          frequency: TideFrequency.monthly,
          byMonthDay: [15],
          count: 3,
        );
        final dates = r.occurrences(start: DateTime(2026, 1, 15)).toList();
        expect(dates, hasLength(3));
        expect(dates[0], DateTime(2026, 1, 15));
        expect(dates[1], DateTime(2026, 2, 15));
        expect(dates[2], DateTime(2026, 3, 15));
      });

      test('yearly on March 19', () {
        final r = TideRecurrence(
          frequency: TideFrequency.yearly,
          byMonth: [3],
          byMonthDay: [19],
          count: 3,
        );
        final dates = r.occurrences(start: DateTime(2026, 3, 19)).toList();
        expect(dates, hasLength(3));
        expect(dates[0], DateTime(2026, 3, 19));
        expect(dates[1], DateTime(2027, 3, 19));
        expect(dates[2], DateTime(2028, 3, 19));
      });

      test('EXDATE excludes specific occurrences', () {
        final r = TideRecurrence(
          frequency: TideFrequency.daily,
          count: 5,
          exDates: [DateTime(2026, 3, 3)],
        );
        final dates = r.occurrences(start: DateTime(2026, 3, 1)).toList();
        // March 3 should be excluded. Excluded dates don't count toward
        // COUNT, so we still get 5 yielded dates (1,2,4,5,6).
        expect(dates, hasLength(5));
        expect(dates.contains(DateTime(2026, 3, 3)), isFalse);
      });

      test('UNTIL limits occurrences', () {
        final r = TideRecurrence(
          frequency: TideFrequency.daily,
          until: DateTime(2026, 3, 5),
        );
        final dates = r.occurrences(start: DateTime(2026, 3, 1)).toList();
        expect(dates, hasLength(5));
        expect(dates.last, DateTime(2026, 3, 5));
      });
    });

    group('full integration: parse -> describe -> generate -> occurrences', () {
      test('weekly MWF until end of year', () {
        final r = TideRecurrence.parse(
          'RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR;UNTIL=20261231T235959Z',
        );
        expect(r, isNotNull);

        // Describe.
        final desc = r!.describe();
        expect(desc, contains('Monday'));
        expect(desc, contains('Wednesday'));
        expect(desc, contains('Friday'));

        // Generate.
        final rrule = r.toRruleString();
        expect(rrule, contains('FREQ=WEEKLY'));
        expect(rrule, contains('BYDAY=MO,WE,FR'));

        // Occurrences — check first few after March 19.
        final dates = r
            .occurrences(
              start: DateTime(2026, 3, 2),
              after: DateTime(2026, 3, 19),
              before: DateTime(2026, 4, 1),
            )
            .toList();
        expect(dates, isNotEmpty);
        // All should be MO, WE, or FR.
        for (final d in dates) {
          expect(
            [DateTime.monday, DateTime.wednesday, DateTime.friday],
            contains(d.weekday),
          );
        }
      });

      test('last Friday of every month, 12 times', () {
        final r = TideRecurrence.parse(
          'RRULE:FREQ=MONTHLY;BYSETPOS=-1;BYDAY=FR;COUNT=12',
        );
        expect(r, isNotNull);

        final desc = r!.describe();
        expect(desc, contains('last'));
        expect(desc, contains('Friday'));

        // Start from January 2026.
        final dates =
            r.occurrences(start: DateTime(2026, 1, 1)).toList();
        expect(dates, hasLength(12));
        // All should be Fridays.
        for (final d in dates) {
          expect(d.weekday, DateTime.friday);
        }
        // Each should be the last Friday of its month.
        for (final d in dates) {
          // The next Friday should be in the next month.
          final nextFriday = d.add(const Duration(days: 7));
          expect(nextFriday.month != d.month, isTrue);
        }
      });
    });

    group('equality', () {
      test('equal for same rule', () {
        final a = TideRecurrence(frequency: TideFrequency.daily, count: 5);
        final b = TideRecurrence(frequency: TideFrequency.daily, count: 5);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('not equal for different rules', () {
        final a = TideRecurrence(frequency: TideFrequency.daily);
        final b = TideRecurrence(frequency: TideFrequency.weekly);
        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('includes RRULE string', () {
        final r = TideRecurrence(frequency: TideFrequency.daily);
        expect(r.toString(), contains('RRULE:FREQ=DAILY'));
      });
    });

    group('convenience getters', () {
      test('frequency delegates to rule', () {
        final r = TideRecurrence(frequency: TideFrequency.weekly);
        expect(r.frequency, TideFrequency.weekly);
      });

      test('interval delegates to rule', () {
        final r = TideRecurrence(frequency: TideFrequency.weekly, interval: 3);
        expect(r.interval, 3);
      });

      test('count delegates to rule', () {
        final r = TideRecurrence(frequency: TideFrequency.daily, count: 10);
        expect(r.count, 10);
      });

      test('until delegates to rule', () {
        final dt = DateTime.utc(2026, 12, 31);
        final r = TideRecurrence(frequency: TideFrequency.daily, until: dt);
        expect(r.until, dt);
      });

      test('byDay delegates to rule', () {
        final r = TideRecurrence(
          frequency: TideFrequency.weekly,
          byDay: [TideByDay(weekday: TideWeekday.monday)],
        );
        expect(r.byDay, hasLength(1));
      });
    });
  });
}

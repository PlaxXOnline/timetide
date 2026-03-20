import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/recurrence/rrule_generator.dart';
import 'package:timetide/src/core/recurrence/rrule_model.dart';
import 'package:timetide/src/core/recurrence/rrule_parser.dart';

void main() {
  group('TideRRuleParser', () {
    group('basic FREQ parsing', () {
      test('parses FREQ=DAILY', () {
        final rule = TideRRuleParser.parse('FREQ=DAILY');
        expect(rule, isNotNull);
        expect(rule!.frequency, TideFrequency.daily);
      });

      test('parses FREQ=WEEKLY', () {
        final rule = TideRRuleParser.parse('FREQ=WEEKLY');
        expect(rule, isNotNull);
        expect(rule!.frequency, TideFrequency.weekly);
      });

      test('parses FREQ=MONTHLY', () {
        final rule = TideRRuleParser.parse('FREQ=MONTHLY');
        expect(rule, isNotNull);
        expect(rule!.frequency, TideFrequency.monthly);
      });

      test('parses FREQ=YEARLY', () {
        final rule = TideRRuleParser.parse('FREQ=YEARLY');
        expect(rule, isNotNull);
        expect(rule!.frequency, TideFrequency.yearly);
      });

      test('strips RRULE: prefix', () {
        final rule = TideRRuleParser.parse('RRULE:FREQ=DAILY');
        expect(rule, isNotNull);
        expect(rule!.frequency, TideFrequency.daily);
      });

      test('handles lowercase rrule prefix', () {
        final rule = TideRRuleParser.parse('rrule:FREQ=DAILY');
        expect(rule, isNotNull);
        expect(rule!.frequency, TideFrequency.daily);
      });

      test('handles mixed-case property names', () {
        final rule = TideRRuleParser.parse('Freq=WEEKLY;Interval=2');
        expect(rule, isNotNull);
        expect(rule!.frequency, TideFrequency.weekly);
        expect(rule.interval, 2);
      });
    });

    group('INTERVAL', () {
      test('defaults to 1 when not specified', () {
        final rule = TideRRuleParser.parse('FREQ=DAILY');
        expect(rule!.interval, 1);
      });

      test('parses INTERVAL=2', () {
        final rule = TideRRuleParser.parse('FREQ=WEEKLY;INTERVAL=2');
        expect(rule!.interval, 2);
      });

      test('parses INTERVAL=12', () {
        final rule = TideRRuleParser.parse('FREQ=MONTHLY;INTERVAL=12');
        expect(rule!.interval, 12);
      });
    });

    group('COUNT', () {
      test('parses COUNT', () {
        final rule = TideRRuleParser.parse('FREQ=DAILY;COUNT=10');
        expect(rule!.count, 10);
      });

      test('COUNT is null when not specified', () {
        final rule = TideRRuleParser.parse('FREQ=DAILY');
        expect(rule!.count, isNull);
      });
    });

    group('UNTIL', () {
      test('parses UTC datetime with Z suffix', () {
        final rule = TideRRuleParser.parse(
          'FREQ=WEEKLY;UNTIL=20261231T235959Z',
        );
        expect(rule!.until, DateTime.utc(2026, 12, 31, 23, 59, 59));
        expect(rule.until!.isUtc, isTrue);
      });

      test('parses local datetime without Z suffix', () {
        final rule = TideRRuleParser.parse(
          'FREQ=WEEKLY;UNTIL=20261231T235959',
        );
        expect(rule!.until, DateTime(2026, 12, 31, 23, 59, 59));
        expect(rule.until!.isUtc, isFalse);
      });

      test('parses date-only UNTIL', () {
        final rule = TideRRuleParser.parse('FREQ=DAILY;UNTIL=20261231');
        expect(rule!.until, DateTime.utc(2026, 12, 31));
      });

      test('UNTIL is null when not specified', () {
        final rule = TideRRuleParser.parse('FREQ=DAILY');
        expect(rule!.until, isNull);
      });
    });

    group('BYDAY', () {
      test('parses single weekday', () {
        final rule = TideRRuleParser.parse('FREQ=WEEKLY;BYDAY=MO');
        expect(rule!.byDay, hasLength(1));
        expect(rule.byDay![0].weekday, TideWeekday.monday);
        expect(rule.byDay![0].ordinal, isNull);
      });

      test('parses multiple weekdays', () {
        final rule = TideRRuleParser.parse('FREQ=WEEKLY;BYDAY=MO,WE,FR');
        expect(rule!.byDay, hasLength(3));
        expect(rule.byDay![0].weekday, TideWeekday.monday);
        expect(rule.byDay![1].weekday, TideWeekday.wednesday);
        expect(rule.byDay![2].weekday, TideWeekday.friday);
      });

      test('parses all weekday abbreviations', () {
        final rule = TideRRuleParser.parse(
          'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU',
        );
        expect(rule!.byDay, hasLength(7));
        expect(rule.byDay![0].weekday, TideWeekday.monday);
        expect(rule.byDay![1].weekday, TideWeekday.tuesday);
        expect(rule.byDay![2].weekday, TideWeekday.wednesday);
        expect(rule.byDay![3].weekday, TideWeekday.thursday);
        expect(rule.byDay![4].weekday, TideWeekday.friday);
        expect(rule.byDay![5].weekday, TideWeekday.saturday);
        expect(rule.byDay![6].weekday, TideWeekday.sunday);
      });

      test('parses positive ordinal (3rd Friday)', () {
        final rule = TideRRuleParser.parse('FREQ=MONTHLY;BYDAY=3FR');
        expect(rule!.byDay, hasLength(1));
        expect(rule.byDay![0].weekday, TideWeekday.friday);
        expect(rule.byDay![0].ordinal, 3);
      });

      test('parses negative ordinal (last Monday)', () {
        final rule = TideRRuleParser.parse('FREQ=MONTHLY;BYDAY=-1MO');
        expect(rule!.byDay, hasLength(1));
        expect(rule.byDay![0].weekday, TideWeekday.monday);
        expect(rule.byDay![0].ordinal, -1);
      });

      test('parses second-to-last Friday', () {
        final rule = TideRRuleParser.parse('FREQ=MONTHLY;BYDAY=-2FR');
        expect(rule!.byDay, hasLength(1));
        expect(rule.byDay![0].weekday, TideWeekday.friday);
        expect(rule.byDay![0].ordinal, -2);
      });

      test('parses mixed ordinal and plain weekdays', () {
        final rule = TideRRuleParser.parse('FREQ=MONTHLY;BYDAY=1MO,FR');
        expect(rule!.byDay, hasLength(2));
        expect(rule.byDay![0].weekday, TideWeekday.monday);
        expect(rule.byDay![0].ordinal, 1);
        expect(rule.byDay![1].weekday, TideWeekday.friday);
        expect(rule.byDay![1].ordinal, isNull);
      });
    });

    group('BYMONTHDAY', () {
      test('parses single day', () {
        final rule = TideRRuleParser.parse('FREQ=MONTHLY;BYMONTHDAY=15');
        expect(rule!.byMonthDay, [15]);
      });

      test('parses multiple days', () {
        final rule = TideRRuleParser.parse('FREQ=MONTHLY;BYMONTHDAY=1,15');
        expect(rule!.byMonthDay, [1, 15]);
      });

      test('parses negative day (last day of month)', () {
        final rule = TideRRuleParser.parse('FREQ=MONTHLY;BYMONTHDAY=-1');
        expect(rule!.byMonthDay, [-1]);
      });
    });

    group('BYMONTH', () {
      test('parses single month', () {
        final rule = TideRRuleParser.parse('FREQ=YEARLY;BYMONTH=3');
        expect(rule!.byMonth, [3]);
      });

      test('parses multiple months', () {
        final rule = TideRRuleParser.parse('FREQ=YEARLY;BYMONTH=1,7');
        expect(rule!.byMonth, [1, 7]);
      });
    });

    group('BYSETPOS', () {
      test('parses positive set position', () {
        final rule = TideRRuleParser.parse(
          'FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=1',
        );
        expect(rule!.bySetPos, [1]);
      });

      test('parses negative set position (last weekday)', () {
        final rule = TideRRuleParser.parse(
          'FREQ=MONTHLY;BYDAY=FR;BYSETPOS=-1',
        );
        expect(rule!.bySetPos, [-1]);
      });

      test('parses multiple set positions', () {
        final rule = TideRRuleParser.parse(
          'FREQ=MONTHLY;BYDAY=MO;BYSETPOS=1,-1',
        );
        expect(rule!.bySetPos, [1, -1]);
      });
    });

    group('BYHOUR', () {
      test('parses single hour', () {
        final rule = TideRRuleParser.parse('FREQ=DAILY;BYHOUR=9');
        expect(rule!.byHour, [9]);
      });

      test('parses multiple hours', () {
        final rule = TideRRuleParser.parse('FREQ=DAILY;BYHOUR=9,12,18');
        expect(rule!.byHour, [9, 12, 18]);
      });
    });

    group('BYMINUTE', () {
      test('parses single minute', () {
        final rule = TideRRuleParser.parse('FREQ=DAILY;BYMINUTE=30');
        expect(rule!.byMinute, [30]);
      });

      test('parses multiple minutes', () {
        final rule = TideRRuleParser.parse('FREQ=DAILY;BYMINUTE=0,30');
        expect(rule!.byMinute, [0, 30]);
      });
    });

    group('BYYEARDAY', () {
      test('parses positive year day', () {
        final rule = TideRRuleParser.parse('FREQ=YEARLY;BYYEARDAY=1');
        expect(rule!.byYearDay, [1]);
      });

      test('parses negative year day', () {
        final rule = TideRRuleParser.parse('FREQ=YEARLY;BYYEARDAY=-1');
        expect(rule!.byYearDay, [-1]);
      });

      test('parses multiple year days', () {
        final rule = TideRRuleParser.parse('FREQ=YEARLY;BYYEARDAY=1,100,200');
        expect(rule!.byYearDay, [1, 100, 200]);
      });
    });

    group('BYWEEKNO', () {
      test('parses single week number', () {
        final rule = TideRRuleParser.parse('FREQ=YEARLY;BYWEEKNO=20');
        expect(rule!.byWeekNo, [20]);
      });

      test('parses negative week number', () {
        final rule = TideRRuleParser.parse('FREQ=YEARLY;BYWEEKNO=-1');
        expect(rule!.byWeekNo, [-1]);
      });

      test('parses multiple week numbers', () {
        final rule = TideRRuleParser.parse('FREQ=YEARLY;BYWEEKNO=1,26,52');
        expect(rule!.byWeekNo, [1, 26, 52]);
      });
    });

    group('WKST', () {
      test('defaults to monday', () {
        final rule = TideRRuleParser.parse('FREQ=WEEKLY');
        expect(rule!.weekStart, TideWeekday.monday);
      });

      test('parses WKST=SU', () {
        final rule = TideRRuleParser.parse('FREQ=WEEKLY;WKST=SU');
        expect(rule!.weekStart, TideWeekday.sunday);
      });

      test('parses WKST=SA', () {
        final rule = TideRRuleParser.parse('FREQ=WEEKLY;WKST=SA');
        expect(rule!.weekStart, TideWeekday.saturday);
      });
    });

    group('EXDATE', () {
      test('parses single EXDATE', () {
        final rule = TideRRuleParser.parse(
          'FREQ=WEEKLY;BYDAY=MO;EXDATE=20260403T000000Z',
        );
        expect(rule!.exDates, hasLength(1));
        expect(rule.exDates![0], DateTime.utc(2026, 4, 3));
      });

      test('parses multiple EXDATEs', () {
        final rule = TideRRuleParser.parse(
          'FREQ=WEEKLY;BYDAY=MO;EXDATE=20260403T000000Z,20260410T000000Z',
        );
        expect(rule!.exDates, hasLength(2));
        expect(rule.exDates![0], DateTime.utc(2026, 4, 3));
        expect(rule.exDates![1], DateTime.utc(2026, 4, 10));
      });

      test('parses date-only EXDATEs', () {
        final rule = TideRRuleParser.parse(
          'FREQ=WEEKLY;BYDAY=MO;EXDATE=20260403,20260410',
        );
        expect(rule!.exDates, hasLength(2));
        expect(rule.exDates![0], DateTime.utc(2026, 4, 3));
        expect(rule.exDates![1], DateTime.utc(2026, 4, 10));
      });
    });

    group('RDATE', () {
      test('parses single RDATE', () {
        final rule = TideRRuleParser.parse(
          'FREQ=WEEKLY;BYDAY=MO;RDATE=20260501T090000Z',
        );
        expect(rule!.rDates, hasLength(1));
        expect(rule.rDates![0], DateTime.utc(2026, 5, 1, 9));
      });

      test('parses multiple RDATEs', () {
        final rule = TideRRuleParser.parse(
          'FREQ=WEEKLY;RDATE=20260501T090000Z,20260601T090000Z',
        );
        expect(rule!.rDates, hasLength(2));
      });
    });

    group('complex rules', () {
      test('weekly MO WE FR until end of year', () {
        final rule = TideRRuleParser.parse(
          'RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR;UNTIL=20261231T235959Z',
        );
        expect(rule, isNotNull);
        expect(rule!.frequency, TideFrequency.weekly);
        expect(rule.byDay, hasLength(3));
        expect(rule.until, DateTime.utc(2026, 12, 31, 23, 59, 59));
      });

      test('last Friday of every month', () {
        final rule = TideRRuleParser.parse(
          'RRULE:FREQ=MONTHLY;BYSETPOS=-1;BYDAY=FR',
        );
        expect(rule, isNotNull);
        expect(rule!.frequency, TideFrequency.monthly);
        expect(rule.bySetPos, [-1]);
        expect(rule.byDay, hasLength(1));
        expect(rule.byDay![0].weekday, TideWeekday.friday);
      });

      test('1st and 15th of every month 12 times', () {
        final rule = TideRRuleParser.parse(
          'RRULE:FREQ=MONTHLY;BYMONTHDAY=1,15;COUNT=12',
        );
        expect(rule, isNotNull);
        expect(rule!.frequency, TideFrequency.monthly);
        expect(rule.byMonthDay, [1, 15]);
        expect(rule.count, 12);
      });

      test('yearly on March 19', () {
        final rule = TideRRuleParser.parse(
          'RRULE:FREQ=YEARLY;BYMONTH=3;BYMONTHDAY=19',
        );
        expect(rule, isNotNull);
        expect(rule!.frequency, TideFrequency.yearly);
        expect(rule.byMonth, [3]);
        expect(rule.byMonthDay, [19]);
      });

      test('every 2 weeks on Tu Th with WKST=SU', () {
        final rule = TideRRuleParser.parse(
          'RRULE:FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,TH;WKST=SU',
        );
        expect(rule, isNotNull);
        expect(rule!.frequency, TideFrequency.weekly);
        expect(rule.interval, 2);
        expect(rule.byDay, hasLength(2));
        expect(rule.byDay![0].weekday, TideWeekday.tuesday);
        expect(rule.byDay![1].weekday, TideWeekday.thursday);
        expect(rule.weekStart, TideWeekday.sunday);
      });

      test('daily at 9:00 and 17:00', () {
        final rule = TideRRuleParser.parse(
          'FREQ=DAILY;BYHOUR=9,17;BYMINUTE=0',
        );
        expect(rule, isNotNull);
        expect(rule!.byHour, [9, 17]);
        expect(rule.byMinute, [0]);
      });

      test('3rd Friday of every month with count', () {
        final rule = TideRRuleParser.parse(
          'FREQ=MONTHLY;BYDAY=3FR;COUNT=6',
        );
        expect(rule, isNotNull);
        expect(rule!.byDay, hasLength(1));
        expect(rule.byDay![0].weekday, TideWeekday.friday);
        expect(rule.byDay![0].ordinal, 3);
        expect(rule.count, 6);
      });

      test('rule with EXDATE and RDATE', () {
        final rule = TideRRuleParser.parse(
          'FREQ=WEEKLY;BYDAY=MO;EXDATE=20260406T000000Z;RDATE=20260501T090000Z',
        );
        expect(rule, isNotNull);
        expect(rule!.exDates, hasLength(1));
        expect(rule.rDates, hasLength(1));
      });
    });

    group('invalid input', () {
      test('returns null for empty string', () {
        expect(TideRRuleParser.parse(''), isNull);
      });

      test('returns null for whitespace only', () {
        expect(TideRRuleParser.parse('   '), isNull);
      });

      test('returns null for missing FREQ', () {
        expect(TideRRuleParser.parse('INTERVAL=2;BYDAY=MO'), isNull);
      });

      test('returns null for unknown FREQ value', () {
        expect(TideRRuleParser.parse('FREQ=SECONDLY'), isNull);
      });

      test('returns null for RRULE: prefix only', () {
        expect(TideRRuleParser.parse('RRULE:'), isNull);
      });

      test('handles garbage gracefully', () {
        expect(TideRRuleParser.parse('not a rule'), isNull);
      });

      test('handles properties without values', () {
        // No equals sign — skipped, missing FREQ → null.
        expect(TideRRuleParser.parse('FREQ'), isNull);
      });
    });

    group('edge cases', () {
      test('ignores trailing semicolons', () {
        final rule = TideRRuleParser.parse('FREQ=DAILY;COUNT=5;');
        expect(rule, isNotNull);
        expect(rule!.count, 5);
      });

      test('handles spaces around values', () {
        final rule = TideRRuleParser.parse('FREQ = DAILY ; COUNT = 3');
        expect(rule, isNotNull);
        expect(rule!.frequency, TideFrequency.daily);
        expect(rule.count, 3);
      });

      test('unknown properties are silently ignored', () {
        final rule = TideRRuleParser.parse(
          'FREQ=DAILY;X-CUSTOM=foo;COUNT=5',
        );
        expect(rule, isNotNull);
        expect(rule!.count, 5);
      });
    });
  });

  group('TideRRuleGenerator', () {
    test('generates minimal FREQ rule', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.daily);
      expect(TideRRuleGenerator.generate(rule), 'RRULE:FREQ=DAILY');
    });

    test('generates INTERVAL', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        interval: 2,
      );
      expect(
        TideRRuleGenerator.generate(rule),
        'RRULE:FREQ=WEEKLY;INTERVAL=2',
      );
    });

    test('omits INTERVAL when 1', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.weekly);
      expect(TideRRuleGenerator.generate(rule), 'RRULE:FREQ=WEEKLY');
    });

    test('generates COUNT', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 10,
      );
      expect(TideRRuleGenerator.generate(rule), 'RRULE:FREQ=DAILY;COUNT=10');
    });

    test('generates UNTIL with UTC Z suffix', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        until: DateTime.utc(2026, 12, 31, 23, 59, 59),
      );
      expect(
        TideRRuleGenerator.generate(rule),
        'RRULE:FREQ=WEEKLY;UNTIL=20261231T235959Z',
      );
    });

    test('generates UNTIL without Z for local datetime', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        until: DateTime(2026, 12, 31, 23, 59, 59),
      );
      expect(
        TideRRuleGenerator.generate(rule),
        'RRULE:FREQ=WEEKLY;UNTIL=20261231T235959',
      );
    });

    test('generates BYDAY with plain weekdays', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        byDay: [
          TideByDay(weekday: TideWeekday.monday),
          TideByDay(weekday: TideWeekday.wednesday),
          TideByDay(weekday: TideWeekday.friday),
        ],
      );
      expect(
        TideRRuleGenerator.generate(rule),
        'RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR',
      );
    });

    test('generates BYDAY with ordinals', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.friday, ordinal: 3)],
      );
      expect(
        TideRRuleGenerator.generate(rule),
        'RRULE:FREQ=MONTHLY;BYDAY=3FR',
      );
    });

    test('generates BYDAY with negative ordinals', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.monday, ordinal: -1)],
      );
      expect(
        TideRRuleGenerator.generate(rule),
        'RRULE:FREQ=MONTHLY;BYDAY=-1MO',
      );
    });

    test('generates BYMONTHDAY', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byMonthDay: [1, 15],
      );
      expect(
        TideRRuleGenerator.generate(rule),
        'RRULE:FREQ=MONTHLY;BYMONTHDAY=1,15',
      );
    });

    test('generates BYMONTH', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byMonth: [1, 7],
      );
      expect(
        TideRRuleGenerator.generate(rule),
        'RRULE:FREQ=YEARLY;BYMONTH=1,7',
      );
    });

    test('generates BYSETPOS', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.friday)],
        bySetPos: [-1],
      );
      expect(
        TideRRuleGenerator.generate(rule),
        'RRULE:FREQ=MONTHLY;BYDAY=FR;BYSETPOS=-1',
      );
    });

    test('generates BYHOUR and BYMINUTE', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        byHour: [9, 17],
        byMinute: [0, 30],
      );
      expect(
        TideRRuleGenerator.generate(rule),
        'RRULE:FREQ=DAILY;BYHOUR=9,17;BYMINUTE=0,30',
      );
    });

    test('generates BYYEARDAY', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byYearDay: [1, 100, -1],
      );
      expect(
        TideRRuleGenerator.generate(rule),
        'RRULE:FREQ=YEARLY;BYYEARDAY=1,100,-1',
      );
    });

    test('generates BYWEEKNO', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byWeekNo: [1, 26],
      );
      expect(
        TideRRuleGenerator.generate(rule),
        'RRULE:FREQ=YEARLY;BYWEEKNO=1,26',
      );
    });

    test('generates WKST when not monday', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        weekStart: TideWeekday.sunday,
      );
      expect(
        TideRRuleGenerator.generate(rule),
        'RRULE:FREQ=WEEKLY;WKST=SU',
      );
    });

    test('omits WKST when monday (default)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        weekStart: TideWeekday.monday,
      );
      expect(TideRRuleGenerator.generate(rule), 'RRULE:FREQ=WEEKLY');
    });

    test('generates EXDATE', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        byDay: [TideByDay(weekday: TideWeekday.monday)],
        exDates: [DateTime.utc(2026, 4, 6)],
      );
      final generated = TideRRuleGenerator.generate(rule);
      expect(generated, contains('EXDATE=20260406T000000Z'));
    });

    test('generates RDATE', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        rDates: [DateTime.utc(2026, 5, 1, 9)],
      );
      final generated = TideRRuleGenerator.generate(rule);
      expect(generated, contains('RDATE=20260501T090000Z'));
    });

    test('generates complex rule with all properties', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        interval: 2,
        count: 24,
        byDay: [TideByDay(weekday: TideWeekday.friday, ordinal: 3)],
        byMonth: [1, 4, 7, 10],
        weekStart: TideWeekday.sunday,
      );
      final generated = TideRRuleGenerator.generate(rule);
      expect(generated, startsWith('RRULE:'));
      expect(generated, contains('FREQ=MONTHLY'));
      expect(generated, contains('INTERVAL=2'));
      expect(generated, contains('COUNT=24'));
      expect(generated, contains('BYDAY=3FR'));
      expect(generated, contains('BYMONTH=1,4,7,10'));
      expect(generated, contains('WKST=SU'));
    });
  });

  group('round-trip (parse -> generate -> parse)', () {
    void testRoundTrip(String description, String rrule) {
      test(description, () {
        final parsed = TideRRuleParser.parse(rrule);
        expect(parsed, isNotNull, reason: 'Failed to parse: $rrule');
        final generated = TideRRuleGenerator.generate(parsed!);
        final reparsed = TideRRuleParser.parse(generated);
        expect(reparsed, isNotNull, reason: 'Failed to reparse: $generated');
        expect(reparsed, equals(parsed));
      });
    }

    testRoundTrip(
      'daily with count',
      'RRULE:FREQ=DAILY;COUNT=30',
    );

    testRoundTrip(
      'weekly MO WE FR until date',
      'RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR;UNTIL=20261231T235959Z',
    );

    testRoundTrip(
      'monthly on 1st and 15th',
      'RRULE:FREQ=MONTHLY;BYMONTHDAY=1,15;COUNT=12',
    );

    testRoundTrip(
      'last Friday of month',
      'RRULE:FREQ=MONTHLY;BYDAY=FR;BYSETPOS=-1',
    );

    testRoundTrip(
      'yearly on March 19',
      'RRULE:FREQ=YEARLY;BYMONTH=3;BYMONTHDAY=19',
    );

    testRoundTrip(
      'every 2 weeks with WKST=SU',
      'RRULE:FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,TH;WKST=SU',
    );

    testRoundTrip(
      '3rd Friday monthly with count',
      'RRULE:FREQ=MONTHLY;BYDAY=3FR;COUNT=6',
    );

    testRoundTrip(
      'daily with BYHOUR and BYMINUTE',
      'RRULE:FREQ=DAILY;BYHOUR=9,17;BYMINUTE=0,30',
    );

    testRoundTrip(
      'yearly with BYYEARDAY',
      'RRULE:FREQ=YEARLY;BYYEARDAY=1,100,-1',
    );

    testRoundTrip(
      'yearly with BYWEEKNO',
      'RRULE:FREQ=YEARLY;BYWEEKNO=1,26,52',
    );

    testRoundTrip(
      'weekly with EXDATE',
      'RRULE:FREQ=WEEKLY;BYDAY=MO;EXDATE=20260406T000000Z,20260413T000000Z',
    );

    testRoundTrip(
      'weekly with RDATE',
      'RRULE:FREQ=WEEKLY;BYDAY=MO;RDATE=20260501T090000Z',
    );

    testRoundTrip(
      'monthly with negative BYMONTHDAY',
      'RRULE:FREQ=MONTHLY;BYMONTHDAY=-1',
    );
  });

  group('TideRecurrenceRule model', () {
    test('equality for identical rules', () {
      final a = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        byDay: [
          TideByDay(weekday: TideWeekday.monday),
          TideByDay(weekday: TideWeekday.friday),
        ],
      );
      final b = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        byDay: [
          TideByDay(weekday: TideWeekday.monday),
          TideByDay(weekday: TideWeekday.friday),
        ],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality for different rules', () {
      final a = TideRecurrenceRule(frequency: TideFrequency.daily);
      final b = TideRecurrenceRule(frequency: TideFrequency.weekly);
      expect(a, isNot(equals(b)));
    });

    test('copyWith preserves unmodified fields', () {
      final original = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        interval: 2,
        byDay: [TideByDay(weekday: TideWeekday.monday)],
        count: 10,
      );
      final copy = original.copyWith(count: 20);
      expect(copy.frequency, TideFrequency.weekly);
      expect(copy.interval, 2);
      expect(copy.byDay, hasLength(1));
      expect(copy.count, 20);
    });

    test('toString includes non-default fields', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 5,
      );
      final str = rule.toString();
      expect(str, contains('TideRecurrenceRule'));
      expect(str, contains('daily'));
      expect(str, contains('count: 5'));
    });
  });

  group('TideByDay model', () {
    test('equality', () {
      const a = TideByDay(weekday: TideWeekday.friday, ordinal: 3);
      const b = TideByDay(weekday: TideWeekday.friday, ordinal: 3);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality with different ordinal', () {
      const a = TideByDay(weekday: TideWeekday.friday, ordinal: 3);
      const b = TideByDay(weekday: TideWeekday.friday, ordinal: -1);
      expect(a, isNot(equals(b)));
    });

    test('inequality with different weekday', () {
      const a = TideByDay(weekday: TideWeekday.friday);
      const b = TideByDay(weekday: TideWeekday.monday);
      expect(a, isNot(equals(b)));
    });

    test('toString without ordinal', () {
      const byDay = TideByDay(weekday: TideWeekday.monday);
      expect(byDay.toString(), 'MO');
    });

    test('toString with positive ordinal', () {
      const byDay = TideByDay(weekday: TideWeekday.friday, ordinal: 3);
      expect(byDay.toString(), '3FR');
    });

    test('toString with negative ordinal', () {
      const byDay = TideByDay(weekday: TideWeekday.monday, ordinal: -1);
      expect(byDay.toString(), '-1MO');
    });
  });

  group('TideWeekday', () {
    test('abbreviation returns correct values', () {
      expect(TideWeekday.monday.abbreviation, 'MO');
      expect(TideWeekday.tuesday.abbreviation, 'TU');
      expect(TideWeekday.wednesday.abbreviation, 'WE');
      expect(TideWeekday.thursday.abbreviation, 'TH');
      expect(TideWeekday.friday.abbreviation, 'FR');
      expect(TideWeekday.saturday.abbreviation, 'SA');
      expect(TideWeekday.sunday.abbreviation, 'SU');
    });

    test('fromAbbreviation round-trips all days', () {
      for (final day in TideWeekday.values) {
        expect(TideWeekday.fromAbbreviation(day.abbreviation), day);
      }
    });

    test('fromAbbreviation is case insensitive', () {
      expect(TideWeekday.fromAbbreviation('mo'), TideWeekday.monday);
      expect(TideWeekday.fromAbbreviation('Mo'), TideWeekday.monday);
    });

    test('fromAbbreviation returns null for invalid input', () {
      expect(TideWeekday.fromAbbreviation('XX'), isNull);
      expect(TideWeekday.fromAbbreviation(''), isNull);
    });

    test('dateTimeWeekday matches DateTime constants', () {
      expect(TideWeekday.monday.dateTimeWeekday, DateTime.monday);
      expect(TideWeekday.sunday.dateTimeWeekday, DateTime.sunday);
    });

    test('fromDateTimeWeekday round-trips', () {
      for (final day in TideWeekday.values) {
        expect(
          TideWeekday.fromDateTimeWeekday(day.dateTimeWeekday),
          day,
        );
      }
    });

    test('fromDateTimeWeekday returns null for invalid input', () {
      expect(TideWeekday.fromDateTimeWeekday(0), isNull);
      expect(TideWeekday.fromDateTimeWeekday(8), isNull);
    });
  });

  group('TideFrequency', () {
    test('toRfcString returns uppercase names', () {
      expect(TideFrequency.daily.toRfcString(), 'DAILY');
      expect(TideFrequency.weekly.toRfcString(), 'WEEKLY');
      expect(TideFrequency.monthly.toRfcString(), 'MONTHLY');
      expect(TideFrequency.yearly.toRfcString(), 'YEARLY');
    });

    test('fromRfcString round-trips all frequencies', () {
      for (final freq in TideFrequency.values) {
        expect(TideFrequency.fromRfcString(freq.toRfcString()), freq);
      }
    });

    test('fromRfcString is case insensitive', () {
      expect(TideFrequency.fromRfcString('daily'), TideFrequency.daily);
      expect(TideFrequency.fromRfcString('Daily'), TideFrequency.daily);
    });

    test('fromRfcString returns null for invalid input', () {
      expect(TideFrequency.fromRfcString('SECONDLY'), isNull);
      expect(TideFrequency.fromRfcString(''), isNull);
    });
  });
}

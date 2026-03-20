import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/recurrence/rrule_description.dart';
import 'package:timetide/src/core/recurrence/rrule_model.dart';

void main() {
  // ─── DAILY descriptions ───────────────────────────────────────────

  group('DAILY descriptions', () {
    test('every day (en)', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.daily);
      expect(TideRRuleDescription.describe(rule), 'Every day');
    });

    test('every day (de)', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.daily);
      expect(TideRRuleDescription.describe(rule, locale: 'de'), 'Jeden Tag');
    });

    test('every 3 days (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        interval: 3,
      );
      expect(TideRRuleDescription.describe(rule), 'Every 3 days');
    });

    test('every 3 days (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        interval: 3,
      );
      expect(TideRRuleDescription.describe(rule, locale: 'de'), 'Alle 3 Tage');
    });
  });

  // ─── WEEKLY descriptions ──────────────────────────────────────────

  group('WEEKLY descriptions', () {
    test('every week (en)', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.weekly);
      expect(TideRRuleDescription.describe(rule), 'Every week');
    });

    test('every week (de)', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.weekly);
      expect(TideRRuleDescription.describe(rule, locale: 'de'), 'Jede Woche');
    });

    test('every week on Monday, Wednesday, Friday (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        byDay: [
          TideByDay(weekday: TideWeekday.monday),
          TideByDay(weekday: TideWeekday.wednesday),
          TideByDay(weekday: TideWeekday.friday),
        ],
      );
      expect(
        TideRRuleDescription.describe(rule),
        'Every week on Monday, Wednesday, Friday',
      );
    });

    test('every week on Montag, Mittwoch, Freitag (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        byDay: [
          TideByDay(weekday: TideWeekday.monday),
          TideByDay(weekday: TideWeekday.wednesday),
          TideByDay(weekday: TideWeekday.friday),
        ],
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Jede Woche am Montag, Mittwoch, Freitag',
      );
    });

    test('every 2 weeks (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        interval: 2,
      );
      expect(TideRRuleDescription.describe(rule), 'Every 2 weeks');
    });

    test('every 2 weeks (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        interval: 2,
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Alle 2 Wochen',
      );
    });

    test('every 2 weeks on Tuesday, Thursday (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        interval: 2,
        byDay: [
          TideByDay(weekday: TideWeekday.tuesday),
          TideByDay(weekday: TideWeekday.thursday),
        ],
      );
      expect(
        TideRRuleDescription.describe(rule),
        'Every 2 weeks on Tuesday, Thursday',
      );
    });

    test('every 2 weeks on Dienstag, Donnerstag (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        interval: 2,
        byDay: [
          TideByDay(weekday: TideWeekday.tuesday),
          TideByDay(weekday: TideWeekday.thursday),
        ],
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Alle 2 Wochen am Dienstag, Donnerstag',
      );
    });
  });

  // ─── MONTHLY descriptions ────────────────────────────────────────

  group('MONTHLY descriptions', () {
    test('every month (en)', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.monthly);
      expect(TideRRuleDescription.describe(rule), 'Every month');
    });

    test('every month (de)', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.monthly);
      expect(TideRRuleDescription.describe(rule, locale: 'de'), 'Jeden Monat');
    });

    test('every month on the 15th (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byMonthDay: [15],
      );
      expect(TideRRuleDescription.describe(rule), 'Every month on the 15th');
    });

    test('every month on the 15. (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byMonthDay: [15],
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Jeden Monat am 15.',
      );
    });

    test('every month on the 1st and 15th (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byMonthDay: [1, 15],
      );
      expect(
        TideRRuleDescription.describe(rule),
        'Every month on the 1st, 15th',
      );
    });

    test('every 2 months on the 10th (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        interval: 2,
        byMonthDay: [10],
      );
      expect(
        TideRRuleDescription.describe(rule),
        'Every 2 months on the 10th',
      );
    });

    test('every 2 months on the 10. (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        interval: 2,
        byMonthDay: [10],
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Alle 2 Monate am 10.',
      );
    });

    test('the 3rd Friday of every month (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.friday, ordinal: 3)],
      );
      expect(
        TideRRuleDescription.describe(rule),
        'The 3rd Friday of every month',
      );
    });

    test('the 3. Freitag jeden Monats (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.friday, ordinal: 3)],
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Der 3. Freitag jeden Monats',
      );
    });

    test('the last Friday of every month (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.friday, ordinal: -1)],
      );
      expect(
        TideRRuleDescription.describe(rule),
        'The last Friday of every month',
      );
    });

    test('the letzte Freitag jeden Monats (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.friday, ordinal: -1)],
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Der letzte Freitag jeden Monats',
      );
    });

    test('BYSETPOS=3 with BYDAY: 3rd Friday of every month (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.friday)],
        bySetPos: [3],
      );
      expect(
        TideRRuleDescription.describe(rule),
        'The 3rd Friday of every month',
      );
    });

    test('BYSETPOS=3 with BYDAY: 3. Freitag jeden Monats (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.friday)],
        bySetPos: [3],
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Der 3. Freitag jeden Monats',
      );
    });

    test('BYSETPOS=-1 with BYDAY: last Monday (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.monday)],
        bySetPos: [-1],
      );
      expect(
        TideRRuleDescription.describe(rule),
        'The last Monday of every month',
      );
    });
  });

  // ─── YEARLY descriptions ──────────────────────────────────────────

  group('YEARLY descriptions', () {
    test('every year (en)', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.yearly);
      expect(TideRRuleDescription.describe(rule), 'Every year');
    });

    test('every year (de)', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.yearly);
      expect(TideRRuleDescription.describe(rule, locale: 'de'), 'Jedes Jahr');
    });

    test('every year on March 19 (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byMonth: [3],
        byMonthDay: [19],
      );
      expect(TideRRuleDescription.describe(rule), 'Every year on March 19');
    });

    test('every year on 19. März (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byMonth: [3],
        byMonthDay: [19],
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Jedes Jahr am 19. März',
      );
    });

    test('every 2 years (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        interval: 2,
      );
      expect(TideRRuleDescription.describe(rule), 'Every 2 years');
    });

    test('every 2 years (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        interval: 2,
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Alle 2 Jahre',
      );
    });

    test('every year on July 4 (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byMonth: [7],
        byMonthDay: [4],
      );
      expect(TideRRuleDescription.describe(rule), 'Every year on July 4');
    });

    test('every year in January (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byMonth: [1],
      );
      expect(TideRRuleDescription.describe(rule), 'Every year in January');
    });

    test('every year in Januar (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byMonth: [1],
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Jedes Jahr im Januar',
      );
    });

    test('4th Thursday of November every year (Thanksgiving, en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byMonth: [11],
        byDay: [TideByDay(weekday: TideWeekday.thursday, ordinal: 4)],
      );
      expect(
        TideRRuleDescription.describe(rule),
        'The 4th Thursday of November every year',
      );
    });

    test('4. Donnerstag im November jedes Jahr (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byMonth: [11],
        byDay: [TideByDay(weekday: TideWeekday.thursday, ordinal: 4)],
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Der 4. Donnerstag im November jedes Jahr',
      );
    });

    test('every 3 years on December 25 (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        interval: 3,
        byMonth: [12],
        byMonthDay: [25],
      );
      expect(
        TideRRuleDescription.describe(rule),
        'Every 3 years on December 25',
      );
    });

    test('every 3 years on 25. Dezember (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        interval: 3,
        byMonth: [12],
        byMonthDay: [25],
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Alle 3 Jahre am 25. Dezember',
      );
    });
  });

  // ─── COUNT suffix ─────────────────────────────────────────────────

  group('COUNT suffix', () {
    test('daily with COUNT (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 10,
      );
      expect(TideRRuleDescription.describe(rule), 'Every day, 10 times');
    });

    test('daily with COUNT (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 10,
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Jeden Tag, 10 Mal',
      );
    });

    test('weekly with BYDAY + COUNT (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        byDay: [TideByDay(weekday: TideWeekday.monday)],
        count: 5,
      );
      expect(
        TideRRuleDescription.describe(rule),
        'Every week on Monday, 5 times',
      );
    });

    test('monthly with COUNT (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byMonthDay: [1],
        count: 12,
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Jeden Monat am 1., 12 Mal',
      );
    });
  });

  // ─── UNTIL suffix ─────────────────────────────────────────────────

  group('UNTIL suffix', () {
    test('daily with UNTIL (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        until: DateTime(2026, 12, 31),
      );
      expect(
        TideRRuleDescription.describe(rule),
        'Every day, until December 31, 2026',
      );
    });

    test('daily with UNTIL (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        until: DateTime(2026, 12, 31),
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Jeden Tag, bis 31. Dezember 2026',
      );
    });

    test('weekly with BYDAY + UNTIL (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        byDay: [
          TideByDay(weekday: TideWeekday.monday),
          TideByDay(weekday: TideWeekday.wednesday),
          TideByDay(weekday: TideWeekday.friday),
        ],
        until: DateTime(2026, 6, 30),
      );
      expect(
        TideRRuleDescription.describe(rule),
        'Every week on Monday, Wednesday, Friday, until June 30, 2026',
      );
    });

    test('monthly with UNTIL (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byMonthDay: [15],
        until: DateTime(2027, 3, 15),
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Jeden Monat am 15., bis 15. März 2027',
      );
    });
  });

  // ─── Ordinal formatting ───────────────────────────────────────────

  group('Ordinal formatting (en)', () {
    test('1st, 2nd, 3rd, 4th, 11th, 21st ordinals', () {
      final desc = TideRRuleDescription.describe;

      expect(
        desc(TideRecurrenceRule(
          frequency: TideFrequency.monthly,
          byMonthDay: [1],
        )),
        'Every month on the 1st',
      );

      expect(
        desc(TideRecurrenceRule(
          frequency: TideFrequency.monthly,
          byMonthDay: [2],
        )),
        'Every month on the 2nd',
      );

      expect(
        desc(TideRecurrenceRule(
          frequency: TideFrequency.monthly,
          byMonthDay: [3],
        )),
        'Every month on the 3rd',
      );

      expect(
        desc(TideRecurrenceRule(
          frequency: TideFrequency.monthly,
          byMonthDay: [4],
        )),
        'Every month on the 4th',
      );

      expect(
        desc(TideRecurrenceRule(
          frequency: TideFrequency.monthly,
          byMonthDay: [11],
        )),
        'Every month on the 11th',
      );

      expect(
        desc(TideRecurrenceRule(
          frequency: TideFrequency.monthly,
          byMonthDay: [21],
        )),
        'Every month on the 21st',
      );

      expect(
        desc(TideRecurrenceRule(
          frequency: TideFrequency.monthly,
          byMonthDay: [22],
        )),
        'Every month on the 22nd',
      );

      expect(
        desc(TideRecurrenceRule(
          frequency: TideFrequency.monthly,
          byMonthDay: [23],
        )),
        'Every month on the 23rd',
      );
    });
  });

  // ─── All weekday names ────────────────────────────────────────────

  group('All weekday names', () {
    test('all weekday names in English', () {
      for (final wd in TideWeekday.values) {
        final rule = TideRecurrenceRule(
          frequency: TideFrequency.weekly,
          byDay: [TideByDay(weekday: wd)],
        );
        final desc = TideRRuleDescription.describe(rule);
        expect(desc.startsWith('Every week on'), isTrue);
        expect(desc.length > 'Every week on '.length, isTrue);
      }
    });

    test('all weekday names in German', () {
      final expectedNames = [
        'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag',
        'Freitag', 'Samstag', 'Sonntag',
      ];
      for (var i = 0; i < TideWeekday.values.length; i++) {
        final rule = TideRecurrenceRule(
          frequency: TideFrequency.weekly,
          byDay: [TideByDay(weekday: TideWeekday.values[i])],
        );
        final desc = TideRRuleDescription.describe(rule, locale: 'de');
        expect(desc, 'Jede Woche am ${expectedNames[i]}');
      }
    });
  });

  // ─── All month names ──────────────────────────────────────────────

  group('All month names', () {
    test('all month names in English', () {
      final expectedMonths = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      for (var m = 1; m <= 12; m++) {
        final rule = TideRecurrenceRule(
          frequency: TideFrequency.yearly,
          byMonth: [m],
        );
        final desc = TideRRuleDescription.describe(rule);
        expect(desc, 'Every year in ${expectedMonths[m - 1]}');
      }
    });

    test('all month names in German', () {
      final expectedMonths = [
        'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
        'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
      ];
      for (var m = 1; m <= 12; m++) {
        final rule = TideRecurrenceRule(
          frequency: TideFrequency.yearly,
          byMonth: [m],
        );
        final desc = TideRRuleDescription.describe(rule, locale: 'de');
        expect(desc, 'Jedes Jahr im ${expectedMonths[m - 1]}');
      }
    });
  });

  // ─── Fallback locale ──────────────────────────────────────────────

  group('Fallback locale', () {
    test('unknown locale falls back to English', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.daily);
      expect(TideRRuleDescription.describe(rule, locale: 'fr'), 'Every day');
    });
  });

  // ─── Combined rules ──────────────────────────────────────────────

  group('Combined descriptions', () {
    test('weekly MO/WE/FR with COUNT (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        byDay: [
          TideByDay(weekday: TideWeekday.monday),
          TideByDay(weekday: TideWeekday.wednesday),
          TideByDay(weekday: TideWeekday.friday),
        ],
        count: 24,
      );
      expect(
        TideRRuleDescription.describe(rule),
        'Every week on Monday, Wednesday, Friday, 24 times',
      );
    });

    test('monthly 3rd Friday with UNTIL (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.friday, ordinal: 3)],
        until: DateTime(2027, 12, 31),
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Der 3. Freitag jeden Monats, bis 31. Dezember 2027',
      );
    });

    test('every 2 weeks on Mon/Wed with UNTIL (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        interval: 2,
        byDay: [
          TideByDay(weekday: TideWeekday.monday),
          TideByDay(weekday: TideWeekday.wednesday),
        ],
        until: DateTime(2026, 12, 31),
      );
      expect(
        TideRRuleDescription.describe(rule),
        'Every 2 weeks on Monday, Wednesday, until December 31, 2026',
      );
    });

    test('yearly on March 19 with COUNT (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byMonth: [3],
        byMonthDay: [19],
        count: 5,
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Jedes Jahr am 19. März, 5 Mal',
      );
    });
  });

  // ─── 2nd ordinal descriptions ─────────────────────────────────────

  group('2nd ordinal descriptions', () {
    test('the 2nd Monday of every month (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.monday, ordinal: 2)],
      );
      expect(
        TideRRuleDescription.describe(rule),
        'The 2nd Monday of every month',
      );
    });

    test('the 1st Tuesday of every month (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.tuesday, ordinal: 1)],
      );
      expect(
        TideRRuleDescription.describe(rule),
        'The 1st Tuesday of every month',
      );
    });

    test('the second to last Wednesday (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.wednesday, ordinal: -2)],
      );
      expect(
        TideRRuleDescription.describe(rule),
        'The second to last Wednesday of every month',
      );
    });
  });

  // ─── Every N months ───────────────────────────────────────────────

  group('Every N months', () {
    test('every 3 months (en)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        interval: 3,
      );
      expect(TideRRuleDescription.describe(rule), 'Every 3 months');
    });

    test('alle 3 Monate (de)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        interval: 3,
      );
      expect(
        TideRRuleDescription.describe(rule, locale: 'de'),
        'Alle 3 Monate',
      );
    });
  });
}

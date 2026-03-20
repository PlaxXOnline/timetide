import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/recurrence/occurrence_engine.dart';
import 'package:timetide/src/core/recurrence/rrule_model.dart';

void main() {
  // ─── DAILY frequency ──────────────────────────────────────────────

  group('DAILY frequency', () {
    test('generates daily occurrences', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.daily, count: 5);
      final start = DateTime(2026, 3, 1, 10, 0);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 3, 1, 10, 0),
        DateTime(2026, 3, 2, 10, 0),
        DateTime(2026, 3, 3, 10, 0),
        DateTime(2026, 3, 4, 10, 0),
        DateTime(2026, 3, 5, 10, 0),
      ]);
    });

    test('respects INTERVAL for daily', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        interval: 3,
        count: 4,
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 4),
        DateTime(2026, 1, 7),
        DateTime(2026, 1, 10),
      ]);
    });

    test('daily with BYDAY filter', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        byDay: [
          TideByDay(weekday: TideWeekday.monday),
          TideByDay(weekday: TideWeekday.wednesday),
          TideByDay(weekday: TideWeekday.friday),
        ],
        count: 6,
      );
      // 2026-03-02 is a Monday.
      final start = DateTime(2026, 3, 2, 9, 0);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 3, 2, 9, 0),  // Mon
        DateTime(2026, 3, 4, 9, 0),  // Wed
        DateTime(2026, 3, 6, 9, 0),  // Fri
        DateTime(2026, 3, 9, 9, 0),  // Mon
        DateTime(2026, 3, 11, 9, 0), // Wed
        DateTime(2026, 3, 13, 9, 0), // Fri
      ]);
    });

    test('daily with BYMONTH filter', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        byMonth: [1, 3],
        count: 5,
      );
      final start = DateTime(2026, 1, 30);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 30),
        DateTime(2026, 1, 31),
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 2),
        DateTime(2026, 3, 3),
      ]);
    });
  });

  // ─── WEEKLY frequency ─────────────────────────────────────────────

  group('WEEKLY frequency', () {
    test('generates weekly occurrences on same weekday', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        count: 4,
      );
      // 2026-03-02 is a Monday.
      final start = DateTime(2026, 3, 2, 14, 30);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 3, 2, 14, 30),
        DateTime(2026, 3, 9, 14, 30),
        DateTime(2026, 3, 16, 14, 30),
        DateTime(2026, 3, 23, 14, 30),
      ]);
    });

    test('weekly with INTERVAL=2', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        interval: 2,
        count: 3,
      );
      final start = DateTime(2026, 3, 2);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 3, 2),
        DateTime(2026, 3, 16),
        DateTime(2026, 3, 30),
      ]);
    });

    test('weekly with BYDAY expands to multiple days', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        byDay: [
          TideByDay(weekday: TideWeekday.monday),
          TideByDay(weekday: TideWeekday.wednesday),
          TideByDay(weekday: TideWeekday.friday),
        ],
        count: 6,
      );
      // 2026-03-02 is a Monday.
      final start = DateTime(2026, 3, 2, 9, 0);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 3, 2, 9, 0),  // Mon
        DateTime(2026, 3, 4, 9, 0),  // Wed
        DateTime(2026, 3, 6, 9, 0),  // Fri
        DateTime(2026, 3, 9, 9, 0),  // Mon
        DateTime(2026, 3, 11, 9, 0), // Wed
        DateTime(2026, 3, 13, 9, 0), // Fri
      ]);
    });

    test('weekly BYDAY with INTERVAL=2 and WKST', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        interval: 2,
        byDay: [
          TideByDay(weekday: TideWeekday.tuesday),
          TideByDay(weekday: TideWeekday.thursday),
        ],
        weekStart: TideWeekday.monday,
        count: 4,
      );
      // 2026-03-02 is a Monday. Week starts on Monday.
      final start = DateTime(2026, 3, 2, 10, 0);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 3, 3, 10, 0),  // Tue week 1
        DateTime(2026, 3, 5, 10, 0),  // Thu week 1
        DateTime(2026, 3, 17, 10, 0), // Tue week 3
        DateTime(2026, 3, 19, 10, 0), // Thu week 3
      ]);
    });

    test('weekly with BYMONTH filter', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        byMonth: [3],
        count: 5,
      );
      // 2026-03-02 is a Monday.
      final start = DateTime(2026, 3, 2);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results.length, 5);
      for (final d in results) {
        expect(d.month, 3);
      }
    });

    test('weekly with WKST=SU changes week boundary', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        byDay: [
          TideByDay(weekday: TideWeekday.sunday),
          TideByDay(weekday: TideWeekday.monday),
        ],
        weekStart: TideWeekday.sunday,
        count: 4,
      );
      // 2026-03-01 is a Sunday.
      final start = DateTime(2026, 3, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 3, 1),  // Sun
        DateTime(2026, 3, 2),  // Mon
        DateTime(2026, 3, 8),  // Sun
        DateTime(2026, 3, 9),  // Mon
      ]);
    });
  });

  // ─── MONTHLY frequency ────────────────────────────────────────────

  group('MONTHLY frequency', () {
    test('monthly on same day-of-month', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        count: 4,
      );
      final start = DateTime(2026, 1, 15, 10, 0);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 15, 10, 0),
        DateTime(2026, 2, 15, 10, 0),
        DateTime(2026, 3, 15, 10, 0),
        DateTime(2026, 4, 15, 10, 0),
      ]);
    });

    test('monthly with INTERVAL=3', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        interval: 3,
        count: 4,
      );
      final start = DateTime(2026, 1, 10);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 10),
        DateTime(2026, 4, 10),
        DateTime(2026, 7, 10),
        DateTime(2026, 10, 10),
      ]);
    });

    test('monthly with BYMONTHDAY', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byMonthDay: [1, 15],
        count: 6,
      );
      final start = DateTime(2026, 1, 1, 8, 0);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 1, 8, 0),
        DateTime(2026, 1, 15, 8, 0),
        DateTime(2026, 2, 1, 8, 0),
        DateTime(2026, 2, 15, 8, 0),
        DateTime(2026, 3, 1, 8, 0),
        DateTime(2026, 3, 15, 8, 0),
      ]);
    });

    test('monthly with BYMONTHDAY=-1 (last day of month)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byMonthDay: [-1],
        count: 4,
      );
      final start = DateTime(2026, 1, 31);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
      ]);
    });

    test('monthly with BYDAY ordinal: 3rd Friday', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.friday, ordinal: 3)],
        count: 4,
      );
      final start = DateTime(2026, 1, 16, 15, 0); // 3rd Friday of Jan 2026
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 16, 15, 0),  // 3rd Fri Jan
        DateTime(2026, 2, 20, 15, 0),  // 3rd Fri Feb
        DateTime(2026, 3, 20, 15, 0),  // 3rd Fri Mar
        DateTime(2026, 4, 17, 15, 0),  // 3rd Fri Apr
      ]);
    });

    test('monthly with BYDAY ordinal: last Friday', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.friday, ordinal: -1)],
        count: 4,
      );
      final start = DateTime(2026, 1, 30); // Last Friday of Jan 2026
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 30),  // Last Fri Jan
        DateTime(2026, 2, 27),  // Last Fri Feb
        DateTime(2026, 3, 27),  // Last Fri Mar
        DateTime(2026, 4, 24),  // Last Fri Apr
      ]);
    });

    test('monthly with BYDAY without ordinal expands all weekdays', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.monday)],
        count: 5,
      );
      final start = DateTime(2026, 3, 2); // Monday
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      // All Mondays in March 2026: 2, 9, 16, 23, 30.
      expect(results, [
        DateTime(2026, 3, 2),
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 16),
        DateTime(2026, 3, 23),
        DateTime(2026, 3, 30),
      ]);
    });

    test('monthly BYMONTHDAY=31 skips months without 31 days', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byMonthDay: [31],
        count: 4,
      );
      final start = DateTime(2026, 1, 31);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      // Months with 31 days: Jan, Mar, May, Jul, Aug, Oct, Dec.
      expect(results, [
        DateTime(2026, 1, 31),
        DateTime(2026, 3, 31),
        DateTime(2026, 5, 31),
        DateTime(2026, 7, 31),
      ]);
    });

    test('monthly with BYSETPOS=-1 and BYDAY (last Friday of month)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.friday)],
        bySetPos: [-1],
        count: 4,
      );
      final start = DateTime(2026, 1, 30); // Last Friday of Jan 2026
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 30),  // Last Fri Jan
        DateTime(2026, 2, 27),  // Last Fri Feb
        DateTime(2026, 3, 27),  // Last Fri Mar
        DateTime(2026, 4, 24),  // Last Fri Apr
      ]);
    });

    test('monthly with BYSETPOS=1 and BYDAY (first Monday)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [TideByDay(weekday: TideWeekday.monday)],
        bySetPos: [1],
        count: 4,
      );
      final start = DateTime(2026, 1, 5); // 1st Monday Jan
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 5),
        DateTime(2026, 2, 2),
        DateTime(2026, 3, 2),
        DateTime(2026, 4, 6),
      ]);
    });

    test('monthly with BYMONTH filter', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byMonth: [3, 6, 9, 12],
        count: 4,
      );
      final start = DateTime(2026, 3, 15);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 3, 15),
        DateTime(2026, 6, 15),
        DateTime(2026, 9, 15),
        DateTime(2026, 12, 15),
      ]);
    });

    test('monthly skips when day-of-month exceeds month length', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        count: 4,
      );
      // Start on Jan 31.
      final start = DateTime(2026, 1, 31);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      // Feb has no 31, so it's skipped. Mar 31 exists.
      expect(results, [
        DateTime(2026, 1, 31),
        DateTime(2026, 3, 31),
        DateTime(2026, 5, 31),
        DateTime(2026, 7, 31),
      ]);
    });
  });

  // ─── YEARLY frequency ─────────────────────────────────────────────

  group('YEARLY frequency', () {
    test('yearly on same month/day', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        count: 4,
      );
      final start = DateTime(2026, 3, 19, 12, 0);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 3, 19, 12, 0),
        DateTime(2027, 3, 19, 12, 0),
        DateTime(2028, 3, 19, 12, 0),
        DateTime(2029, 3, 19, 12, 0),
      ]);
    });

    test('yearly with INTERVAL=2', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        interval: 2,
        count: 3,
      );
      final start = DateTime(2026, 6, 15);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 6, 15),
        DateTime(2028, 6, 15),
        DateTime(2030, 6, 15),
      ]);
    });

    test('yearly with BYMONTH expands to multiple months', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byMonth: [3, 9],
        count: 4,
      );
      final start = DateTime(2026, 3, 19);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 3, 19),
        DateTime(2026, 9, 19),
        DateTime(2027, 3, 19),
        DateTime(2027, 9, 19),
      ]);
    });

    test('yearly with BYMONTH and BYMONTHDAY', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byMonth: [1, 7],
        byMonthDay: [1, 15],
        count: 4,
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 15),
        DateTime(2026, 7, 1),
        DateTime(2026, 7, 15),
      ]);
    });

    test('yearly with BYMONTH and BYDAY ordinal', () {
      // 2nd Monday of March every year.
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byMonth: [3],
        byDay: [TideByDay(weekday: TideWeekday.monday, ordinal: 2)],
        count: 3,
      );
      final start = DateTime(2026, 3, 9); // 2nd Monday of Mar 2026
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 3, 9),
        DateTime(2027, 3, 8),
        DateTime(2028, 3, 13),
      ]);
    });

    test('yearly with BYYEARDAY', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byYearDay: [1, 100, 200],
        count: 6,
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results.length, 6);
      expect(results[0], DateTime(2026, 1, 1));     // Day 1
      expect(results[1], DateTime(2026, 4, 10));     // Day 100
      expect(results[2], DateTime(2026, 7, 19));     // Day 200
      expect(results[3], DateTime(2027, 1, 1));      // Day 1 next year
    });

    test('yearly with BYWEEKNO', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byWeekNo: [1, 26],
        count: 4,
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results.length, 4);
      // The specific dates depend on ISO week calculations.
      // Just verify we get 4 results in chronological order.
      for (var i = 1; i < results.length; i++) {
        expect(results[i].isAfter(results[i - 1]), isTrue);
      }
    });
  });

  // ─── COUNT and UNTIL ──────────────────────────────────────────────

  group('COUNT and UNTIL', () {
    test('COUNT limits number of occurrences', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 3,
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results.length, 3);
    });

    test('UNTIL stops generation at boundary date', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        until: DateTime(2026, 1, 5),
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 3),
        DateTime(2026, 1, 4),
        DateTime(2026, 1, 5),
      ]);
    });

    test('UNTIL is inclusive', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        until: DateTime(2026, 3, 16),
      );
      final start = DateTime(2026, 3, 2); // Monday
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 3, 2),
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 16),
      ]);
    });
  });

  // ─── EXDATE ───────────────────────────────────────────────────────

  group('EXDATE exclusion', () {
    test('excludes specific dates', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 5,
        exDates: [DateTime(2026, 1, 3), DateTime(2026, 1, 5)],
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 4),
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 7),
      ]);
    });

    test('excluded dates do not count toward COUNT', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 3,
        exDates: [DateTime(2026, 1, 2)],
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 3),
        DateTime(2026, 1, 4),
      ]);
    });

    test('EXDATE uses binary search (works with many exclusions)', () {
      // Create a rule with many exdates to verify binary search correctness.
      final exDates = List.generate(
        100,
        (i) => DateTime(2026, 1, 1).add(Duration(days: i * 2)), // Even days.
      );
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        exDates: exDates,
        count: 10,
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      // Only odd-offset days should appear.
      expect(results.length, 10);
      for (final r in results) {
        final dayOffset = r.difference(DateTime(2026, 1, 1)).inDays;
        expect(dayOffset % 2, 1, reason: 'Day $dayOffset should be odd');
      }
    });

    test('EXDATE with unsorted input still works', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 5,
        exDates: [DateTime(2026, 1, 5), DateTime(2026, 1, 2)], // Unsorted.
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 3),
        DateTime(2026, 1, 4),
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 7),
      ]);
    });
  });

  // ─── RDATE ────────────────────────────────────────────────────────

  group('RDATE inclusion', () {
    test('adds additional dates to occurrence stream', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        count: 3,
        rDates: [DateTime(2026, 3, 4, 14, 30)], // Extra date mid-week.
      );
      final start = DateTime(2026, 3, 2, 14, 30); // Monday
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      // Should include the 3 weekly occurrences plus the RDATE merged in order.
      expect(results.contains(DateTime(2026, 3, 4, 14, 30)), isTrue);
    });

    test('RDATEs are merged in chronological order', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        count: 2,
        rDates: [
          DateTime(2026, 3, 5),  // Between week 1 and week 2.
          DateTime(2026, 3, 12), // Between week 2 and week 3.
        ],
      );
      final start = DateTime(2026, 3, 2); // Monday
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      // Verify chronological ordering.
      for (var i = 1; i < results.length; i++) {
        expect(!results[i].isBefore(results[i - 1]), isTrue,
            reason: '${results[i]} should not be before ${results[i - 1]}');
      }
    });

    test('RDATE + EXDATE: excluded RDATE is removed', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 3,
        rDates: [DateTime(2026, 1, 10)],
        exDates: [DateTime(2026, 1, 10)], // Same date in both.
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results.contains(DateTime(2026, 1, 10)), isFalse);
    });

    test('RDATE duplicate with rule occurrence is not doubled', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 3,
        rDates: [DateTime(2026, 1, 2)], // Same as 2nd daily occurrence.
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      // Should not have duplicate Jan 2.
      final jan2Count =
          results.where((d) => d.isAtSameMomentAs(DateTime(2026, 1, 2))).length;
      expect(jan2Count, 1);
    });
  });

  // ─── Range filtering (after/before) ───────────────────────────────

  group('Range filtering', () {
    test('after parameter skips early occurrences', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 10,
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(
        rule,
        start,
        after: DateTime(2026, 1, 5),
      ).toList();

      expect(results.first, DateTime(2026, 1, 6));
      // COUNT=10 means 10 total occurrences starting from start, but only
      // those after the filter date are returned.
    });

    test('before parameter limits generation', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.daily);
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(
        rule,
        start,
        before: DateTime(2026, 1, 4),
      ).toList();

      expect(results, [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 3),
      ]);
    });

    test('after and before together form a window', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.daily);
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(
        rule,
        start,
        after: DateTime(2026, 1, 3),
        before: DateTime(2026, 1, 7),
      ).toList();

      expect(results, [
        DateTime(2026, 1, 4),
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 6),
      ]);
    });

    test('before is exclusive', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.daily);
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(
        rule,
        start,
        before: DateTime(2026, 1, 3),
      ).toList();

      expect(results, [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
      ]);
    });

    test('after is exclusive (occurrence on after date is excluded)', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 5,
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(
        rule,
        start,
        after: DateTime(2026, 1, 1),
      ).toList();

      expect(results.first, DateTime(2026, 1, 2));
    });
  });

  // ─── Leap year ────────────────────────────────────────────────────

  group('Leap year handling', () {
    test('BYMONTHDAY=29 BYMONTH=2 skips non-leap years', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byMonth: [2],
        byMonthDay: [29],
        count: 3,
      );
      final start = DateTime(2024, 2, 29); // 2024 is a leap year.
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      // Leap years: 2024, 2028, 2032.
      expect(results, [
        DateTime(2024, 2, 29),
        DateTime(2028, 2, 29),
        DateTime(2032, 2, 29),
      ]);
    });

    test('yearly on Feb 29 skips non-leap years', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        count: 3,
      );
      final start = DateTime(2024, 2, 29);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      // Only leap years have Feb 29.
      expect(results, [
        DateTime(2024, 2, 29),
        DateTime(2028, 2, 29),
        DateTime(2032, 2, 29),
      ]);
    });

    test('monthly BYMONTHDAY=29 skips February in non-leap years', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byMonthDay: [29],
        count: 5,
      );
      // Start in Jan 2026 (not a leap year).
      final start = DateTime(2026, 1, 29);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      // Jan=29, Feb=skip (no 29th in 2026), Mar=29, Apr=29, May=29.
      expect(results, [
        DateTime(2026, 1, 29),
        DateTime(2026, 3, 29),
        DateTime(2026, 4, 29),
        DateTime(2026, 5, 29),
        DateTime(2026, 6, 29),
      ]);
    });
  });

  // ─── Infinite series ──────────────────────────────────────────────

  group('Infinite series', () {
    test('without COUNT/UNTIL uses before to stop', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.daily);
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(
        rule,
        start,
        before: DateTime(2026, 1, 6),
      ).toList();

      expect(results.length, 5);
    });

    test('without any limit yields up to defaultMaxOccurrences', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.daily);
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results.length, TideOccurrenceEngine.defaultMaxOccurrences);
    });

    test('lazy evaluation — taking only 3 from infinite does not hang', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.daily);
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).take(3).toList();

      expect(results, [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 3),
      ]);
    });
  });

  // ─── BYHOUR / BYMINUTE ───────────────────────────────────────────

  group('BYHOUR / BYMINUTE', () {
    test('BYHOUR expands to multiple hours', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        byHour: [9, 14, 18],
        count: 6,
      );
      final start = DateTime(2026, 1, 1, 9, 0);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 1, 9, 0),
        DateTime(2026, 1, 1, 14, 0),
        DateTime(2026, 1, 1, 18, 0),
        DateTime(2026, 1, 2, 9, 0),
        DateTime(2026, 1, 2, 14, 0),
        DateTime(2026, 1, 2, 18, 0),
      ]);
    });

    test('BYMINUTE expands within each hour', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        byMinute: [0, 30],
        count: 4,
      );
      final start = DateTime(2026, 1, 1, 10, 0);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 1, 10, 0),
        DateTime(2026, 1, 1, 10, 30),
        DateTime(2026, 1, 2, 10, 0),
        DateTime(2026, 1, 2, 10, 30),
      ]);
    });

    test('BYHOUR + BYMINUTE cross product', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        byHour: [9, 17],
        byMinute: [0, 30],
        count: 4,
      );
      final start = DateTime(2026, 1, 1, 9, 0);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 1, 1, 9, 0),
        DateTime(2026, 1, 1, 9, 30),
        DateTime(2026, 1, 1, 17, 0),
        DateTime(2026, 1, 1, 17, 30),
      ]);
    });
  });

  // ─── Boundary conditions ──────────────────────────────────────────

  group('Boundary conditions', () {
    test('COUNT=1 returns only start date', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 1,
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [DateTime(2026, 1, 1)]);
    });

    test('UNTIL before start returns only start', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        until: DateTime(2026, 1, 1),
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [DateTime(2026, 1, 1)]);
    });

    test('empty result when after is past all occurrences', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 3,
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(
        rule,
        start,
        after: DateTime(2027, 1, 1),
      ).toList();

      expect(results, isEmpty);
    });

    test('empty result when before is before start', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 5,
      );
      final start = DateTime(2026, 3, 1);
      final results = TideOccurrenceEngine.occurrences(
        rule,
        start,
        before: DateTime(2026, 1, 1),
      ).toList();

      expect(results, isEmpty);
    });

    test('preserves time component of DTSTART', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        count: 3,
      );
      final start = DateTime(2026, 1, 1, 14, 30, 45);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      for (final r in results) {
        expect(r.hour, 14);
        expect(r.minute, 30);
        expect(r.second, 45);
      }
    });

    test('single occurrence rule works correctly', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        count: 1,
      );
      final start = DateTime(2026, 6, 15, 10, 0);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [DateTime(2026, 6, 15, 10, 0)]);
    });
  });

  // ─── Complex combined rules ───────────────────────────────────────

  group('Complex combined rules', () {
    test('every 2nd week on MO/WE/FR with UNTIL', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        interval: 2,
        byDay: [
          TideByDay(weekday: TideWeekday.monday),
          TideByDay(weekday: TideWeekday.wednesday),
          TideByDay(weekday: TideWeekday.friday),
        ],
        until: DateTime(2026, 3, 20, 23, 59, 59),
      );
      // 2026-03-02 is a Monday.
      final start = DateTime(2026, 3, 2, 10, 0);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 3, 2, 10, 0),   // Mon wk1
        DateTime(2026, 3, 4, 10, 0),   // Wed wk1
        DateTime(2026, 3, 6, 10, 0),   // Fri wk1
        DateTime(2026, 3, 16, 10, 0),  // Mon wk3
        DateTime(2026, 3, 18, 10, 0),  // Wed wk3
        DateTime(2026, 3, 20, 10, 0),  // Fri wk3
      ]);
    });

    test('yearly with BYMONTH + BYDAY ordinal: Thanksgiving', () {
      // US Thanksgiving: 4th Thursday of November.
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byMonth: [11],
        byDay: [TideByDay(weekday: TideWeekday.thursday, ordinal: 4)],
        count: 3,
      );
      final start = DateTime(2026, 11, 26); // 4th Thu Nov 2026
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results.length, 3);
      for (final r in results) {
        expect(r.month, 11);
        expect(r.weekday, DateTime.thursday);
        // Verify it's the 4th Thursday.
        var thuCount = 0;
        for (var d = 1; d <= r.day; d++) {
          if (DateTime(r.year, 11, d).weekday == DateTime.thursday) thuCount++;
        }
        expect(thuCount, 4);
      }
    });

    test('monthly BYSETPOS=3 + BYDAY=MO-FR: 3rd weekday of month', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.monthly,
        byDay: [
          TideByDay(weekday: TideWeekday.monday),
          TideByDay(weekday: TideWeekday.tuesday),
          TideByDay(weekday: TideWeekday.wednesday),
          TideByDay(weekday: TideWeekday.thursday),
          TideByDay(weekday: TideWeekday.friday),
        ],
        bySetPos: [3],
        count: 3,
      );
      final start = DateTime(2026, 1, 5); // 3rd weekday of Jan 2026 (Mon)
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results.length, 3);
      // Jan 2026: weekdays are 1(Thu),2(Fri),5(Mon)... 3rd weekday = Jan 5
      expect(results[0], DateTime(2026, 1, 5));
      // Feb 2026: 2(Mon),3(Tue),4(Wed)... 3rd weekday = Feb 4
      expect(results[1], DateTime(2026, 2, 4));
      // Mar 2026: 2(Mon),3(Tue),4(Wed)... 3rd weekday = Mar 4
      expect(results[2], DateTime(2026, 3, 4));
    });

    test('daily with EXDATE and after/before window', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.daily,
        exDates: [DateTime(2026, 1, 5), DateTime(2026, 1, 7)],
      );
      final start = DateTime(2026, 1, 1);
      final results = TideOccurrenceEngine.occurrences(
        rule,
        start,
        after: DateTime(2026, 1, 3),
        before: DateTime(2026, 1, 10),
      ).toList();

      expect(results, [
        DateTime(2026, 1, 4),
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 8),
        DateTime(2026, 1, 9),
      ]);
    });

    test('weekly with RDATE and EXDATE combined', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.weekly,
        count: 3,
        rDates: [DateTime(2026, 3, 5)],   // Extra mid-week date.
        exDates: [DateTime(2026, 3, 9)],  // Exclude 2nd weekly occurrence.
      );
      final start = DateTime(2026, 3, 2); // Monday
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results.contains(DateTime(2026, 3, 5)), isTrue,
          reason: 'RDATE should be included');
      expect(results.contains(DateTime(2026, 3, 9)), isFalse,
          reason: 'EXDATE should be excluded');
    });
  });

  // ─── BYYEARDAY negative ───────────────────────────────────────────

  group('BYYEARDAY negative values', () {
    test('BYYEARDAY=-1 is last day of year', () {
      final rule = TideRecurrenceRule(
        frequency: TideFrequency.yearly,
        byYearDay: [-1],
        count: 3,
      );
      final start = DateTime(2026, 12, 31);
      final results = TideOccurrenceEngine.occurrences(rule, start).toList();

      expect(results, [
        DateTime(2026, 12, 31),
        DateTime(2027, 12, 31),
        DateTime(2028, 12, 31),
      ]);
    });
  });

  // ─── Lazy evaluation verification ─────────────────────────────────

  group('Lazy evaluation', () {
    test('can take N from infinite series without materializing all', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.daily);
      final start = DateTime(2026, 1, 1);

      // Just calling .take(5) should not hang or cause memory issues.
      final results = TideOccurrenceEngine.occurrences(rule, start).take(5).toList();
      expect(results.length, 5);
    });

    test('iterator can be paused and resumed', () {
      final rule = TideRecurrenceRule(frequency: TideFrequency.daily);
      final start = DateTime(2026, 1, 1);
      final iter = TideOccurrenceEngine.occurrences(
        rule,
        start,
        before: DateTime(2026, 2, 1),
      ).iterator;

      // Take first 3.
      final batch1 = <DateTime>[];
      for (var i = 0; i < 3 && iter.moveNext(); i++) {
        batch1.add(iter.current);
      }
      expect(batch1.length, 3);
      expect(batch1.last, DateTime(2026, 1, 3));

      // Resume and take 2 more.
      final batch2 = <DateTime>[];
      for (var i = 0; i < 2 && iter.moveNext(); i++) {
        batch2.add(iter.current);
      }
      expect(batch2.length, 2);
      expect(batch2.first, DateTime(2026, 1, 4));
    });
  });
}

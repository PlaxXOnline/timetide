import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/widgets/shift_planner/closed_day_predicate.dart';

void main() {
  group('isDayClosed', () {
    // A Monday in 2026 used as a baseline working day.
    final monday = DateTime(2026, 1, 5); // Monday
    final tuesday = DateTime(2026, 1, 6);
    final saturday = DateTime(2026, 1, 3);
    final sunday = DateTime(2026, 1, 4);

    test('returns false for any day when no sources are provided', () {
      expect(isDayClosed(monday), isFalse);
      expect(isDayClosed(saturday), isFalse);
      expect(isDayClosed(sunday), isFalse);
      expect(
        isDayClosed(monday, daysOfWeek: const {}, dates: const {}),
        isFalse,
      );
    });

    test('marks the configured weekday as closed via daysOfWeek', () {
      final closed = isDayClosed(
        sunday,
        daysOfWeek: const {DateTime.sunday},
      );
      final open = isDayClosed(
        monday,
        daysOfWeek: const {DateTime.sunday},
      );
      expect(closed, isTrue);
      expect(open, isFalse);
    });

    test('handles multiple weekdays in daysOfWeek', () {
      const daysOfWeek = {DateTime.saturday, DateTime.sunday};
      expect(isDayClosed(saturday, daysOfWeek: daysOfWeek), isTrue);
      expect(isDayClosed(sunday, daysOfWeek: daysOfWeek), isTrue);
      expect(isDayClosed(monday, daysOfWeek: daysOfWeek), isFalse);
      expect(isDayClosed(tuesday, daysOfWeek: daysOfWeek), isFalse);
    });

    test('marks specific dates as closed (midnight)', () {
      final christmas = DateTime(2026, 12, 25);
      final christmasEve = DateTime(2026, 12, 24);
      expect(isDayClosed(christmas, dates: {christmas}), isTrue);
      expect(isDayClosed(christmasEve, dates: {christmas}), isFalse);
    });

    test('ignores time component when comparing against dates', () {
      final christmas = DateTime(2026, 12, 25);
      final christmasAfternoon = DateTime(2026, 12, 25, 14, 30);
      final christmasLateNight = DateTime(2026, 12, 25, 23, 59, 59, 999);
      expect(
        isDayClosed(christmasAfternoon, dates: {christmas}),
        isTrue,
      );
      expect(
        isDayClosed(christmasLateNight, dates: {christmas}),
        isTrue,
      );
    });

    test('treats date-set entries with time components as the same day', () {
      final entryWithTime = DateTime(2026, 12, 25, 14, 30);
      final query = DateTime(2026, 12, 25);
      expect(isDayClosed(query, dates: {entryWithTime}), isTrue);
    });

    test('uses custom predicate when supplied', () {
      bool august(DateTime d) => d.month == DateTime.august;
      expect(
        isDayClosed(DateTime(2026, 8, 15), predicate: august),
        isTrue,
      );
      expect(
        isDayClosed(DateTime(2026, 7, 31), predicate: august),
        isFalse,
      );
      expect(
        isDayClosed(DateTime(2026, 9, 1), predicate: august),
        isFalse,
      );
    });

    test('combines all three sources with OR semantics', () {
      const daysOfWeek = {DateTime.sunday};
      final dates = {DateTime(2026, 12, 25)};
      bool august(DateTime d) => d.month == DateTime.august;

      // Only daysOfWeek matches.
      expect(
        isDayClosed(
          sunday,
          daysOfWeek: daysOfWeek,
          dates: dates,
          predicate: august,
        ),
        isTrue,
      );

      // Only dates matches (Friday 25.12.2026).
      expect(
        isDayClosed(
          DateTime(2026, 12, 25),
          daysOfWeek: daysOfWeek,
          dates: dates,
          predicate: august,
        ),
        isTrue,
      );

      // Only predicate matches (a Monday in August).
      expect(
        isDayClosed(
          DateTime(2026, 8, 3),
          daysOfWeek: daysOfWeek,
          dates: dates,
          predicate: august,
        ),
        isTrue,
      );

      // None matches → open.
      expect(
        isDayClosed(
          DateTime(2026, 1, 6), // Tuesday in January, not Christmas.
          daysOfWeek: daysOfWeek,
          dates: dates,
          predicate: august,
        ),
        isFalse,
      );
    });
  });
}

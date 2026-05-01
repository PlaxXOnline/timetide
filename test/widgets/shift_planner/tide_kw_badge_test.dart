import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/l10n/tide_localizations.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/widgets/shift_planner/tide_kw_badge.dart';

void main() {
  group('isoWeekNumber', () {
    test('2026-01-01 (Thursday) is week 1', () {
      expect(isoWeekNumber(DateTime(2026, 1, 1)), 1);
    });

    test('2026-01-04 (Sunday) is week 1', () {
      // Week starts Monday 2025-12-29, contains Thursday 2026-01-01.
      expect(isoWeekNumber(DateTime(2026, 1, 4)), 1);
    });

    test('2026-01-05 (Monday) is week 2', () {
      expect(isoWeekNumber(DateTime(2026, 1, 5)), 2);
    });

    test('2025-12-29 belongs to ISO week 1 of 2026 (year boundary)', () {
      // ISO weeks are owned by the year of the Thursday in that week.
      // 2025-12-29 (Mon) → Thu = 2026-01-01 → week 1.
      expect(isoWeekNumber(DateTime(2025, 12, 29)), 1);
    });

    test('2026-12-28 (Monday) is week 53', () {
      // 2026 starts on a Thursday (and is a non-leap year), which is one of
      // the canonical conditions for a 53-week ISO year.
      expect(isoWeekNumber(DateTime(2026, 12, 28)), 53);
    });

    test('2020-12-28 (Monday) is week 53 (leap-year boundary)', () {
      // 2020 was a leap year starting on Wednesday → 53 ISO weeks.
      expect(isoWeekNumber(DateTime(2020, 12, 28)), 53);
    });

    test('2021-01-03 (Sunday) is week 53 of 2020', () {
      // The week containing Thu 2020-12-31 is the last week of 2020.
      expect(isoWeekNumber(DateTime(2021, 1, 3)), 53);
    });

    test('2021-01-04 (Monday) is week 1 of 2021', () {
      expect(isoWeekNumber(DateTime(2021, 1, 4)), 1);
    });
  });

  group('TideKwBadge', () {
    Widget wrap(Widget child, {TideThemeData? theme}) {
      final widget = Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      );
      if (theme == null) return widget;
      return TideTheme(data: theme, child: widget);
    }

    testWidgets('renders the ISO week number using English locale by default',
        (tester) async {
      // 2026-03-23 is the Monday of ISO week 13.
      await tester.pumpWidget(
        wrap(
          TideKwBadge(weekStart: DateTime(2026, 3, 23)),
          theme: const TideThemeData(),
        ),
      );

      expect(find.text('Week 13'), findsOneWidget);
    });

    testWidgets('renders localized week label when a German locale is supplied',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          TideKwBadge(
            weekStart: DateTime(2026, 3, 23),
            locale: TideLocalizations.de(),
          ),
          theme: const TideThemeData(),
        ),
      );

      expect(find.text('KW 13'), findsOneWidget);
    });

    testWidgets(
        'uses theme.shiftPlannerColumnHeaderTextStyle when no style is supplied',
        (tester) async {
      const themed = TextStyle(
        fontSize: 99,
        fontWeight: FontWeight.w700,
        color: Color(0xFF112233),
      );
      final theme = const TideThemeData()
          .copyWith(shiftPlannerColumnHeaderTextStyle: themed);

      await tester.pumpWidget(
        wrap(
          TideKwBadge(weekStart: DateTime(2026, 3, 23)),
          theme: theme,
        ),
      );

      final text = tester.widget<Text>(find.text('Week 13'));
      expect(text.style, themed);
    });

    testWidgets('explicit style overrides the theme style', (tester) async {
      const override = TextStyle(
        fontSize: 42,
        fontStyle: FontStyle.italic,
        color: Color(0xFFAA00AA),
      );

      await tester.pumpWidget(
        wrap(
          TideKwBadge(
            weekStart: DateTime(2026, 3, 23),
            style: override,
          ),
          theme: const TideThemeData(),
        ),
      );

      final text = tester.widget<Text>(find.text('Week 13'));
      expect(text.style, override);
    });

    testWidgets('renders without crashing when no TideTheme ancestor is present',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideKwBadge(weekStart: DateTime(2026, 3, 23)),
        ),
      );

      expect(find.text('Week 13'), findsOneWidget);

      // Falls back to default theme's shiftPlannerColumnHeaderTextStyle.
      final text = tester.widget<Text>(find.text('Week 13'));
      expect(
        text.style,
        const TideThemeData().shiftPlannerColumnHeaderTextStyle,
      );
    });
  });
}

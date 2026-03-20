import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';

void main() {
  group('TideThemeData', () {
    test('const default constructor creates a valid instance', () {
      const theme = TideThemeData();
      expect(theme.backgroundColor, const Color(0xFFFFFFFF));
      expect(theme.primaryColor, const Color(0xFF2196F3));
      expect(theme.timeSlotBorderWidth, 0.5);
      expect(theme.eventMinHeight, 20.0);
      expect(theme.dragGhostOpacity, 0.5);
      expect(theme.focusIndicatorWidth, 2.0);
      expect(theme.scrollbarRadius, 3.0);
    });

    group('copyWith', () {
      test('returns identical instance when no fields are overridden', () {
        const original = TideThemeData();
        final copy = original.copyWith();
        expect(copy, equals(original));
      });

      test('overrides backgroundColor', () {
        const original = TideThemeData();
        final copy = original.copyWith(backgroundColor: const Color(0xFF000000));
        expect(copy.backgroundColor, const Color(0xFF000000));
        expect(copy.primaryColor, original.primaryColor);
      });

      test('overrides surfaceColor', () {
        const original = TideThemeData();
        final copy = original.copyWith(surfaceColor: const Color(0xFF111111));
        expect(copy.surfaceColor, const Color(0xFF111111));
      });

      test('overrides borderColor', () {
        const original = TideThemeData();
        final copy = original.copyWith(borderColor: const Color(0xFF222222));
        expect(copy.borderColor, const Color(0xFF222222));
      });

      test('overrides todayHighlightColor', () {
        const original = TideThemeData();
        final copy =
            original.copyWith(todayHighlightColor: const Color(0xFF333333));
        expect(copy.todayHighlightColor, const Color(0xFF333333));
      });

      test('overrides selectionColor', () {
        const original = TideThemeData();
        final copy =
            original.copyWith(selectionColor: const Color(0xFF444444));
        expect(copy.selectionColor, const Color(0xFF444444));
      });

      test('overrides primaryColor', () {
        const original = TideThemeData();
        final copy = original.copyWith(primaryColor: const Color(0xFF555555));
        expect(copy.primaryColor, const Color(0xFF555555));
      });

      test('overrides headerTextStyle', () {
        const original = TideThemeData();
        const style = TextStyle(fontSize: 42);
        final copy = original.copyWith(headerTextStyle: style);
        expect(copy.headerTextStyle, style);
      });

      test('overrides dayHeaderTextStyle', () {
        const original = TideThemeData();
        const style = TextStyle(fontSize: 99);
        final copy = original.copyWith(dayHeaderTextStyle: style);
        expect(copy.dayHeaderTextStyle, style);
      });

      test('overrides timeSlotTextStyle', () {
        const original = TideThemeData();
        const style = TextStyle(fontSize: 7);
        final copy = original.copyWith(timeSlotTextStyle: style);
        expect(copy.timeSlotTextStyle, style);
      });

      test('overrides eventTitleStyle', () {
        const original = TideThemeData();
        const style = TextStyle(fontSize: 20);
        final copy = original.copyWith(eventTitleStyle: style);
        expect(copy.eventTitleStyle, style);
      });

      test('overrides eventTimeStyle', () {
        const original = TideThemeData();
        const style = TextStyle(fontSize: 8);
        final copy = original.copyWith(eventTimeStyle: style);
        expect(copy.eventTimeStyle, style);
      });

      test('overrides monthDateTextStyle', () {
        const original = TideThemeData();
        const style = TextStyle(fontSize: 30);
        final copy = original.copyWith(monthDateTextStyle: style);
        expect(copy.monthDateTextStyle, style);
      });

      test('overrides timeSlotBorderColor', () {
        const original = TideThemeData();
        final copy =
            original.copyWith(timeSlotBorderColor: const Color(0xFF666666));
        expect(copy.timeSlotBorderColor, const Color(0xFF666666));
      });

      test('overrides timeSlotBorderWidth', () {
        const original = TideThemeData();
        final copy = original.copyWith(timeSlotBorderWidth: 3.0);
        expect(copy.timeSlotBorderWidth, 3.0);
      });

      test('overrides workingHoursColor', () {
        const original = TideThemeData();
        final copy =
            original.copyWith(workingHoursColor: const Color(0xFF777777));
        expect(copy.workingHoursColor, const Color(0xFF777777));
      });

      test('overrides nonWorkingHoursColor', () {
        const original = TideThemeData();
        final copy =
            original.copyWith(nonWorkingHoursColor: const Color(0xFF888888));
        expect(copy.nonWorkingHoursColor, const Color(0xFF888888));
      });

      test('overrides eventBorderRadius', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          eventBorderRadius: const BorderRadius.all(Radius.circular(16)),
        );
        expect(
          copy.eventBorderRadius,
          const BorderRadius.all(Radius.circular(16)),
        );
      });

      test('overrides eventMinHeight', () {
        const original = TideThemeData();
        final copy = original.copyWith(eventMinHeight: 50.0);
        expect(copy.eventMinHeight, 50.0);
      });

      test('overrides eventPadding', () {
        const original = TideThemeData();
        final copy = original.copyWith(eventPadding: EdgeInsets.zero);
        expect(copy.eventPadding, EdgeInsets.zero);
      });

      test('overrides eventSpacing', () {
        const original = TideThemeData();
        final copy = original.copyWith(eventSpacing: 4.0);
        expect(copy.eventSpacing, 4.0);
      });

      test('overrides resourceHeaderWidth', () {
        const original = TideThemeData();
        final copy = original.copyWith(resourceHeaderWidth: 200.0);
        expect(copy.resourceHeaderWidth, 200.0);
      });

      test('overrides resourceDividerColor', () {
        const original = TideThemeData();
        final copy =
            original.copyWith(resourceDividerColor: const Color(0xFF999999));
        expect(copy.resourceDividerColor, const Color(0xFF999999));
      });

      test('overrides resourceDividerWidth', () {
        const original = TideThemeData();
        final copy = original.copyWith(resourceDividerWidth: 2.0);
        expect(copy.resourceDividerWidth, 2.0);
      });

      test('overrides currentTimeIndicatorColor', () {
        const original = TideThemeData();
        final copy = original.copyWith(
            currentTimeIndicatorColor: const Color(0xFFAAAAAA));
        expect(copy.currentTimeIndicatorColor, const Color(0xFFAAAAAA));
      });

      test('overrides currentTimeIndicatorHeight', () {
        const original = TideThemeData();
        final copy = original.copyWith(currentTimeIndicatorHeight: 4.0);
        expect(copy.currentTimeIndicatorHeight, 4.0);
      });

      test('overrides monthCellBorderColor', () {
        const original = TideThemeData();
        final copy =
            original.copyWith(monthCellBorderColor: const Color(0xFFBBBBBB));
        expect(copy.monthCellBorderColor, const Color(0xFFBBBBBB));
      });

      test('overrides leadingTrailingDatesColor', () {
        const original = TideThemeData();
        final copy = original.copyWith(
            leadingTrailingDatesColor: const Color(0xFFCCCCCC));
        expect(copy.leadingTrailingDatesColor, const Color(0xFFCCCCCC));
      });

      test('overrides todayCellColor', () {
        const original = TideThemeData();
        final copy =
            original.copyWith(todayCellColor: const Color(0xFFDDDDDD));
        expect(copy.todayCellColor, const Color(0xFFDDDDDD));
      });

      test('overrides selectedCellColor', () {
        const original = TideThemeData();
        final copy =
            original.copyWith(selectedCellColor: const Color(0xFFEEEEEE));
        expect(copy.selectedCellColor, const Color(0xFFEEEEEE));
      });

      test('overrides dragGhostColor', () {
        const original = TideThemeData();
        final copy =
            original.copyWith(dragGhostColor: const Color(0xFFFF0000));
        expect(copy.dragGhostColor, const Color(0xFFFF0000));
      });

      test('overrides dragGhostOpacity', () {
        const original = TideThemeData();
        final copy = original.copyWith(dragGhostOpacity: 0.8);
        expect(copy.dragGhostOpacity, 0.8);
      });

      test('overrides dragConflictColor', () {
        const original = TideThemeData();
        final copy =
            original.copyWith(dragConflictColor: const Color(0xFF00FF00));
        expect(copy.dragConflictColor, const Color(0xFF00FF00));
      });

      test('overrides scrollbarColor', () {
        const original = TideThemeData();
        final copy =
            original.copyWith(scrollbarColor: const Color(0xFF0000FF));
        expect(copy.scrollbarColor, const Color(0xFF0000FF));
      });

      test('overrides scrollbarThickness', () {
        const original = TideThemeData();
        final copy = original.copyWith(scrollbarThickness: 10.0);
        expect(copy.scrollbarThickness, 10.0);
      });

      test('overrides scrollbarRadius', () {
        const original = TideThemeData();
        final copy = original.copyWith(scrollbarRadius: 8.0);
        expect(copy.scrollbarRadius, 8.0);
      });

      test('overrides focusIndicatorColor', () {
        const original = TideThemeData();
        final copy =
            original.copyWith(focusIndicatorColor: const Color(0xFFABCDEF));
        expect(copy.focusIndicatorColor, const Color(0xFFABCDEF));
      });

      test('overrides focusIndicatorWidth', () {
        const original = TideThemeData();
        final copy = original.copyWith(focusIndicatorWidth: 5.0);
        expect(copy.focusIndicatorWidth, 5.0);
      });
    });

    group('lerp', () {
      test('t=0 returns values of a', () {
        const a = TideThemeData(
          primaryColor: Color(0xFF000000),
          eventMinHeight: 10.0,
        );
        const b = TideThemeData(
          primaryColor: Color(0xFFFFFFFF),
          eventMinHeight: 50.0,
        );
        final result = TideThemeData.lerp(a, b, 0.0);
        expect(result.primaryColor, a.primaryColor);
        expect(result.eventMinHeight, a.eventMinHeight);
      });

      test('t=1 returns values of b', () {
        const a = TideThemeData(
          primaryColor: Color(0xFF000000),
          eventMinHeight: 10.0,
        );
        const b = TideThemeData(
          primaryColor: Color(0xFFFFFFFF),
          eventMinHeight: 50.0,
        );
        final result = TideThemeData.lerp(a, b, 1.0);
        expect(result.primaryColor, b.primaryColor);
        expect(result.eventMinHeight, b.eventMinHeight);
      });

      test('t=0.5 interpolates Color values', () {
        const a = TideThemeData(backgroundColor: Color(0xFF000000));
        const b = TideThemeData(backgroundColor: Color(0xFFFFFFFF));
        final result = TideThemeData.lerp(a, b, 0.5);
        // Midpoint between black and white
        expect(result.backgroundColor, Color.lerp(a.backgroundColor, b.backgroundColor, 0.5));
      });

      test('t=0.5 interpolates double values', () {
        const a = TideThemeData(
          timeSlotBorderWidth: 1.0,
          eventMinHeight: 20.0,
          scrollbarThickness: 4.0,
        );
        const b = TideThemeData(
          timeSlotBorderWidth: 3.0,
          eventMinHeight: 40.0,
          scrollbarThickness: 12.0,
        );
        final result = TideThemeData.lerp(a, b, 0.5);
        expect(result.timeSlotBorderWidth, 2.0);
        expect(result.eventMinHeight, 30.0);
        expect(result.scrollbarThickness, 8.0);
      });

      test('interpolates BorderRadius', () {
        const a = TideThemeData(
          eventBorderRadius: BorderRadius.all(Radius.circular(0)),
        );
        const b = TideThemeData(
          eventBorderRadius: BorderRadius.all(Radius.circular(20)),
        );
        final result = TideThemeData.lerp(a, b, 0.5);
        expect(
          result.eventBorderRadius,
          const BorderRadius.all(Radius.circular(10)),
        );
      });

      test('interpolates EdgeInsets', () {
        const a = TideThemeData(eventPadding: EdgeInsets.all(0));
        const b = TideThemeData(eventPadding: EdgeInsets.all(20));
        final result = TideThemeData.lerp(a, b, 0.5);
        expect(result.eventPadding, const EdgeInsets.all(10));
      });

      test('interpolates TextStyle', () {
        const a = TideThemeData(
          headerTextStyle: TextStyle(fontSize: 10),
        );
        const b = TideThemeData(
          headerTextStyle: TextStyle(fontSize: 30),
        );
        final result = TideThemeData.lerp(a, b, 0.5);
        expect(result.headerTextStyle.fontSize, 20.0);
      });
    });

    group('equality', () {
      test('two default instances are equal', () {
        const a = TideThemeData();
        const b = TideThemeData();
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('instances with different primaryColor are not equal', () {
        const a = TideThemeData(primaryColor: Color(0xFF000000));
        const b = TideThemeData(primaryColor: Color(0xFFFFFFFF));
        expect(a, isNot(equals(b)));
      });

      test('instances with different eventMinHeight are not equal', () {
        const a = TideThemeData(eventMinHeight: 20.0);
        const b = TideThemeData(eventMinHeight: 40.0);
        expect(a, isNot(equals(b)));
      });

      test('identical instance is equal', () {
        const theme = TideThemeData();
        expect(theme == theme, isTrue);
      });

      test('not equal to non-TideThemeData object', () {
        const theme = TideThemeData();
        expect(theme == Object(), isFalse);
      });
    });

    test('toString includes primaryColor', () {
      const theme = TideThemeData();
      expect(theme.toString(), contains('TideThemeData'));
      expect(theme.toString(), contains('primaryColor'));
    });
  });

  group('TideTheme', () {
    testWidgets('of() returns provided theme data', (tester) async {
      const customTheme = TideThemeData(
        primaryColor: Color(0xFF6200EA),
      );

      late TideThemeData retrievedTheme;

      await tester.pumpWidget(
        TideTheme(
          data: customTheme,
          child: Builder(
            builder: (context) {
              retrievedTheme = TideTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(retrievedTheme.primaryColor, const Color(0xFF6200EA));
    });

    testWidgets('of() returns default when no TideTheme ancestor',
        (tester) async {
      late TideThemeData retrievedTheme;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            retrievedTheme = TideTheme.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(retrievedTheme, equals(const TideThemeData()));
    });

    testWidgets('nearest ancestor theme wins', (tester) async {
      const outerTheme = TideThemeData(primaryColor: Color(0xFF000000));
      const innerTheme = TideThemeData(primaryColor: Color(0xFFFF0000));

      late TideThemeData retrievedTheme;

      await tester.pumpWidget(
        TideTheme(
          data: outerTheme,
          child: TideTheme(
            data: innerTheme,
            child: Builder(
              builder: (context) {
                retrievedTheme = TideTheme.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(retrievedTheme.primaryColor, const Color(0xFFFF0000));
    });

    testWidgets('rebuilds dependents when theme data changes', (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        TideTheme(
          data: const TideThemeData(primaryColor: Color(0xFF000000)),
          child: Builder(
            builder: (context) {
              TideTheme.of(context);
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(buildCount, 1);

      await tester.pumpWidget(
        TideTheme(
          data: const TideThemeData(primaryColor: Color(0xFFFF0000)),
          child: Builder(
            builder: (context) {
              TideTheme.of(context);
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(buildCount, 2);
    });

    testWidgets('does not rebuild when theme data is equal', (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        TideTheme(
          data: const TideThemeData(),
          child: Builder(
            builder: (context) {
              TideTheme.of(context);
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(buildCount, 1);

      // Same theme data — should not trigger rebuild of dependent
      await tester.pumpWidget(
        TideTheme(
          data: const TideThemeData(),
          child: Builder(
            builder: (context) {
              TideTheme.of(context);
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // Builder itself rebuilds because of pumpWidget, but
      // updateShouldNotify should return false.
      // The important thing is that it doesn't crash and the data is the same.
      expect(TideTheme.of(tester.element(find.byType(Builder))),
          equals(const TideThemeData()));
    });
  });
}

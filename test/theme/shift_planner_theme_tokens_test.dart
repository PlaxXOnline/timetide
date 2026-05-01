import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';

void main() {
  group('TideThemeData – Shift Planner tokens', () {
    group('defaults', () {
      const theme = TideThemeData();

      test('shiftPlannerSidebarWidth defaults to 240.0', () {
        expect(theme.shiftPlannerSidebarWidth, 240.0);
      });

      test('shiftPlannerSidebarBackground defaults to a light slate', () {
        expect(theme.shiftPlannerSidebarBackground, const Color(0xFFF8FAFC));
      });

      test('shiftPlannerCardPadding defaults to EdgeInsets.all(8)', () {
        expect(theme.shiftPlannerCardPadding, const EdgeInsets.all(8));
      });

      test('shiftPlannerCardBorderRadius defaults to circular(6)', () {
        expect(
          theme.shiftPlannerCardBorderRadius,
          const BorderRadius.all(Radius.circular(6)),
        );
      });

      test('shiftPlannerCardLeftBorderWidth defaults to 3.0', () {
        expect(theme.shiftPlannerCardLeftBorderWidth, 3.0);
      });

      test('shiftPlannerClosedDayPatternColor defaults to 8% black', () {
        expect(
          theme.shiftPlannerClosedDayPatternColor,
          const Color(0x14000000),
        );
      });

      test('shiftPlannerClosedDayPatternSpacing defaults to 8.0', () {
        expect(theme.shiftPlannerClosedDayPatternSpacing, 8.0);
      });

      test('shiftPlannerColumnHeaderTextStyle defaults to w600', () {
        expect(
          theme.shiftPlannerColumnHeaderTextStyle.fontWeight,
          FontWeight.w600,
        );
      });

      test('shiftPlannerColumnDateStyle defaults to a smaller, subtler style',
          () {
        final headerStyle = theme.shiftPlannerColumnHeaderTextStyle;
        final dateStyle = theme.shiftPlannerColumnDateStyle;
        expect(dateStyle.fontSize, lessThan(headerStyle.fontSize!));
        expect(dateStyle.color, isNot(equals(headerStyle.color)));
      });

      test('shiftPlannerCardTitleStyle defaults match design tokens', () {
        expect(theme.shiftPlannerCardTitleStyle.fontSize, 11);
        expect(theme.shiftPlannerCardTitleStyle.color, const Color(0xFF1F2937));
        expect(
          theme.shiftPlannerCardTitleStyle.fontWeight,
          FontWeight.w600,
        );
      });

      test('shiftPlannerCardTimeStyle defaults match design tokens', () {
        expect(theme.shiftPlannerCardTimeStyle.fontSize, 10.5);
        expect(theme.shiftPlannerCardTimeStyle.color, const Color(0xB81F2937));
      });

      test('shiftPlannerClosedLabelStyle defaults match design tokens', () {
        expect(theme.shiftPlannerClosedLabelStyle.fontSize, 12);
        expect(
          theme.shiftPlannerClosedLabelStyle.color,
          const Color(0xFF757575),
        );
      });

      test('shiftPlannerAddButtonStyle defaults match design tokens', () {
        expect(theme.shiftPlannerAddButtonStyle.fontSize, 12);
        expect(
          theme.shiftPlannerAddButtonStyle.color,
          const Color(0xFF757575),
        );
      });

      test('shiftPlannerAddButtonBorderColor defaults to 20% black', () {
        expect(
          theme.shiftPlannerAddButtonBorderColor,
          const Color(0x33000000),
        );
      });

      test('shiftPlannerSidebarAvatarTextStyle defaults match design tokens',
          () {
        expect(theme.shiftPlannerSidebarAvatarTextStyle.fontSize, 12);
        expect(
          theme.shiftPlannerSidebarAvatarTextStyle.color,
          const Color(0xFFFFFFFF),
        );
        expect(
          theme.shiftPlannerSidebarAvatarTextStyle.fontWeight,
          FontWeight.w600,
        );
      });

      test('shiftPlannerSidebarItemTextStyle defaults match design tokens',
          () {
        expect(theme.shiftPlannerSidebarItemTextStyle.fontSize, 13);
        expect(
          theme.shiftPlannerSidebarItemTextStyle.color,
          const Color(0xFF212121),
        );
        expect(
          theme.shiftPlannerSidebarItemTextStyle.fontWeight,
          FontWeight.w500,
        );
      });

      test('shiftPlannerCardAvatarTextStyle defaults match design tokens', () {
        expect(theme.shiftPlannerCardAvatarTextStyle.fontSize, 9);
        expect(
          theme.shiftPlannerCardAvatarTextStyle.color,
          const Color(0xFFFFFFFF),
        );
        expect(
          theme.shiftPlannerCardAvatarTextStyle.fontWeight,
          FontWeight.w600,
        );
      });
    });

    group('copyWith', () {
      test('returns identical instance when no fields are overridden', () {
        const original = TideThemeData();
        final copy = original.copyWith();
        expect(copy, equals(original));
      });

      test('overrides shiftPlannerSidebarWidth and leaves others intact', () {
        const original = TideThemeData();
        final copy = original.copyWith(shiftPlannerSidebarWidth: 320.0);
        expect(copy.shiftPlannerSidebarWidth, 320.0);
        expect(
          copy.shiftPlannerSidebarBackground,
          original.shiftPlannerSidebarBackground,
        );
        expect(copy.shiftPlannerCardPadding, original.shiftPlannerCardPadding);
        expect(copy.primaryColor, original.primaryColor);
      });

      test('overrides shiftPlannerSidebarBackground', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          shiftPlannerSidebarBackground: const Color(0xFF101010),
        );
        expect(copy.shiftPlannerSidebarBackground, const Color(0xFF101010));
        expect(
          copy.shiftPlannerSidebarWidth,
          original.shiftPlannerSidebarWidth,
        );
      });

      test('overrides shiftPlannerCardPadding', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          shiftPlannerCardPadding: const EdgeInsets.all(16),
        );
        expect(copy.shiftPlannerCardPadding, const EdgeInsets.all(16));
      });

      test('overrides shiftPlannerCardBorderRadius', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          shiftPlannerCardBorderRadius:
              const BorderRadius.all(Radius.circular(12)),
        );
        expect(
          copy.shiftPlannerCardBorderRadius,
          const BorderRadius.all(Radius.circular(12)),
        );
      });

      test('overrides shiftPlannerCardLeftBorderWidth', () {
        const original = TideThemeData();
        final copy = original.copyWith(shiftPlannerCardLeftBorderWidth: 5.0);
        expect(copy.shiftPlannerCardLeftBorderWidth, 5.0);
      });

      test('overrides shiftPlannerClosedDayPatternColor', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          shiftPlannerClosedDayPatternColor: const Color(0x33FF0000),
        );
        expect(
          copy.shiftPlannerClosedDayPatternColor,
          const Color(0x33FF0000),
        );
      });

      test('overrides shiftPlannerClosedDayPatternSpacing', () {
        const original = TideThemeData();
        final copy =
            original.copyWith(shiftPlannerClosedDayPatternSpacing: 12.0);
        expect(copy.shiftPlannerClosedDayPatternSpacing, 12.0);
      });

      test('overrides shiftPlannerColumnHeaderTextStyle', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          shiftPlannerColumnHeaderTextStyle: const TextStyle(fontSize: 20),
        );
        expect(copy.shiftPlannerColumnHeaderTextStyle.fontSize, 20);
      });

      test('overrides shiftPlannerColumnDateStyle', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          shiftPlannerColumnDateStyle: const TextStyle(fontSize: 9),
        );
        expect(copy.shiftPlannerColumnDateStyle.fontSize, 9);
      });

      test('overrides shiftPlannerCardTitleStyle', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          shiftPlannerCardTitleStyle: const TextStyle(fontSize: 22),
        );
        expect(copy.shiftPlannerCardTitleStyle.fontSize, 22);
        expect(
          copy.shiftPlannerCardTimeStyle,
          original.shiftPlannerCardTimeStyle,
        );
      });

      test('overrides shiftPlannerCardTimeStyle', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          shiftPlannerCardTimeStyle: const TextStyle(fontSize: 24),
        );
        expect(copy.shiftPlannerCardTimeStyle.fontSize, 24);
      });

      test('overrides shiftPlannerClosedLabelStyle', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          shiftPlannerClosedLabelStyle: const TextStyle(fontSize: 18),
        );
        expect(copy.shiftPlannerClosedLabelStyle.fontSize, 18);
      });

      test('overrides shiftPlannerAddButtonStyle', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          shiftPlannerAddButtonStyle: const TextStyle(fontSize: 19),
        );
        expect(copy.shiftPlannerAddButtonStyle.fontSize, 19);
      });

      test('overrides shiftPlannerAddButtonBorderColor', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          shiftPlannerAddButtonBorderColor: const Color(0xFFAB1234),
        );
        expect(
          copy.shiftPlannerAddButtonBorderColor,
          const Color(0xFFAB1234),
        );
      });

      test('overrides shiftPlannerSidebarAvatarTextStyle', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          shiftPlannerSidebarAvatarTextStyle:
              const TextStyle(fontSize: 30),
        );
        expect(copy.shiftPlannerSidebarAvatarTextStyle.fontSize, 30);
      });

      test('overrides shiftPlannerSidebarItemTextStyle', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          shiftPlannerSidebarItemTextStyle:
              const TextStyle(fontSize: 17),
        );
        expect(copy.shiftPlannerSidebarItemTextStyle.fontSize, 17);
      });

      test('overrides shiftPlannerCardAvatarTextStyle', () {
        const original = TideThemeData();
        final copy = original.copyWith(
          shiftPlannerCardAvatarTextStyle: const TextStyle(fontSize: 21),
        );
        expect(copy.shiftPlannerCardAvatarTextStyle.fontSize, 21);
      });
    });

    group('lerp', () {
      const a = TideThemeData();
      final b = const TideThemeData().copyWith(
        shiftPlannerSidebarWidth: 400.0,
        shiftPlannerSidebarBackground: const Color(0xFF000000),
        shiftPlannerCardPadding: const EdgeInsets.all(16),
        shiftPlannerCardBorderRadius:
            const BorderRadius.all(Radius.circular(12)),
        shiftPlannerCardLeftBorderWidth: 7.0,
        shiftPlannerClosedDayPatternColor: const Color(0xFFFFFFFF),
        shiftPlannerClosedDayPatternSpacing: 16.0,
        shiftPlannerColumnHeaderTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF000000),
        ),
        shiftPlannerColumnDateStyle: const TextStyle(
          fontSize: 20,
          color: Color(0xFF000000),
        ),
        shiftPlannerCardTitleStyle: const TextStyle(
          fontSize: 22,
          color: Color(0xFF000000),
          fontWeight: FontWeight.w800,
        ),
        shiftPlannerCardTimeStyle: const TextStyle(
          fontSize: 22,
          color: Color(0xFF000000),
        ),
        shiftPlannerClosedLabelStyle: const TextStyle(
          fontSize: 22,
          color: Color(0xFF000000),
        ),
        shiftPlannerAddButtonStyle: const TextStyle(
          fontSize: 22,
          color: Color(0xFF000000),
        ),
        shiftPlannerAddButtonBorderColor: const Color(0xFF000000),
        shiftPlannerSidebarAvatarTextStyle: const TextStyle(
          fontSize: 22,
          color: Color(0xFF000000),
          fontWeight: FontWeight.w800,
        ),
        shiftPlannerSidebarItemTextStyle: const TextStyle(
          fontSize: 22,
          color: Color(0xFF000000),
          fontWeight: FontWeight.w800,
        ),
        shiftPlannerCardAvatarTextStyle: const TextStyle(
          fontSize: 22,
          color: Color(0xFF000000),
          fontWeight: FontWeight.w800,
        ),
      );

      test('t=0 returns values of a', () {
        final r = TideThemeData.lerp(a, b, 0.0);
        expect(r.shiftPlannerSidebarWidth, a.shiftPlannerSidebarWidth);
        expect(
          r.shiftPlannerSidebarBackground,
          a.shiftPlannerSidebarBackground,
        );
        expect(r.shiftPlannerCardPadding, a.shiftPlannerCardPadding);
        expect(
          r.shiftPlannerClosedDayPatternSpacing,
          a.shiftPlannerClosedDayPatternSpacing,
        );
      });

      test('t=1 returns values of b', () {
        final r = TideThemeData.lerp(a, b, 1.0);
        expect(r.shiftPlannerSidebarWidth, b.shiftPlannerSidebarWidth);
        expect(
          r.shiftPlannerSidebarBackground,
          b.shiftPlannerSidebarBackground,
        );
        expect(r.shiftPlannerCardPadding, b.shiftPlannerCardPadding);
      });

      test('t=0.5 interpolates doubles linearly', () {
        final r = TideThemeData.lerp(a, b, 0.5);
        expect(
          r.shiftPlannerSidebarWidth,
          (a.shiftPlannerSidebarWidth + b.shiftPlannerSidebarWidth) / 2,
        );
        expect(
          r.shiftPlannerCardLeftBorderWidth,
          (a.shiftPlannerCardLeftBorderWidth +
                  b.shiftPlannerCardLeftBorderWidth) /
              2,
        );
        expect(
          r.shiftPlannerClosedDayPatternSpacing,
          (a.shiftPlannerClosedDayPatternSpacing +
                  b.shiftPlannerClosedDayPatternSpacing) /
              2,
        );
      });

      test('t=0.5 interpolates Color via Color.lerp', () {
        final r = TideThemeData.lerp(a, b, 0.5);
        expect(
          r.shiftPlannerSidebarBackground,
          Color.lerp(
            a.shiftPlannerSidebarBackground,
            b.shiftPlannerSidebarBackground,
            0.5,
          ),
        );
        expect(
          r.shiftPlannerClosedDayPatternColor,
          Color.lerp(
            a.shiftPlannerClosedDayPatternColor,
            b.shiftPlannerClosedDayPatternColor,
            0.5,
          ),
        );
      });

      test('t=0.5 interpolates EdgeInsets via EdgeInsets.lerp', () {
        final r = TideThemeData.lerp(a, b, 0.5);
        expect(
          r.shiftPlannerCardPadding,
          EdgeInsets.lerp(
            a.shiftPlannerCardPadding,
            b.shiftPlannerCardPadding,
            0.5,
          ),
        );
      });

      test('t=0.5 interpolates BorderRadius via BorderRadius.lerp', () {
        final r = TideThemeData.lerp(a, b, 0.5);
        expect(
          r.shiftPlannerCardBorderRadius,
          BorderRadius.lerp(
            a.shiftPlannerCardBorderRadius,
            b.shiftPlannerCardBorderRadius,
            0.5,
          ),
        );
      });

      test('t=0.5 interpolates TextStyles via TextStyle.lerp', () {
        final r = TideThemeData.lerp(a, b, 0.5);
        expect(
          r.shiftPlannerColumnHeaderTextStyle,
          TextStyle.lerp(
            a.shiftPlannerColumnHeaderTextStyle,
            b.shiftPlannerColumnHeaderTextStyle,
            0.5,
          ),
        );
        expect(
          r.shiftPlannerColumnDateStyle,
          TextStyle.lerp(
            a.shiftPlannerColumnDateStyle,
            b.shiftPlannerColumnDateStyle,
            0.5,
          ),
        );
      });

      test('t=0/1 returns the new sub-widget tokens of a and b', () {
        final r0 = TideThemeData.lerp(a, b, 0.0);
        final r1 = TideThemeData.lerp(a, b, 1.0);

        expect(r0.shiftPlannerCardTitleStyle, a.shiftPlannerCardTitleStyle);
        expect(r0.shiftPlannerCardTimeStyle, a.shiftPlannerCardTimeStyle);
        expect(
          r0.shiftPlannerAddButtonBorderColor,
          a.shiftPlannerAddButtonBorderColor,
        );

        expect(r1.shiftPlannerCardTitleStyle, b.shiftPlannerCardTitleStyle);
        expect(r1.shiftPlannerCardTimeStyle, b.shiftPlannerCardTimeStyle);
        expect(
          r1.shiftPlannerAddButtonBorderColor,
          b.shiftPlannerAddButtonBorderColor,
        );
      });

      test('t=0.5 interpolates the new sub-widget TextStyles via TextStyle.lerp',
          () {
        final r = TideThemeData.lerp(a, b, 0.5);
        expect(
          r.shiftPlannerCardTitleStyle,
          TextStyle.lerp(
            a.shiftPlannerCardTitleStyle,
            b.shiftPlannerCardTitleStyle,
            0.5,
          ),
        );
        expect(
          r.shiftPlannerCardTimeStyle,
          TextStyle.lerp(
            a.shiftPlannerCardTimeStyle,
            b.shiftPlannerCardTimeStyle,
            0.5,
          ),
        );
        expect(
          r.shiftPlannerClosedLabelStyle,
          TextStyle.lerp(
            a.shiftPlannerClosedLabelStyle,
            b.shiftPlannerClosedLabelStyle,
            0.5,
          ),
        );
        expect(
          r.shiftPlannerAddButtonStyle,
          TextStyle.lerp(
            a.shiftPlannerAddButtonStyle,
            b.shiftPlannerAddButtonStyle,
            0.5,
          ),
        );
        expect(
          r.shiftPlannerSidebarAvatarTextStyle,
          TextStyle.lerp(
            a.shiftPlannerSidebarAvatarTextStyle,
            b.shiftPlannerSidebarAvatarTextStyle,
            0.5,
          ),
        );
        expect(
          r.shiftPlannerSidebarItemTextStyle,
          TextStyle.lerp(
            a.shiftPlannerSidebarItemTextStyle,
            b.shiftPlannerSidebarItemTextStyle,
            0.5,
          ),
        );
        expect(
          r.shiftPlannerCardAvatarTextStyle,
          TextStyle.lerp(
            a.shiftPlannerCardAvatarTextStyle,
            b.shiftPlannerCardAvatarTextStyle,
            0.5,
          ),
        );
      });

      test('t=0.5 interpolates the new add-button border color via Color.lerp',
          () {
        final r = TideThemeData.lerp(a, b, 0.5);
        expect(
          r.shiftPlannerAddButtonBorderColor,
          Color.lerp(
            a.shiftPlannerAddButtonBorderColor,
            b.shiftPlannerAddButtonBorderColor,
            0.5,
          ),
        );
      });
    });

    group('equality and hashCode', () {
      test('two default instances are equal and share hashCode', () {
        const a = TideThemeData();
        const b = TideThemeData();
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('changing a shift planner field breaks equality', () {
        const a = TideThemeData();
        final b = a.copyWith(shiftPlannerSidebarWidth: 999.0);
        expect(a, isNot(equals(b)));
      });

      test('two instances with identical overrides are equal', () {
        final a = const TideThemeData().copyWith(
          shiftPlannerSidebarWidth: 300.0,
          shiftPlannerCardPadding: const EdgeInsets.all(10),
        );
        final b = const TideThemeData().copyWith(
          shiftPlannerSidebarWidth: 300.0,
          shiftPlannerCardPadding: const EdgeInsets.all(10),
        );
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('changing any of the new sub-widget tokens breaks equality', () {
        const original = TideThemeData();
        final mutations = <TideThemeData>[
          original.copyWith(
            shiftPlannerCardTitleStyle: const TextStyle(fontSize: 99),
          ),
          original.copyWith(
            shiftPlannerCardTimeStyle: const TextStyle(fontSize: 99),
          ),
          original.copyWith(
            shiftPlannerClosedLabelStyle: const TextStyle(fontSize: 99),
          ),
          original.copyWith(
            shiftPlannerAddButtonStyle: const TextStyle(fontSize: 99),
          ),
          original.copyWith(
            shiftPlannerAddButtonBorderColor: const Color(0xFF112233),
          ),
          original.copyWith(
            shiftPlannerSidebarAvatarTextStyle:
                const TextStyle(fontSize: 99),
          ),
          original.copyWith(
            shiftPlannerSidebarItemTextStyle:
                const TextStyle(fontSize: 99),
          ),
          original.copyWith(
            shiftPlannerCardAvatarTextStyle:
                const TextStyle(fontSize: 99),
          ),
        ];
        for (final mutated in mutations) {
          expect(mutated, isNot(equals(original)));
        }
      });
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/recurrence/rrule_parser.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/widgets/recurrence_editor/recurrence_editor.dart';
import 'package:timetide/src/core/recurrence/rrule_model.dart';

Widget _wrap(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: TideTheme(
      data: const TideThemeData(),
      child: MediaQuery(
        data: const MediaQueryData(),
        child: SingleChildScrollView(child: child),
      ),
    ),
  );
}

void main() {
  group('TideRecurrenceEditor', () {
    testWidgets('renders frequency toggles', (tester) async {
      await tester.pumpWidget(_wrap(
        TideRecurrenceEditor(
          onChanged: (_) {},
        ),
      ));

      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);
    });

    testWidgets('changing frequency calls onChanged', (tester) async {
      String? lastRrule;

      await tester.pumpWidget(_wrap(
        TideRecurrenceEditor(
          onChanged: (rrule) => lastRrule = rrule,
        ),
      ));

      // Tap Daily.
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();

      expect(lastRrule, isNotNull);
      final parsed = TideRRuleParser.parse(lastRrule!);
      expect(parsed, isNotNull);
      expect(parsed!.frequency, TideFrequency.daily);
    });

    testWidgets('interval stepper increments/decrements', (tester) async {
      String? lastRrule;

      await tester.pumpWidget(_wrap(
        TideRecurrenceEditor(
          onChanged: (rrule) => lastRrule = rrule,
        ),
      ));

      // Initial interval is 1 — displayed.
      expect(find.text('1'), findsOneWidget);

      // Tap +.
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      final parsed = TideRRuleParser.parse(lastRrule!);
      expect(parsed!.interval, 2);
    });

    testWidgets('weekday selector shown for weekly frequency', (tester) async {
      String? lastRrule;

      await tester.pumpWidget(_wrap(
        TideRecurrenceEditor(
          onChanged: (rrule) => lastRrule = rrule,
        ),
      ));

      // Default frequency is weekly, so weekday buttons should be visible.
      expect(find.text('Mo'), findsOneWidget);
      expect(find.text('Fr'), findsOneWidget);

      // Select Monday.
      await tester.tap(find.text('Mo'));
      await tester.pumpAndSettle();

      final parsed = TideRRuleParser.parse(lastRrule!);
      expect(parsed, isNotNull);
      expect(parsed!.byDay, isNotNull);
      expect(
        parsed.byDay!.any((bd) => bd.weekday == TideWeekday.monday),
        isTrue,
      );
    });

    testWidgets('weekday selector hidden for daily frequency', (tester) async {
      await tester.pumpWidget(_wrap(
        TideRecurrenceEditor(
          onChanged: (_) {},
        ),
      ));

      // Switch to daily.
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();

      // Weekday buttons (Tu, We, Th) should not be visible.
      // Note: "Mo" might match "Monthly", so check for "Tu".
      expect(find.text('Tu'), findsNothing);
    });

    testWidgets('live preview shows occurrences', (tester) async {
      final previewStart = DateTime(2026, 1, 1);

      await tester.pumpWidget(_wrap(
        TideRecurrenceEditor(
          onChanged: (_) {},
          initialRule: 'RRULE:FREQ=DAILY',
          previewStart: previewStart,
        ),
      ));

      expect(find.text('Next occurrences:'), findsOneWidget);
      // Should show 2026-01-01 as first occurrence.
      expect(find.text('2026-01-01'), findsOneWidget);
    });

    testWidgets('end condition: after N times', (tester) async {
      String? lastRrule;

      await tester.pumpWidget(_wrap(
        TideRecurrenceEditor(
          onChanged: (rrule) => lastRrule = rrule,
        ),
      ));

      // Tap "After" end mode.
      await tester.tap(find.text('After'));
      await tester.pumpAndSettle();

      // Should show count stepper.
      expect(find.text('10 times'), findsOneWidget);

      final parsed = TideRRuleParser.parse(lastRrule!);
      expect(parsed!.count, 10);
    });

    testWidgets('initialRule populates editor state', (tester) async {
      await tester.pumpWidget(_wrap(
        TideRecurrenceEditor(
          onChanged: (_) {},
          initialRule: 'RRULE:FREQ=WEEKLY;INTERVAL=3;BYDAY=MO,FR',
          previewStart: DateTime(2026, 1, 1),
        ),
      ));

      // Interval should be 3.
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('allowedFrequencies limits options', (tester) async {
      await tester.pumpWidget(_wrap(
        TideRecurrenceEditor(
          onChanged: (_) {},
          allowedFrequencies: [TideFrequency.daily, TideFrequency.weekly],
        ),
      ));

      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsNothing);
      expect(find.text('Yearly'), findsNothing);
    });

    testWidgets('description reflects current rule', (tester) async {
      await tester.pumpWidget(_wrap(
        TideRecurrenceEditor(
          onChanged: (_) {},
          initialRule: 'RRULE:FREQ=DAILY',
        ),
      ));

      expect(find.text('Every day'), findsOneWidget);
    });

    testWidgets('German locale shows German labels', (tester) async {
      await tester.pumpWidget(_wrap(
        TideRecurrenceEditor(
          onChanged: (_) {},
          locale: 'de',
        ),
      ));

      expect(find.text('Täglich'), findsOneWidget);
      expect(find.text('Wöchentlich'), findsOneWidget);
      expect(find.text('Monatlich'), findsOneWidget);
      expect(find.text('Jährlich'), findsOneWidget);
    });
  });
}

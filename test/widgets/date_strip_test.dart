import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/l10n/tide_localizations.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/widgets/date_strip/tide_date_strip.dart';

void main() {
  // Fixed reference date: Monday 2026-03-16
  final startDate = DateTime(2026, 3, 16);
  final selectedDate = DateTime(2026, 3, 16);

  Widget buildTestWidget({
    DateTime? start,
    DateTime? selected,
    int dayCount = 14,
    List<DateTime>? disabledDates,
    bool showTodayIndicator = true,
    TideLocalizations? locale,
    ValueChanged<DateTime>? onDateSelected,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TideTheme(
        data: const TideThemeData(),
        child: TideDateStrip(
          startDate: start ?? startDate,
          selectedDate: selected ?? selectedDate,
          dayCount: dayCount,
          disabledDates: disabledDates,
          showTodayIndicator: showTodayIndicator,
          locale: locale,
          onDateSelected: onDateSelected ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('renders TideDateStrip widget', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    expect(find.byType(TideDateStrip), findsOneWidget);
  });

  testWidgets('shows correct number of day items (dayCount)', (tester) async {
    await tester.pumpWidget(buildTestWidget(dayCount: 7));
    await tester.pumpAndSettle();

    // Days 16–22 of March 2026
    for (int d = 16; d <= 22; d++) {
      expect(find.text('$d'), findsOneWidget);
    }
    // Day 23 should not appear
    expect(find.text('23'), findsNothing);
  });

  testWidgets('displays weekday abbreviations (English default)',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(dayCount: 7));
    await tester.pumpAndSettle();

    // 2026-03-16 is a Monday
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('Wed'), findsOneWidget);
  });

  testWidgets('displays weekday abbreviations from locale', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      dayCount: 7,
      locale: TideLocalizations.de(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Mo'), findsOneWidget);
    expect(find.text('Di'), findsOneWidget);
  });

  testWidgets('displays day numbers', (tester) async {
    await tester.pumpWidget(buildTestWidget(dayCount: 5));
    await tester.pumpAndSettle();

    expect(find.text('16'), findsOneWidget);
    expect(find.text('17'), findsOneWidget);
  });

  testWidgets('highlights selected date', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      start: startDate,
      selected: DateTime(2026, 3, 18),
      dayCount: 7,
    ));
    await tester.pumpAndSettle();

    // The selected item has Semantics label containing "selected"
    expect(
      find.bySemanticsLabel(RegExp(r'.*18.*selected.*')),
      findsOneWidget,
    );
  });

  testWidgets('shows today indicator dot when showTodayIndicator is true',
      (tester) async {
    final today = DateTime.now();
    final todayStripped = DateTime(today.year, today.month, today.day);

    await tester.pumpWidget(buildTestWidget(
      start: todayStripped,
      selected: todayStripped,
      dayCount: 7,
      showTodayIndicator: true,
    ));
    await tester.pumpAndSettle();

    // The today indicator dot is a Container with BoxShape.circle inside
    // We verify by checking semantics label contains "today"
    expect(
      find.bySemanticsLabel(RegExp(r'.*today.*')),
      findsWidgets,
    );
  });

  testWidgets('does not show today indicator when showTodayIndicator is false',
      (tester) async {
    final today = DateTime.now();
    final todayStripped = DateTime(today.year, today.month, today.day);

    await tester.pumpWidget(buildTestWidget(
      start: todayStripped,
      selected: todayStripped,
      dayCount: 3,
      showTodayIndicator: false,
    ));
    await tester.pumpAndSettle();

    // No semantics label should contain "today"
    expect(find.bySemanticsLabel(RegExp(r'.*today.*')), findsNothing);
  });

  testWidgets('calls onDateSelected when tapping a date', (tester) async {
    DateTime? tapped;
    await tester.pumpWidget(buildTestWidget(
      dayCount: 7,
      onDateSelected: (d) => tapped = d,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('17'));
    expect(tapped, equals(DateTime(2026, 3, 17)));
  });

  testWidgets('does NOT call onDateSelected when tapping a disabled date',
      (tester) async {
    int tapCount = 0;
    await tester.pumpWidget(buildTestWidget(
      dayCount: 7,
      disabledDates: [DateTime(2026, 3, 17)],
      onDateSelected: (_) => tapCount++,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('17'));
    expect(tapCount, 0);
  });

  testWidgets('disabled dates are marked in semantics', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      dayCount: 7,
      disabledDates: [DateTime(2026, 3, 17)],
    ));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp(r'.*17.*disabled.*')),
      findsOneWidget,
    );
  });

  testWidgets('defaults to 14 days when dayCount not specified',
      (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TideTheme(
          data: const TideThemeData(),
          child: TideDateStrip(
            startDate: startDate,
            selectedDate: selectedDate,
            onDateSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // First day (index 0) should be visible
    expect(find.text('16'), findsOneWidget);
    // Day 30 (index 14) must NOT be rendered — outside the 14-day range
    expect(find.text('30'), findsNothing);
  });

  testWidgets('uses custom startDate when provided', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      start: DateTime(2026, 4, 1),
      selected: DateTime(2026, 4, 1),
      dayCount: 5,
    ));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsNothing);
  });

  testWidgets('accessibility: semantics labels present', (tester) async {
    await tester.pumpWidget(buildTestWidget(dayCount: 7));
    await tester.pumpAndSettle();

    // Each day item should have a semantics label containing the day number
    for (int d = 16; d <= 22; d++) {
      expect(
        find.bySemanticsLabel(RegExp('.*$d.*')),
        findsAtLeastNWidgets(1),
      );
    }
  });
}

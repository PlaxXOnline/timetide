import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/widgets/event_content.dart';

Widget buildTestWidget({
  required double height,
  double? availableHeight,
  String subject = 'Meeting',
  String? timeRange = '09:00 – 10:00',
  TextStyle titleStyle = const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  ),
  TextStyle? timeStyle = const TextStyle(fontSize: 11),
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox(
        width: 200,
        height: height,
        child: TideEventContent(
          subject: subject,
          timeRange: timeRange,
          titleStyle: titleStyle,
          timeStyle: timeStyle,
          padding: padding,
          availableHeight: availableHeight ?? height,
        ),
      ),
    ),
  );
}

void main() {
  group('TideEventContent', () {
    testWidgets(
      'should render subject and time range in full mode when height is '
      'sufficient',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(height: 60));

        expect(find.text('Meeting'), findsOneWidget);
        expect(find.text('09:00 – 10:00'), findsOneWidget);
      },
    );

    testWidgets(
      'should render subject only in compact mode when height is small',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(height: 20));

        expect(find.text('Meeting'), findsOneWidget);
        expect(find.text('09:00 – 10:00'), findsNothing);
      },
    );

    testWidgets(
      'should render subject with reduced padding in minimal mode',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(height: 10));

        expect(find.text('Meeting'), findsOneWidget);
      },
    );

    testWidgets(
      'should show subject only when timeRange is null even with sufficient '
      'height',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(height: 60, timeRange: null),
        );

        expect(find.text('Meeting'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (Widget w) =>
                w is Text && w.data != null && w.data!.contains(':'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'should render subject when timeRange is null and height is minimal',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(height: 10, timeRange: null),
        );

        expect(find.text('Meeting'), findsOneWidget);
      },
    );

    testWidgets(
      'should select compact mode when height is between one and two lines',
      (WidgetTester tester) async {
        // Height enough for title+padding but not for time range
        await tester.pumpWidget(buildTestWidget(height: 60, availableHeight: 20));
        expect(find.text('Meeting'), findsOneWidget);
        expect(find.text('09:00 – 10:00'), findsNothing);
      },
    );

    testWidgets(
      'should apply ellipsis overflow and maxLines 1 to subject text',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(height: 60));

        final Text subjectText = tester.widget<Text>(
          find.text('Meeting'),
        );
        expect(subjectText.overflow, TextOverflow.ellipsis);
        expect(subjectText.maxLines, 1);
      },
    );

    testWidgets(
      'should apply provided timeStyle to the time range text',
      (WidgetTester tester) async {
        const TextStyle expectedTimeStyle = TextStyle(fontSize: 11);
        await tester.pumpWidget(
          buildTestWidget(height: 60, timeStyle: expectedTimeStyle),
        );

        final Text timeText = tester.widget<Text>(
          find.text('09:00 – 10:00'),
        );
        expect(timeText.style?.fontSize, 11);
      },
    );
  });
}

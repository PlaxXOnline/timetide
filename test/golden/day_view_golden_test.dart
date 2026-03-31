import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/timetide.dart';

void main() {
  group('TideDayView golden', () {
    testWidgets('renders day view with sample events', (tester) async {
      final datasource = TideInMemoryDatasource(
        events: [
          // Use dates far in the past so "today" highlighting never
          // falls within the visible range, making the golden stable.
          TideEvent(
            id: '1',
            subject: 'Team Standup',
            startTime: DateTime(2025, 1, 15, 9, 0),
            endTime: DateTime(2025, 1, 15, 9, 30),
            color: const Color(0xFF4CAF50),
          ),
          TideEvent(
            id: '2',
            subject: 'Design Review',
            startTime: DateTime(2025, 1, 15, 10, 0),
            endTime: DateTime(2025, 1, 15, 11, 30),
            color: const Color(0xFF2196F3),
          ),
          TideEvent(
            id: '3',
            subject: 'Lunch Break',
            startTime: DateTime(2025, 1, 15, 12, 0),
            endTime: DateTime(2025, 1, 15, 13, 0),
            color: const Color(0xFFFF9800),
          ),
          TideEvent(
            id: '4',
            subject: 'All-Day Conference',
            startTime: DateTime(2025, 1, 15),
            endTime: DateTime(2025, 1, 16),
            isAllDay: true,
            color: const Color(0xFF9C27B0),
          ),
        ],
      );

      final controller = TideController(
        datasource: datasource,
        initialView: TideView.day,
        initialDate: DateTime(2025, 1, 15),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 400,
              height: 800,
              child: TideDayView(
                controller: controller,
                startHour: 8,
                endHour: 18,
                showCurrentTimeIndicator: false,
              ),
            ),
          ),
        ),
      );

      // Allow async event loading to complete.
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TideDayView),
        matchesGoldenFile('goldens/day_view_sample.png'),
      );

      controller.dispose();
    });
  });
}

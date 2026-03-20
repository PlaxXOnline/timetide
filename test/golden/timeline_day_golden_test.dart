import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/timetide.dart';

void main() {
  group('TideTimelineDayView golden', () {
    testWidgets('renders timeline day view with resources', (tester) async {
      final datasource = TideInMemoryDatasource(
        events: [
          TideEvent(
            id: '1',
            subject: 'Client Meeting',
            startTime: DateTime(2026, 3, 20, 9, 0),
            endTime: DateTime(2026, 3, 20, 10, 0),
            color: const Color(0xFF4CAF50),
            resourceIds: ['r1'],
          ),
          TideEvent(
            id: '2',
            subject: 'Code Review',
            startTime: DateTime(2026, 3, 20, 10, 0),
            endTime: DateTime(2026, 3, 20, 11, 30),
            color: const Color(0xFF2196F3),
            resourceIds: ['r2'],
          ),
          TideEvent(
            id: '3',
            subject: 'Workshop',
            startTime: DateTime(2026, 3, 20, 13, 0),
            endTime: DateTime(2026, 3, 20, 15, 0),
            color: const Color(0xFFFF9800),
            resourceIds: ['r3'],
          ),
        ],
        resources: [
          const TideResource(
            id: 'r1',
            displayName: 'Meeting Room A',
            color: Color(0xFF4CAF50),
          ),
          const TideResource(
            id: 'r2',
            displayName: 'Meeting Room B',
            color: Color(0xFF2196F3),
          ),
          const TideResource(
            id: 'r3',
            displayName: 'Conference Hall',
            color: Color(0xFFFF9800),
          ),
        ],
      );

      final controller = TideController(
        datasource: datasource,
        initialView: TideView.timelineDay,
        initialDate: DateTime(2026, 3, 20),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 800,
              height: 400,
              child: TideTimelineDayView(
                controller: controller,
                startHour: 8,
                endHour: 18,
                showCurrentTimeIndicator: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TideTimelineDayView),
        matchesGoldenFile('goldens/timeline_day_view_sample.png'),
      );

      controller.dispose();
    });
  });
}

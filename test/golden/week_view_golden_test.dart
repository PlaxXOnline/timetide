@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/timetide.dart';

void main() {
  group('TideWeekView golden', () {
    testWidgets('renders week view with sample events', (tester) async {
      final datasource = TideInMemoryDatasource(
        events: [
          // Use dates far in the past so "today" highlighting never
          // falls within the visible range, making the golden stable.
          TideEvent(
            id: '1',
            subject: 'Sprint Planning',
            startTime: DateTime(2025, 1, 13, 9, 0),
            endTime: DateTime(2025, 1, 13, 10, 0),
            color: const Color(0xFF4CAF50),
          ),
          TideEvent(
            id: '2',
            subject: 'Code Review',
            startTime: DateTime(2025, 1, 14, 14, 0),
            endTime: DateTime(2025, 1, 14, 15, 30),
            color: const Color(0xFF2196F3),
          ),
          TideEvent(
            id: '3',
            subject: 'Team Lunch',
            startTime: DateTime(2025, 1, 15, 12, 0),
            endTime: DateTime(2025, 1, 15, 13, 0),
            color: const Color(0xFFFF9800),
          ),
          TideEvent(
            id: '4',
            subject: 'Retro',
            startTime: DateTime(2025, 1, 17, 16, 0),
            endTime: DateTime(2025, 1, 17, 17, 0),
            color: const Color(0xFF9C27B0),
          ),
        ],
      );

      final controller = TideController(
        datasource: datasource,
        initialView: TideView.week,
        initialDate: DateTime(2025, 1, 15),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 800,
              height: 600,
              child: TideWeekView(
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
        find.byType(TideWeekView),
        matchesGoldenFile('goldens/week_view_sample.png'),
      );

      controller.dispose();
    });
  });
}

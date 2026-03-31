@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/timetide.dart';

void main() {
  group('TideMonthView golden', () {
    testWidgets('renders month view with sample events', (tester) async {
      final datasource = TideInMemoryDatasource(
        events: [
          // Use dates far in the past so "today" highlighting never
          // falls within the visible range, making the golden stable.
          TideEvent(
            id: '1',
            subject: 'Project Kickoff',
            startTime: DateTime(2025, 1, 2, 10, 0),
            endTime: DateTime(2025, 1, 2, 12, 0),
            color: const Color(0xFF4CAF50),
          ),
          TideEvent(
            id: '2',
            subject: 'Sprint Review',
            startTime: DateTime(2025, 1, 13, 14, 0),
            endTime: DateTime(2025, 1, 13, 15, 0),
            color: const Color(0xFF2196F3),
          ),
          TideEvent(
            id: '3',
            subject: 'Release Day',
            startTime: DateTime(2025, 1, 20),
            endTime: DateTime(2025, 1, 21),
            isAllDay: true,
            color: const Color(0xFFFF9800),
          ),
          TideEvent(
            id: '4',
            subject: 'Team Offsite',
            startTime: DateTime(2025, 1, 25),
            endTime: DateTime(2025, 1, 27),
            isAllDay: true,
            color: const Color(0xFF9C27B0),
          ),
        ],
      );

      final controller = TideController(
        datasource: datasource,
        initialView: TideView.month,
        initialDate: DateTime(2025, 1, 15),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 600,
              height: 500,
              child: TideMonthView(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TideMonthView),
        matchesGoldenFile('goldens/month_view_sample.png'),
      );

      controller.dispose();
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/timetide.dart';

void main() {
  group('TideWeekView golden', () {
    testWidgets('renders week view with sample events', (tester) async {
      final datasource = TideInMemoryDatasource(
        events: [
          TideEvent(
            id: '1',
            subject: 'Sprint Planning',
            startTime: DateTime(2026, 3, 16, 9, 0),
            endTime: DateTime(2026, 3, 16, 10, 0),
            color: const Color(0xFF4CAF50),
          ),
          TideEvent(
            id: '2',
            subject: 'Code Review',
            startTime: DateTime(2026, 3, 17, 14, 0),
            endTime: DateTime(2026, 3, 17, 15, 30),
            color: const Color(0xFF2196F3),
          ),
          TideEvent(
            id: '3',
            subject: 'Team Lunch',
            startTime: DateTime(2026, 3, 18, 12, 0),
            endTime: DateTime(2026, 3, 18, 13, 0),
            color: const Color(0xFFFF9800),
          ),
          TideEvent(
            id: '4',
            subject: 'Retro',
            startTime: DateTime(2026, 3, 20, 16, 0),
            endTime: DateTime(2026, 3, 20, 17, 0),
            color: const Color(0xFF9C27B0),
          ),
        ],
      );

      final controller = TideController(
        datasource: datasource,
        initialView: TideView.week,
        initialDate: DateTime(2026, 3, 18),
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

import 'package:flutter/widgets.dart';
import 'package:timetide/timetide.dart';

/// Minimal timetide example showing a week calendar with sample events.
void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final datasource = TideInMemoryDatasource(
      events: [
        TideEvent(
          id: '1',
          subject: 'Team Standup',
          startTime: today.add(const Duration(hours: 9)),
          endTime: today.add(const Duration(hours: 9, minutes: 30)),
          color: const Color(0xFF4CAF50),
        ),
        TideEvent(
          id: '2',
          subject: 'Design Review',
          startTime: today.add(const Duration(hours: 11)),
          endTime: today.add(const Duration(hours: 12)),
          color: const Color(0xFF2196F3),
        ),
        TideEvent(
          id: '3',
          subject: 'Sprint Planning',
          startTime: today.add(const Duration(hours: 14)),
          endTime: today.add(const Duration(hours: 15, minutes: 30)),
          color: const Color(0xFF9C27B0),
        ),
      ],
    );

    return WidgetsApp(
      title: 'timetide Example',
      color: const Color(0xFF2196F3),
      home: TideCalendar(
        datasource: datasource,
        initialView: TideView.week,
        allowedViews: [TideView.day, TideView.week, TideView.month],
        startHour: 7,
        endHour: 20,
        allowDragAndDrop: true,
        allowResize: true,
      ),
    );
  }
}

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/widgets.dart';
import 'package:timetide/src/core/controller.dart';
import 'package:timetide/src/core/datasource_in_memory.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/core/models/view.dart';
import 'package:timetide/src/widgets/tide_calendar.dart';
import 'package:timetide/src/core/models/drag_details.dart';

/// Minimal timetide example — InMemoryDatasource with sample events.
void main() {
  runApp(const BasicCalendarApp());
}

class BasicCalendarApp extends StatelessWidget {
  const BasicCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'timetide Basic Example',
      color: Color(0xFF2196F3),
      home: BasicCalendarScreen(),
    );
  }
}

class BasicCalendarScreen extends StatefulWidget {
  const BasicCalendarScreen({super.key});

  @override
  State<BasicCalendarScreen> createState() => _BasicCalendarScreenState();
}

class _BasicCalendarScreenState extends State<BasicCalendarScreen> {
  late final TideInMemoryDatasource _datasource;
  late final TideController _controller;

  @override
  void initState() {
    super.initState();
    _datasource = TideInMemoryDatasource();
    _addSampleEvents();

    _controller = TideController(
      datasource: _datasource,
      initialView: TideView.day,
      initialDate: DateTime.now(),
    );
  }

  void _addSampleEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _datasource.addEvents([
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
        subject: 'Lunch Break',
        startTime: today.add(const Duration(hours: 12, minutes: 30)),
        endTime: today.add(const Duration(hours: 13, minutes: 30)),
        color: const Color(0xFFFF9800),
      ),
      TideEvent(
        id: '4',
        subject: 'Sprint Planning',
        startTime: today.add(const Duration(hours: 14)),
        endTime: today.add(const Duration(hours: 15, minutes: 30)),
        color: const Color(0xFF9C27B0),
      ),
      TideEvent(
        id: '5',
        subject: 'Release Party',
        startTime: today,
        endTime: today.add(const Duration(days: 1)),
        isAllDay: true,
        color: const Color(0xFFE91E63),
      ),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TideCalendar(
      datasource: _datasource,
      controller: _controller,
      initialView: TideView.day,
      allowedViews: [TideView.day, TideView.week, TideView.month],
      startHour: 7,
      endHour: 20,
      allowDragAndDrop: true,
      allowResize: true,
      onEventTap: (event) {
        // ignore: avoid_print
        debugPrint('Tapped: ${event.subject}');
      },
      onDragEnd: (TideDragEndDetails details) {
        List<String>? updatedResourceIds = details.event.resourceIds;

        if (details.newResourceId != null && updatedResourceIds != null) {
          // Event has specific resource assignments — update them.
          if (details.sourceResourceId != null &&
              updatedResourceIds.contains(details.sourceResourceId)) {
            // Replace only the source resource with the target.
            updatedResourceIds = updatedResourceIds
                .map((id) => id == details.sourceResourceId
                    ? details.newResourceId!
                    : id)
                .toList();
          } else {
            // Single-resource or source unknown — assign to target.
            updatedResourceIds = [details.newResourceId!];
          }
        }
        // If resourceIds is null → stays null (event visible in all resources).
        // Only the time changes.

        _datasource.updateEvent(details.event.copyWith(
          startTime: details.newStart,
          endTime: details.newEnd,
          resourceIds: updatedResourceIds,
        ));
      },
      onResizeEnd: (TideResizeEndDetails details) {
        _datasource.updateEvent(details.event.copyWith(
          startTime: details.newStart,
          endTime: details.newEnd,
        ));
      },
    );
  }
}

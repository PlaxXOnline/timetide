import 'package:flutter/widgets.dart';
import 'package:timetide/timetide.dart';

/// Team & room planning example using week view with resources.
///
/// Demonstrates:
/// - Multi-resource scheduling (rooms as resources)
/// - Week view with drag-and-drop
/// - Custom theme
/// - Event callbacks
void main() {
  runApp(const ResourcePlanningApp());
}

class ResourcePlanningApp extends StatelessWidget {
  const ResourcePlanningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Resource Planning',
      color: const Color(0xFF3F51B5),
      home: const ResourcePlanningScreen(),
    );
  }
}

class ResourcePlanningScreen extends StatefulWidget {
  const ResourcePlanningScreen({super.key});

  @override
  State<ResourcePlanningScreen> createState() => _ResourcePlanningScreenState();
}

class _ResourcePlanningScreenState extends State<ResourcePlanningScreen> {
  late final TideInMemoryDatasource _datasource;
  late final TideController _controller;

  @override
  void initState() {
    super.initState();
    _datasource = TideInMemoryDatasource();
    _addRooms();
    _addMeetings();

    _controller = TideController(
      datasource: _datasource,
      initialView: TideView.timelineWeek,
      initialDate: DateTime.now(),
    );
  }

  void _addRooms() {
    const rooms = [
      TideResource(
        id: 'room-a',
        displayName: 'Conference Room A',
        color: Color(0xFF3F51B5),
        sortOrder: 0,
        metadata: {'capacity': 12, 'floor': '3rd'},
      ),
      TideResource(
        id: 'room-b',
        displayName: 'Meeting Room B',
        color: Color(0xFF009688),
        sortOrder: 1,
        metadata: {'capacity': 6, 'floor': '3rd'},
      ),
      TideResource(
        id: 'room-c',
        displayName: 'Board Room',
        color: Color(0xFFFF5722),
        sortOrder: 2,
        metadata: {'capacity': 20, 'floor': '5th'},
      ),
      TideResource(
        id: 'room-d',
        displayName: 'Phone Booth 1',
        color: Color(0xFF607D8B),
        sortOrder: 3,
        metadata: {'capacity': 1, 'floor': '2nd'},
      ),
    ];

    for (final room in rooms) {
      _datasource.addResource(room);
    }
  }

  void _addMeetings() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);

    final meetings = [
      // Monday
      TideEvent(
        id: 'mtg-1',
        subject: 'Sprint Planning',
        startTime: weekStart.add(const Duration(hours: 9)),
        endTime: weekStart.add(const Duration(hours: 10, minutes: 30)),
        color: const Color(0xFF3F51B5),
        resourceIds: ['room-a'],
        metadata: {'organizer': 'Alice', 'team': 'Platform'},
      ),
      TideEvent(
        id: 'mtg-2',
        subject: '1:1 with Manager',
        startTime: weekStart.add(const Duration(hours: 11)),
        endTime: weekStart.add(const Duration(hours: 11, minutes: 30)),
        color: const Color(0xFF607D8B),
        resourceIds: ['room-d'],
        metadata: {'organizer': 'Bob'},
      ),
      TideEvent(
        id: 'mtg-3',
        subject: 'Design Review',
        startTime: weekStart.add(const Duration(hours: 14)),
        endTime: weekStart.add(const Duration(hours: 15)),
        color: const Color(0xFF009688),
        resourceIds: ['room-b'],
        metadata: {'organizer': 'Charlie', 'team': 'Design'},
      ),

      // Tuesday
      TideEvent(
        id: 'mtg-4',
        subject: 'Board Meeting',
        startTime: weekStart.add(const Duration(days: 1, hours: 10)),
        endTime: weekStart.add(const Duration(days: 1, hours: 12)),
        color: const Color(0xFFFF5722),
        resourceIds: ['room-c'],
        metadata: {'organizer': 'CEO', 'confidential': true},
      ),
      TideEvent(
        id: 'mtg-5',
        subject: 'Team Standup',
        startTime: weekStart.add(const Duration(days: 1, hours: 9)),
        endTime: weekStart.add(const Duration(days: 1, hours: 9, minutes: 15)),
        color: const Color(0xFF009688),
        resourceIds: ['room-b'],
        metadata: {'organizer': 'Alice', 'recurring': true},
      ),

      // Wednesday
      TideEvent(
        id: 'mtg-6',
        subject: 'Product Demo',
        startTime: weekStart.add(const Duration(days: 2, hours: 14)),
        endTime: weekStart.add(const Duration(days: 2, hours: 15, minutes: 30)),
        color: const Color(0xFF3F51B5),
        resourceIds: ['room-a'],
        metadata: {'organizer': 'Diana', 'external': true},
      ),
      TideEvent(
        id: 'mtg-7',
        subject: 'Retro',
        startTime: weekStart.add(const Duration(days: 2, hours: 16)),
        endTime: weekStart.add(const Duration(days: 2, hours: 17)),
        color: const Color(0xFF009688),
        resourceIds: ['room-b'],
        metadata: {'organizer': 'Alice', 'team': 'Platform'},
      ),

      // Thursday
      TideEvent(
        id: 'mtg-8',
        subject: 'All Hands',
        startTime: weekStart.add(const Duration(days: 3, hours: 11)),
        endTime: weekStart.add(const Duration(days: 3, hours: 12)),
        color: const Color(0xFFFF5722),
        resourceIds: ['room-c'],
        metadata: {'organizer': 'CEO', 'company-wide': true},
      ),

      // Friday
      TideEvent(
        id: 'mtg-9',
        subject: 'Knowledge Share',
        startTime: weekStart.add(const Duration(days: 4, hours: 15)),
        endTime: weekStart.add(const Duration(days: 4, hours: 16)),
        color: const Color(0xFF3F51B5),
        resourceIds: ['room-a'],
        metadata: {'organizer': 'Eve', 'topic': 'Flutter internals'},
      ),
    ];

    _datasource.addEvents(meetings);
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
      initialView: TideView.timelineWeek,
      allowedViews: [
        TideView.timelineDay,
        TideView.timelineWeek,
        TideView.week,
        TideView.month,
      ],
      showResourceView: true,
      resourceHeaderWidth: 150,
      startHour: 8,
      endHour: 19,
      allowDragAndDrop: true,
      allowResize: true,
      themeData: const TideThemeData(
        primaryColor: Color(0xFF3F51B5),
        todayHighlightColor: Color(0xFF3F51B5),
        resourceHeaderWidth: 150,
        headerTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
      onEventTap: (event) {
        final organizer = event.metadata?['organizer'] ?? 'Unknown';
        final room = event.resourceIds?.first ?? 'No room';
        debugPrint(
          'Meeting: ${event.subject} | Organizer: $organizer | Room: $room',
        );
      },
      onEmptySlotTap: (dateTime) {
        debugPrint('Empty slot tapped at: $dateTime');
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

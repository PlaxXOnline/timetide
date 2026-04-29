import 'package:flutter/widgets.dart';
import 'package:timetide/timetide.dart';

/// Companion widgets example — TideDateStrip, TideSlotPicker, TideTemplateEditor.
///
/// Demonstrates:
/// - TideDateStrip for date selection
/// - TideSlotPicker with resource grouping
/// - TideTemplateEditor for weekly shift planning
void main() {
  runApp(const CompanionWidgetsApp());
}

class CompanionWidgetsApp extends StatelessWidget {
  const CompanionWidgetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Companion Widgets',
      color: const Color(0xFF4CAF50),
      home: const Directionality(
        textDirection: TextDirection.ltr,
        child: CompanionWidgetsScreen(),
      ),
    );
  }
}

class CompanionWidgetsScreen extends StatefulWidget {
  const CompanionWidgetsScreen({super.key});

  @override
  State<CompanionWidgetsScreen> createState() => _CompanionWidgetsScreenState();
}

class _CompanionWidgetsScreenState extends State<CompanionWidgetsScreen> {
  late DateTime _selectedDate;
  TideSlot? _selectedSlot;

  static const _resources = [
    TideResource(
      id: 'alice',
      displayName: 'Alice',
      color: Color(0xFF4CAF50),
    ),
    TideResource(
      id: 'bob',
      displayName: 'Bob',
      color: Color(0xFF2196F3),
    ),
  ];

  static const _templateSlots = [
    TideTemplateSlot(
      id: 'ts-1',
      resourceId: 'alice',
      dayOfWeek: 1, // Monday
      startTime: TideTimeOfDay(hour: 9, minute: 0),
      endTime: TideTimeOfDay(hour: 12, minute: 0),
    ),
    TideTemplateSlot(
      id: 'ts-2',
      resourceId: 'alice',
      dayOfWeek: 3, // Wednesday
      startTime: TideTimeOfDay(hour: 9, minute: 0),
      endTime: TideTimeOfDay(hour: 12, minute: 0),
    ),
    TideTemplateSlot(
      id: 'ts-3',
      resourceId: 'bob',
      dayOfWeek: 1, // Monday
      startTime: TideTimeOfDay(hour: 13, minute: 0),
      endTime: TideTimeOfDay(hour: 17, minute: 0),
    ),
    TideTemplateSlot(
      id: 'ts-4',
      resourceId: 'bob',
      dayOfWeek: 1, // Monday — break
      startTime: TideTimeOfDay(hour: 15, minute: 0),
      endTime: TideTimeOfDay(hour: 15, minute: 30),
      isBreak: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  List<TideSlot> _buildSlots() {
    final d = _selectedDate;
    return [
      TideSlot(
        id: 'slot-alice-900',
        startTime: d.add(const Duration(hours: 9)),
        endTime: d.add(const Duration(hours: 9, minutes: 30)),
        resourceId: 'alice',
        resourceName: 'Alice',
      ),
      TideSlot(
        id: 'slot-alice-930',
        startTime: d.add(const Duration(hours: 9, minutes: 30)),
        endTime: d.add(const Duration(hours: 10)),
        resourceId: 'alice',
        resourceName: 'Alice',
      ),
      TideSlot(
        id: 'slot-alice-1000',
        startTime: d.add(const Duration(hours: 10)),
        endTime: d.add(const Duration(hours: 10, minutes: 30)),
        resourceId: 'alice',
        resourceName: 'Alice',
      ),
      TideSlot(
        id: 'slot-bob-1030',
        startTime: d.add(const Duration(hours: 10, minutes: 30)),
        endTime: d.add(const Duration(hours: 11)),
        resourceId: 'bob',
        resourceName: 'Bob',
      ),
      TideSlot(
        id: 'slot-bob-1100',
        startTime: d.add(const Duration(hours: 11)),
        endTime: d.add(const Duration(hours: 11, minutes: 30)),
        resourceId: 'bob',
        resourceName: 'Bob',
      ),
      TideSlot(
        id: 'slot-bob-1400',
        startTime: d.add(const Duration(hours: 14)),
        endTime: d.add(const Duration(hours: 14, minutes: 30)),
        resourceId: 'bob',
        resourceName: 'Bob',
      ),
    ];
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedSlot = null;
    });
    debugPrint('Selected date: $date');
  }

  void _onSlotSelected(TideSlot slot) {
    setState(() => _selectedSlot = slot);
    debugPrint('Selected slot: ${slot.id} at ${slot.startTime}');
  }

  void _onSlotCreated(TideTemplateSlot slot) {
    debugPrint('Created template slot: ${slot.id} day=${slot.dayOfWeek}');
  }

  void _onSlotUpdated(TideTemplateSlot slot) {
    debugPrint('Updated template slot: ${slot.id}');
  }

  void _onSlotDeleted(TideTemplateSlot slot) {
    debugPrint('Deleted template slot: ${slot.id}');
  }

  @override
  Widget build(BuildContext context) {
    return TideTheme(
      data: const TideThemeData(),
      child: Container(
        color: const Color(0xFFFFFFFF),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Companion Widgets Demo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 16),
            TideDateStrip(
              selectedDate: _selectedDate,
              onDateSelected: _onDateSelected,
              dayCount: 14,
              showTodayIndicator: true,
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Slots',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 8),
            TideSlotPicker(
              slots: _buildSlots(),
              selectedSlot: _selectedSlot,
              onSlotSelected: _onSlotSelected,
              groupByResource: true,
            ),
            const SizedBox(height: 24),
            const Text(
              'Weekly Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TideTemplateEditor(
                resources: _resources,
                slots: _templateSlots,
                startHour: 8,
                endHour: 18,
                onSlotCreated: _onSlotCreated,
                onSlotUpdated: _onSlotUpdated,
                onSlotDeleted: _onSlotDeleted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

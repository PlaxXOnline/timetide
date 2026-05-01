import 'package:flutter/widgets.dart';
import 'package:timetide/timetide.dart';

/// TideShiftPlanner example — weekly resource-based shift planning with
/// drag & drop, week navigation, and bulk-copy.
///
/// Demonstrates:
/// - 4 mock resources (employees) rendered in the sidebar palette.
/// - 5–10 seeded shifts spread across the current week.
/// - Toolbar with [TideKwBadge], previous/next-week buttons, and
///   "copy previous week" via [TideShiftPlannerController.copyPreviousWeek].
/// - [ShiftDragMode.instantWithDefaults] (drop a resource onto a day to
///   instantly create a 09:00–17:00 shift).
/// - Sundays declared closed via `closedDaysOfWeek: {DateTime.sunday}`.
/// - `onShiftCreated`, `onShiftTap`, and `onAddShiftPressed` callbacks
///   wired to an in-pane status banner.
///
/// Stays widget-layer only (no Material/Cupertino) to match the other
/// examples in this directory.
void main() {
  runApp(const ShiftPlannerApp());
}

class ShiftPlannerApp extends StatelessWidget {
  const ShiftPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'TideShiftPlanner Demo',
      color: const Color(0xFF3B82F6),
      home: const Directionality(
        textDirection: TextDirection.ltr,
        child: ShiftPlannerScreen(),
      ),
    );
  }
}

class ShiftPlannerScreen extends StatefulWidget {
  const ShiftPlannerScreen({super.key});

  @override
  State<ShiftPlannerScreen> createState() => _ShiftPlannerScreenState();
}

class _ShiftPlannerScreenState extends State<ShiftPlannerScreen> {
  static const _resources = <TideResource>[
    TideResource(
      id: 'r1',
      displayName: 'Anna Müller',
      color: Color(0xFF3B82F6),
    ),
    TideResource(
      id: 'r2',
      displayName: 'Ben Schulz',
      color: Color(0xFF10B981),
    ),
    TideResource(
      id: 'r3',
      displayName: 'Clara Weber',
      color: Color(0xFFF59E0B),
    ),
    TideResource(
      id: 'r4',
      displayName: 'David Hoffmann',
      color: Color(0xFFEF4444),
    ),
  ];

  static const _closedDays = <int>{DateTime.sunday};

  late final TideShiftPlannerController _controller;
  late List<TideEvent> _events;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _controller = TideShiftPlannerController();
    _events = _seedEvents(_controller.currentWeekStart);
    _controller.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) setState(() {});
  }

  /// Seven plausible shifts spread over Mon..Sat of [weekStart].
  List<TideEvent> _seedEvents(DateTime weekStart) {
    DateTime at(int dayOffset, int startHour, int endHour) =>
        DateTime(weekStart.year, weekStart.month, weekStart.day + dayOffset,
            startHour);
    DateTime end(int dayOffset, int hour) =>
        DateTime(weekStart.year, weekStart.month, weekStart.day + dayOffset,
            hour);

    return <TideEvent>[
      // Monday — Anna 08:00–16:00, Ben 12:00–20:00
      TideEvent(
        id: 'seed-mon-anna',
        subject: 'Anna Müller',
        startTime: at(0, 8, 0),
        endTime: end(0, 16),
        color: _resources[0].color,
        resourceIds: const ['r1'],
      ),
      TideEvent(
        id: 'seed-mon-ben',
        subject: 'Ben Schulz',
        startTime: at(0, 12, 0),
        endTime: end(0, 20),
        color: _resources[1].color,
        resourceIds: const ['r2'],
      ),
      // Tuesday — Clara 09:00–17:00
      TideEvent(
        id: 'seed-tue-clara',
        subject: 'Clara Weber',
        startTime: at(1, 9, 0),
        endTime: end(1, 17),
        color: _resources[2].color,
        resourceIds: const ['r3'],
      ),
      // Wednesday — David 10:00–18:00, Anna 08:00–14:00
      TideEvent(
        id: 'seed-wed-david',
        subject: 'David Hoffmann',
        startTime: at(2, 10, 0),
        endTime: end(2, 18),
        color: _resources[3].color,
        resourceIds: const ['r4'],
      ),
      TideEvent(
        id: 'seed-wed-anna',
        subject: 'Anna Müller',
        startTime: at(2, 8, 0),
        endTime: end(2, 14),
        color: _resources[0].color,
        resourceIds: const ['r1'],
      ),
      // Thursday — Ben 09:00–17:00
      TideEvent(
        id: 'seed-thu-ben',
        subject: 'Ben Schulz',
        startTime: at(3, 9, 0),
        endTime: end(3, 17),
        color: _resources[1].color,
        resourceIds: const ['r2'],
      ),
      // Friday — Clara 08:00–14:00, David 14:00–20:00
      TideEvent(
        id: 'seed-fri-clara',
        subject: 'Clara Weber',
        startTime: at(4, 8, 0),
        endTime: end(4, 14),
        color: _resources[2].color,
        resourceIds: const ['r3'],
      ),
      TideEvent(
        id: 'seed-fri-david',
        subject: 'David Hoffmann',
        startTime: at(4, 14, 0),
        endTime: end(4, 20),
        color: _resources[3].color,
        resourceIds: const ['r4'],
      ),
    ];
  }

  void _onShiftCreated(TideEvent event) {
    setState(() {
      _events = <TideEvent>[..._events, event];
      _statusMessage = 'Created shift ${event.id} for ${event.subject} '
          'on ${_formatDate(event.startTime)}.';
    });
  }

  void _onShiftTap(TideEvent event) {
    setState(() {
      _statusMessage = 'Tapped: ${event.subject} '
          '(${_formatTime(event.startTime)}–${_formatTime(event.endTime)})';
    });
  }

  void _onAddShiftPressed(DateTime date) {
    setState(() {
      _statusMessage = 'Add-shift button pressed for ${_formatDate(date)}.';
    });
  }

  void _copyPreviousWeek() {
    // Source-week events: those whose start date falls into the previous week.
    final prevStart =
        _controller.currentWeekStart.subtract(const Duration(days: 7));
    final prevEnd = _controller.currentWeekStart;
    final previousWeekEvents = _events
        .where((e) =>
            !e.startTime.isBefore(prevStart) && e.startTime.isBefore(prevEnd))
        .toList();

    final copied = _controller.copyPreviousWeek(
      previousWeekEvents: previousWeekEvents,
      isDayClosed: (d) => _closedDays.contains(d.weekday),
    );

    setState(() {
      _events = <TideEvent>[..._events, ...copied];
      _statusMessage = copied.isEmpty
          ? 'No events in the previous week to copy.'
          : 'Copied ${copied.length} shifts from previous week.';
    });
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${_pad(d.month)}-${_pad(d.day)}';
  String _formatTime(DateTime d) => '${_pad(d.hour)}:${_pad(d.minute)}';
  String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return TideTheme(
      data: const TideThemeData(),
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Toolbar(
              weekStart: _controller.currentWeekStart,
              onPrevious: _controller.goToPreviousWeek,
              onNext: _controller.goToNextWeek,
              onCopyPrevious: _copyPreviousWeek,
            ),
            if (_statusMessage != null) _StatusBanner(message: _statusMessage!),
            Expanded(
              child: TideShiftPlanner(
                resources: _resources,
                events: _events,
                weekStart: _controller.currentWeekStart,
                controller: _controller,
                closedDaysOfWeek: _closedDays,
                onShiftCreated: _onShiftCreated,
                onShiftTap: _onShiftTap,
                onAddShiftPressed: _onAddShiftPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight widget-layer toolbar (no Material AppBar dependency).
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.weekStart,
    required this.onPrevious,
    required this.onNext,
    required this.onCopyPrevious,
  });

  final DateTime weekStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCopyPrevious;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Text(
            'TideShiftPlanner Demo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 24),
          TideKwBadge(weekStart: weekStart),
          const Spacer(),
          _ToolbarButton(label: '< Vorwoche', onTap: onPrevious),
          const SizedBox(width: 8),
          _ToolbarButton(label: 'Nächste Woche >', onTap: onNext),
          const SizedBox(width: 8),
          _ToolbarButton(
            label: 'Vorwoche kopieren',
            onTap: onCopyPrevious,
            primary: true,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bg = primary ? const Color(0xFF3B82F6) : const Color(0xFFF3F4F6);
    final fg = primary ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFEFF6FF),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF1E3A8A),
        ),
      ),
    );
  }
}

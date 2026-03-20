import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/event.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';
import 'month_agenda_panel.dart';
import 'month_cell.dart';

/// A standard month calendar grid view (6 rows x 7 columns).
///
/// Features:
/// - Multi-day event spanning bars
/// - Configurable event display mode (indicator, text, custom)
/// - "+N" badge when events exceed [maxEventsPerCell]
/// - Optional agenda panel for the selected date
/// - Week number column
/// - Leading/trailing dates from adjacent months
class TideMonthView extends StatefulWidget {
  /// Creates a [TideMonthView].
  const TideMonthView({
    super.key,
    required this.controller,
    this.showAgendaPanel = false,
    this.agendaPanelHeight = 200.0,
    this.maxEventsPerCell = 3,
    this.showLeadingTrailingDates = true,
    this.showWeekNumbers = false,
    this.weekNumberWidth = 32.0,
    this.eventDisplayMode = TideEventDisplayMode.indicator,
    this.firstDayOfWeek = DateTime.monday,
    this.onEventTap,
    this.onDateTap,
    this.eventBuilder,
    this.emptyBuilder,
  });

  /// The controller managing navigation, selection, and data.
  final TideController controller;

  /// Whether to show the agenda panel for the selected date.
  final bool showAgendaPanel;

  /// Height of the agenda panel when visible.
  final double agendaPanelHeight;

  /// Maximum events shown per cell before "+N" badge.
  final int maxEventsPerCell;

  /// Whether to show dates from adjacent months.
  final bool showLeadingTrailingDates;

  /// Whether to show a week number column.
  final bool showWeekNumbers;

  /// Width of the week number column.
  final double weekNumberWidth;

  /// How events are displayed in each cell.
  final TideEventDisplayMode eventDisplayMode;

  /// First day of the week (1 = Monday, 7 = Sunday).
  final int firstDayOfWeek;

  /// Called when an event is tapped.
  final ValueChanged<TideEvent>? onEventTap;

  /// Called when a date cell is tapped.
  final ValueChanged<DateTime>? onDateTap;

  /// Custom builder for events in month cells.
  final Widget Function(BuildContext context, TideEvent event)? eventBuilder;

  /// Builder for the empty state in the agenda panel.
  final WidgetBuilder? emptyBuilder;

  @override
  State<TideMonthView> createState() => _TideMonthViewState();
}

class _TideMonthViewState extends State<TideMonthView> {
  List<TideEvent> _events = const [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _loadEvents();
  }

  @override
  void didUpdateWidget(TideMonthView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _loadEvents();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final gridDates = _buildGridDates();
    if (gridDates.isEmpty) return;

    final rangeStart = gridDates.first;
    final rangeEnd = DateTime(
      gridDates.last.year,
      gridDates.last.month,
      gridDates.last.day + 1,
    );

    final events =
        await widget.controller.datasource.getEvents(rangeStart, rangeEnd);

    if (mounted) {
      setState(() {
        _events = events;
      });
    }
  }

  /// Builds the 42-element grid of dates (6 rows x 7 columns).
  List<DateTime> _buildGridDates() {
    final display = widget.controller.displayDate;
    final firstOfMonth = DateTime(display.year, display.month, 1);
    final daysBefore =
        (firstOfMonth.weekday - widget.firstDayOfWeek + 7) % 7;
    final gridStart = firstOfMonth.subtract(Duration(days: daysBefore));

    return List.generate(42, (i) {
      return DateTime(gridStart.year, gridStart.month, gridStart.day + i);
    });
  }

  List<TideEvent> _eventsForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day + 1);
    return _events.where((e) {
      return e.startTime.isBefore(dayEnd) && e.endTime.isAfter(dayStart);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final display = widget.controller.displayDate;
    final gridDates = _buildGridDates();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = widget.controller.selectedDate;

    return Semantics(
      label: 'Month view',
      child: Column(
        children: [
          // Weekday headers
          _buildWeekdayHeaders(theme),

          // Month grid
          Expanded(
            child: Column(
              children: List.generate(6, (row) {
                return Expanded(
                  child: Row(
                    children: [
                      // Week number
                      if (widget.showWeekNumbers)
                        _buildWeekNumber(
                          theme,
                          gridDates[row * 7],
                        ),

                      // Day cells
                      for (var col = 0; col < 7; col++)
                        Expanded(
                          child: _buildCell(
                            context,
                            theme,
                            gridDates[row * 7 + col],
                            display,
                            today,
                            selectedDate,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Agenda panel
          if (widget.showAgendaPanel && selectedDate != null)
            SizedBox(
              height: widget.agendaPanelHeight,
              child: TideMonthAgendaPanel(
                selectedDate: selectedDate,
                events: _eventsForDate(selectedDate),
                onEventTap: widget.onEventTap,
                eventBuilder: widget.eventBuilder,
                emptyBuilder: widget.emptyBuilder,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders(TideThemeData theme) {
    final weekdays = <String>[];
    for (var i = 0; i < 7; i++) {
      final day = (widget.firstDayOfWeek + i - 1) % 7 + 1;
      weekdays.add(_shortWeekday(day));
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (widget.showWeekNumbers) SizedBox(width: widget.weekNumberWidth),
          for (final day in weekdays)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  day,
                  style: theme.dayHeaderTextStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekNumber(TideThemeData theme, DateTime weekDate) {
    final weekNumber = _isoWeekNumber(weekDate);
    return SizedBox(
      width: widget.weekNumberWidth,
      child: Center(
        child: Text(
          '$weekNumber',
          style: theme.timeSlotTextStyle,
        ),
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    TideThemeData theme,
    DateTime date,
    DateTime displayDate,
    DateTime today,
    DateTime? selectedDate,
  ) {
    final isCurrentMonth = date.month == displayDate.month &&
        date.year == displayDate.year;
    final isLeadingTrailing = !isCurrentMonth;

    if (isLeadingTrailing && !widget.showLeadingTrailingDates) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.monthCellBorderColor,
            width: 0.5,
          ),
        ),
      );
    }

    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isSelected = selectedDate != null &&
        date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;

    return TideMonthCell(
      date: date,
      events: _eventsForDate(date),
      isToday: isToday,
      isSelected: isSelected,
      isLeadingTrailing: isLeadingTrailing,
      maxEvents: widget.maxEventsPerCell,
      eventDisplayMode: widget.eventDisplayMode,
      onTap: () {
        widget.controller.selectDate(date);
        widget.onDateTap?.call(date);
      },
      onEventTap: widget.onEventTap,
      eventBuilder: widget.eventBuilder,
    );
  }

  static int _isoWeekNumber(DateTime date) {
    // ISO 8601 week number calculation.
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    final jan1 = DateTime(thursday.year, 1, 1);
    return ((thursday.difference(jan1).inDays) / 7).ceil() + 1;
  }

  static String _shortWeekday(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }
}

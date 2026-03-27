import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/drag_details.dart';
import '../../core/models/event.dart';
import '../../interaction/drag_drop/drag_handler.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';

/// A multi-week calendar view showing a configurable number of weeks (2–6).
///
/// Layout is similar to a month view but is not constrained to month
/// boundaries — it shows [numberOfWeeks] consecutive weeks starting from
/// the controller's display date. Use cases include 2-week shift views and
/// 4-week planning boards.
class TideMultiWeekView extends StatefulWidget {
  /// Creates a [TideMultiWeekView].
  const TideMultiWeekView({
    super.key,
    required this.controller,
    this.numberOfWeeks = 2,
    this.cellHeight = 100.0,
    this.dayHeaderHeight = 32.0,
    this.showTrailingLeadingDates = true,
    this.maxEventsPerCell = 3,
    this.onDateTap,
    this.onEventTap,
    this.onMoreEventsTap,
    this.cellBuilder,
    this.eventBuilder,
    this.allowDragAndDrop = false,
    this.allowResize = false,
    this.dragSnapInterval,
    this.dragStartBehavior = TideDragStartBehavior.adaptive,
    this.onDragEnd,
    this.onResizeEnd,
  }) : assert(numberOfWeeks >= 2 && numberOfWeeks <= 6);

  /// The controller managing navigation, data, and selection.
  final TideController controller;

  /// Number of weeks to display (2–6).
  final int numberOfWeeks;

  /// Height of each week row.
  final double cellHeight;

  /// Height of the day-of-week header.
  final double dayHeaderHeight;

  /// Whether to show dates from adjacent periods.
  final bool showTrailingLeadingDates;

  /// Maximum number of events to show per cell before showing "+N more".
  final int maxEventsPerCell;

  /// Called when a date cell is tapped.
  final ValueChanged<DateTime>? onDateTap;

  /// Called when an event is tapped.
  final ValueChanged<TideEvent>? onEventTap;

  /// Called when the "+N more" indicator is tapped.
  final void Function(DateTime date, List<TideEvent> events)? onMoreEventsTap;

  /// Custom builder for day cells.
  final Widget Function(BuildContext, DateTime, List<TideEvent>)? cellBuilder;

  /// Custom builder for event items within cells.
  final Widget Function(BuildContext, TideEvent)? eventBuilder;

  /// Whether events can be dragged.
  final bool allowDragAndDrop;

  /// Whether events can be resized.
  final bool allowResize;

  /// Time grid snap interval for drag operations.
  final Duration? dragSnapInterval;

  /// When the drag gesture starts.
  final TideDragStartBehavior dragStartBehavior;

  /// Called when a drag operation completes.
  final void Function(TideDragEndDetails details)? onDragEnd;

  /// Called when a resize operation completes.
  final void Function(TideResizeEndDetails details)? onResizeEnd;

  @override
  State<TideMultiWeekView> createState() => _TideMultiWeekViewState();
}

class _TideMultiWeekViewState extends State<TideMultiWeekView> {
  List<TideEvent> _events = [];
  bool _isLoading = true;

  /// The start date of the grid (Monday of the first week).
  DateTime get _gridStart {
    final d = widget.controller.displayDate;
    return DateTime(d.year, d.month, d.day)
        .subtract(Duration(days: d.weekday - 1));
  }

  /// All dates in the grid.
  List<DateTime> get _dates {
    final start = _gridStart;
    final totalDays = widget.numberOfWeeks * 7;
    return List.generate(
      totalDays,
      (i) => start.add(Duration(days: i)),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _loadData();
  }

  @override
  void didUpdateWidget(TideMultiWeekView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _loadData();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => _loadData();

  Future<void> _loadData() async {
    final dates = _dates;
    if (dates.isEmpty) return;
    final start = dates.first;
    final end = dates.last.add(const Duration(days: 1));
    final events = await widget.controller.datasource.getEvents(start, end);
    if (!mounted) return;
    setState(() {
      _events = events;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final theme = TideTheme.of(context);
    final dates = _dates;

    return Semantics(
      label: 'Multi-week view, ${widget.numberOfWeeks} weeks',
      child: Column(
        children: [
          // Day-of-week headers.
          SizedBox(
            height: widget.dayHeaderHeight,
            child: _buildDayHeaders(theme),
          ),
          // Week rows.
          Expanded(
            child: Column(
              children: List.generate(widget.numberOfWeeks, (weekIndex) {
                final weekDates =
                    dates.skip(weekIndex * 7).take(7).toList();
                return Expanded(
                  child: _buildWeekRow(theme, weekDates),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeaders(TideThemeData theme) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: dayNames.map((name) {
        return Expanded(
          child: Center(
            child: Text(name, style: theme.dayHeaderTextStyle),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekRow(TideThemeData theme, List<DateTime> weekDates) {
    return Row(
      children: weekDates.map((date) {
        return Expanded(
          child: _buildDayCell(theme, date),
        );
      }).toList(),
    );
  }

  Widget _buildDayCell(TideThemeData theme, DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final dayEvents = _events
        .where(
            (e) => e.startTime.isBefore(dayEnd) && e.endTime.isAfter(dayStart))
        .toList();
    final isToday = _isToday(date);
    final isSelected = widget.controller.selectedDate != null &&
        _isSameDay(widget.controller.selectedDate!, date);

    if (widget.cellBuilder != null) {
      return widget.cellBuilder!(context, date, dayEvents);
    }

    return Semantics(
      label:
          '${date.day} ${date.month}, ${dayEvents.length} events',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDateTap != null ? () => widget.onDateTap!(date) : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isToday
                ? theme.todayCellColor
                : isSelected
                    ? theme.selectedCellColor
                    : null,
            border: Border.all(
              color: theme.monthCellBorderColor,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date number.
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  '${date.day}',
                  style: isToday
                      ? theme.monthDateTextStyle.copyWith(
                          color: theme.todayHighlightColor,
                        )
                      : theme.monthDateTextStyle,
                ),
              ),
              // Events.
              ...dayEvents.take(widget.maxEventsPerCell).map((event) {
                if (widget.eventBuilder != null) {
                  return widget.eventBuilder!(context, event);
                }

                Widget eventWidget = DecoratedBox(
                  decoration: BoxDecoration(
                    color: event.color ?? theme.primaryColor,
                    borderRadius:
                        const BorderRadius.all(Radius.circular(2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    child: Text(
                      event.subject,
                      style: theme.eventTitleStyle.copyWith(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                );

                if (widget.allowDragAndDrop) {
                  eventWidget = TideDragHandler(
                    event: event,
                    controller: widget.controller,
                    dragStartBehavior: widget.dragStartBehavior,
                    snapInterval: widget.dragSnapInterval,
                    showGhost: true,
                    onTap: widget.onEventTap != null
                        ? () => widget.onEventTap!(event)
                        : null,
                    onDragEnd: widget.onDragEnd != null
                        ? (details) async {
                            widget.onDragEnd!(details);
                            return true;
                          }
                        : null,
                    child: eventWidget,
                  );
                } else {
                  eventWidget = GestureDetector(
                    onTap: widget.onEventTap != null
                        ? () => widget.onEventTap!(event)
                        : null,
                    child: eventWidget,
                  );
                }

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: eventWidget,
                );
              }),
              // "+N more" indicator.
              if (dayEvents.length > widget.maxEventsPerCell)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: widget.onMoreEventsTap != null
                        ? () => widget.onMoreEventsTap!(date, dayEvents)
                        : null,
                    child: Text(
                      '+${dayEvents.length - widget.maxEventsPerCell} more',
                      style: theme.timeSlotTextStyle.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

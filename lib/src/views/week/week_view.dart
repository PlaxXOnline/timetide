import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/event.dart';
import '../../core/models/time_region.dart';
import '../../rendering/current_time_painter.dart';
import '../../rendering/event_layout_engine.dart';
import '../../rendering/time_region_painter.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';
import '../day/day_view_layout.dart';
import '../day/time_slot_widget.dart';
import 'week_header.dart';

/// A 7-column (configurable) week calendar view.
///
/// Shows a shared vertical time axis on the left and one column per day.
/// All-day events span across day columns at the top. Supports swipe
/// navigation via [TideController.forward] / [TideController.backward].
class TideWeekView extends StatefulWidget {
  /// Creates a [TideWeekView].
  const TideWeekView({
    super.key,
    required this.controller,
    this.numberOfDays = 7,
    this.firstDayOfWeek = DateTime.monday,
    this.showWeekends = true,
    this.timeSlotInterval = const Duration(minutes: 30),
    this.startHour = 0,
    this.endHour = 24,
    this.hourHeight = 60.0,
    this.timeAxisWidth = 56.0,
    this.showAllDayPanel = true,
    this.showCurrentTimeIndicator = true,
    this.workingHoursStart,
    this.workingHoursEnd,
    this.eventOverlapStrategy = TideOverlapStrategy.sideBySide,
    this.onEventTap,
    this.onEmptySlotTap,
    this.eventBuilder,
    this.allDayEventBuilder,
  });

  /// The controller managing navigation, selection, and data.
  final TideController controller;

  /// Number of day columns to display. Defaults to 7.
  final int numberOfDays;

  /// First day of the week (1 = Monday, 7 = Sunday). Defaults to Monday.
  final int firstDayOfWeek;

  /// Whether to include weekend days. Defaults to true.
  final bool showWeekends;

  /// Duration of each time-slot row.
  final Duration timeSlotInterval;

  /// First visible hour.
  final double startHour;

  /// Last visible hour.
  final double endHour;

  /// Pixels per hour.
  final double hourHeight;

  /// Width of the time-axis labels column.
  final double timeAxisWidth;

  /// Whether to show the all-day event panel.
  final bool showAllDayPanel;

  /// Whether to show the current time indicator.
  final bool showCurrentTimeIndicator;

  /// Start of working hours as fractional hour.
  final double? workingHoursStart;

  /// End of working hours as fractional hour.
  final double? workingHoursEnd;

  /// Strategy for laying out overlapping events.
  final TideOverlapStrategy eventOverlapStrategy;

  /// Called when an event is tapped.
  final ValueChanged<TideEvent>? onEventTap;

  /// Called when an empty time slot is tapped.
  final ValueChanged<DateTime>? onEmptySlotTap;

  /// Custom builder for timed event tiles.
  final Widget Function(BuildContext context, TideEvent event)? eventBuilder;

  /// Custom builder for all-day event tiles.
  final Widget Function(BuildContext context, TideEvent event)?
      allDayEventBuilder;

  @override
  State<TideWeekView> createState() => _TideWeekViewState();
}

class _TideWeekViewState extends State<TideWeekView> {
  late final ScrollController _scrollController;
  late final TideCurrentTimeNotifier _timeNotifier;
  List<TideEvent> _events = const [];
  List<TideTimeRegion> _timeRegions = const [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _timeNotifier = TideCurrentTimeNotifier();
    widget.controller.addListener(_onControllerChanged);
    _loadEvents();
  }

  @override
  void didUpdateWidget(TideWeekView oldWidget) {
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
    _scrollController.dispose();
    _timeNotifier.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    _loadEvents();
  }

  List<DateTime> get _visibleDates {
    final display = widget.controller.displayDate;
    final weekStart =
        display.subtract(Duration(days: (display.weekday - widget.firstDayOfWeek + 7) % 7));
    final dates = <DateTime>[];
    for (var i = 0; i < widget.numberOfDays; i++) {
      final date = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day + i,
      );
      if (!widget.showWeekends &&
          (date.weekday == DateTime.saturday ||
              date.weekday == DateTime.sunday)) {
        continue;
      }
      dates.add(date);
    }
    return dates;
  }

  Future<void> _loadEvents() async {
    final dates = _visibleDates;
    if (dates.isEmpty) return;

    final rangeStart = dates.first;
    final rangeEnd = DateTime(
      dates.last.year,
      dates.last.month,
      dates.last.day + 1,
    );

    final events =
        await widget.controller.datasource.getEvents(rangeStart, rangeEnd);
    final regions =
        await widget.controller.datasource.getTimeRegions(rangeStart, rangeEnd);

    if (mounted) {
      setState(() {
        _events = events;
        _timeRegions = regions;
      });
    }
  }

  List<TideEvent> _eventsForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day + 1);
    return _events.where((e) {
      return e.startTime.isBefore(dayEnd) && e.endTime.isAfter(dayStart);
    }).toList();
  }

  List<TideTimeRegion> _regionsForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day + 1);
    return _timeRegions.where((r) {
      return r.startTime.isBefore(dayEnd) && r.endTime.isAfter(dayStart);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final dates = _visibleDates;
    final allDayEvents = _events.where((e) => e.isAllDay).toList();
    final totalHours = widget.endHour - widget.startHour;
    final totalHeight = totalHours * widget.hourHeight;

    return Semantics(
      label: 'Week view',
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -200) {
            widget.controller.forward();
          } else if (details.primaryVelocity! > 200) {
            widget.controller.backward();
          }
        },
        child: Column(
          children: [
            // Day headers
            TideWeekHeader(
              dates: dates,
              timeAxisWidth: widget.timeAxisWidth,
            ),

            // All-day events
            if (widget.showAllDayPanel && allDayEvents.isNotEmpty)
              _buildAllDayRow(context, theme, dates, allDayEvents),

            // Scrollable time grid
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: SizedBox(
                  height: totalHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time axis
                      SizedBox(
                        width: widget.timeAxisWidth,
                        height: totalHeight,
                        child: CustomPaint(
                          painter: _WeekTimeAxisPainter(
                            startHour: widget.startHour,
                            endHour: widget.endHour,
                            hourHeight: widget.hourHeight,
                            textStyle: theme.timeSlotTextStyle,
                          ),
                        ),
                      ),

                      // Day columns
                      for (final date in dates)
                        Expanded(
                          child: _buildDayColumn(context, theme, date),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllDayRow(
    BuildContext context,
    TideThemeData theme,
    List<DateTime> dates,
    List<TideEvent> allDayEvents,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: widget.timeAxisWidth,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text('All day', style: theme.timeSlotTextStyle),
            ),
          ),
          for (final date in dates)
            Expanded(
              child: _buildAllDayCell(context, theme, date, allDayEvents),
            ),
        ],
      ),
    );
  }

  Widget _buildAllDayCell(
    BuildContext context,
    TideThemeData theme,
    DateTime date,
    List<TideEvent> allDayEvents,
  ) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day + 1);
    final dayAllDay = allDayEvents.where((e) {
      return e.startTime.isBefore(dayEnd) && e.endTime.isAfter(dayStart);
    }).toList();

    if (dayAllDay.isEmpty) return const SizedBox(height: 24);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: dayAllDay.map((event) {
          if (widget.allDayEventBuilder != null) {
            return widget.allDayEventBuilder!(context, event);
          }
          final color = event.color ?? theme.primaryColor;
          return Semantics(
            label: 'All-day event: ${event.subject}',
            button: true,
            child: GestureDetector(
              onTap: widget.onEventTap != null
                  ? () => widget.onEventTap!(event)
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 1),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: theme.eventBorderRadius,
                ),
                child: Text(
                  event.subject,
                  style: theme.eventTitleStyle.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayColumn(
    BuildContext context,
    TideThemeData theme,
    DateTime date,
  ) {
    final dayEvents = TideDayViewLayout.timedEvents(_eventsForDate(date));
    final dayRegions = _regionsForDate(date);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final layoutResults = TideDayViewLayout.layoutEvents(
          events: dayEvents,
          strategy: widget.eventOverlapStrategy,
          startHour: widget.startHour,
          endHour: widget.endHour,
          availableWidth: availableWidth,
          hourHeight: widget.hourHeight,
        );

        final positionedRegions = dayRegions.map((region) {
          final top = TideDayViewLayout.timeToY(
            time: region.startTime,
            startHour: widget.startHour,
            hourHeight: widget.hourHeight,
          );
          final bottom = TideDayViewLayout.timeToY(
            time: region.endTime,
            startHour: widget.startHour,
            hourHeight: widget.hourHeight,
          );
          return TidePositionedRegion(
            type: region.type,
            top: top,
            height: bottom - top,
            color: region.color,
            text: region.text,
          );
        }).toList();

        return TideTimeSlotWidget(
          date: date,
          startHour: widget.startHour,
          endHour: widget.endHour,
          hourHeight: widget.hourHeight,
          timeSlotInterval: widget.timeSlotInterval,
          workingHoursStart: widget.workingHoursStart,
          workingHoursEnd: widget.workingHoursEnd,
          onEmptySlotTap: widget.onEmptySlotTap,
          child: Stack(
            children: [
              // Time regions (non-interactive)
              if (positionedRegions.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: TideTimeRegionPainter(regions: positionedRegions),
                    ),
                  ),
                ),

              // Day column border
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 0.5,
                    color: theme.borderColor,
                  ),
                ),
              ),

              // Events
              for (final result in layoutResults)
                Positioned(
                  left: result.bounds.left,
                  top: result.bounds.top,
                  width: result.bounds.width,
                  height: result.bounds.height,
                  child: _buildEventTile(context, theme, result.event),
                ),

              // Current time indicator (non-interactive)
              if (widget.showCurrentTimeIndicator && _isToday(date))
                ListenableBuilder(
                  listenable: _timeNotifier,
                  builder: (context, _) {
                    return Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: TideCurrentTimePainter(
                            currentTime: _timeNotifier.currentTime,
                            startHour: widget.startHour,
                            endHour: widget.endHour,
                            hourHeight: widget.hourHeight,
                            color: theme.currentTimeIndicatorColor,
                            lineHeight: theme.currentTimeIndicatorHeight,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildEventTile(
    BuildContext context,
    TideThemeData theme,
    TideEvent event,
  ) {
    if (widget.eventBuilder != null) {
      return widget.eventBuilder!(context, event);
    }

    final color = event.color ?? theme.primaryColor;
    final isSelected = widget.controller.selectedEvents.contains(event);

    return Semantics(
      label: 'Event: ${event.subject}',
      button: true,
      child: GestureDetector(
        onTap:
            widget.onEventTap != null ? () => widget.onEventTap!(event) : null,
        child: Container(
          margin: EdgeInsets.only(right: theme.eventSpacing),
          padding: theme.eventPadding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: theme.eventBorderRadius,
            border: isSelected
                ? Border.all(color: theme.selectionColor, width: 2)
                : null,
          ),
          child: Text(
            event.subject,
            style: theme.eventTitleStyle.copyWith(fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Paints hour labels for the week view time axis.
class _WeekTimeAxisPainter extends CustomPainter {
  const _WeekTimeAxisPainter({
    required this.startHour,
    required this.endHour,
    required this.hourHeight,
    required this.textStyle,
  });

  final double startHour;
  final double endHour;
  final double hourHeight;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    for (var hour = startHour.ceil(); hour < endHour; hour++) {
      final y = (hour - startHour) * hourHeight;
      final label = '${hour.toString().padLeft(2, '0')}:00';
      final painter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(size.width - painter.width - 4, y - painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeekTimeAxisPainter oldDelegate) {
    return startHour != oldDelegate.startHour ||
        endHour != oldDelegate.endHour ||
        hourHeight != oldDelegate.hourHeight ||
        textStyle != oldDelegate.textStyle;
  }
}

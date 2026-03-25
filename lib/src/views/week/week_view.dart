import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/drag_details.dart';
import '../../core/models/event.dart';
import '../../core/models/time_region.dart';
import '../../interaction/drag_drop/drag_handler.dart';
import '../../interaction/drag_drop/resize_handler.dart';
import '../../interaction/drag_drop/time_axis.dart';
import '../../rendering/current_time_painter.dart';
import '../../rendering/event_layout_engine.dart';
import '../../rendering/time_region_painter.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';
import '../../widgets/event_content.dart';
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
    this.allowDragAndDrop = false,
    this.allowResize = false,
    this.dragSnapInterval,
    this.dragStartBehavior = TideDragStartBehavior.adaptive,
    this.onDragEnd,
    this.onResizeEnd,
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

  /// Whether drag and drop is enabled for events.
  final bool allowDragAndDrop;

  /// Whether resize handles are shown on events.
  final bool allowResize;

  /// Grid interval for snapping during drag/resize.
  final Duration? dragSnapInterval;

  /// When drag gesture begins.
  final TideDragStartBehavior dragStartBehavior;

  /// Called when a drag operation completes.
  final void Function(TideDragEndDetails details)? onDragEnd;

  /// Called when a resize operation completes.
  final void Function(TideResizeEndDetails details)? onResizeEnd;

  @override
  State<TideWeekView> createState() => _TideWeekViewState();
}

class _TideWeekViewState extends State<TideWeekView> {
  late final ScrollController _scrollController;
  late final TideCurrentTimeNotifier _timeNotifier;
  List<TideEvent> _events = const [];
  List<TideTimeRegion> _timeRegions = const [];

  /// GlobalKeys for day columns — used for cross-day drag hit-testing.
  final Map<int, GlobalKey> _dayColumnKeys = {};

  /// Tracks the last known global position during a drag for cross-day
  /// hit-testing when the drag ends.
  Offset? _lastDragGlobalPosition;

  // ─── Live snap-to-slot state ───────────────────────────
  /// The event currently being dragged, or `null`.
  TideEvent? _draggingEvent;

  /// The snapped proposed start time during an active drag.
  DateTime? _dragProposedStart;

  /// The proposed end time during an active resize drag.
  DateTime? _dragProposedEnd;

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
                      for (var i = 0; i < dates.length; i++) ...[
                        () {
                          _dayColumnKeys.putIfAbsent(i, GlobalKey.new);
                          return Expanded(
                            key: _dayColumnKeys[i],
                            child: _buildDayColumn(context, theme, dates[i]),
                          );
                        }(),
                      ],
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

    final timeAxis = TideTimeAxis.vertical(
      date: date,
      startHour: widget.startHour,
      hourHeight: widget.hourHeight,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Substitute the dragged event with its proposed position so the
        // layout engine places it at the snap slot (side-by-side overlap).
        final displayEvents = dayEvents.map((e) {
          if (_draggingEvent?.id == e.id && _dragProposedStart != null) {
            return e.copyWith(
              startTime: _dragProposedStart!,
              endTime: _dragProposedEnd ?? _dragProposedStart!.add(e.duration),
            );
          }
          return e;
        }).toList();

        final layoutResults = TideDayViewLayout.layoutEvents(
          events: displayEvents,
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
                  key: ValueKey(result.event.id),
                  left: result.bounds.left,
                  top: result.bounds.top,
                  width: result.bounds.width,
                  height: math.max(result.bounds.height, theme.eventMinHeight),
                  child: _buildEventTile(context, theme, result.event, timeAxis, date, math.max(result.bounds.height, theme.eventMinHeight)),
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

  /// Determines which day column contains the given global position.
  DateTime? _resolveDayAtPosition(Offset globalPosition) {
    final dates = _visibleDates;
    for (var i = 0; i < dates.length; i++) {
      final key = _dayColumnKeys[i];
      final renderBox =
          key?.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;
      final local = renderBox.globalToLocal(globalPosition);
      if (renderBox.paintBounds.contains(local)) {
        return dates[i];
      }
    }
    return null;
  }

  Widget _buildEventTile(
    BuildContext context,
    TideThemeData theme,
    TideEvent event,
    TideTimeAxis timeAxis,
    DateTime date,
    double tileHeight,
  ) {
    final isDragging = _draggingEvent?.id == event.id;

    // Build the visual content — either custom or default.
    Widget tile;
    if (widget.eventBuilder != null) {
      tile = widget.eventBuilder!(context, event);
    } else {
      final color = event.color ?? theme.primaryColor;
      final isSelected = widget.controller.selectedEvents.contains(event);

      final tileContent = Semantics(
        label: 'Event: ${event.subject}',
        button: true,
        child: Container(
          margin: EdgeInsets.only(right: theme.eventSpacing),
          padding: theme.eventPadding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: theme.eventBorderRadius,
            border: isDragging
                ? Border.all(color: theme.selectionColor, width: 2)
                : isSelected
                    ? Border.all(color: theme.selectionColor, width: 2)
                    : null,
          ),
          child: TideEventContent(
            subject: event.subject,
            titleStyle: theme.eventTitleStyle.copyWith(fontSize: 11),
            padding: EdgeInsets.zero,
            availableHeight: tileHeight - theme.eventPadding.vertical,
          ),
        ),
      );

      if (widget.allowDragAndDrop) {
        tile = tileContent;
      } else {
        tile = GestureDetector(
          onTap: widget.onEventTap != null
              ? () => widget.onEventTap!(event)
              : null,
          child: tileContent,
        );
      }
    }

    // Apply reduced opacity when this event is being dragged.
    if (isDragging) {
      tile = Opacity(opacity: 0.7, child: tile);
    }

    // ALWAYS wrap with drag handler if enabled (includes resize when
    // allowResize is true — merged to avoid gesture-arena conflicts).
    if (widget.allowDragAndDrop) {
      tile = TideDragHandler(
        event: event,
        controller: widget.controller,
        timeAxis: timeAxis,
        dragStartBehavior: widget.dragStartBehavior,
        snapInterval: widget.dragSnapInterval,
        existingEvents: _events,
        showGhost: false,
        allowResize: widget.allowResize,
        resizeHandleSize: 8.0,
        onResizeEnd: widget.onResizeEnd != null
            ? (details) async {
                widget.onResizeEnd!(details);
                return true;
              }
            : null,
        onTap: widget.onEventTap != null
            ? () => widget.onEventTap!(event)
            : null,
        onDragStart: (dragEvent, offset) {
          setState(() {
            _draggingEvent = dragEvent;
            _dragProposedStart = dragEvent.startTime;
          });
        },
        onDragUpdate: (details) {
          _lastDragGlobalPosition = details.globalPosition;
          setState(() {
            _draggingEvent = details.event;
            _dragProposedStart = details.proposedStart;
            _dragProposedEnd = details.proposedEnd;
          });
        },
        onDragEnd: (details) async {
          // Resolve target day for cross-day drag.
          final resolvePos =
              details.dropPosition ?? _lastDragGlobalPosition;
          DateTime newStart = details.newStart;
          DateTime newEnd = details.newEnd;
          if (resolvePos != null) {
            final targetDay = _resolveDayAtPosition(resolvePos);
            if (targetDay != null) {
              final originDay = DateTime(date.year, date.month, date.day);
              final resolvedDay = DateTime(
                targetDay.year,
                targetDay.month,
                targetDay.day,
              );
              if (resolvedDay != originDay) {
                // Event was dragged to a different day — adjust the date
                // while keeping the time-of-day from the vertical drag.
                final timeOfDay = Duration(
                  hours: details.newStart.hour,
                  minutes: details.newStart.minute,
                );
                newStart = resolvedDay.add(timeOfDay);
                newEnd = newStart.add(details.event.duration);
              }
            }
          }
          _lastDragGlobalPosition = null;

          final enrichedDetails = TideDragEndDetails(
            event: details.event,
            newStart: newStart,
            newEnd: newEnd,
            dropPosition: details.dropPosition,
          );
          widget.onDragEnd?.call(enrichedDetails);
          await Future<void>.delayed(Duration.zero);
          if (mounted) {
            setState(() {
              _draggingEvent = null;
              _dragProposedStart = null;
              _dragProposedEnd = null;
            });
          }
          return true;
        },
        child: tile,
      );
    } else if (widget.allowResize) {
      tile = TideResizeHandler(
        event: event,
        timeAxis: timeAxis,
        snapInterval: widget.dragSnapInterval,
        onResizeEnd: (details) async {
          widget.onResizeEnd?.call(details);
          return true;
        },
        child: tile,
      );
    }

    return tile;
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

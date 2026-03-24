import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/drag_details.dart';
import '../../core/models/event.dart';
import '../../core/models/resource.dart';
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
import '../../widgets/resource_header/resource_header.dart';
import '../day/day_view_layout.dart';
import '../day/time_slot_widget.dart';

/// A resource week view showing resources as side-by-side column groups, each
/// subdivided into day sub-columns with a shared vertical time axis.
///
/// ```
/// ┌─────────┬──────────────────────┬──────────────────────┐
/// │         │       Alice          │       Bob            │
/// │  Time   │ Mon Tue Wed Thu Fri  │ Mon Tue Wed Thu Fri  │
/// ├─────────┼──────────────────────┼──────────────────────┤
/// │  09:00  │ ┌─┐         ┌─┐     │       ┌─┐           │
/// │         │ │M│         │R│     │       │D│           │
/// │  10:00  │ └─┘ ┌─┐     └─┘     │       └─┘ ┌─┐       │
/// │         │     │P│             │           │W│       │
/// │  11:00  │     └─┘             │           └─┘       │
/// └─────────┴──────────────────────┴──────────────────────┘
/// ```
class TideResourceWeekView extends StatefulWidget {
  /// Creates a [TideResourceWeekView].
  const TideResourceWeekView({
    super.key,
    required this.controller,
    this.timeSlotInterval = const Duration(minutes: 30),
    this.startHour = 0,
    this.endHour = 24,
    this.hourHeight = 60.0,
    this.timeAxisWidth = 56.0,
    this.minColumnWidth = 40.0,
    this.showAllDayPanel = true,
    this.showCurrentTimeIndicator = true,
    this.workingHoursStart,
    this.workingHoursEnd,
    this.eventOverlapStrategy = TideOverlapStrategy.sideBySide,
    this.allowDragAndDrop = false,
    this.allowResize = false,
    this.dragSnapInterval,
    this.dragStartBehavior = TideDragStartBehavior.adaptive,
    this.onEventTap,
    this.onEmptySlotTap,
    this.onDragEnd,
    this.onResizeEnd,
    this.eventBuilder,
    this.allDayEventBuilder,
    this.resourceHeaderBuilder,
    this.numberOfDays = 7,
    this.firstDayOfWeek = DateTime.monday,
    this.showWeekends = true,
  });

  /// The controller managing navigation, selection, and data.
  final TideController controller;

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

  /// Minimum width for each day sub-column.
  final double minColumnWidth;

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

  /// Whether drag and drop is enabled for events.
  final bool allowDragAndDrop;

  /// Whether resize handles are shown on events.
  final bool allowResize;

  /// Grid interval for snapping during drag/resize.
  final Duration? dragSnapInterval;

  /// When drag gesture begins.
  final TideDragStartBehavior dragStartBehavior;

  /// Called when an event is tapped.
  final ValueChanged<TideEvent>? onEventTap;

  /// Called when an empty time slot is tapped.
  final ValueChanged<DateTime>? onEmptySlotTap;

  /// Called when a drag operation completes.
  final void Function(TideDragEndDetails details)? onDragEnd;

  /// Called when a resize operation completes.
  final void Function(TideResizeEndDetails details)? onResizeEnd;

  /// Custom builder for timed event tiles.
  final Widget Function(BuildContext, TideEvent)? eventBuilder;

  /// Custom builder for all-day event tiles.
  final Widget Function(BuildContext, TideEvent)? allDayEventBuilder;

  /// Custom builder for resource column headers.
  final Widget Function(BuildContext, TideResource)? resourceHeaderBuilder;

  /// Number of days to show per resource. Defaults to 7.
  final int numberOfDays;

  /// First day of the week (1 = Monday, 7 = Sunday).
  final int firstDayOfWeek;

  /// Whether to show weekend days.
  final bool showWeekends;

  @override
  State<TideResourceWeekView> createState() => _TideResourceWeekViewState();
}

class _TideResourceWeekViewState extends State<TideResourceWeekView> {
  final ScrollController _scrollController = ScrollController();
  late final TideCurrentTimeNotifier _timeNotifier;

  List<TideResource> _resources = [];
  List<TideEvent> _events = [];
  List<TideTimeRegion> _timeRegions = [];
  bool _isLoading = true;

  /// GlobalKeys for resource columns — used for cross-resource drag.
  final Map<String, GlobalKey> _columnKeys = {};

  /// GlobalKeys for day sub-columns — used for cross-day drag.
  /// Key format: "resourceId_dayIndex".
  final Map<String, GlobalKey> _dayColumnKeys = {};

  List<DateTime> get _days {
    final range = widget.controller.visibleDateRange;
    final allDays = List.generate(
      widget.numberOfDays,
      (i) => range.start.add(Duration(days: i)),
    );
    if (!widget.showWeekends) {
      return allDays
          .where((d) => d.weekday != DateTime.saturday &&
              d.weekday != DateTime.sunday)
          .toList();
    }
    return allDays;
  }

  @override
  void initState() {
    super.initState();
    _timeNotifier = TideCurrentTimeNotifier();
    widget.controller.addListener(_onControllerChanged);
    _loadData();
  }

  @override
  void didUpdateWidget(TideResourceWeekView oldWidget) {
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
    _scrollController.dispose();
    _timeNotifier.dispose();
    super.dispose();
  }

  void _onControllerChanged() => _loadData();

  Future<void> _loadData() async {
    final range = widget.controller.visibleDateRange;
    final results = await Future.wait([
      widget.controller.datasource.getResources(),
      widget.controller.datasource.getEvents(range.start, range.end),
      widget.controller.datasource.getTimeRegions(range.start, range.end),
    ]);
    if (!mounted) return;
    setState(() {
      _resources = results[0] as List<TideResource>;
      _events = results[1] as List<TideEvent>;
      _timeRegions = results[2] as List<TideTimeRegion>;
      _isLoading = false;

      for (final r in _resources) {
        _columnKeys.putIfAbsent(r.id, GlobalKey.new);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final theme = TideTheme.of(context);

    return Semantics(
      label: 'Resource week view',
      child: Column(
        children: [
          // Resource header row (top level).
          _buildResourceHeaderRow(theme),

          // Day header row (sub-columns).
          _buildDayHeaderRow(theme),

          // Scrollable time grid.
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height:
                    (widget.endHour - widget.startHour) * widget.hourHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeAxis(theme),
                    Expanded(child: _buildResourceColumns(context, theme)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceHeaderRow(TideThemeData theme) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          SizedBox(width: widget.timeAxisWidth),
          Expanded(
            child: Row(
              children: _resources.map((resource) {
                return Expanded(
                  child: widget.resourceHeaderBuilder != null
                      ? widget.resourceHeaderBuilder!(context, resource)
                      : TideResourceHeader(resource: resource, height: 48),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeaderRow(TideThemeData theme) {
    final days = _days;
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          SizedBox(width: widget.timeAxisWidth),
          Expanded(
            child: Row(
              children: _resources.map((resource) {
                return Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: theme.resourceDividerColor,
                          width: theme.resourceDividerWidth,
                        ),
                        bottom: BorderSide(
                          color: theme.borderColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: days.map((day) {
                        final isToday = _isToday(day);
                        return Expanded(
                          child: Center(
                            child: Text(
                              _formatDayAbbrev(day),
                              style: isToday
                                  ? theme.dayHeaderTextStyle.copyWith(
                                      color: theme.todayHighlightColor,
                                    )
                                  : theme.dayHeaderTextStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAxis(TideThemeData theme) {
    final totalHours = widget.endHour - widget.startHour;
    final totalHeight = totalHours * widget.hourHeight;

    return SizedBox(
      width: widget.timeAxisWidth,
      height: totalHeight,
      child: CustomPaint(
        painter: _TimeAxisPainter(
          startHour: widget.startHour,
          endHour: widget.endHour,
          hourHeight: widget.hourHeight,
          textStyle: theme.timeSlotTextStyle,
        ),
      ),
    );
  }

  Widget _buildResourceColumns(BuildContext context, TideThemeData theme) {
    final days = _days;

    return Row(
      children: _resources.map((resource) {
        return Expanded(
          key: _columnKeys[resource.id],
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: theme.resourceDividerColor,
                  width: theme.resourceDividerWidth,
                ),
              ),
            ),
            child: Row(
              children: days.asMap().entries.map((dayEntry) {
                final dayIndex = dayEntry.key;
                final day = dayEntry.value;
                final dayStart = DateTime(day.year, day.month, day.day);
                final dayEnd = dayStart.add(const Duration(days: 1));

                final dayEvents = _events
                    .where((e) =>
                        !e.isAllDay &&
                        (e.resourceIds == null ||
                            e.resourceIds!.contains(resource.id)) &&
                        e.startTime.isBefore(dayEnd) &&
                        e.endTime.isAfter(dayStart))
                    .toList();

                final timeAxis = TideTimeAxis.vertical(
                  date: day,
                  startHour: widget.startHour,
                  hourHeight: widget.hourHeight,
                );

                final keyId = '${resource.id}_$dayIndex';
                _dayColumnKeys.putIfAbsent(keyId, GlobalKey.new);

                return Expanded(
                  child: _ResourceDaySubColumn(
                    key: _dayColumnKeys[keyId],
                    resource: resource,
                    events: dayEvents,
                    allEvents: _events,
                    timeRegions: _timeRegions,
                    date: day,
                    timeAxis: timeAxis,
                    startHour: widget.startHour,
                    endHour: widget.endHour,
                    hourHeight: widget.hourHeight,
                    timeSlotInterval: widget.timeSlotInterval,
                    workingHoursStart: widget.workingHoursStart,
                    workingHoursEnd: widget.workingHoursEnd,
                    eventOverlapStrategy: widget.eventOverlapStrategy,
                    showCurrentTimeIndicator:
                        widget.showCurrentTimeIndicator && _isToday(day),
                    timeNotifier: _timeNotifier,
                    controller: widget.controller,
                    allowDragAndDrop: widget.allowDragAndDrop,
                    allowResize: widget.allowResize,
                    dragSnapInterval: widget.dragSnapInterval,
                    dragStartBehavior: widget.dragStartBehavior,
                    onEventTap: widget.onEventTap,
                    onEmptySlotTap: widget.onEmptySlotTap,
                    onDragEnd: widget.onDragEnd,
                    onResizeEnd: widget.onResizeEnd,
                    eventBuilder: widget.eventBuilder,
                    resolveResourceAtPosition: _resolveResourceAtPosition,
                    resolveDayAtPosition: _resolveDayAtPosition,
                    showDivider: true,
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  String? _resolveResourceAtPosition(Offset globalPosition) {
    for (final entry in _columnKeys.entries) {
      final renderBox =
          entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;
      final local = renderBox.globalToLocal(globalPosition);
      if (renderBox.paintBounds.contains(local)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Determines which day sub-column contains the given global position.
  DateTime? _resolveDayAtPosition(Offset globalPosition) {
    final days = _days;
    for (final resource in _resources) {
      for (var i = 0; i < days.length; i++) {
        final keyId = '${resource.id}_$i';
        final key = _dayColumnKeys[keyId];
        final renderBox =
            key?.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) continue;
        final local = renderBox.globalToLocal(globalPosition);
        if (renderBox.paintBounds.contains(local)) {
          return days[i];
        }
      }
    }
    return null;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDayAbbrev(DateTime date) {
    const weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return weekdays[date.weekday - 1];
  }
}

/// A single day sub-column within a resource column for the week view.
class _ResourceDaySubColumn extends StatefulWidget {
  const _ResourceDaySubColumn({
    super.key,
    required this.resource,
    required this.events,
    required this.allEvents,
    required this.timeRegions,
    required this.date,
    required this.timeAxis,
    required this.startHour,
    required this.endHour,
    required this.hourHeight,
    required this.timeSlotInterval,
    this.workingHoursStart,
    this.workingHoursEnd,
    required this.eventOverlapStrategy,
    required this.showCurrentTimeIndicator,
    required this.timeNotifier,
    required this.controller,
    required this.allowDragAndDrop,
    required this.allowResize,
    this.dragSnapInterval,
    required this.dragStartBehavior,
    this.onEventTap,
    this.onEmptySlotTap,
    this.onDragEnd,
    this.onResizeEnd,
    this.eventBuilder,
    required this.resolveResourceAtPosition,
    required this.resolveDayAtPosition,
    required this.showDivider,
  });

  final TideResource resource;
  final List<TideEvent> events;
  final List<TideEvent> allEvents;
  final List<TideTimeRegion> timeRegions;
  final DateTime date;
  final TideTimeAxis timeAxis;
  final double startHour;
  final double endHour;
  final double hourHeight;
  final Duration timeSlotInterval;
  final double? workingHoursStart;
  final double? workingHoursEnd;
  final TideOverlapStrategy eventOverlapStrategy;
  final bool showCurrentTimeIndicator;
  final TideCurrentTimeNotifier timeNotifier;
  final TideController controller;
  final bool allowDragAndDrop;
  final bool allowResize;
  final Duration? dragSnapInterval;
  final TideDragStartBehavior dragStartBehavior;
  final ValueChanged<TideEvent>? onEventTap;
  final ValueChanged<DateTime>? onEmptySlotTap;
  final void Function(TideDragEndDetails details)? onDragEnd;
  final void Function(TideResizeEndDetails details)? onResizeEnd;
  final Widget Function(BuildContext, TideEvent)? eventBuilder;
  final String? Function(Offset globalPosition) resolveResourceAtPosition;
  final DateTime? Function(Offset globalPosition) resolveDayAtPosition;
  final bool showDivider;

  @override
  State<_ResourceDaySubColumn> createState() => _ResourceDaySubColumnState();
}

class _ResourceDaySubColumnState extends State<_ResourceDaySubColumn> {
  Offset? _lastDragGlobalPosition;

  // ─── Live snap-to-slot state ───────────────────────────
  /// The event currently being dragged, or `null`.
  TideEvent? _draggingEvent;

  /// The snapped proposed start time during an active drag.
  DateTime? _dragProposedStart;

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Substitute the dragged event with its proposed position so the
        // layout engine places it at the snap slot (side-by-side overlap).
        final displayEvents = widget.events.map((e) {
          if (_draggingEvent?.id == e.id && _dragProposedStart != null) {
            return e.copyWith(
              startTime: _dragProposedStart!,
              endTime: _dragProposedStart!.add(e.duration),
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

        final positionedRegions = _buildPositionedRegions();

        return DecoratedBox(
          decoration: BoxDecoration(
            border: widget.showDivider
                ? Border(
                    right: BorderSide(
                      color: theme.borderColor,
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: TideTimeSlotWidget(
            date: widget.date,
            startHour: widget.startHour,
            endHour: widget.endHour,
            hourHeight: widget.hourHeight,
            timeSlotInterval: widget.timeSlotInterval,
            workingHoursStart: widget.workingHoursStart,
            workingHoursEnd: widget.workingHoursEnd,
            onEmptySlotTap: widget.onEmptySlotTap,
            child: Stack(
              children: [
                if (positionedRegions.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: TideTimeRegionPainter(
                          regions: positionedRegions,
                        ),
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
                    child: _buildEventTile(context, theme, result.event, math.max(result.bounds.height, theme.eventMinHeight)),
                  ),

                if (widget.showCurrentTimeIndicator)
                  ListenableBuilder(
                    listenable: widget.timeNotifier,
                    builder: (context, _) {
                      return Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: TideCurrentTimePainter(
                              currentTime: widget.timeNotifier.currentTime,
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
          ),
        );
      },
    );
  }

  List<TidePositionedRegion> _buildPositionedRegions() {
    final resourceRegions = widget.timeRegions
        .where((r) =>
            r.resourceIds == null ||
            r.resourceIds!.contains(widget.resource.id))
        .toList();

    return resourceRegions.map((region) {
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
  }

  Widget _buildEventTile(
    BuildContext context,
    TideThemeData theme,
    TideEvent event,
    double tileHeight,
  ) {
    final isDragging = _draggingEvent?.id == event.id;

    // Build the visual content — either custom or default.
    Widget tile;
    if (widget.eventBuilder != null) {
      tile = widget.eventBuilder!(context, event);
    } else {
      final color = event.color ?? theme.primaryColor;

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
                : null,
          ),
          child: TideEventContent(
            subject: event.subject,
            titleStyle: theme.eventTitleStyle,
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
        timeAxis: widget.timeAxis,
        dragStartBehavior: widget.dragStartBehavior,
        snapInterval: widget.dragSnapInterval,
        existingEvents: widget.allEvents,
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
          setState(() {
            _draggingEvent = details.event;
            _dragProposedStart = details.proposedStart;
          });
          _lastDragGlobalPosition = details.globalPosition;
        },
        onDragEnd: (details) async {
          final resolvePos = details.dropPosition ?? _lastDragGlobalPosition;
          final newResourceId = resolvePos != null
              ? widget.resolveResourceAtPosition(resolvePos)
              : null;

          // Resolve target day for cross-day drag.
          DateTime newStart = details.newStart;
          DateTime newEnd = details.newEnd;
          if (resolvePos != null) {
            final targetDay = widget.resolveDayAtPosition(resolvePos);
            if (targetDay != null) {
              final originDay = DateTime(
                widget.date.year,
                widget.date.month,
                widget.date.day,
              );
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

          final enrichedDetails = TideDragEndDetails(
            event: details.event,
            newStart: newStart,
            newEnd: newEnd,
            newResourceId: newResourceId,
            sourceResourceId: widget.resource.id,
            dropPosition: details.dropPosition,
          );
          // Call parent FIRST so the new position propagates before
          // we clear the drag visual state. This prevents snap-back flicker.
          widget.onDragEnd?.call(enrichedDetails);
          await Future<void>.delayed(Duration.zero);
          if (mounted) {
            setState(() {
              _draggingEvent = null;
              _dragProposedStart = null;
            });
          }
          _lastDragGlobalPosition = null;
          return true;
        },
        child: tile,
      );
    } else if (widget.allowResize) {
      tile = TideResizeHandler(
        event: event,
        timeAxis: widget.timeAxis,
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

/// Paints time-axis labels along the left edge.
class _TimeAxisPainter extends CustomPainter {
  const _TimeAxisPainter({
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
        Offset(size.width - painter.width - 8, y - painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimeAxisPainter oldDelegate) {
    return startHour != oldDelegate.startHour ||
        endHour != oldDelegate.endHour ||
        hourHeight != oldDelegate.hourHeight ||
        textStyle != oldDelegate.textStyle;
  }
}

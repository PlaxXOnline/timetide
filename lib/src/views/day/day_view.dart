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
import 'day_view_layout.dart';
import 'time_slot_widget.dart';

/// A single-day calendar view showing hours vertically.
///
/// Features:
/// - Vertical time axis with configurable start/end hours
/// - All-day event panel at the top (collapsible)
/// - Events laid out using [TideEventLayoutEngine] with configurable overlap
///   strategy
/// - Current time indicator
/// - Time regions (working hours, blocked, etc.)
/// - Vertical scroll through the day
class TideDayView extends StatefulWidget {
  /// Creates a [TideDayView].
  const TideDayView({
    super.key,
    required this.controller,
    this.timeSlotInterval = const Duration(minutes: 30),
    this.startHour = 0,
    this.endHour = 24,
    this.hourHeight = 60.0,
    this.timeAxisWidth = 56.0,
    this.showAllDayPanel = true,
    this.allDayPanelCollapsible = true,
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

  /// Duration of each time-slot row. Defaults to 30 minutes.
  final Duration timeSlotInterval;

  /// First visible hour (e.g. 0 for midnight). Defaults to 0.
  final double startHour;

  /// Last visible hour (e.g. 24 for end-of-day). Defaults to 24.
  final double endHour;

  /// Pixels per hour. Defaults to 60.
  final double hourHeight;

  /// Width of the time-axis labels column. Defaults to 56.
  final double timeAxisWidth;

  /// Whether to show the all-day event panel. Defaults to true.
  final bool showAllDayPanel;

  /// Whether the all-day panel can be collapsed. Defaults to true.
  final bool allDayPanelCollapsible;

  /// Whether to show the current time indicator. Defaults to true.
  final bool showCurrentTimeIndicator;

  /// Start of working hours as fractional hour (e.g. 9.0).
  final double? workingHoursStart;

  /// End of working hours as fractional hour (e.g. 17.0).
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
  State<TideDayView> createState() => _TideDayViewState();
}

class _TideDayViewState extends State<TideDayView> {
  late final ScrollController _scrollController;
  late final TideCurrentTimeNotifier _timeNotifier;
  List<TideEvent> _events = const [];
  List<TideTimeRegion> _timeRegions = const [];
  bool _allDayPanelExpanded = true;

  // ─── Live snap-to-slot state ───────────────────────────
  /// The event currently being dragged, or `null`.
  TideEvent? _draggingEvent;

  /// The snapped proposed start time during an active drag.
  DateTime? _dragProposedStart;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _timeNotifier = TideCurrentTimeNotifier();
    widget.controller.addListener(_onControllerChanged);
    _loadEvents();
  }

  @override
  void didUpdateWidget(TideDayView oldWidget) {
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

  Future<void> _loadEvents() async {
    final date = widget.controller.displayDate;
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day + 1);

    final events =
        await widget.controller.datasource.getEvents(dayStart, dayEnd);
    final regions =
        await widget.controller.datasource.getTimeRegions(dayStart, dayEnd);

    if (mounted) {
      setState(() {
        _events = events;
        _timeRegions = regions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final date = widget.controller.displayDate;
    final allDay = TideDayViewLayout.allDayEvents(_events);
    final timed = TideDayViewLayout.timedEvents(_events);
    final totalHours = widget.endHour - widget.startHour;
    final totalHeight = totalHours * widget.hourHeight;

    return Semantics(
      label: 'Day view',
      child: Column(
        children: [
          // All-day event panel
          if (widget.showAllDayPanel && allDay.isNotEmpty)
            _buildAllDayPanel(context, theme, allDay),

          // Scrollable time grid
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height: totalHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time axis labels
                    _buildTimeAxis(theme),

                    // Day column with events
                    Expanded(
                      child: _buildDayColumn(
                        context,
                        theme,
                        date,
                        timed,
                        totalHeight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDayPanel(
    BuildContext context,
    TideThemeData theme,
    List<TideEvent> allDayEvents,
  ) {
    final isExpanded =
        !widget.allDayPanelCollapsible || _allDayPanelExpanded;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.allDayPanelCollapsible)
            GestureDetector(
              onTap: () {
                setState(() {
                  _allDayPanelExpanded = !_allDayPanelExpanded;
                });
              },
              child: Semantics(
                label: _allDayPanelExpanded
                    ? 'Collapse all-day events'
                    : 'Expand all-day events',
                button: true,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'All day (${allDayEvents.length})',
                    style: theme.dayHeaderTextStyle,
                  ),
                ),
              ),
            ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Wrap(
                spacing: 4,
                runSpacing: 2,
                children: allDayEvents.map((event) {
                  return _buildAllDayEventTile(context, theme, event);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllDayEventTile(
    BuildContext context,
    TideThemeData theme,
    TideEvent event,
  ) {
    if (widget.allDayEventBuilder != null) {
      return widget.allDayEventBuilder!(context, event);
    }

    final color = event.color ?? theme.primaryColor;
    return Semantics(
      label: 'All-day event: ${event.subject}',
      button: true,
      child: GestureDetector(
        onTap: widget.onEventTap != null ? () => widget.onEventTap!(event) : null,
        child: Container(
          padding: theme.eventPadding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: theme.eventBorderRadius,
          ),
          child: Text(
            event.subject,
            style: theme.eventTitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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

  Widget _buildDayColumn(
    BuildContext context,
    TideThemeData theme,
    DateTime date,
    List<TideEvent> timedEvents,
    double totalHeight,
  ) {
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
        final displayEvents = timedEvents.map((e) {
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

        // Build time region positions
        final positionedRegions = _buildPositionedRegions();

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
              // Time regions (non-interactive overlay)
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
                  child: _buildEventTile(context, theme, result.event, timeAxis, math.max(result.bounds.height, theme.eventMinHeight)),
                ),

              // Current time indicator (non-interactive overlay)
              if (widget.showCurrentTimeIndicator)
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

  List<TidePositionedRegion> _buildPositionedRegions() {
    return _timeRegions.map((region) {
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
    TideTimeAxis timeAxis,
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

      // When drag is enabled, tap is handled by TideDragHandler below,
      // so the tile itself does not need a GestureDetector.
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
                ? Border.all(
                    color: theme.selectionColor,
                    width: 2,
                  )
                : isSelected
                    ? Border.all(
                        color: theme.selectionColor,
                        width: 2,
                      )
                    : null,
          ),
          child: TideEventContent(
            subject: event.subject,
            timeRange: _formatTimeRange(event),
            titleStyle: theme.eventTitleStyle,
            timeStyle: theme.eventTimeStyle,
            padding: EdgeInsets.zero,
            availableHeight: tileHeight - theme.eventPadding.vertical,
          ),
        ),
      );

      if (widget.allowDragAndDrop) {
        // Tap is forwarded via TideDragHandler.onTap to avoid nested
        // GestureDetectors competing for the same gesture.
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
          setState(() {
            _draggingEvent = details.event;
            _dragProposedStart = details.proposedStart;
          });
        },
        onDragEnd: (details) async {
          // Update datasource FIRST so the new position propagates before
          // we clear the drag visual state. This prevents snap-back flicker.
          widget.onDragEnd?.call(details);
          // Wait one microtask for stream events to propagate.
          await Future<void>.delayed(Duration.zero);
          if (mounted) {
            setState(() {
              _draggingEvent = null;
              _dragProposedStart = null;
            });
          }
          return true;
        },
        child: tile,
      );
    } else if (widget.allowResize) {
      // Resize-only (no drag) — use standalone TideResizeHandler.
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

  String _formatTimeRange(TideEvent event) {
    final start = event.startTime;
    final end = event.endTime;
    return '${_formatHour(start)} – ${_formatHour(end)}';
  }

  String _formatHour(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Paints time-axis labels along the left edge of the day view.
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

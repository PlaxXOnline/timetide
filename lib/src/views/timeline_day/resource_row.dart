import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/drag_details.dart';
import '../../core/models/event.dart';
import '../../core/models/time_region.dart';
import '../../interaction/drag_drop/drag_handler.dart';
import '../../interaction/drag_drop/resize_handler.dart';
import '../../interaction/drag_drop/time_axis.dart';
import '../../rendering/event_layout_engine.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';

/// Renders a single resource row in a timeline view.
///
/// Events are positioned horizontally along the time axis within this row.
/// A resource divider line is drawn at the bottom when [showDivider] is true.
class TideResourceRow extends StatefulWidget {
  /// Creates a [TideResourceRow].
  const TideResourceRow({
    super.key,
    required this.events,
    required this.startHour,
    required this.endHour,
    required this.hourWidth,
    required this.rowHeight,
    this.timeRegions = const [],
    this.timeSlotInterval = const Duration(minutes: 60),
    this.overlapStrategy = TideOverlapStrategy.sideBySide,
    this.showDivider = true,
    this.onEventTap,
    this.onEmptySlotTap,
    this.eventBuilder,
    this.controller,
    this.date,
    this.allowDragAndDrop = false,
    this.allowResize = false,
    this.dragSnapInterval,
    this.dragStartBehavior = TideDragStartBehavior.adaptive,
    this.onDragEnd,
    this.onResizeEnd,
  });

  /// Events to display in this row.
  final List<TideEvent> events;

  /// First visible hour.
  final double startHour;

  /// Last visible hour.
  final double endHour;

  /// Pixels per hour along the horizontal time axis.
  final double hourWidth;

  /// Height of this resource row.
  final double rowHeight;

  /// Time regions applicable to this resource.
  final List<TideTimeRegion> timeRegions;

  /// Duration of each time-slot column.
  final Duration timeSlotInterval;

  /// Strategy for handling overlapping events.
  final TideOverlapStrategy overlapStrategy;

  /// Whether to show a divider line at the bottom.
  final bool showDivider;

  /// Called when an event is tapped.
  final ValueChanged<TideEvent>? onEventTap;

  /// Called when an empty area is tapped.
  final ValueChanged<DateTime>? onEmptySlotTap;

  /// Custom builder for event tiles. Receives the event and its bounds.
  final Widget Function(BuildContext, TideEvent, TideEventBounds)? eventBuilder;

  /// Controller required for drag and drop operations.
  final TideController? controller;

  /// Date of this row (needed for horizontal time axis in drag operations).
  final DateTime? date;

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
  State<TideResourceRow> createState() => _TideResourceRowState();
}

class _TideResourceRowState extends State<TideResourceRow> {
  // ─── Live snap-to-slot state ───────────────────────────
  /// The event currently being dragged, or `null`.
  TideEvent? _draggingEvent;

  /// The snapped proposed start time during an active drag.
  DateTime? _dragProposedStart;

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final totalHours = widget.endHour - widget.startHour;
    final totalWidth = totalHours * widget.hourWidth;

    // Layout events horizontally — we repurpose the vertical layout engine
    // by swapping axes: width becomes height, height becomes width.
    final timedEvents = widget.events.where((e) => !e.isAllDay).toList();

    return SizedBox(
      width: totalWidth,
      height: widget.rowHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Time region overlays (rotated to horizontal).
          if (widget.timeRegions.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: _HorizontalTimeRegionPainter(
                  regions: widget.timeRegions,
                  startHour: widget.startHour,
                  endHour: widget.endHour,
                  hourWidth: widget.hourWidth,
                  rowHeight: widget.rowHeight,
                ),
              ),
            ),

          // Events positioned horizontally.
          for (final event in timedEvents)
            _buildEventTile(
              context,
              theme,
              event,
              totalWidth,
              widget.date != null
                  ? TideTimeAxis.horizontal(
                      date: widget.date!,
                      startHour: widget.startHour,
                      hourWidth: widget.hourWidth,
                    )
                  : null,
            ),

          // Bottom divider.
          if (widget.showDivider)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: theme.resourceDividerWidth,
                color: theme.resourceDividerColor,
              ),
            ),

          // Tap target for empty area.
          if (widget.onEmptySlotTap != null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) {
                  final hour = widget.startHour + details.localPosition.dx / widget.hourWidth;
                  final h = hour.floor();
                  final m = ((hour - h) * 60).round();
                  widget.onEmptySlotTap!(DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                    h,
                    m,
                  ));
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventTile(
    BuildContext context,
    TideThemeData theme,
    TideEvent event,
    double totalWidth,
    TideTimeAxis? timeAxis,
  ) {
    final isDragging = _draggingEvent?.id == event.id;

    // Use proposed position during drag for live snap feedback.
    final displayEvent = (isDragging && _dragProposedStart != null)
        ? event.copyWith(
            startTime: _dragProposedStart!,
            endTime: _dragProposedStart!.add(event.duration),
          )
        : event;

    final eventHourStart =
        displayEvent.startTime.hour + displayEvent.startTime.minute / 60.0;
    final eventHourEnd = displayEvent.endTime.hour + displayEvent.endTime.minute / 60.0;

    final left = (eventHourStart - widget.startHour) * widget.hourWidth;
    final width =
        ((eventHourEnd - eventHourStart) * widget.hourWidth).clamp(0.0, totalWidth);

    // Build the visual content — either custom or default.
    Widget tile;
    if (widget.eventBuilder != null) {
      final bounds = TideEventBounds(
        left: left,
        top: 0,
        width: width,
        height: widget.rowHeight,
      );
      tile = widget.eventBuilder!(context, event, bounds);
    } else {
      final tileContent = Semantics(
        label: 'Event: ${event.subject}',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: event.color ?? theme.primaryColor,
            borderRadius: theme.eventBorderRadius,
            border: isDragging
                ? Border.all(color: theme.selectionColor, width: 2)
                : null,
          ),
          child: Padding(
            padding: theme.eventPadding,
            child: Text(
              event.subject,
              style: theme.eventTitleStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      );

      if (widget.allowDragAndDrop) {
        tile = tileContent;
      } else {
        tile = GestureDetector(
          onTap: widget.onEventTap != null ? () => widget.onEventTap!(event) : null,
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
    if (widget.allowDragAndDrop && timeAxis != null && widget.controller != null) {
      tile = TideDragHandler(
        event: event,
        controller: widget.controller!,
        timeAxis: timeAxis,
        dragStartBehavior: widget.dragStartBehavior,
        snapInterval: widget.dragSnapInterval,
        existingEvents: widget.events,
        showGhost: false,
        allowResize: widget.allowResize,
        resizeHandleSize: 8.0,
        onResizeEnd: widget.onResizeEnd != null
            ? (details) async {
                widget.onResizeEnd!(details);
                return true;
              }
            : null,
        onTap: widget.onEventTap != null ? () => widget.onEventTap!(event) : null,
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
          widget.onDragEnd?.call(details);
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
    } else if (widget.allowResize && timeAxis != null) {
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

    return Positioned(
      left: left,
      top: 2,
      width: width.clamp(theme.eventMinHeight, double.infinity),
      height: widget.rowHeight - 4,
      child: tile,
    );
  }
}

/// Paints time regions horizontally for timeline resource rows.
class _HorizontalTimeRegionPainter extends CustomPainter {
  const _HorizontalTimeRegionPainter({
    required this.regions,
    required this.startHour,
    required this.endHour,
    required this.hourWidth,
    required this.rowHeight,
  });

  final List<TideTimeRegion> regions;
  final double startHour;
  final double endHour;
  final double hourWidth;
  final double rowHeight;

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      final regionStart =
          region.startTime.hour + region.startTime.minute / 60.0;
      final regionEnd = region.endTime.hour + region.endTime.minute / 60.0;

      final left = (regionStart - startHour) * hourWidth;
      final right = (regionEnd - startHour) * hourWidth;
      final rect = Rect.fromLTRB(
        left.clamp(0.0, size.width),
        0,
        right.clamp(0.0, size.width),
        rowHeight,
      );

      switch (region.type) {
        case TimeRegionType.blocked:
          final paint = Paint()
            ..color = region.color ?? const Color(0xFF9E9E9E)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;
          canvas.save();
          canvas.clipRect(rect);
          for (var x = rect.left - rowHeight; x < rect.right; x += 8.0) {
            canvas.drawLine(
              Offset(x, 0),
              Offset(x + rowHeight, rowHeight),
              paint,
            );
          }
          canvas.restore();
        case TimeRegionType.highlight:
          canvas.drawRect(
            rect,
            Paint()..color = region.color ?? const Color(0x332196F3),
          );
        case TimeRegionType.nonWorking:
          canvas.drawRect(
            rect,
            Paint()..color = region.color ?? const Color(0x1A000000),
          );
        case TimeRegionType.working:
        case TimeRegionType.custom:
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HorizontalTimeRegionPainter oldDelegate) {
    return regions != oldDelegate.regions ||
        startHour != oldDelegate.startHour ||
        endHour != oldDelegate.endHour ||
        hourWidth != oldDelegate.hourWidth ||
        rowHeight != oldDelegate.rowHeight;
  }
}

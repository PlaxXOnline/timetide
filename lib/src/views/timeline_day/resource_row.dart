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
import '../../widgets/event_content.dart';

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
    this.resourceId,
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
    this.crossDragEvent,
    this.crossDragStart,
    this.crossDragEnd,
    this.crossDragTargetResourceId,
    this.crossDragSourceResourceId,
    this.onCrossDragUpdate,
    this.onCrossDragEnd,
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

  /// The resource ID this row represents.
  ///
  /// Passed through to [TideDragEndDetails.sourceResourceId] so the app
  /// layer can correctly update multi-resource events on cross-resource drag.
  final String? resourceId;

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

  /// The event currently being dragged across resources, if any.
  final TideEvent? crossDragEvent;

  /// The proposed start time for the cross-drag preview.
  final DateTime? crossDragStart;

  /// The proposed end time for the cross-drag preview.
  final DateTime? crossDragEnd;

  /// The resource ID that the cross-drag pointer is currently over.
  final String? crossDragTargetResourceId;

  /// The resource ID that the cross-drag originated from.
  final String? crossDragSourceResourceId;

  /// Called during a drag to notify the parent of cross-resource movement.
  final void Function(
    TideEvent event,
    DateTime proposedStart,
    DateTime? proposedEnd,
    String sourceResourceId,
    Offset globalPosition,
  )? onCrossDragUpdate;

  /// Called when a cross-resource drag ends.
  final VoidCallback? onCrossDragEnd;

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
    List<TideEvent> displayEventList =
        widget.events.where((e) => !e.isAllDay).toList();

    // Cross-resource drag: add preview event in target row.
    if (widget.crossDragEvent != null &&
        widget.crossDragTargetResourceId == widget.resourceId &&
        widget.crossDragSourceResourceId != widget.resourceId &&
        widget.crossDragStart != null) {
      // Only add if the event's proposed time falls on this row's date.
      final rowDate = widget.date;
      final proposedDate = widget.crossDragStart!;
      if (rowDate == null ||
          (proposedDate.year == rowDate.year &&
              proposedDate.month == rowDate.month &&
              proposedDate.day == rowDate.day)) {
        displayEventList = List.of(displayEventList);
        displayEventList.add(widget.crossDragEvent!.copyWith(
          startTime: widget.crossDragStart!,
          endTime: widget.crossDragEnd ??
              widget.crossDragStart!.add(widget.crossDragEvent!.duration),
        ));
      }
    }

    // Cross-resource drag: track which event to hide (but keep in tree
    // so its GestureRecognizer stays alive for onPanEnd).
    final String? hiddenCrossDragEventId =
        (widget.crossDragEvent != null &&
                widget.crossDragSourceResourceId == widget.resourceId &&
                widget.crossDragTargetResourceId != null &&
                widget.crossDragTargetResourceId != widget.resourceId)
            ? widget.crossDragEvent!.id
            : null;

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
          for (final event in displayEventList)
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
              hidden: event.id == hiddenCrossDragEventId,
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
    TideTimeAxis? timeAxis, {
    bool hidden = false,
  }) {
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
          child: TideEventContent(
            subject: event.subject,
            titleStyle: theme.eventTitleStyle,
            padding: theme.eventPadding,
            availableHeight: widget.rowHeight - 4,
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
        sourceResourceId: widget.resourceId,
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
          // Notify parent for cross-resource feedback.
          if (details.globalPosition != null) {
            widget.onCrossDragUpdate?.call(
              details.event,
              details.proposedStart,
              details.proposedEnd,
              widget.resourceId ?? '',
              details.globalPosition!,
            );
          }
        },
        onDragEnd: (details) async {
          // onDragEnd FIRST so _handleRowDragEnd updates _events
          // before onCrossDragEnd triggers a parent rebuild.
          widget.onDragEnd?.call(details);
          widget.onCrossDragEnd?.call();
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
      // Always wrap in Opacity so the tree structure stays stable.
      // Changing only the value (not the tree) preserves GestureRecognizer state.
      child: Opacity(opacity: hidden ? 0.0 : 1.0, child: tile),
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

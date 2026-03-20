import 'package:flutter/widgets.dart';

import '../../core/models/event.dart';
import '../../core/models/time_region.dart';
import '../../rendering/event_layout_engine.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';

/// Renders a single resource row in a timeline view.
///
/// Events are positioned horizontally along the time axis within this row.
/// A resource divider line is drawn at the bottom when [showDivider] is true.
class TideResourceRow extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final totalHours = endHour - startHour;
    final totalWidth = totalHours * hourWidth;

    // Layout events horizontally — we repurpose the vertical layout engine
    // by swapping axes: width becomes height, height becomes width.
    final timedEvents = events.where((e) => !e.isAllDay).toList();

    return SizedBox(
      width: totalWidth,
      height: rowHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Time region overlays (rotated to horizontal).
          if (timeRegions.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: _HorizontalTimeRegionPainter(
                  regions: timeRegions,
                  startHour: startHour,
                  endHour: endHour,
                  hourWidth: hourWidth,
                  rowHeight: rowHeight,
                ),
              ),
            ),

          // Events positioned horizontally.
          for (final event in timedEvents)
            _buildEventTile(context, theme, event, totalWidth),

          // Bottom divider.
          if (showDivider)
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
          if (onEmptySlotTap != null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) {
                  final hour = startHour + details.localPosition.dx / hourWidth;
                  final h = hour.floor();
                  final m = ((hour - h) * 60).round();
                  onEmptySlotTap!(DateTime(
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
  ) {
    final eventHourStart =
        event.startTime.hour + event.startTime.minute / 60.0;
    final eventHourEnd = event.endTime.hour + event.endTime.minute / 60.0;

    final left = (eventHourStart - startHour) * hourWidth;
    final width =
        ((eventHourEnd - eventHourStart) * hourWidth).clamp(0.0, totalWidth);

    if (eventBuilder != null) {
      final bounds = TideEventBounds(
        left: left,
        top: 0,
        width: width,
        height: rowHeight,
      );
      return Positioned(
        left: left,
        top: 0,
        width: width,
        height: rowHeight,
        child: eventBuilder!(context, event, bounds),
      );
    }

    return Positioned(
      left: left,
      top: 2,
      width: width.clamp(theme.eventMinHeight, double.infinity),
      height: rowHeight - 4,
      child: Semantics(
        label: 'Event: ${event.subject}',
        child: GestureDetector(
          onTap: onEventTap != null ? () => onEventTap!(event) : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: event.color ?? theme.primaryColor,
              borderRadius: theme.eventBorderRadius,
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
        ),
      ),
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

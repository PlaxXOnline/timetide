import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/drag_details.dart';
import '../../core/models/event.dart';
import '../../rendering/event_layout_engine.dart';
import '../week/week_view.dart';

/// A work-week calendar view (Monday–Friday).
///
/// Delegates to [TideWeekView] with `numberOfDays: 5` and
/// `showWeekends: false`.
class TideWorkWeekView extends StatelessWidget {
  /// Creates a [TideWorkWeekView].
  const TideWorkWeekView({
    super.key,
    required this.controller,
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
  Widget build(BuildContext context) {
    return TideWeekView(
      controller: controller,
      numberOfDays: 5,
      showWeekends: false,
      timeSlotInterval: timeSlotInterval,
      startHour: startHour,
      endHour: endHour,
      hourHeight: hourHeight,
      timeAxisWidth: timeAxisWidth,
      showAllDayPanel: showAllDayPanel,
      showCurrentTimeIndicator: showCurrentTimeIndicator,
      workingHoursStart: workingHoursStart,
      workingHoursEnd: workingHoursEnd,
      eventOverlapStrategy: eventOverlapStrategy,
      onEventTap: onEventTap,
      onEmptySlotTap: onEmptySlotTap,
      eventBuilder: eventBuilder,
      allDayEventBuilder: allDayEventBuilder,
      allowDragAndDrop: allowDragAndDrop,
      allowResize: allowResize,
      dragSnapInterval: dragSnapInterval,
      dragStartBehavior: dragStartBehavior,
      onDragEnd: onDragEnd,
      onResizeEnd: onResizeEnd,
    );
  }
}

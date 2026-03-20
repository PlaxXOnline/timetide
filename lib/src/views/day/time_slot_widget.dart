import 'package:flutter/widgets.dart';

import '../../rendering/time_slot_painter.dart';
import '../../theme/tide_theme.dart';
import 'day_view_layout.dart';

/// Interactive time-slot background widget.
///
/// Wraps a [CustomPaint] with [TideTimeSlotPainter] and provides a
/// [GestureDetector] for tap-on-empty-slot interactions.
class TideTimeSlotWidget extends StatelessWidget {
  /// Creates a [TideTimeSlotWidget].
  const TideTimeSlotWidget({
    super.key,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.hourHeight,
    required this.timeSlotInterval,
    this.workingHoursStart,
    this.workingHoursEnd,
    this.onEmptySlotTap,
    this.child,
  });

  /// The date this time slot grid represents.
  final DateTime date;

  /// First visible hour.
  final double startHour;

  /// Last visible hour.
  final double endHour;

  /// Pixels per hour.
  final double hourHeight;

  /// Duration of each time-slot row.
  final Duration timeSlotInterval;

  /// Start of working hours as fractional hour.
  final double? workingHoursStart;

  /// End of working hours as fractional hour.
  final double? workingHoursEnd;

  /// Called when an empty area is tapped with the corresponding [DateTime].
  final ValueChanged<DateTime>? onEmptySlotTap;

  /// Content rendered on top of the time slot grid.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final totalHours = endHour - startHour;
    final totalHeight = totalHours * hourHeight;

    return Semantics(
      label: 'Time slot grid',
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: onEmptySlotTap != null
            ? (details) {
                final tappedTime = TideDayViewLayout.yToTime(
                  y: details.localPosition.dy,
                  date: date,
                  startHour: startHour,
                  hourHeight: hourHeight,
                );
                onEmptySlotTap!(tappedTime);
              }
            : null,
        child: SizedBox(
          height: totalHeight,
          child: CustomPaint(
            painter: TideTimeSlotPainter(
              startHour: startHour,
              endHour: endHour,
              timeSlotInterval: timeSlotInterval,
              hourHeight: hourHeight,
              timeSlotBorderColor: theme.timeSlotBorderColor,
              timeSlotBorderWidth: theme.timeSlotBorderWidth,
              workingHoursColor: theme.workingHoursColor,
              nonWorkingHoursColor: theme.nonWorkingHoursColor,
              workingHoursStart: workingHoursStart,
              workingHoursEnd: workingHoursEnd,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

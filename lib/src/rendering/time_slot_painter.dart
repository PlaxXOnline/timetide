import 'package:flutter/widgets.dart';

/// Paints the time-slot grid for day and week views.
///
/// Renders horizontal grid lines at each [timeSlotInterval], fills working and
/// non-working hours with distinct background colours, and optionally draws
/// thicker lines at hour boundaries.
///
/// All rendering parameters are passed through the constructor — the painter
/// never reads from [BuildContext] or an [InheritedWidget].
class TideTimeSlotPainter extends CustomPainter {
  /// Creates a [TideTimeSlotPainter].
  const TideTimeSlotPainter({
    required this.startHour,
    required this.endHour,
    required this.timeSlotInterval,
    required this.hourHeight,
    required this.timeSlotBorderColor,
    required this.timeSlotBorderWidth,
    required this.workingHoursColor,
    required this.nonWorkingHoursColor,
    this.workingHoursStart,
    this.workingHoursEnd,
  });

  /// The first visible hour (e.g. 0.0 for midnight, 6.0 for 6 AM).
  final double startHour;

  /// The last visible hour (e.g. 24.0 for end-of-day).
  final double endHour;

  /// Duration of each time-slot row (e.g. 30 minutes).
  final Duration timeSlotInterval;

  /// Pixels per hour — controls the vertical density.
  final double hourHeight;

  /// Color of the horizontal grid lines between time slots.
  final Color timeSlotBorderColor;

  /// Stroke width of the grid lines.
  final double timeSlotBorderWidth;

  /// Background color for time slots inside working hours.
  final Color workingHoursColor;

  /// Background color for time slots outside working hours.
  final Color nonWorkingHoursColor;

  /// Start of working hours as fractional hour (e.g. 9.0 for 9 AM).
  ///
  /// If null, no working-hours band is drawn and the entire surface uses
  /// [nonWorkingHoursColor].
  final double? workingHoursStart;

  /// End of working hours as fractional hour (e.g. 17.0 for 5 PM).
  ///
  /// If null, no working-hours band is drawn.
  final double? workingHoursEnd;

  /// Converts a fractional hour to a y-pixel offset relative to [startHour].
  double hourToY(double hour) => (hour - startHour) * hourHeight;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fill entire canvas with non-working background.
    final bgPaint = Paint()..color = nonWorkingHoursColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Fill working-hours band (if defined).
    if (workingHoursStart != null && workingHoursEnd != null) {
      final whStart = workingHoursStart!.clamp(startHour, endHour);
      final whEnd = workingHoursEnd!.clamp(startHour, endHour);
      if (whEnd > whStart) {
        final whPaint = Paint()..color = workingHoursColor;
        final top = hourToY(whStart);
        final bottom = hourToY(whEnd);
        canvas.drawRect(
          Rect.fromLTRB(0, top, size.width, bottom),
          whPaint,
        );
      }
    }

    // 3. Draw horizontal grid lines at each timeSlotInterval.
    final linePaint = Paint()
      ..color = timeSlotBorderColor
      ..strokeWidth = timeSlotBorderWidth
      ..style = PaintingStyle.stroke;

    final hourLinePaint = Paint()
      ..color = timeSlotBorderColor
      ..strokeWidth = timeSlotBorderWidth * 2
      ..style = PaintingStyle.stroke;

    final intervalHours = timeSlotInterval.inMinutes / 60.0;
    if (intervalHours <= 0) return;

    for (var hour = startHour; hour <= endHour; hour += intervalHours) {
      final y = hourToY(hour);
      if (y < 0 || y > size.height) continue;

      // Use thicker paint at whole-hour boundaries.
      final isHourBoundary = (hour % 1.0).abs() < 0.001;
      final paint = isHourBoundary ? hourLinePaint : linePaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant TideTimeSlotPainter oldDelegate) {
    return startHour != oldDelegate.startHour ||
        endHour != oldDelegate.endHour ||
        timeSlotInterval != oldDelegate.timeSlotInterval ||
        hourHeight != oldDelegate.hourHeight ||
        timeSlotBorderColor != oldDelegate.timeSlotBorderColor ||
        timeSlotBorderWidth != oldDelegate.timeSlotBorderWidth ||
        workingHoursColor != oldDelegate.workingHoursColor ||
        nonWorkingHoursColor != oldDelegate.nonWorkingHoursColor ||
        workingHoursStart != oldDelegate.workingHoursStart ||
        workingHoursEnd != oldDelegate.workingHoursEnd;
  }
}

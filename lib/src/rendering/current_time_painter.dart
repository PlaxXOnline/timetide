import 'dart:async';

import 'package:flutter/widgets.dart';

/// Paints the "now" indicator — a small filled circle at the left edge and a
/// horizontal line spanning the full width.
///
/// All layout parameters are passed via the constructor; the painter never
/// reads from [BuildContext].
class TideCurrentTimePainter extends CustomPainter {
  /// Creates a [TideCurrentTimePainter].
  const TideCurrentTimePainter({
    required this.currentTime,
    required this.startHour,
    required this.endHour,
    required this.hourHeight,
    required this.color,
    required this.lineHeight,
    this.circleRadius = 5.0,
  });

  /// The current wall-clock time.
  final DateTime currentTime;

  /// First visible hour (fractional, e.g. 0.0 for midnight).
  final double startHour;

  /// Last visible hour (fractional, e.g. 24.0 for end-of-day).
  final double endHour;

  /// Pixels per hour.
  final double hourHeight;

  /// Color of the indicator line and circle.
  final Color color;

  /// Thickness (height) of the horizontal line.
  final double lineHeight;

  /// Radius of the circle drawn at the left edge. Defaults to 5.0.
  final double circleRadius;

  /// Converts [currentTime] to a fractional hour value.
  double get _currentFractionalHour =>
      currentTime.hour + currentTime.minute / 60.0;

  /// Returns the y-pixel position for the current time relative to [startHour].
  double get yPosition => (_currentFractionalHour - startHour) * hourHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final fractional = _currentFractionalHour;
    if (fractional < startHour || fractional > endHour) return;

    final y = yPosition;
    final paint = Paint()..color = color;

    // Draw filled circle at left edge.
    canvas.drawCircle(Offset(0, y), circleRadius, paint);

    // Draw horizontal line across full width.
    canvas.drawRect(
      Rect.fromLTWH(0, y - lineHeight / 2, size.width, lineHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant TideCurrentTimePainter oldDelegate) {
    // Repaint when minute changes (ignore seconds/millis for efficiency).
    return currentTime.hour != oldDelegate.currentTime.hour ||
        currentTime.minute != oldDelegate.currentTime.minute ||
        startHour != oldDelegate.startHour ||
        endHour != oldDelegate.endHour ||
        hourHeight != oldDelegate.hourHeight ||
        color != oldDelegate.color ||
        lineHeight != oldDelegate.lineHeight ||
        circleRadius != oldDelegate.circleRadius;
  }
}

/// A [ChangeNotifier] that ticks every minute to keep [currentTime] up to date.
///
/// Views can listen to this notifier and trigger a repaint of the current-time
/// indicator without rebuilding the entire widget tree.
class TideCurrentTimeNotifier extends ChangeNotifier {
  /// Creates a [TideCurrentTimeNotifier] and starts the internal timer.
  TideCurrentTimeNotifier() {
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _currentTime = DateTime.now();
      notifyListeners();
    });
  }

  late DateTime _currentTime;
  late final Timer _timer;

  /// The current wall-clock time, updated every minute.
  DateTime get currentTime => _currentTime;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

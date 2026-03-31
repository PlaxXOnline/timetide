import 'dart:ui' show Offset;

import 'package:flutter/widgets.dart' show Axis;

/// Abstraction for pixel ↔ time conversion, provided by each view.
///
/// Vertical views (day, week, resource_day) use Y-axis conversion.
/// Horizontal views (timeline) use X-axis conversion.
///
/// The [direction] field tells drag and resize handlers which coordinate
/// component of an [Offset] to use when converting pointer positions to
/// time values.
class TideTimeAxis {
  /// Creates a [TideTimeAxis] with explicit conversion functions.
  const TideTimeAxis({
    required this.pixelToTime,
    required this.timeToPixel,
    this.direction = Axis.vertical,
  });

  /// Converts a pixel offset (relative to the scrollable content origin)
  /// to a DateTime.
  final DateTime Function(double pixel) pixelToTime;

  /// Converts a DateTime to a pixel offset.
  final double Function(DateTime time) timeToPixel;

  /// The axis direction — [Axis.vertical] for day/week views (Y-axis),
  /// [Axis.horizontal] for timeline views (X-axis).
  final Axis direction;

  /// Extracts the correct coordinate from an [Offset] based on [direction].
  ///
  /// Returns [Offset.dy] for vertical axes and [Offset.dx] for horizontal
  /// axes.
  double offsetToPixel(Offset offset) {
    return direction == Axis.vertical ? offset.dy : offset.dx;
  }

  /// Extracts the correct delta component from an [Offset] based on
  /// [direction].
  ///
  /// Identical to [offsetToPixel] but named for clarity when used with
  /// drag deltas.
  double deltaToPixel(Offset delta) {
    return direction == Axis.vertical ? delta.dy : delta.dx;
  }

  /// Creates a vertical time axis for day/week views.
  ///
  /// [date] is the reference day for the conversion.
  /// [startHour] and [hourHeight] define the pixel mapping.
  factory TideTimeAxis.vertical({
    required DateTime date,
    required double startHour,
    required double hourHeight,
  }) {
    return TideTimeAxis(
      direction: Axis.vertical,
      pixelToTime: (double y) {
        final fractionalHour = startHour + y / hourHeight;
        final hour = fractionalHour.floor();
        final minute = ((fractionalHour - hour) * 60).round();
        return DateTime(date.year, date.month, date.day, hour, minute);
      },
      timeToPixel: (DateTime time) {
        final fractionalHour =
            time.hour + time.minute / 60.0 + time.second / 3600.0;
        return (fractionalHour - startHour) * hourHeight;
      },
    );
  }

  /// Creates a horizontal time axis for timeline views.
  ///
  /// [date] is the reference day.
  /// [startHour] and [hourWidth] define the pixel mapping.
  factory TideTimeAxis.horizontal({
    required DateTime date,
    required double startHour,
    required double hourWidth,
  }) {
    return TideTimeAxis(
      direction: Axis.horizontal,
      pixelToTime: (double x) {
        final fractionalHour = startHour + x / hourWidth;
        final hour = fractionalHour.floor();
        final minute = ((fractionalHour - hour) * 60).round();
        return DateTime(date.year, date.month, date.day, hour, minute);
      },
      timeToPixel: (DateTime time) {
        final fractionalHour =
            time.hour + time.minute / 60.0 + time.second / 3600.0;
        return (fractionalHour - startHour) * hourWidth;
      },
    );
  }
}

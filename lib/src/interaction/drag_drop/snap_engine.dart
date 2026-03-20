/// Pure calculation utility for snapping drag positions to a time grid.
///
/// Used by [TideDragHandler] and [TideResizeHandler] to quantize proposed
/// times to the nearest grid interval (e.g. every 15 minutes).
class TideSnapEngine {
  // Coverage-only constructor.
  const TideSnapEngine._();

  /// Snaps [proposed] to the nearest grid point defined by [interval].
  ///
  /// If [interval] is `null`, [proposed] is returned unchanged (pixel-precise
  /// placement).
  ///
  /// Example with a 15-minute grid:
  /// ```dart
  /// final snapped = TideSnapEngine.snapToGrid(
  ///   DateTime(2024, 1, 1, 9, 22),
  ///   Duration(minutes: 15),
  /// ); // → 2024-01-01 09:15
  /// ```
  static DateTime snapToGrid(DateTime proposed, Duration? interval) {
    if (interval == null || interval.inMicroseconds == 0) return proposed;

    final intervalUs = interval.inMicroseconds;
    final proposedUs = proposed.microsecondsSinceEpoch;

    // Round to nearest interval boundary.
    final remainder = proposedUs % intervalUs;
    final snappedUs = remainder < intervalUs ~/ 2
        ? proposedUs - remainder
        : proposedUs + (intervalUs - remainder);

    return DateTime.fromMicrosecondsSinceEpoch(snappedUs, isUtc: proposed.isUtc);
  }

  /// Snaps [proposed] duration to the nearest multiple of [interval].
  ///
  /// Returns at least [interval] (or [proposed] if [interval] is `null`)
  /// to prevent zero-length events.
  static Duration snapDuration(Duration proposed, Duration? interval) {
    if (interval == null || interval.inMicroseconds == 0) return proposed;

    final intervalUs = interval.inMicroseconds;
    final proposedUs = proposed.inMicroseconds;

    final remainder = proposedUs % intervalUs;
    var snappedUs = remainder < intervalUs ~/ 2
        ? proposedUs - remainder
        : proposedUs + (intervalUs - remainder);

    // Ensure minimum duration of one interval.
    if (snappedUs < intervalUs) snappedUs = intervalUs;

    return Duration(microseconds: snappedUs);
  }
}

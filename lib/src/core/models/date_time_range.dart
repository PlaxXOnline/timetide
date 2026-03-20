/// An immutable range of [DateTime] values from [start] to [end].
///
/// This is a widget-layer-only replacement for Flutter's `DateTimeRange`
/// (which lives in `material.dart` and cannot be imported).
class TideDateTimeRange {
  /// Creates a [TideDateTimeRange].
  ///
  /// [start] must be at or before [end].
  const TideDateTimeRange({
    required this.start,
    required this.end,
  });

  /// The start of the range.
  final DateTime start;

  /// The end of the range.
  final DateTime end;

  /// The duration of this range.
  Duration get duration => end.difference(start);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TideDateTimeRange &&
          other.start == start &&
          other.end == end);

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'TideDateTimeRange(start: $start, end: $end)';
}

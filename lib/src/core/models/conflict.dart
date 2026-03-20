import 'event.dart';

/// Describes a scheduling conflict between two events.
///
/// Used by the recurrence engine to report overlapping occurrences
/// within a checked date range.
class TideConflict {
  /// Creates a [TideConflict].
  const TideConflict({
    required this.eventA,
    required this.eventB,
    required this.overlapStart,
    required this.overlapEnd,
  });

  /// The first conflicting event.
  final TideEvent eventA;

  /// The second conflicting event.
  final TideEvent eventB;

  /// Start of the overlapping time range.
  final DateTime overlapStart;

  /// End of the overlapping time range.
  final DateTime overlapEnd;

  /// Duration of the overlap.
  Duration get overlapDuration => overlapEnd.difference(overlapStart);

  @override
  String toString() =>
      'TideConflict(eventA: ${eventA.id}, eventB: ${eventB.id}, '
      'overlap: $overlapStart – $overlapEnd)';
}

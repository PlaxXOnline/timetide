import '../../core/models/conflict.dart';
import '../../core/models/event.dart';

/// Detects scheduling conflicts between a dragged event and existing events.
///
/// Called continuously during drag (from `onDragUpdate`) to provide live
/// visual feedback about overlapping events.
class TideConflictDetector {
  // Coverage-only constructor.
  const TideConflictDetector._();

  /// Returns all conflicts between the dragged event at its proposed position
  /// and [existingEvents].
  ///
  /// An event is considered conflicting when its time range overlaps with
  /// the proposed range and (if [proposedResourceId] is given) shares the
  /// same resource.
  ///
  /// The dragged event itself is excluded from conflict detection.
  static List<TideConflict> detectConflicts({
    required TideEvent draggedEvent,
    required DateTime proposedStart,
    required DateTime proposedEnd,
    required List<TideEvent> existingEvents,
    String? proposedResourceId,
  }) {
    final conflicts = <TideConflict>[];

    for (final existing in existingEvents) {
      // Skip the event being dragged.
      if (existing.id == draggedEvent.id) continue;

      // When a resource is specified, only check events on the same resource.
      if (proposedResourceId != null) {
        final existingResources = existing.resourceIds;
        if (existingResources != null &&
            !existingResources.contains(proposedResourceId)) {
          continue;
        }
      }

      // Check for time overlap: two intervals overlap when
      // start_A < end_B AND start_B < end_A.
      if (proposedStart.isBefore(existing.endTime) &&
          existing.startTime.isBefore(proposedEnd)) {
        final overlapStart = proposedStart.isAfter(existing.startTime)
            ? proposedStart
            : existing.startTime;
        final overlapEnd = proposedEnd.isBefore(existing.endTime)
            ? proposedEnd
            : existing.endTime;

        conflicts.add(TideConflict(
          eventA: draggedEvent,
          eventB: existing,
          overlapStart: overlapStart,
          overlapEnd: overlapEnd,
        ));
      }
    }

    return conflicts;
  }
}

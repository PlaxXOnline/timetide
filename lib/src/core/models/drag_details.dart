import 'dart:ui' show Color, Offset;

import 'event.dart';

/// Determines when a drag gesture begins.
enum TideDragStartBehavior {
  /// Platform-dependent: long press on mobile, immediate on desktop.
  adaptive,

  /// Always requires a long press to initiate drag.
  longPress,

  /// Drag begins immediately on pointer down.
  immediate,
}

/// Controls which edges of an event can be resized.
enum TideResizeDirection {
  /// Both start and end times can be resized.
  both,

  /// Only the start time can be resized.
  startOnly,

  /// Only the end time can be resized.
  endOnly,
}

/// Details provided when a drag operation completes.
///
/// Contains the dragged event and its resolved new time slot.
class TideDragEndDetails {
  /// Creates a [TideDragEndDetails].
  const TideDragEndDetails({
    required this.event,
    required this.newStart,
    required this.newEnd,
    this.newResourceId,
    this.sourceResourceId,
    this.dropPosition,
  });

  /// The event that was dragged.
  final TideEvent event;

  /// The new start time after the drag.
  final DateTime newStart;

  /// The new end time after the drag.
  final DateTime newEnd;

  /// The resource the event was dropped onto, if any.
  final String? newResourceId;

  /// The resource the event was dragged FROM.
  ///
  /// Used together with [newResourceId] to correctly update multi-resource
  /// events: replace only the source resource with the target, keeping
  /// other resource assignments intact.
  final String? sourceResourceId;

  /// The global screen position where the drop occurred.
  ///
  /// Used by parent views (e.g. timeline views) to resolve which resource
  /// row the event was dropped on for cross-resource drag.
  final Offset? dropPosition;
}

/// Details provided when a resize operation completes.
///
/// Contains the resized event and its resolved new time boundaries.
class TideResizeEndDetails {
  /// Creates a [TideResizeEndDetails].
  const TideResizeEndDetails({
    required this.event,
    required this.newStart,
    required this.newEnd,
  });

  /// The event that was resized.
  final TideEvent event;

  /// The new start time after the resize.
  final DateTime newStart;

  /// The new end time after the resize.
  final DateTime newEnd;
}

/// Details provided continuously during a drag operation.
///
/// Used to give live feedback, e.g. highlighting conflict slots.
class TideDragUpdateDetails {
  /// Creates a [TideDragUpdateDetails].
  const TideDragUpdateDetails({
    required this.event,
    required this.proposedStart,
    this.proposedResourceId,
    this.conflicts = const [],
    this.globalPosition,
  });

  /// The event currently being dragged.
  final TideEvent event;

  /// The proposed new start time at the current drag position.
  final DateTime proposedStart;

  /// The resource currently under the drag pointer, if any.
  final String? proposedResourceId;

  /// Events that conflict with the proposed drop slot.
  final List<TideEvent> conflicts;

  /// The current global pointer position during the drag.
  final Offset? globalPosition;
}

/// Data payload for an event dragged in from an external source.
///
/// Used with [TideExternalDragEndDetails] when dropping non-calendar items
/// onto the calendar.
class TideExternalDragData {
  /// Creates a [TideExternalDragData].
  const TideExternalDragData({
    required this.subject,
    required this.duration,
    this.color,
    this.metadata,
  });

  /// Title of the event to be created.
  final String subject;

  /// Duration of the event to be created.
  final Duration duration;

  /// Optional color for the new event.
  final Color? color;

  /// Arbitrary additional data for the new event.
  final Map<String, dynamic>? metadata;
}

/// Details provided when an external drag completes on the calendar.
class TideExternalDragEndDetails {
  /// Creates a [TideExternalDragEndDetails].
  const TideExternalDragEndDetails({
    required this.data,
    required this.dropTime,
    this.dropResourceId,
  });

  /// The external drag payload.
  final TideExternalDragData data;

  /// The time slot where the external item was dropped.
  final DateTime dropTime;

  /// The resource onto which the item was dropped, if any.
  final String? dropResourceId;
}

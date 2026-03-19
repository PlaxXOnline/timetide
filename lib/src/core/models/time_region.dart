import 'dart:ui' show Color;

/// The type of a time region.
enum TimeRegionType {
  /// Normal working hours.
  working,

  /// Non-working hours (greyed out, events still allowed).
  nonWorking,

  /// Blocked time (no events can be created or dropped here).
  blocked,

  /// Visually highlighted zone.
  highlight,

  /// Fully controlled via custom builder.
  custom,
}

/// Represents a highlighted or restricted time region in the calendar.
///
/// Time regions can mark working/non-working hours, blocked slots, or
/// custom highlighted zones. All fields are immutable; use [copyWith] to
/// produce modified copies. Equality and [hashCode] are based on [id].
class TideTimeRegion {
  /// Creates a [TideTimeRegion].
  const TideTimeRegion({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.text,
    this.color,
    this.recurrenceRule,
    this.recurrenceExceptions,
    this.resourceIds,
    this.enableInteraction = false,
    this.type = TimeRegionType.nonWorking,
    this.metadata,
  });

  /// Unique identifier for this time region.
  final String id;

  /// Start date and time of the region.
  final DateTime startTime;

  /// End date and time of the region.
  final DateTime endTime;

  /// Optional label displayed inside the region.
  final String? text;

  /// Optional background color for this region.
  final Color? color;

  /// RFC 5545 RRULE string for recurring regions.
  final String? recurrenceRule;

  /// Dates excluded from the recurrence pattern.
  final List<DateTime>? recurrenceExceptions;

  /// IDs of resources this region applies to. Null means all resources.
  final List<String>? resourceIds;

  /// Whether users can interact (create/drop events) within this region.
  ///
  /// Defaults to `false`.
  final bool enableInteraction;

  /// Semantic type that controls rendering and interaction behaviour.
  ///
  /// Defaults to [TimeRegionType.nonWorking].
  final TimeRegionType type;

  /// Arbitrary additional data attached to this region.
  final Map<String, dynamic>? metadata;

  /// Returns a copy of this region with the given fields replaced.
  TideTimeRegion copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    String? text,
    Color? color,
    String? recurrenceRule,
    List<DateTime>? recurrenceExceptions,
    List<String>? resourceIds,
    bool? enableInteraction,
    TimeRegionType? type,
    Map<String, dynamic>? metadata,
  }) {
    return TideTimeRegion(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      text: text ?? this.text,
      color: color ?? this.color,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceExceptions: recurrenceExceptions ?? this.recurrenceExceptions,
      resourceIds: resourceIds ?? this.resourceIds,
      enableInteraction: enableInteraction ?? this.enableInteraction,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TideTimeRegion && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TideTimeRegion(id: $id, type: $type, start: $startTime, end: $endTime)';
}

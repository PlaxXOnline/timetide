import 'dart:ui' show Color;

/// Represents a single calendar event within timetide.
///
/// All fields are immutable. Use [copyWith] to create a modified copy.
/// Equality and [hashCode] are based solely on [id].
class TideEvent {
  /// Creates a [TideEvent].
  const TideEvent({
    required this.id,
    required this.subject,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.color,
    this.notes,
    this.location,
    this.recurrenceRule,
    this.recurrenceExceptions,
    this.resourceIds,
    this.metadata,
  });

  /// Unique identifier for this event.
  final String id;

  /// Display title of the event.
  final String subject;

  /// Start date and time of the event.
  final DateTime startTime;

  /// End date and time of the event.
  final DateTime endTime;

  /// Whether this event spans an entire day without specific times.
  final bool isAllDay;

  /// Optional color used to distinguish this event visually.
  final Color? color;

  /// Optional free-text notes or description.
  final String? notes;

  /// Optional location string for the event.
  final String? location;

  /// RFC 5545 RRULE string for recurring events.
  final String? recurrenceRule;

  /// Dates excluded from the recurrence pattern.
  final List<DateTime>? recurrenceExceptions;

  /// IDs of resources this event is assigned to.
  final List<String>? resourceIds;

  /// Arbitrary additional data attached to this event.
  final Map<String, dynamic>? metadata;

  /// The duration between [startTime] and [endTime].
  Duration get duration => endTime.difference(startTime);

  /// Whether this event has a recurrence rule defined.
  bool get isRecurring => recurrenceRule != null;

  /// Whether this event spans more than one calendar day.
  ///
  /// Returns `false` when [isAllDay] is `true`, even if start and end dates differ.
  bool get isMultiDay {
    if (isAllDay) return false;
    return startTime.year != endTime.year ||
        startTime.month != endTime.month ||
        startTime.day != endTime.day;
  }

  /// Returns a copy of this event with the given fields replaced.
  TideEvent copyWith({
    String? id,
    String? subject,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    Color? color,
    String? notes,
    String? location,
    String? recurrenceRule,
    List<DateTime>? recurrenceExceptions,
    List<String>? resourceIds,
    Map<String, dynamic>? metadata,
  }) {
    return TideEvent(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceExceptions: recurrenceExceptions ?? this.recurrenceExceptions,
      resourceIds: resourceIds ?? this.resourceIds,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TideEvent && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TideEvent(id: $id, subject: $subject)';
}

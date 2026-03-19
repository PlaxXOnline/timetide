import 'dart:ui' show Color;

import 'event.dart';

/// A patch object describing a set of changes to apply to a [TideEvent].
///
/// Only non-null fields are applied; null fields leave the original value
/// untouched. Use [applyTo] to obtain an updated [TideEvent].
class TideEventChanges {
  /// Creates a [TideEventChanges].
  ///
  /// All fields are optional. An instance where all fields are null is
  /// considered empty ([isEmpty] returns `true`).
  const TideEventChanges({
    this.subject,
    this.startTime,
    this.endTime,
    this.isAllDay,
    this.color,
    this.notes,
    this.location,
    this.recurrenceRule,
    this.recurrenceExceptions,
    this.resourceIds,
    this.metadata,
  });

  /// New display title, or null to keep the existing value.
  final String? subject;

  /// New start time, or null to keep the existing value.
  final DateTime? startTime;

  /// New end time, or null to keep the existing value.
  final DateTime? endTime;

  /// New all-day flag, or null to keep the existing value.
  final bool? isAllDay;

  /// New color, or null to keep the existing value.
  final Color? color;

  /// New notes, or null to keep the existing value.
  final String? notes;

  /// New location, or null to keep the existing value.
  final String? location;

  /// New RFC 5545 RRULE string, or null to keep the existing value.
  final String? recurrenceRule;

  /// New recurrence exceptions, or null to keep the existing value.
  final List<DateTime>? recurrenceExceptions;

  /// New resource IDs, or null to keep the existing value.
  final List<String>? resourceIds;

  /// New metadata, or null to keep the existing value.
  final Map<String, dynamic>? metadata;

  /// Whether this change set has no modifications.
  bool get isEmpty =>
      subject == null &&
      startTime == null &&
      endTime == null &&
      isAllDay == null &&
      color == null &&
      notes == null &&
      location == null &&
      recurrenceRule == null &&
      recurrenceExceptions == null &&
      resourceIds == null &&
      metadata == null;

  /// Applies the non-null fields of this change set to [event].
  ///
  /// Returns a new [TideEvent] with the changes merged in. Fields that are
  /// null in this [TideEventChanges] retain their original values from
  /// [event].
  TideEvent applyTo(TideEvent event) {
    return event.copyWith(
      subject: subject ?? event.subject,
      startTime: startTime ?? event.startTime,
      endTime: endTime ?? event.endTime,
      isAllDay: isAllDay ?? event.isAllDay,
      color: color ?? event.color,
      notes: notes ?? event.notes,
      location: location ?? event.location,
      recurrenceRule: recurrenceRule ?? event.recurrenceRule,
      recurrenceExceptions: recurrenceExceptions ?? event.recurrenceExceptions,
      resourceIds: resourceIds ?? event.resourceIds,
      metadata: metadata ?? event.metadata,
    );
  }

  @override
  String toString() =>
      'TideEventChanges(subject: $subject, startTime: $startTime, '
      'endTime: $endTime, isAllDay: $isAllDay, color: $color, '
      'notes: $notes, location: $location, recurrenceRule: $recurrenceRule, '
      'recurrenceExceptions: $recurrenceExceptions, '
      'resourceIds: $resourceIds, metadata: $metadata)';
}

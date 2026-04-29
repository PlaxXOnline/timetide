/// Lightweight time-of-day representation for widget-layer-only usage.
///
/// Unlike Flutter's `TimeOfDay` (which lives in `material.dart`), this class
/// can be used without pulling in Material dependencies.
///
/// [hour] ranges from 0 to 23, [minute] from 0 to 59.
class TideTimeOfDay {
  /// Creates a [TideTimeOfDay].
  const TideTimeOfDay({required this.hour, required this.minute});

  /// The hour of the day, from 0 to 23.
  final int hour;

  /// The minute of the hour, from 0 to 59.
  final int minute;

  /// Total minutes since midnight, useful for comparison and arithmetic.
  int get totalMinutes => hour * 60 + minute;

  /// Returns a copy of this time with the given fields replaced.
  TideTimeOfDay copyWith({int? hour, int? minute}) {
    return TideTimeOfDay(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  /// Whether this time is strictly before [other].
  bool operator <(TideTimeOfDay other) => totalMinutes < other.totalMinutes;

  /// Whether this time is strictly after [other].
  bool operator >(TideTimeOfDay other) => totalMinutes > other.totalMinutes;

  /// Whether this time is before or equal to [other].
  bool operator <=(TideTimeOfDay other) => totalMinutes <= other.totalMinutes;

  /// Whether this time is after or equal to [other].
  bool operator >=(TideTimeOfDay other) => totalMinutes >= other.totalMinutes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TideTimeOfDay &&
          other.hour == hour &&
          other.minute == minute);

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// A time slot within a weekly template for shift/schedule planning.
///
/// All fields are immutable. Use [copyWith] to create a modified copy.
/// Equality and [hashCode] are based solely on [id].
class TideTemplateSlot {
  /// Creates a [TideTemplateSlot].
  const TideTemplateSlot({
    required this.id,
    required this.resourceId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isBreak = false,
  });

  /// Unique identifier for this template slot.
  final String id;

  /// The resource this template slot belongs to.
  final String resourceId;

  /// Day of the week (ISO 8601: 1 = Monday, 7 = Sunday).
  final int dayOfWeek;

  /// Start time of this slot within the day.
  final TideTimeOfDay startTime;

  /// End time of this slot within the day.
  final TideTimeOfDay endTime;

  /// Whether this slot represents a break period.
  final bool isBreak;

  /// Duration of this slot in minutes.
  int get durationMinutes => endTime.totalMinutes - startTime.totalMinutes;

  /// Returns a copy of this template slot with the given fields replaced.
  TideTemplateSlot copyWith({
    String? id,
    String? resourceId,
    int? dayOfWeek,
    TideTimeOfDay? startTime,
    TideTimeOfDay? endTime,
    bool? isBreak,
  }) {
    return TideTemplateSlot(
      id: id ?? this.id,
      resourceId: resourceId ?? this.resourceId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isBreak: isBreak ?? this.isBreak,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TideTemplateSlot && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TideTemplateSlot(id: $id, day: $dayOfWeek)';
}

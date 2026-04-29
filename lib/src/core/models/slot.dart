/// A bookable time slot for the [TideSlotPicker] widget.
///
/// All fields are immutable. Use [copyWith] to create a modified copy.
/// Equality and [hashCode] are based solely on [id].
class TideSlot {
  /// Creates a [TideSlot].
  const TideSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.resourceId,
    this.resourceName,
    this.data,
  });

  /// Unique identifier for this slot.
  final String id;

  /// Start date and time of the slot.
  final DateTime startTime;

  /// End date and time of the slot.
  final DateTime endTime;

  /// Optional resource identifier this slot is linked to.
  final String? resourceId;

  /// Optional display name for grouping header.
  final String? resourceName;

  /// Optional arbitrary user data attached to this slot.
  final Object? data;

  /// The duration between [startTime] and [endTime].
  Duration get duration => endTime.difference(startTime);

  /// Returns a copy of this slot with the given fields replaced.
  TideSlot copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    String? resourceId,
    String? resourceName,
    Object? data,
  }) {
    return TideSlot(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      resourceId: resourceId ?? this.resourceId,
      resourceName: resourceName ?? this.resourceName,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TideSlot && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TideSlot(id: $id, startTime: $startTime)';
}

import 'package:flutter/widgets.dart';

/// Represents a single bookable resource (e.g. a person, room, or equipment).
///
/// All fields are immutable. Use [copyWith] to create a modified copy.
/// Equality and [hashCode] are based solely on [id].
class TideResource {
  /// Creates a [TideResource].
  const TideResource({
    required this.id,
    required this.displayName,
    required this.color,
    this.avatar,
    this.sortOrder = 0,
    this.groupId,
    this.metadata,
  });

  /// Unique identifier for this resource.
  final String id;

  /// Human-readable name shown in the UI.
  final String displayName;

  /// Color used to distinguish this resource visually.
  final Color color;

  /// Optional avatar image for this resource.
  final ImageProvider? avatar;

  /// Determines the display order among resources; lower values appear first.
  final int sortOrder;

  /// Optional ID of the [TideResourceGroup] this resource belongs to.
  final String? groupId;

  /// Arbitrary additional data attached to this resource.
  final Map<String, dynamic>? metadata;

  /// Returns a copy of this resource with the given fields replaced.
  TideResource copyWith({
    String? id,
    String? displayName,
    Color? color,
    ImageProvider? avatar,
    int? sortOrder,
    String? groupId,
    Map<String, dynamic>? metadata,
  }) {
    return TideResource(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      color: color ?? this.color,
      avatar: avatar ?? this.avatar,
      sortOrder: sortOrder ?? this.sortOrder,
      groupId: groupId ?? this.groupId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TideResource && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TideResource(id: $id, displayName: $displayName)';
}

/// Groups multiple [TideResource] instances under a collapsible heading.
///
/// All fields are immutable. Use [copyWith] to create a modified copy.
/// Equality and [hashCode] are based solely on [id].
class TideResourceGroup {
  /// Creates a [TideResourceGroup].
  const TideResourceGroup({
    required this.id,
    required this.displayName,
    this.initiallyExpanded = true,
  });

  /// Unique identifier for this group.
  final String id;

  /// Human-readable name shown as the group heading.
  final String displayName;

  /// Whether the group is expanded on first render.
  final bool initiallyExpanded;

  /// Returns a copy of this group with the given fields replaced.
  TideResourceGroup copyWith({
    String? id,
    String? displayName,
    bool? initiallyExpanded,
  }) {
    return TideResourceGroup(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      initiallyExpanded: initiallyExpanded ?? this.initiallyExpanded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TideResourceGroup && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TideResourceGroup(id: $id, displayName: $displayName)';
}

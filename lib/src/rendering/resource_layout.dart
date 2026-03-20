import '../core/models/resource.dart';

/// How resources are arranged in the calendar view.
enum TideResourceViewMode {
  /// Each resource occupies a horizontal strip (used in timeline views).
  rows,

  /// Each resource occupies a vertical column (used in day/week views).
  columns,

  /// Resources are grouped by [TideResource.groupId] with group headers.
  grouped,

  /// All resources share the same space with events overlaid.
  stacked,
}

/// Describes the position and size of a laid-out resource lane.
class TideResourceBounds {
  /// Creates a [TideResourceBounds].
  const TideResourceBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Horizontal offset from the left edge of the container.
  final double left;

  /// Vertical offset from the top edge of the container.
  final double top;

  /// Width of the resource lane.
  final double width;

  /// Height of the resource lane.
  final double height;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TideResourceBounds &&
        other.left == left &&
        other.top == top &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() =>
      'TideResourceBounds(left: $left, top: $top, width: $width, height: $height)';
}

/// Pairs a [TideResource] with its computed layout bounds and header bounds.
class TideResourceLayoutResult {
  /// Creates a [TideResourceLayoutResult].
  const TideResourceLayoutResult({
    required this.resource,
    required this.bounds,
    required this.headerBounds,
    this.groupId,
    this.isGroupHeader = false,
    this.groupDisplayName,
  });

  /// The resource being laid out.
  final TideResource resource;

  /// The computed position and size of the resource lane.
  final TideResourceBounds bounds;

  /// The computed position and size of the sticky header for this resource.
  final TideResourceBounds headerBounds;

  /// The group this resource belongs to (if in grouped mode).
  final String? groupId;

  /// Whether this result represents a group header rather than a resource.
  final bool isGroupHeader;

  /// Display name for a group header entry.
  final String? groupDisplayName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TideResourceLayoutResult &&
        other.resource == resource &&
        other.bounds == bounds &&
        other.headerBounds == headerBounds &&
        other.groupId == groupId &&
        other.isGroupHeader == isGroupHeader;
  }

  @override
  int get hashCode =>
      Object.hash(resource, bounds, headerBounds, groupId, isGroupHeader);

  @override
  String toString() =>
      'TideResourceLayoutResult(resource: ${resource.id}, bounds: $bounds)';
}

/// Computes the spatial layout for a list of resources.
class TideResourceLayout {
  const TideResourceLayout._();

  /// Lays out [resources] within a container of the given dimensions.
  ///
  /// [resourceHeaderWidth] is used in [TideResourceViewMode.rows] mode to
  /// reserve space for the sticky header on the left. In
  /// [TideResourceViewMode.columns] mode the header is placed on top and
  /// uses the full column width.
  static List<TideResourceLayoutResult> layout({
    required List<TideResource> resources,
    required TideResourceViewMode mode,
    required double availableWidth,
    required double availableHeight,
    double? fixedRowHeight,
    double? fixedColumnWidth,
    double resourceHeaderWidth = 120.0,
    double groupHeaderHeight = 32.0,
    double columnHeaderHeight = 40.0,
  }) {
    if (resources.isEmpty) return const [];

    switch (mode) {
      case TideResourceViewMode.rows:
        return _layoutRows(
          resources,
          availableWidth,
          availableHeight,
          fixedRowHeight,
          resourceHeaderWidth,
        );
      case TideResourceViewMode.columns:
        return _layoutColumns(
          resources,
          availableWidth,
          availableHeight,
          fixedColumnWidth,
          columnHeaderHeight,
        );
      case TideResourceViewMode.grouped:
        return _layoutGrouped(
          resources,
          availableWidth,
          availableHeight,
          fixedRowHeight,
          resourceHeaderWidth,
          groupHeaderHeight,
        );
      case TideResourceViewMode.stacked:
        return _layoutStacked(
          resources,
          availableWidth,
          availableHeight,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Rows mode
  // ---------------------------------------------------------------------------

  static List<TideResourceLayoutResult> _layoutRows(
    List<TideResource> resources,
    double availableWidth,
    double availableHeight,
    double? fixedRowHeight,
    double resourceHeaderWidth,
  ) {
    final rowHeight =
        fixedRowHeight ?? availableHeight / resources.length;
    final contentWidth = availableWidth - resourceHeaderWidth;

    return List.generate(resources.length, (i) {
      final resource = resources[i];
      final top = i * rowHeight;
      return TideResourceLayoutResult(
        resource: resource,
        bounds: TideResourceBounds(
          left: resourceHeaderWidth,
          top: top,
          width: contentWidth,
          height: rowHeight,
        ),
        headerBounds: TideResourceBounds(
          left: 0,
          top: top,
          width: resourceHeaderWidth,
          height: rowHeight,
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Columns mode
  // ---------------------------------------------------------------------------

  static List<TideResourceLayoutResult> _layoutColumns(
    List<TideResource> resources,
    double availableWidth,
    double availableHeight,
    double? fixedColumnWidth,
    double columnHeaderHeight,
  ) {
    final colWidth =
        fixedColumnWidth ?? availableWidth / resources.length;
    final contentHeight = availableHeight - columnHeaderHeight;

    return List.generate(resources.length, (i) {
      final resource = resources[i];
      final left = i * colWidth;
      return TideResourceLayoutResult(
        resource: resource,
        bounds: TideResourceBounds(
          left: left,
          top: columnHeaderHeight,
          width: colWidth,
          height: contentHeight,
        ),
        headerBounds: TideResourceBounds(
          left: left,
          top: 0,
          width: colWidth,
          height: columnHeaderHeight,
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Grouped mode
  // ---------------------------------------------------------------------------

  static List<TideResourceLayoutResult> _layoutGrouped(
    List<TideResource> resources,
    double availableWidth,
    double availableHeight,
    double? fixedRowHeight,
    double resourceHeaderWidth,
    double groupHeaderHeight,
  ) {
    // Group resources by groupId, preserving insertion order.
    final grouped = <String?, List<TideResource>>{};
    for (final r in resources) {
      grouped.putIfAbsent(r.groupId, () => []).add(r);
    }

    // Calculate row height: distribute remaining height after group headers.
    final totalGroupHeaders = grouped.length;
    final remainingHeight =
        availableHeight - totalGroupHeaders * groupHeaderHeight;
    final rowHeight =
        fixedRowHeight ?? (remainingHeight / resources.length);

    final contentWidth = availableWidth - resourceHeaderWidth;
    final results = <TideResourceLayoutResult>[];
    var currentTop = 0.0;

    for (final entry in grouped.entries) {
      final groupId = entry.key;
      final groupResources = entry.value;

      // Group header — we use the first resource in the group as a
      // representative (the caller can check [isGroupHeader]).
      final firstResource = groupResources.first;
      results.add(TideResourceLayoutResult(
        resource: firstResource,
        bounds: TideResourceBounds(
          left: 0,
          top: currentTop,
          width: availableWidth,
          height: groupHeaderHeight,
        ),
        headerBounds: TideResourceBounds(
          left: 0,
          top: currentTop,
          width: availableWidth,
          height: groupHeaderHeight,
        ),
        groupId: groupId,
        isGroupHeader: true,
        groupDisplayName: groupId ?? 'Ungrouped',
      ));
      currentTop += groupHeaderHeight;

      // Resource rows within the group.
      for (final resource in groupResources) {
        results.add(TideResourceLayoutResult(
          resource: resource,
          bounds: TideResourceBounds(
            left: resourceHeaderWidth,
            top: currentTop,
            width: contentWidth,
            height: rowHeight,
          ),
          headerBounds: TideResourceBounds(
            left: 0,
            top: currentTop,
            width: resourceHeaderWidth,
            height: rowHeight,
          ),
          groupId: groupId,
        ));
        currentTop += rowHeight;
      }
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // Stacked mode
  // ---------------------------------------------------------------------------

  static List<TideResourceLayoutResult> _layoutStacked(
    List<TideResource> resources,
    double availableWidth,
    double availableHeight,
  ) {
    // All resources share the entire container.
    return resources.map((resource) {
      return TideResourceLayoutResult(
        resource: resource,
        bounds: TideResourceBounds(
          left: 0,
          top: 0,
          width: availableWidth,
          height: availableHeight,
        ),
        headerBounds: TideResourceBounds(
          left: 0,
          top: 0,
          width: availableWidth,
          height: 0,
        ),
      );
    }).toList();
  }
}

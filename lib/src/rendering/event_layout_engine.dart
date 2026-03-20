import 'dart:math' as math;

import '../core/models/event.dart';

/// How overlapping events are arranged within a day column.
enum TideOverlapStrategy {
  /// Events share the available width equally in side-by-side columns.
  ///
  /// Uses a sweep-line algorithm to detect overlap clusters and assign
  /// column indices — O(n log n) time complexity.
  sideBySide,

  /// Overlapping events are stacked with a small offset, creating a
  /// card-stack appearance.
  stack,

  /// Like [sideBySide] but each subsequent column is progressively
  /// narrower, producing a compressed fan effect.
  compress,
}

/// Describes the position and size of a laid-out event, relative to
/// its container.
///
/// All values are in logical pixels.
class TideEventBounds {
  /// Creates a [TideEventBounds].
  const TideEventBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Horizontal offset from the left edge of the container.
  final double left;

  /// Vertical offset from the top edge of the container.
  final double top;

  /// Width of the event rectangle.
  final double width;

  /// Height of the event rectangle.
  final double height;

  /// Returns a copy with the given fields replaced.
  TideEventBounds copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
  }) {
    return TideEventBounds(
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TideEventBounds &&
        other.left == left &&
        other.top == top &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() =>
      'TideEventBounds(left: $left, top: $top, width: $width, height: $height)';
}

/// Pairs a [TideEvent] with its computed layout bounds.
class TideEventLayoutResult {
  /// Creates a [TideEventLayoutResult].
  const TideEventLayoutResult({
    required this.event,
    required this.bounds,
  });

  /// The event being laid out.
  final TideEvent event;

  /// The computed position and size of the event.
  final TideEventBounds bounds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TideEventLayoutResult &&
        other.event == event &&
        other.bounds == bounds;
  }

  @override
  int get hashCode => Object.hash(event, bounds);

  @override
  String toString() =>
      'TideEventLayoutResult(event: ${event.id}, bounds: $bounds)';
}

/// Computes pixel-level layout for a list of events within a single
/// day column.
///
/// The engine filters out all-day events, then applies the chosen
/// [TideOverlapStrategy] to position timed events.
class TideEventLayoutEngine {
  const TideEventLayoutEngine._();

  /// Lays out [events] within a container of the given dimensions.
  ///
  /// [startHour] and [endHour] define the visible time range (e.g. 0–24
  /// for a full day, or 8–18 for working hours).
  ///
  /// Returns a [TideEventLayoutResult] for every non-all-day event.
  static List<TideEventLayoutResult> layout({
    required List<TideEvent> events,
    required TideOverlapStrategy strategy,
    required double startHour,
    required double endHour,
    required double availableWidth,
    required double availableHeight,
  }) {
    // Filter out all-day events.
    final timed = events.where((e) => !e.isAllDay).toList();
    if (timed.isEmpty) return const [];

    switch (strategy) {
      case TideOverlapStrategy.sideBySide:
        return _layoutSideBySide(
          timed, startHour, endHour, availableWidth, availableHeight,
        );
      case TideOverlapStrategy.stack:
        return _layoutStack(
          timed, startHour, endHour, availableWidth, availableHeight,
        );
      case TideOverlapStrategy.compress:
        return _layoutCompress(
          timed, startHour, endHour, availableWidth, availableHeight,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Side-by-side (sweep-line, O(n log n))
  // ---------------------------------------------------------------------------

  static List<TideEventLayoutResult> _layoutSideBySide(
    List<TideEvent> events,
    double startHour,
    double endHour,
    double availableWidth,
    double availableHeight,
  ) {
    final totalHours = endHour - startHour;
    if (totalHours <= 0) return const [];

    // Sort by start time, then by end time descending for stable ordering.
    final sorted = List<TideEvent>.of(events)
      ..sort((a, b) {
        final cmp = a.startTime.compareTo(b.startTime);
        if (cmp != 0) return cmp;
        return b.endTime.compareTo(a.endTime);
      });

    // Build overlap clusters using sweep-line.
    final clusters = _buildClusters(sorted);

    final results = <TideEventLayoutResult>[];

    for (final cluster in clusters) {
      // Assign column indices within the cluster.
      final columns = _assignColumns(cluster);
      final totalColumns = columns.values.fold<int>(0, math.max) + 1;

      for (final event in cluster) {
        final col = columns[event.id]!;
        final colWidth = availableWidth / totalColumns;

        final top = _timeToY(
          event.startTime, startHour, totalHours, availableHeight,
        );
        final bottom = _timeToY(
          event.endTime, startHour, totalHours, availableHeight,
        );

        results.add(TideEventLayoutResult(
          event: event,
          bounds: TideEventBounds(
            left: col * colWidth,
            top: top,
            width: colWidth,
            height: math.max(0, bottom - top),
          ),
        ));
      }
    }

    return results;
  }

  /// Groups events into overlap clusters using a sweep-line.
  ///
  /// Two events are in the same cluster if they overlap (directly or
  /// transitively). The input must be sorted by startTime.
  static List<List<TideEvent>> _buildClusters(List<TideEvent> sorted) {
    final clusters = <List<TideEvent>>[];
    List<TideEvent>? current;
    DateTime? clusterEnd;

    for (final event in sorted) {
      if (current == null ||
          clusterEnd == null ||
          !event.startTime.isBefore(clusterEnd)) {
        // Start a new cluster.
        current = [event];
        clusters.add(current);
        clusterEnd = event.endTime;
      } else {
        // Extend the current cluster.
        current.add(event);
        if (event.endTime.isAfter(clusterEnd)) {
          clusterEnd = event.endTime;
        }
      }
    }

    return clusters;
  }

  /// Assigns each event in a cluster to a column index using a greedy
  /// algorithm.
  ///
  /// Events are processed in the order they appear (already sorted by
  /// start time). Each event is placed in the lowest-indexed column
  /// where it does not overlap with the column's last occupant.
  static Map<String, int> _assignColumns(List<TideEvent> cluster) {
    final columns = <String, int>{};
    // Track the end time of the last event placed in each column.
    final columnEnds = <DateTime>[];

    for (final event in cluster) {
      int? placed;
      for (var c = 0; c < columnEnds.length; c++) {
        if (!event.startTime.isBefore(columnEnds[c])) {
          placed = c;
          columnEnds[c] = event.endTime;
          break;
        }
      }
      if (placed == null) {
        placed = columnEnds.length;
        columnEnds.add(event.endTime);
      }
      columns[event.id] = placed;
    }

    return columns;
  }

  // ---------------------------------------------------------------------------
  // Stack
  // ---------------------------------------------------------------------------

  static List<TideEventLayoutResult> _layoutStack(
    List<TideEvent> events,
    double startHour,
    double endHour,
    double availableWidth,
    double availableHeight,
  ) {
    final totalHours = endHour - startHour;
    if (totalHours <= 0) return const [];

    const offsetStep = 8.0;
    final eventWidth = availableWidth * 0.9;

    final sorted = List<TideEvent>.of(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final clusters = _buildClusters(sorted);
    final results = <TideEventLayoutResult>[];

    for (final cluster in clusters) {
      for (var i = 0; i < cluster.length; i++) {
        final event = cluster[i];
        final top = _timeToY(
          event.startTime, startHour, totalHours, availableHeight,
        );
        final bottom = _timeToY(
          event.endTime, startHour, totalHours, availableHeight,
        );

        results.add(TideEventLayoutResult(
          event: event,
          bounds: TideEventBounds(
            left: i * offsetStep,
            top: top + i * offsetStep,
            width: math.max(0, eventWidth - i * offsetStep),
            height: math.max(0, bottom - top),
          ),
        ));
      }
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // Compress
  // ---------------------------------------------------------------------------

  static List<TideEventLayoutResult> _layoutCompress(
    List<TideEvent> events,
    double startHour,
    double endHour,
    double availableWidth,
    double availableHeight,
  ) {
    final totalHours = endHour - startHour;
    if (totalHours <= 0) return const [];

    final sorted = List<TideEvent>.of(events)
      ..sort((a, b) {
        final cmp = a.startTime.compareTo(b.startTime);
        if (cmp != 0) return cmp;
        return b.endTime.compareTo(a.endTime);
      });

    final clusters = _buildClusters(sorted);
    final results = <TideEventLayoutResult>[];

    for (final cluster in clusters) {
      final columns = _assignColumns(cluster);
      final totalColumns = columns.values.fold<int>(0, math.max) + 1;

      for (final event in cluster) {
        final col = columns[event.id]!;

        // Each subsequent column is 15% narrower: 100%, 85%, 70%, …
        final widthFraction = math.max(0.1, 1.0 - col * 0.15);
        final eventWidth = availableWidth * widthFraction;

        // Shift each column right by a fraction of the available width.
        final leftOffset =
            totalColumns <= 1 ? 0.0 : col * (availableWidth / totalColumns);

        final top = _timeToY(
          event.startTime, startHour, totalHours, availableHeight,
        );
        final bottom = _timeToY(
          event.endTime, startHour, totalHours, availableHeight,
        );

        results.add(TideEventLayoutResult(
          event: event,
          bounds: TideEventBounds(
            left: leftOffset,
            top: top,
            width: eventWidth,
            height: math.max(0, bottom - top),
          ),
        ));
      }
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Converts a [DateTime] to a Y-pixel position within the visible range.
  static double _timeToY(
    DateTime time,
    double startHour,
    double totalHours,
    double availableHeight,
  ) {
    final hour = time.hour + time.minute / 60.0 + time.second / 3600.0;
    final fraction = (hour - startHour) / totalHours;
    return fraction.clamp(0.0, 1.0) * availableHeight;
  }
}

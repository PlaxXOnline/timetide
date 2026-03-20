import 'package:flutter/widgets.dart';

import '../../core/controller.dart';

/// Manages date and date-range selection for Month View and similar views.
///
/// Single date selection via tap; date range selection via drag across cells.
class TideDateSelectionHandler {
  /// Creates a [TideDateSelectionHandler].
  TideDateSelectionHandler({required this.controller});

  /// The calendar controller managing selection state.
  final TideController controller;

  DateTime? _dragStartDate;

  /// Handles a tap on a date cell — selects a single date.
  void handleDateTap(DateTime date) {
    controller.selectDate(date);
  }

  /// Call when a drag starts on a date cell.
  void handleDragStart(DateTime date) {
    _dragStartDate = date;
    controller.selectDate(date);
  }

  /// Call when the drag moves over a new date cell.
  void handleDragUpdate(DateTime date) {
    if (_dragStartDate == null) return;
    final start = _dragStartDate!;
    if (start.isBefore(date) || start.isAtSameMomentAs(date)) {
      controller.selectDateRange(start, date);
    } else {
      controller.selectDateRange(date, start);
    }
  }

  /// Call when the drag ends.
  void handleDragEnd() {
    _dragStartDate = null;
  }

  /// Wraps [child] in gesture detectors for date cell tap and drag.
  ///
  /// [date] is the date represented by the cell.
  Widget buildDateCellDetector({
    required DateTime date,
    required Widget child,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => handleDateTap(date),
      onPanStart: (_) => handleDragStart(date),
      onPanEnd: (_) => handleDragEnd(),
      child: Semantics(
        button: true,
        label:
            'Select date: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        child: child,
      ),
    );
  }
}

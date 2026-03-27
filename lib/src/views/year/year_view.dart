import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/drag_details.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';

/// A year overview showing 12 mini-month grids with heatmap coloring based
/// on event density.
///
/// Each day cell is colored by event count using the [heatMapColorScale].
/// Tapping a month triggers [onMonthTap], which can be used to switch to
/// a month view.
class TideYearView extends StatefulWidget {
  /// Creates a [TideYearView].
  const TideYearView({
    super.key,
    required this.controller,
    this.monthsPerRow = 3,
    this.monthSpacing = 16.0,
    this.daySize = 16.0,
    this.monthHeaderHeight = 24.0,
    this.heatMapColorScale,
    this.onMonthTap,
    this.onDayTap,
    this.allowDragAndDrop = false,
    this.allowResize = false,
    this.dragSnapInterval,
    this.dragStartBehavior = TideDragStartBehavior.adaptive,
    this.onDragEnd,
    this.onResizeEnd,
  });

  /// The controller managing navigation, data, and selection.
  final TideController controller;

  /// Number of month grids per row (typically 3 or 4).
  final int monthsPerRow;

  /// Spacing between month grids.
  final double monthSpacing;

  /// Size of each day cell in the mini-month grid.
  final double daySize;

  /// Height of the month name header.
  final double monthHeaderHeight;

  /// Color scale for the heatmap. Maps event count to color.
  ///
  /// If null, uses a default blue gradient based on the theme's primary color.
  final Color Function(int eventCount)? heatMapColorScale;

  /// Called when a month header or area is tapped.
  final ValueChanged<DateTime>? onMonthTap;

  /// Called when a specific day is tapped.
  final ValueChanged<DateTime>? onDayTap;

  /// Whether events can be dragged. Present for API consistency.
  final bool allowDragAndDrop;

  /// Whether events can be resized. Present for API consistency.
  final bool allowResize;

  /// Time grid snap interval for drag operations. Present for API consistency.
  final Duration? dragSnapInterval;

  /// When the drag gesture starts. Present for API consistency.
  final TideDragStartBehavior dragStartBehavior;

  /// Called when a drag operation completes. Present for API consistency.
  final void Function(TideDragEndDetails details)? onDragEnd;

  /// Called when a resize operation completes. Present for API consistency.
  final void Function(TideResizeEndDetails details)? onResizeEnd;

  @override
  State<TideYearView> createState() => _TideYearViewState();
}

class _TideYearViewState extends State<TideYearView> {
  /// Maps "YYYY-MM-DD" to event count.
  Map<String, int> _eventCounts = {};
  bool _isLoading = true;

  int get _year => widget.controller.displayDate.year;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _loadData();
  }

  @override
  void didUpdateWidget(TideYearView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _loadData();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => _loadData();

  Future<void> _loadData() async {
    final yearStart = DateTime(_year);
    final yearEnd = DateTime(_year + 1);
    final events =
        await widget.controller.datasource.getEvents(yearStart, yearEnd);
    if (!mounted) return;

    final counts = <String, int>{};
    for (final event in events) {
      // Count each day the event spans.
      var day = DateTime(
          event.startTime.year, event.startTime.month, event.startTime.day);
      final end = DateTime(
          event.endTime.year, event.endTime.month, event.endTime.day);
      while (!day.isAfter(end)) {
        final key = _dateKey(day);
        counts[key] = (counts[key] ?? 0) + 1;
        day = day.add(const Duration(days: 1));
      }
    }

    setState(() {
      _eventCounts = counts;
      _isLoading = false;
    });
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final theme = TideTheme.of(context);

    return Semantics(
      label: 'Year view, $_year',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(widget.monthSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Year header.
            Padding(
              padding: EdgeInsets.only(bottom: widget.monthSpacing),
              child: Text(
                '$_year',
                style: theme.headerTextStyle,
              ),
            ),
            // Month grid.
            Wrap(
              spacing: widget.monthSpacing,
              runSpacing: widget.monthSpacing,
              children: List.generate(12, (i) {
                return _buildMiniMonth(theme, i + 1);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMonth(TideThemeData theme, int month) {
    final firstDay = DateTime(_year, month);
    final daysInMonth =
        DateTime(_year, month + 1).difference(firstDay).inDays;
    // Which weekday does the month start on? (1=Mon .. 7=Sun)
    final startWeekday = firstDay.weekday;
    // Total grid cells (including leading blanks).
    final leadingBlanks = startWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final gridWidth = 7 * widget.daySize;

    return GestureDetector(
      onTap: widget.onMonthTap != null
          ? () => widget.onMonthTap!(firstDay)
          : null,
      child: Semantics(
        label: '${monthNames[month - 1]} $_year',
        child: SizedBox(
          width: gridWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month name.
              SizedBox(
                height: widget.monthHeaderHeight,
                child: Text(
                  monthNames[month - 1],
                  style: theme.dayHeaderTextStyle,
                ),
              ),
              // Day grid.
              ...List.generate(rows, (row) {
                return Row(
                  children: List.generate(7, (col) {
                    final cellIndex = row * 7 + col;
                    final dayNumber = cellIndex - leadingBlanks + 1;

                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return SizedBox(
                        width: widget.daySize,
                        height: widget.daySize,
                      );
                    }

                    final date = DateTime(_year, month, dayNumber);
                    final count = _eventCounts[_dateKey(date)] ?? 0;
                    final isToday = _isToday(date);

                    return GestureDetector(
                      onTap: widget.onDayTap != null
                          ? () => widget.onDayTap!(date)
                          : null,
                      child: Semantics(
                        label: '$dayNumber ${monthNames[month - 1]}, $count events',
                        child: Container(
                          width: widget.daySize,
                          height: widget.daySize,
                          decoration: BoxDecoration(
                            color: _heatmapColor(theme, count),
                            border: isToday
                                ? Border.all(
                                    color: theme.todayHighlightColor,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: widget.daySize * 0.5,
                                color: count > 0
                                    ? const Color(0xFFFFFFFF)
                                    : theme.monthDateTextStyle.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Color _heatmapColor(TideThemeData theme, int count) {
    if (widget.heatMapColorScale != null) {
      return widget.heatMapColorScale!(count);
    }

    if (count == 0) return theme.backgroundColor;

    // Default gradient: lighter to darker blue based on count.
    final intensity = (count / 5).clamp(0.0, 1.0);
    return Color.lerp(
      theme.primaryColor.withValues(alpha: 0.2),
      theme.primaryColor,
      intensity,
    )!;
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

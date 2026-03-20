import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/event.dart';
import '../../core/models/resource.dart';
import '../../core/models/time_region.dart';
import '../../rendering/event_layout_engine.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';
import '../timeline_day/resource_row.dart';

/// A timeline week view showing resources as rows with a 7-day time axis
/// flowing left to right.
///
/// Like [TideTimelineDayView] but the horizontal axis spans an entire week.
/// Day separator lines are drawn between days, and day headers remain fixed
/// during horizontal scrolling.
class TideTimelineWeekView extends StatefulWidget {
  /// Creates a [TideTimelineWeekView].
  const TideTimelineWeekView({
    super.key,
    required this.controller,
    this.startHour = 0,
    this.endHour = 24,
    this.hourWidth = 60.0,
    this.resourceRowHeight = 60.0,
    this.resourceHeaderWidth = 120.0,
    this.timeHeaderHeight = 40.0,
    this.dayHeaderHeight = 24.0,
    this.showResourceDividers = true,
    this.overlapStrategy = TideOverlapStrategy.sideBySide,
    this.onEventTap,
    this.onEmptySlotTap,
    this.resourceHeaderBuilder,
    this.eventBuilder,
  });

  /// The controller managing navigation, data, and selection.
  final TideController controller;

  /// First visible hour per day.
  final double startHour;

  /// Last visible hour per day.
  final double endHour;

  /// Pixels per hour along the horizontal time axis.
  final double hourWidth;

  /// Height of each resource row.
  final double resourceRowHeight;

  /// Width of the sticky resource header column.
  final double resourceHeaderWidth;

  /// Height of the time header row at the top.
  final double timeHeaderHeight;

  /// Height of the day header row below the time header.
  final double dayHeaderHeight;

  /// Whether to show divider lines between resource rows.
  final bool showResourceDividers;

  /// Strategy for handling overlapping events.
  final TideOverlapStrategy overlapStrategy;

  /// Called when an event is tapped.
  final ValueChanged<TideEvent>? onEventTap;

  /// Called when an empty slot is tapped.
  final ValueChanged<DateTime>? onEmptySlotTap;

  /// Custom builder for resource headers.
  final Widget Function(BuildContext, TideResource)? resourceHeaderBuilder;

  /// Custom builder for event tiles.
  final Widget Function(BuildContext, TideEvent, TideEventBounds)? eventBuilder;

  @override
  State<TideTimelineWeekView> createState() => _TideTimelineWeekViewState();
}

class _TideTimelineWeekViewState extends State<TideTimelineWeekView> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  List<TideResource> _resources = [];
  List<TideEvent> _events = [];
  List<TideTimeRegion> _timeRegions = [];
  bool _isLoading = true;

  int get _numberOfDays => 7;

  List<DateTime> get _days {
    final range = widget.controller.visibleDateRange;
    return List.generate(
      _numberOfDays,
      (i) => range.start.add(Duration(days: i)),
    );
  }

  double get _dayWidth {
    final hoursPerDay = widget.endHour - widget.startHour;
    return hoursPerDay * widget.hourWidth;
  }

  double get _totalTimeWidth => _dayWidth * _numberOfDays;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _loadData();
  }

  @override
  void didUpdateWidget(TideTimelineWeekView oldWidget) {
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
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    _loadData();
  }

  Future<void> _loadData() async {
    final range = widget.controller.visibleDateRange;
    final results = await Future.wait([
      widget.controller.datasource.getResources(),
      widget.controller.datasource.getEvents(range.start, range.end),
      widget.controller.datasource.getTimeRegions(range.start, range.end),
    ]);
    if (!mounted) return;
    setState(() {
      _resources = results[0] as List<TideResource>;
      _events = results[1] as List<TideEvent>;
      _timeRegions = results[2] as List<TideTimeRegion>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final theme = TideTheme.of(context);
    final totalResourceHeight = _resources.length * widget.resourceRowHeight;

    return Semantics(
      label: 'Timeline week view',
      child: Column(
        children: [
          // Day headers + time labels.
          SizedBox(
            height: widget.dayHeaderHeight + widget.timeHeaderHeight,
            child: Row(
              children: [
                SizedBox(width: widget.resourceHeaderWidth),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (_) => true,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: _buildCombinedHeader(theme),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Resource rows.
          Expanded(
            child: Row(
              children: [
                // Sticky resource headers.
                SizedBox(
                  width: widget.resourceHeaderWidth,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      controller: _verticalScrollController,
                      child: _buildResourceHeaders(theme),
                    ),
                  ),
                ),
                // Scrollable content.
                Expanded(
                  child: _SyncedScrollArea(
                    horizontalController: _horizontalScrollController,
                    verticalController: _verticalScrollController,
                    totalWidth: _totalTimeWidth,
                    totalHeight: totalResourceHeight,
                    child: _buildContent(theme),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedHeader(TideThemeData theme) {
    final days = _days;
    return SizedBox(
      width: _totalTimeWidth,
      child: Column(
        children: [
          // Day headers.
          SizedBox(
            height: widget.dayHeaderHeight,
            child: Row(
              children: days.map((day) {
                final isToday = _isToday(day);
                return SizedBox(
                  width: _dayWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: theme.borderColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _formatDayHeader(day),
                        style: isToday
                            ? theme.dayHeaderTextStyle.copyWith(
                                color: theme.todayHighlightColor,
                              )
                            : theme.dayHeaderTextStyle,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Time labels per day.
          SizedBox(
            height: widget.timeHeaderHeight,
            child: Row(
              children: days.map((day) {
                return SizedBox(
                  width: _dayWidth,
                  child: _buildDayTimeLabels(theme),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTimeLabels(TideThemeData theme) {
    final hours = <Widget>[];
    for (var h = widget.startHour; h < widget.endHour; h++) {
      hours.add(
        SizedBox(
          width: widget.hourWidth,
          child: Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '${h.toInt().toString().padLeft(2, '0')}:00',
              style: theme.timeSlotTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    return Row(children: hours);
  }

  Widget _buildResourceHeaders(TideThemeData theme) {
    return Column(
      children: _resources.map((resource) {
        return SizedBox(
          height: widget.resourceRowHeight,
          child: widget.resourceHeaderBuilder != null
              ? widget.resourceHeaderBuilder!(context, resource)
              : _DefaultResourceHeader(
                  resource: resource,
                  theme: theme,
                  showDivider: widget.showResourceDividers,
                ),
        );
      }).toList(),
    );
  }

  Widget _buildContent(TideThemeData theme) {
    final days = _days;
    final visibleResIds = widget.controller.visibleResourceIds;

    return Column(
      children: _resources.map((resource) {
        if (visibleResIds.isNotEmpty && !visibleResIds.contains(resource.id)) {
          return SizedBox(height: widget.resourceRowHeight);
        }

        // Build a row spanning all 7 days for this resource.
        return SizedBox(
          height: widget.resourceRowHeight,
          child: Row(
            children: days.map((day) {
              final dayStart = DateTime(day.year, day.month, day.day);
              final dayEnd = dayStart.add(const Duration(days: 1));

              final dayEvents = _events
                  .where((e) =>
                      (e.resourceIds == null ||
                          e.resourceIds!.contains(resource.id)) &&
                      e.startTime.isBefore(dayEnd) &&
                      e.endTime.isAfter(dayStart))
                  .toList();

              final dayRegions = _timeRegions
                  .where((r) =>
                      (r.resourceIds == null ||
                          r.resourceIds!.contains(resource.id)) &&
                      r.startTime.isBefore(dayEnd) &&
                      r.endTime.isAfter(dayStart))
                  .toList();

              return SizedBox(
                width: _dayWidth,
                child: Stack(
                  children: [
                    TideResourceRow(
                      events: dayEvents,
                      startHour: widget.startHour,
                      endHour: widget.endHour,
                      hourWidth: widget.hourWidth,
                      rowHeight: widget.resourceRowHeight,
                      timeRegions: dayRegions,
                      overlapStrategy: widget.overlapStrategy,
                      showDivider: widget.showResourceDividers,
                      onEventTap: widget.onEventTap,
                      eventBuilder: widget.eventBuilder,
                    ),
                    // Day separator line.
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 1,
                        color: theme.borderColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDayHeader(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]} ${date.day}';
  }
}

/// Default resource header widget.
class _DefaultResourceHeader extends StatelessWidget {
  const _DefaultResourceHeader({
    required this.resource,
    required this.theme,
    required this.showDivider,
  });

  final TideResource resource;
  final TideThemeData theme;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Resource: ${resource.displayName}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: theme.resourceDividerColor,
                    width: theme.resourceDividerWidth,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(width: 4, color: resource.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                resource.displayName,
                style: theme.dayHeaderTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-axis synced scroll area.
class _SyncedScrollArea extends StatefulWidget {
  const _SyncedScrollArea({
    required this.horizontalController,
    required this.verticalController,
    required this.totalWidth,
    required this.totalHeight,
    required this.child,
  });

  final ScrollController horizontalController;
  final ScrollController verticalController;
  final double totalWidth;
  final double totalHeight;
  final Widget child;

  @override
  State<_SyncedScrollArea> createState() => _SyncedScrollAreaState();
}

class _SyncedScrollAreaState extends State<_SyncedScrollArea> {
  final ScrollController _localH = ScrollController();
  final ScrollController _localV = ScrollController();
  bool _syncH = false;
  bool _syncV = false;

  @override
  void initState() {
    super.initState();
    _localH.addListener(_onLocalH);
    _localV.addListener(_onLocalV);
    widget.horizontalController.addListener(_onExtH);
    widget.verticalController.addListener(_onExtV);
  }

  @override
  void dispose() {
    _localH.removeListener(_onLocalH);
    _localV.removeListener(_onLocalV);
    widget.horizontalController.removeListener(_onExtH);
    widget.verticalController.removeListener(_onExtV);
    _localH.dispose();
    _localV.dispose();
    super.dispose();
  }

  void _onLocalH() {
    if (_syncH) return;
    _syncH = true;
    if (widget.horizontalController.hasClients) {
      widget.horizontalController.jumpTo(_localH.offset);
    }
    _syncH = false;
  }

  void _onExtH() {
    if (_syncH) return;
    _syncH = true;
    if (_localH.hasClients) {
      _localH.jumpTo(widget.horizontalController.offset);
    }
    _syncH = false;
  }

  void _onLocalV() {
    if (_syncV) return;
    _syncV = true;
    if (widget.verticalController.hasClients) {
      widget.verticalController.jumpTo(_localV.offset);
    }
    _syncV = false;
  }

  void _onExtV() {
    if (_syncV) return;
    _syncV = true;
    if (_localV.hasClients) {
      _localV.jumpTo(widget.verticalController.offset);
    }
    _syncV = false;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _localV,
      child: SingleChildScrollView(
        controller: _localH,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: widget.totalWidth,
          height: widget.totalHeight,
          child: widget.child,
        ),
      ),
    );
  }
}

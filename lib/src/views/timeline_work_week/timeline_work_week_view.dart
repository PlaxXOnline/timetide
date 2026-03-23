import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/drag_details.dart';
import '../../widgets/common/scroll_sync.dart';
import '../../core/models/event.dart';
import '../../core/models/resource.dart';
import '../../core/models/time_region.dart';
import '../../rendering/event_layout_engine.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';
import '../timeline_day/resource_row.dart';

/// A timeline work week view — identical to [TideTimelineWeekView] but
/// spanning only 5 weekdays (Monday–Friday).
class TideTimelineWorkWeekView extends StatefulWidget {
  /// Creates a [TideTimelineWorkWeekView].
  const TideTimelineWorkWeekView({
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
    this.allowDragAndDrop = false,
    this.allowResize = false,
    this.dragSnapInterval,
    this.dragStartBehavior = TideDragStartBehavior.adaptive,
    this.onDragEnd,
    this.onResizeEnd,
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

  /// Height of the time header row.
  final double timeHeaderHeight;

  /// Height of the day header row.
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

  /// Whether drag and drop is enabled for events.
  final bool allowDragAndDrop;

  /// Whether resize handles are shown on events.
  final bool allowResize;

  /// Grid interval for snapping during drag/resize.
  final Duration? dragSnapInterval;

  /// When drag gesture begins.
  final TideDragStartBehavior dragStartBehavior;

  /// Called when a drag operation completes.
  final void Function(TideDragEndDetails details)? onDragEnd;

  /// Called when a resize operation completes.
  final void Function(TideResizeEndDetails details)? onResizeEnd;

  @override
  State<TideTimelineWorkWeekView> createState() =>
      _TideTimelineWorkWeekViewState();
}

class _TideTimelineWorkWeekViewState extends State<TideTimelineWorkWeekView> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  List<TideResource> _resources = [];
  List<TideEvent> _events = [];
  List<TideTimeRegion> _timeRegions = [];
  bool _isLoading = true;

  /// GlobalKeys for resource rows — used for cross-resource drag hit-testing.
  final Map<String, GlobalKey> _resourceRowKeys = {};

  static const _numberOfDays = 5;

  List<DateTime> get _days {
    final range = widget.controller.visibleDateRange;
    return List.generate(
      _numberOfDays,
      (i) => range.start.add(Duration(days: i)),
    );
  }

  double get _dayWidth => (widget.endHour - widget.startHour) * widget.hourWidth;
  double get _totalTimeWidth => _dayWidth * _numberOfDays;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _loadData();
  }

  @override
  void didUpdateWidget(TideTimelineWorkWeekView oldWidget) {
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

  void _onControllerChanged() => _loadData();

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

      for (final r in _resources) {
        _resourceRowKeys.putIfAbsent(r.id, GlobalKey.new);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final theme = TideTheme.of(context);
    final totalResourceHeight = _resources.length * widget.resourceRowHeight;

    return Semantics(
      label: 'Timeline work week view',
      child: Column(
        children: [
          // Day + time header.
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
          Expanded(
            child: Row(
              children: [
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
                Expanded(
                  child: _SyncedScrollArea(
                    hController: _horizontalScrollController,
                    vController: _verticalScrollController,
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
                        right: BorderSide(color: theme.borderColor),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _formatDay(day),
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
          SizedBox(
            height: widget.timeHeaderHeight,
            child: Row(
              children: days.map((_) {
                return SizedBox(
                  width: _dayWidth,
                  child: _buildTimeLabels(theme),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLabels(TideThemeData theme) {
    return Row(
      children: List.generate(
        (widget.endHour - widget.startHour).toInt(),
        (i) => SizedBox(
          width: widget.hourWidth,
          child: Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '${(widget.startHour + i).toInt().toString().padLeft(2, '0')}:00',
              style: theme.timeSlotTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResourceHeaders(TideThemeData theme) {
    return Column(
      children: _resources.map((r) {
        return SizedBox(
          height: widget.resourceRowHeight,
          child: widget.resourceHeaderBuilder != null
              ? widget.resourceHeaderBuilder!(context, r)
              : Semantics(
                  label: 'Resource: ${r.displayName}',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: widget.showResourceDividers
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
                        Container(width: 4, color: r.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.displayName,
                            style: theme.dayHeaderTextStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
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

        return SizedBox(
          key: _resourceRowKeys[resource.id],
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
                      controller: widget.controller,
                      date: day,
                      allowDragAndDrop: widget.allowDragAndDrop,
                      allowResize: widget.allowResize,
                      dragSnapInterval: widget.dragSnapInterval,
                      dragStartBehavior: widget.dragStartBehavior,
                      onDragEnd: widget.onDragEnd != null
                          ? (details) {
                              final targetResourceId =
                                  details.dropPosition != null
                                      ? _resolveResourceAtPosition(
                                          details.dropPosition!)
                                      : null;
                              widget.onDragEnd!(TideDragEndDetails(
                                event: details.event,
                                newStart: details.newStart,
                                newEnd: details.newEnd,
                                newResourceId:
                                    targetResourceId ?? resource.id,
                                dropPosition: details.dropPosition,
                              ));
                            }
                          : null,
                      onResizeEnd: widget.onResizeEnd,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 1, color: theme.borderColor),
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

  /// Determines which resource row contains the given global position.
  String? _resolveResourceAtPosition(Offset globalPosition) {
    for (final entry in _resourceRowKeys.entries) {
      final renderBox =
          entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;
      final local = renderBox.globalToLocal(globalPosition);
      if (renderBox.paintBounds.contains(local)) {
        return entry.key;
      }
    }
    return null;
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _formatDay(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[d.weekday - 1]} ${d.day}';
  }
}

/// Two-axis synced scroll area (extracted for reuse).
class _SyncedScrollArea extends StatefulWidget {
  const _SyncedScrollArea({
    required this.hController,
    required this.vController,
    required this.totalWidth,
    required this.totalHeight,
    required this.child,
  });

  final ScrollController hController;
  final ScrollController vController;
  final double totalWidth;
  final double totalHeight;
  final Widget child;

  @override
  State<_SyncedScrollArea> createState() => _SyncedScrollAreaState();
}

class _SyncedScrollAreaState extends State<_SyncedScrollArea> {
  final ScrollController _lH = ScrollController();
  final ScrollController _lV = ScrollController();
  late final TideScrollSync _hSync;
  late final TideScrollSync _vSync;

  @override
  void initState() {
    super.initState();
    _hSync = TideScrollSync(primary: _lH, secondary: widget.hController);
    _vSync = TideScrollSync(primary: _lV, secondary: widget.vController);
  }

  @override
  void dispose() {
    _hSync.dispose();
    _vSync.dispose();
    _lH.dispose();
    _lV.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _lV,
      child: SingleChildScrollView(
        controller: _lH,
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

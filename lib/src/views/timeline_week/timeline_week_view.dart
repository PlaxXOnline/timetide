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
  State<TideTimelineWeekView> createState() => _TideTimelineWeekViewState();
}

class _TideTimelineWeekViewState extends State<TideTimelineWeekView> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  List<TideResource> _resources = [];
  List<TideEvent> _events = [];
  List<TideTimeRegion> _timeRegions = [];
  bool _isLoading = true;
  int _loadGeneration = 0;

  /// GlobalKeys for resource rows — used for cross-resource drag hit-testing.
  final Map<String, GlobalKey> _resourceRowKeys = {};

  // Cross-resource drag state — managed at parent level so all rows
  // can show/hide the dragged event as it moves between resources.
  TideEvent? _crossDragEvent;
  DateTime? _crossDragStart;
  DateTime? _crossDragEnd;
  String? _crossDragTargetResourceId;
  String? _crossDragSourceResourceId;

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
    final gen = ++_loadGeneration;
    final range = widget.controller.visibleDateRange;
    final results = await Future.wait([
      widget.controller.datasource.getResources(),
      widget.controller.datasource.getEvents(range.start, range.end),
      widget.controller.datasource.getTimeRegions(range.start, range.end),
    ]);
    if (!mounted || gen != _loadGeneration) return;
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
                      resourceId: resource.id,
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
                      onDragEnd: (details) {
                        final targetResourceId =
                            details.dropPosition != null
                                ? _resolveResourceAtPosition(
                                    details.dropPosition!)
                                : null;
                        _handleRowDragEnd(TideDragEndDetails(
                          event: details.event,
                          newStart: details.newStart,
                          newEnd: details.newEnd,
                          newResourceId:
                              targetResourceId ?? resource.id,
                          sourceResourceId: details.sourceResourceId,
                          dropPosition: details.dropPosition,
                        ));
                      },
                      onResizeEnd: widget.onResizeEnd,
                      crossDragEvent: _crossDragEvent,
                      crossDragStart: _crossDragStart,
                      crossDragEnd: _crossDragEnd,
                      crossDragTargetResourceId: _crossDragTargetResourceId,
                      crossDragSourceResourceId: _crossDragSourceResourceId,
                      onCrossDragUpdate: _onCrossDragUpdate,
                      onCrossDragEnd: _onCrossDragEnd,
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

  void _onCrossDragUpdate(
    TideEvent event,
    DateTime proposedStart,
    DateTime? proposedEnd,
    String sourceResourceId,
    Offset globalPosition,
  ) {
    final targetResourceId = _resolveResourceAtPosition(globalPosition);
    final isCrossResource =
        targetResourceId != null && targetResourceId != sourceResourceId;

    if (!isCrossResource && _crossDragEvent == null) {
      return; // Within source row, no cross-drag active — skip.
    }

    if (!isCrossResource && _crossDragEvent != null) {
      // Pointer moved back to source row — clear cross-drag.
      setState(() {
        _crossDragEvent = null;
        _crossDragStart = null;
        _crossDragEnd = null;
        _crossDragTargetResourceId = null;
        _crossDragSourceResourceId = null;
      });
      return;
    }

    // Cross-resource drag — only update if something changed.
    if (targetResourceId != _crossDragTargetResourceId ||
        proposedStart != _crossDragStart ||
        proposedEnd != _crossDragEnd) {
      setState(() {
        _crossDragEvent = event;
        _crossDragStart = proposedStart;
        _crossDragEnd = proposedEnd;
        _crossDragTargetResourceId = targetResourceId;
        _crossDragSourceResourceId = sourceResourceId;
      });
    }
  }

  void _onCrossDragEnd() {
    if (_crossDragEvent != null) {
      setState(() {
        _crossDragEvent = null;
        _crossDragStart = null;
        _crossDragEnd = null;
        _crossDragTargetResourceId = null;
        _crossDragSourceResourceId = null;
      });
    }
  }

  /// Optimistically updates [_events] when an event is dropped on a different
  /// resource so that any subsequent parent rebuild uses correct data.
  void _handleRowDragEnd(TideDragEndDetails details) {
    debugPrint('[DRAG-END] event=${details.event.subject}, '
        'source=${details.sourceResourceId}, '
        'target=${details.newResourceId}, '
        'dropPos=${details.dropPosition}');
    if (details.newResourceId != null && details.sourceResourceId != null) {
      final idx = _events.indexWhere((e) => e.id == details.event.id);
      debugPrint('[DRAG-END] idx=$idx, '
          'eventResourceIds=${idx >= 0 ? _events[idx].resourceIds : "N/A"}');
      if (idx >= 0) {
        final event = _events[idx];
        if (event.resourceIds != null) {
          final newIds = event.resourceIds!
              .map((id) =>
                  id == details.sourceResourceId ? details.newResourceId! : id)
              .toList();
          debugPrint('[DRAG-END] APPLYING optimistic update: $newIds');
          ++_loadGeneration; // Invalidate any pending _loadData
          setState(() {
            _events = List<TideEvent>.from(_events);
            _events[idx] = event.copyWith(
              resourceIds: newIds,
              startTime: details.newStart,
              endTime: details.newEnd,
            );
          });
        } else {
          debugPrint('[DRAG-END] SKIPPED: resourceIds is null');
        }
      } else {
        debugPrint('[DRAG-END] SKIPPED: event not found in _events');
      }
    } else {
      debugPrint('[DRAG-END] SKIPPED: newResourceId=${details.newResourceId}, sourceResourceId=${details.sourceResourceId}');
    }
    // Forward to the app's callback.
    widget.onDragEnd?.call(details);
  }

  /// Determines which resource row contains the given global position.
  String? _resolveResourceAtPosition(Offset globalPosition) {
    for (final entry in _resourceRowKeys.entries) {
      final renderBox =
          entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        debugPrint('[RESOLVE] key=${entry.key}: renderBox=NULL');
        continue;
      }
      final local = renderBox.globalToLocal(globalPosition);
      final contains = renderBox.paintBounds.contains(local);
      if (contains) {
        debugPrint('[RESOLVE] HIT key=${entry.key} local=$local bounds=${renderBox.paintBounds}');
        return entry.key;
      }
    }
    debugPrint('[RESOLVE] MISS for globalPosition=$globalPosition (checked ${_resourceRowKeys.length} keys)');
    return null;
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
  late final TideScrollSync _hSync;
  late final TideScrollSync _vSync;

  @override
  void initState() {
    super.initState();
    _hSync = TideScrollSync(
      primary: _localH,
      secondary: widget.horizontalController,
    );
    _vSync = TideScrollSync(
      primary: _localV,
      secondary: widget.verticalController,
    );
  }

  @override
  void dispose() {
    _hSync.dispose();
    _vSync.dispose();
    _localH.dispose();
    _localV.dispose();
    super.dispose();
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

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/event.dart';
import '../../core/models/resource.dart';
import '../../rendering/event_layout_engine.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';

/// A timeline month view showing resources as rows with the entire month as
/// the horizontal axis.
///
/// Hours are compressed into day blocks — suitable for absence/shift planning
/// where events span multiple days. Week separator lines visually divide
/// the month.
class TideTimelineMonthView extends StatefulWidget {
  /// Creates a [TideTimelineMonthView].
  const TideTimelineMonthView({
    super.key,
    required this.controller,
    this.dayWidth = 40.0,
    this.resourceRowHeight = 50.0,
    this.resourceHeaderWidth = 120.0,
    this.dayHeaderHeight = 40.0,
    this.showResourceDividers = true,
    this.showWeekSeparators = true,
    this.onEventTap,
    this.resourceHeaderBuilder,
    this.eventBuilder,
  });

  /// The controller managing navigation, data, and selection.
  final TideController controller;

  /// Width of each day column along the horizontal axis.
  final double dayWidth;

  /// Height of each resource row.
  final double resourceRowHeight;

  /// Width of the sticky resource header column.
  final double resourceHeaderWidth;

  /// Height of the day header at the top.
  final double dayHeaderHeight;

  /// Whether to show divider lines between resource rows.
  final bool showResourceDividers;

  /// Whether to show vertical separator lines at week boundaries.
  final bool showWeekSeparators;

  /// Called when an event is tapped.
  final ValueChanged<TideEvent>? onEventTap;

  /// Custom builder for resource headers.
  final Widget Function(BuildContext, TideResource)? resourceHeaderBuilder;

  /// Custom builder for event tiles.
  final Widget Function(BuildContext, TideEvent, TideEventBounds)? eventBuilder;

  @override
  State<TideTimelineMonthView> createState() => _TideTimelineMonthViewState();
}

class _TideTimelineMonthViewState extends State<TideTimelineMonthView> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  List<TideResource> _resources = [];
  List<TideEvent> _events = [];
  bool _isLoading = true;

  List<DateTime> get _days {
    final range = widget.controller.visibleDateRange;
    final dayCount = range.end.difference(range.start).inDays;
    return List.generate(
      dayCount,
      (i) => range.start.add(Duration(days: i)),
    );
  }

  double get _totalTimeWidth => _days.length * widget.dayWidth;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _loadData();
  }

  @override
  void didUpdateWidget(TideTimelineMonthView oldWidget) {
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
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _onControllerChanged() => _loadData();

  Future<void> _loadData() async {
    final range = widget.controller.visibleDateRange;
    final results = await Future.wait([
      widget.controller.datasource.getResources(),
      widget.controller.datasource.getEvents(range.start, range.end),
    ]);
    if (!mounted) return;
    setState(() {
      _resources = results[0] as List<TideResource>;
      _events = results[1] as List<TideEvent>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final theme = TideTheme.of(context);
    final totalResourceHeight = _resources.length * widget.resourceRowHeight;

    return Semantics(
      label: 'Timeline month view',
      child: Column(
        children: [
          // Day header.
          SizedBox(
            height: widget.dayHeaderHeight,
            child: Row(
              children: [
                SizedBox(width: widget.resourceHeaderWidth),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (_) => true,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: _buildDayHeader(theme),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content area.
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: widget.resourceHeaderWidth,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      child: _buildResourceHeaders(theme),
                    ),
                  ),
                ),
                Expanded(
                  child: _SyncedScrollArea(
                    hController: _horizontalController,
                    vController: _verticalController,
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

  Widget _buildDayHeader(TideThemeData theme) {
    final days = _days;
    return SizedBox(
      width: _totalTimeWidth,
      child: Row(
        children: days.map((day) {
          final isToday = _isToday(day);
          final isMonday = day.weekday == DateTime.monday;
          return SizedBox(
            width: widget.dayWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: isMonday && widget.showWeekSeparators
                      ? BorderSide(color: theme.borderColor, width: 2)
                      : BorderSide(color: theme.borderColor, width: 0.5),
                ),
              ),
              child: Center(
                child: Text(
                  '${day.day}',
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
    );
  }

  Widget _buildResourceHeaders(TideThemeData theme) {
    return Column(
      children: _resources.map((resource) {
        return SizedBox(
          height: widget.resourceRowHeight,
          child: widget.resourceHeaderBuilder != null
              ? widget.resourceHeaderBuilder!(context, resource)
              : Semantics(
                  label: 'Resource: ${resource.displayName}',
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
                ),
        );
      }).toList(),
    );
  }

  Widget _buildContent(TideThemeData theme) {
    final days = _days;
    final visibleResIds = widget.controller.visibleResourceIds;

    return Stack(
      children: [
        // Resource rows with events.
        Column(
          children: _resources.map((resource) {
            if (visibleResIds.isNotEmpty &&
                !visibleResIds.contains(resource.id)) {
              return SizedBox(height: widget.resourceRowHeight);
            }

            return SizedBox(
              height: widget.resourceRowHeight,
              child: Stack(
                children: [
                  // Row divider.
                  if (widget.showResourceDividers)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: theme.resourceDividerWidth,
                        color: theme.resourceDividerColor,
                      ),
                    ),
                  // Events spanning days.
                  ..._buildEventsForResource(theme, resource, days),
                ],
              ),
            );
          }).toList(),
        ),
        // Week separator lines.
        if (widget.showWeekSeparators)
          ...days.where((d) => d.weekday == DateTime.monday).map((monday) {
            final dayIndex = days.indexOf(monday);
            return Positioned(
              left: dayIndex * widget.dayWidth,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                color: theme.borderColor,
              ),
            );
          }),
      ],
    );
  }

  List<Widget> _buildEventsForResource(
    TideThemeData theme,
    TideResource resource,
    List<DateTime> days,
  ) {
    if (days.isEmpty) return [];

    final rangeStart = days.first;
    final rangeEnd = days.last.add(const Duration(days: 1));

    final resourceEvents = _events
        .where((e) =>
            (e.resourceIds == null ||
                e.resourceIds!.contains(resource.id)) &&
            e.startTime.isBefore(rangeEnd) &&
            e.endTime.isAfter(rangeStart))
        .toList();

    return resourceEvents.map((event) {
      final startDay = event.startTime.isBefore(rangeStart)
          ? 0.0
          : event.startTime.difference(rangeStart).inHours / 24.0;
      final endDay = event.endTime.isAfter(rangeEnd)
          ? days.length.toDouble()
          : event.endTime.difference(rangeStart).inHours / 24.0;

      final left = startDay * widget.dayWidth;
      final width = (endDay - startDay) * widget.dayWidth;

      if (widget.eventBuilder != null) {
        final bounds = TideEventBounds(
          left: left,
          top: 2,
          width: width.clamp(widget.dayWidth * 0.5, double.infinity),
          height: widget.resourceRowHeight - 4,
        );
        return Positioned(
          left: left,
          top: 2,
          width: width.clamp(widget.dayWidth * 0.5, double.infinity),
          height: widget.resourceRowHeight - 4,
          child: widget.eventBuilder!(context, event, bounds),
        );
      }

      return Positioned(
        left: left,
        top: 2,
        width: width.clamp(widget.dayWidth * 0.5, double.infinity),
        height: widget.resourceRowHeight - 4,
        child: Semantics(
          label: 'Event: ${event.subject}',
          child: GestureDetector(
            onTap: widget.onEventTap != null
                ? () => widget.onEventTap!(event)
                : null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: event.color ?? theme.primaryColor,
                borderRadius: theme.eventBorderRadius,
              ),
              child: Padding(
                padding: theme.eventPadding,
                child: Text(
                  event.subject,
                  style: theme.eventTitleStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

/// Two-axis synced scroll area.
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
  bool _sH = false;
  bool _sV = false;

  @override
  void initState() {
    super.initState();
    _lH.addListener(_onLH);
    _lV.addListener(_onLV);
    widget.hController.addListener(_onEH);
    widget.vController.addListener(_onEV);
  }

  @override
  void dispose() {
    _lH.removeListener(_onLH);
    _lV.removeListener(_onLV);
    widget.hController.removeListener(_onEH);
    widget.vController.removeListener(_onEV);
    _lH.dispose();
    _lV.dispose();
    super.dispose();
  }

  void _onLH() {
    if (_sH) return;
    _sH = true;
    if (widget.hController.hasClients) widget.hController.jumpTo(_lH.offset);
    _sH = false;
  }

  void _onEH() {
    if (_sH) return;
    _sH = true;
    if (_lH.hasClients) _lH.jumpTo(widget.hController.offset);
    _sH = false;
  }

  void _onLV() {
    if (_sV) return;
    _sV = true;
    if (widget.vController.hasClients) widget.vController.jumpTo(_lV.offset);
    _sV = false;
  }

  void _onEV() {
    if (_sV) return;
    _sV = true;
    if (_lV.hasClients) _lV.jumpTo(widget.vController.offset);
    _sV = false;
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

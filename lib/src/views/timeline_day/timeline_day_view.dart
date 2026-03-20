import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/event.dart';
import '../../core/models/time_region.dart';
import '../../core/models/resource.dart';
import '../../rendering/current_time_painter.dart';
import '../../rendering/event_layout_engine.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';
import 'resource_row.dart';

/// A timeline day view showing resources as horizontal rows with time flowing
/// left to right.
///
/// Features two independent scroll axes: horizontal for time and vertical for
/// resources. A sticky resource header column stays fixed during horizontal
/// scrolling.
class TideTimelineDayView extends StatefulWidget {
  /// Creates a [TideTimelineDayView].
  const TideTimelineDayView({
    super.key,
    required this.controller,
    this.startHour = 0,
    this.endHour = 24,
    this.hourWidth = 80.0,
    this.resourceRowHeight = 60.0,
    this.resourceHeaderWidth = 120.0,
    this.timeHeaderHeight = 40.0,
    this.timeSlotInterval = const Duration(minutes: 60),
    this.showResourceDividers = true,
    this.showCurrentTimeIndicator = true,
    this.overlapStrategy = TideOverlapStrategy.sideBySide,
    this.onEventTap,
    this.onEmptySlotTap,
    this.resourceHeaderBuilder,
    this.eventBuilder,
  });

  /// The controller managing navigation, data, and selection.
  final TideController controller;

  /// First visible hour (0–24).
  final double startHour;

  /// Last visible hour (0–24).
  final double endHour;

  /// Pixels per hour along the horizontal time axis.
  final double hourWidth;

  /// Height of each resource row.
  final double resourceRowHeight;

  /// Width of the sticky resource header column.
  final double resourceHeaderWidth;

  /// Height of the time header at the top.
  final double timeHeaderHeight;

  /// Duration of each time-slot column.
  final Duration timeSlotInterval;

  /// Whether to show divider lines between resource rows.
  final bool showResourceDividers;

  /// Whether to show the current time indicator.
  final bool showCurrentTimeIndicator;

  /// Strategy for handling overlapping events within a row.
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
  State<TideTimelineDayView> createState() => _TideTimelineDayViewState();
}

class _TideTimelineDayViewState extends State<TideTimelineDayView> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  late final TideCurrentTimeNotifier _timeNotifier;

  List<TideResource> _resources = [];
  List<TideEvent> _events = [];
  List<TideTimeRegion> _timeRegions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _timeNotifier = TideCurrentTimeNotifier();
    widget.controller.addListener(_onControllerChanged);
    _loadData();
  }

  @override
  void didUpdateWidget(TideTimelineDayView oldWidget) {
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
    _timeNotifier.dispose();
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
    final totalHours = widget.endHour - widget.startHour;
    final totalTimeWidth = totalHours * widget.hourWidth;
    final totalResourceHeight = _resources.length * widget.resourceRowHeight;

    return Semantics(
      label: 'Timeline day view',
      child: Column(
        children: [
          // Time header row.
          SizedBox(
            height: widget.timeHeaderHeight,
            child: Row(
              children: [
                // Corner spacer.
                SizedBox(
                  width: widget.resourceHeaderWidth,
                  height: widget.timeHeaderHeight,
                ),
                // Scrollable time labels.
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (_) => true,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: _buildTimeHeader(theme, totalTimeWidth),
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
                // Sticky resource header column.
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
                // Scrollable content area.
                Expanded(
                  child: _TimelineContent(
                    horizontalController: _horizontalScrollController,
                    verticalController: _verticalScrollController,
                    totalTimeWidth: totalTimeWidth,
                    totalResourceHeight: totalResourceHeight,
                    child: _buildContent(theme, totalTimeWidth),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeHeader(TideThemeData theme, double totalWidth) {
    final hours = <Widget>[];
    for (var h = widget.startHour; h < widget.endHour; h++) {
      hours.add(
        SizedBox(
          width: widget.hourWidth,
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '${h.toInt().toString().padLeft(2, '0')}:00',
              style: theme.timeSlotTextStyle,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: totalWidth,
      child: Row(children: hours),
    );
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

  Widget _buildContent(TideThemeData theme, double totalTimeWidth) {
    final visibleResIds = widget.controller.visibleResourceIds;

    return Column(
      children: _resources.map((resource) {
        if (visibleResIds.isNotEmpty && !visibleResIds.contains(resource.id)) {
          return SizedBox(height: widget.resourceRowHeight);
        }

        final resourceEvents = _events
            .where((e) =>
                e.resourceIds == null || e.resourceIds!.contains(resource.id))
            .toList();

        final resourceRegions = _timeRegions
            .where((r) =>
                r.resourceIds == null || r.resourceIds!.contains(resource.id))
            .toList();

        return TideResourceRow(
          events: resourceEvents,
          startHour: widget.startHour,
          endHour: widget.endHour,
          hourWidth: widget.hourWidth,
          rowHeight: widget.resourceRowHeight,
          timeRegions: resourceRegions,
          timeSlotInterval: widget.timeSlotInterval,
          overlapStrategy: widget.overlapStrategy,
          showDivider: widget.showResourceDividers,
          onEventTap: widget.onEventTap,
          onEmptySlotTap: widget.onEmptySlotTap,
          eventBuilder: widget.eventBuilder,
        );
      }).toList(),
    );
  }
}

/// Default resource header widget showing the resource name and color bar.
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
            Container(
              width: 4,
              color: resource.color,
            ),
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

/// Synchronized two-axis scrollable content area.
///
/// Horizontal scrolling is synced with the time header via
/// [horizontalController], and vertical scrolling is synced with the resource
/// headers via [verticalController].
class _TimelineContent extends StatefulWidget {
  const _TimelineContent({
    required this.horizontalController,
    required this.verticalController,
    required this.totalTimeWidth,
    required this.totalResourceHeight,
    required this.child,
  });

  final ScrollController horizontalController;
  final ScrollController verticalController;
  final double totalTimeWidth;
  final double totalResourceHeight;
  final Widget child;

  @override
  State<_TimelineContent> createState() => _TimelineContentState();
}

class _TimelineContentState extends State<_TimelineContent> {
  final ScrollController _localHorizontal = ScrollController();
  final ScrollController _localVertical = ScrollController();
  bool _syncingHorizontal = false;
  bool _syncingVertical = false;

  @override
  void initState() {
    super.initState();
    _localHorizontal.addListener(_onLocalHorizontalScroll);
    _localVertical.addListener(_onLocalVerticalScroll);
    widget.horizontalController.addListener(_onExternalHorizontalScroll);
    widget.verticalController.addListener(_onExternalVerticalScroll);
  }

  @override
  void dispose() {
    _localHorizontal.removeListener(_onLocalHorizontalScroll);
    _localVertical.removeListener(_onLocalVerticalScroll);
    widget.horizontalController.removeListener(_onExternalHorizontalScroll);
    widget.verticalController.removeListener(_onExternalVerticalScroll);
    _localHorizontal.dispose();
    _localVertical.dispose();
    super.dispose();
  }

  void _onLocalHorizontalScroll() {
    if (_syncingHorizontal) return;
    _syncingHorizontal = true;
    if (widget.horizontalController.hasClients) {
      widget.horizontalController.jumpTo(_localHorizontal.offset);
    }
    _syncingHorizontal = false;
  }

  void _onExternalHorizontalScroll() {
    if (_syncingHorizontal) return;
    _syncingHorizontal = true;
    if (_localHorizontal.hasClients) {
      _localHorizontal.jumpTo(widget.horizontalController.offset);
    }
    _syncingHorizontal = false;
  }

  void _onLocalVerticalScroll() {
    if (_syncingVertical) return;
    _syncingVertical = true;
    if (widget.verticalController.hasClients) {
      widget.verticalController.jumpTo(_localVertical.offset);
    }
    _syncingVertical = false;
  }

  void _onExternalVerticalScroll() {
    if (_syncingVertical) return;
    _syncingVertical = true;
    if (_localVertical.hasClients) {
      _localVertical.jumpTo(widget.verticalController.offset);
    }
    _syncingVertical = false;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _localVertical,
      child: SingleChildScrollView(
        controller: _localHorizontal,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: widget.totalTimeWidth,
          height: widget.totalResourceHeight,
          child: widget.child,
        ),
      ),
    );
  }
}

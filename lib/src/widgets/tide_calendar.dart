import 'package:flutter/widgets.dart';

import '../core/controller.dart';
import '../core/datasource.dart';
import '../core/models/drag_details.dart';
import '../core/models/event.dart';
import '../core/models/resource.dart';
import '../core/models/view.dart';
import '../core/presets.dart';
import '../interaction/drag_drop/external_drag.dart';
import '../interaction/keyboard/shortcut_handler.dart';
import '../l10n/tide_localizations.dart';
import '../rendering/event_layout_engine.dart';
import '../theme/tide_theme.dart';
import '../theme/tide_theme_data.dart';
import '../views/day/day_view.dart';
import '../views/month/month_view.dart';
import '../views/multi_week/multi_week_view.dart';
import '../views/schedule/schedule_view.dart';
import '../views/timeline_day/timeline_day_view.dart';
import '../views/timeline_month/timeline_month_view.dart';
import '../views/timeline_week/timeline_week_view.dart';
import '../views/timeline_work_week/timeline_work_week_view.dart';
import '../views/resource_day/resource_day_view.dart';
import '../views/resource_week/resource_week_view.dart';
import '../views/view_switcher.dart';
import '../views/week/week_view.dart';
import '../views/work_week/work_week_view.dart';
import '../views/year/year_view.dart';
import 'header/calendar_header.dart';

/// The main entry-point widget for timetide.
///
/// Assembles the calendar header, view switcher, and the active view widget
/// into a single composable widget. Manages an internal [TideController] if
/// none is provided (following the [ScrollController] ownership pattern).
///
/// ```dart
/// TideCalendar(
///   datasource: myDatasource,
///   initialView: TideView.week,
///   onEventTap: (event) => showDetails(event),
/// )
/// ```
class TideCalendar extends StatefulWidget {
  /// Creates a [TideCalendar].
  const TideCalendar({
    super.key,
    required this.datasource,
    this.controller,
    this.initialView = TideView.week,
    this.initialDate,
    this.allowedViews,
    this.viewTransition = TideViewTransition.fade,
    this.timeSlotInterval = const Duration(minutes: 30),
    this.startHour = 0.0,
    this.endHour = 24.0,
    this.eventOverlapStrategy = TideOverlapStrategy.sideBySide,
    this.showResourceView = false,
    this.resourceHeaderWidth = 120,
    this.allowDragAndDrop = true,
    this.allowResize = true,
    this.dragSnapInterval = const Duration(minutes: 15),
    this.dragStartBehavior = TideDragStartBehavior.adaptive,
    this.showHeader = true,
    this.firstDayOfWeek,
    // Callbacks
    this.onEventTap,
    this.onEventDoubleTap,
    this.onEmptySlotTap,
    this.onEmptySlotLongPress,
    this.onDragEnd,
    this.onResizeEnd,
    this.onViewChanged,
    this.onSelectionChanged,
    this.onDateTap,
    this.onNewEvent,
    this.onDeleteSelected,
    // Builders
    this.eventBuilder,
    this.resourceHeaderBuilder,
    this.dayHeaderBuilder,
    this.monthCellBuilder,
    this.headerBuilder,
    this.tooltipBuilder,
    this.contextMenuBuilder,
    this.allDayEventBuilder,
    // Theming & l10n
    this.themeData,
    this.localizations,
  });

  /// Creates a [TideCalendar] configured from a [TidePreset].
  ///
  /// Preset values are applied as defaults; explicit parameters override them.
  factory TideCalendar.preset(
    TidePreset preset, {
    Key? key,
    required TideDatasource datasource,
    TideController? controller,
    DateTime? initialDate,
    List<TideView>? allowedViews,
    TideViewTransition viewTransition = TideViewTransition.fade,
    bool showHeader = true,
    int? firstDayOfWeek,
    // Callbacks
    void Function(TideEvent event)? onEventTap,
    void Function(TideEvent event)? onEventDoubleTap,
    void Function(DateTime dateTime)? onEmptySlotTap,
    void Function(DateTime dateTime)? onEmptySlotLongPress,
    void Function(TideDragEndDetails details)? onDragEnd,
    void Function(TideResizeEndDetails details)? onResizeEnd,
    void Function(TideView view)? onViewChanged,
    void Function(List<TideEvent> events)? onSelectionChanged,
    void Function(DateTime date)? onDateTap,
    VoidCallback? onNewEvent,
    VoidCallback? onDeleteSelected,
    // Builders
    Widget Function(BuildContext context, TideEvent event)? eventBuilder,
    Widget Function(BuildContext context, TideResource resource)?
        resourceHeaderBuilder,
    Widget Function(BuildContext context, DateTime date)? dayHeaderBuilder,
    Widget Function(BuildContext context, DateTime date, List<TideEvent> events)?
        monthCellBuilder,
    Widget Function(BuildContext context, TideController controller)?
        headerBuilder,
    Widget Function(BuildContext context, TideEvent event)? tooltipBuilder,
    Widget Function(BuildContext context, TideEvent event)? contextMenuBuilder,
    Widget Function(BuildContext context, TideEvent event)? allDayEventBuilder,
    // Theming & l10n
    TideThemeData? themeData,
    TideLocalizations? localizations,
  }) {
    final config = preset.config;
    return TideCalendar(
      key: key,
      datasource: datasource,
      controller: controller,
      initialView: config.initialView,
      initialDate: initialDate,
      allowedViews: allowedViews,
      viewTransition: viewTransition,
      timeSlotInterval: config.timeSlotDuration,
      startHour: config.workDayStart.toDouble(),
      endHour: config.workDayEnd.toDouble(),
      showResourceView: config.resourcesEnabled,
      showHeader: showHeader,
      firstDayOfWeek: firstDayOfWeek,
      onEventTap: onEventTap,
      onEventDoubleTap: onEventDoubleTap,
      onEmptySlotTap: onEmptySlotTap,
      onEmptySlotLongPress: onEmptySlotLongPress,
      onDragEnd: onDragEnd,
      onResizeEnd: onResizeEnd,
      onViewChanged: onViewChanged,
      onSelectionChanged: onSelectionChanged,
      onDateTap: onDateTap,
      onNewEvent: onNewEvent,
      onDeleteSelected: onDeleteSelected,
      eventBuilder: eventBuilder,
      resourceHeaderBuilder: resourceHeaderBuilder,
      dayHeaderBuilder: dayHeaderBuilder,
      monthCellBuilder: monthCellBuilder,
      headerBuilder: headerBuilder,
      tooltipBuilder: tooltipBuilder,
      contextMenuBuilder: contextMenuBuilder,
      allDayEventBuilder: allDayEventBuilder,
      themeData: themeData,
      localizations: localizations,
    );
  }

  /// The datasource supplying events, resources, and time regions.
  final TideDatasource datasource;

  /// Optional external controller. If null, one is created internally.
  final TideController? controller;

  /// The initial calendar view. Defaults to [TideView.week].
  final TideView initialView;

  /// The initial display date. Defaults to today.
  final DateTime? initialDate;

  /// Views available in the view switcher. If null, all views are allowed.
  final List<TideView>? allowedViews;

  /// Transition style used when switching between views.
  final TideViewTransition viewTransition;

  /// Duration of each time-slot row in day/week/timeline views.
  final Duration timeSlotInterval;

  /// First visible hour. Defaults to 0.0 (midnight).
  final double startHour;

  /// Last visible hour. Defaults to 24.0 (end-of-day).
  final double endHour;

  /// How overlapping events are arranged.
  final TideOverlapStrategy eventOverlapStrategy;

  /// Whether to show resource columns/rows.
  final bool showResourceView;

  /// Width of the resource header column.
  final double resourceHeaderWidth;

  /// Whether events can be dragged.
  final bool allowDragAndDrop;

  /// Whether events can be resized.
  final bool allowResize;

  /// Time grid snap interval for drag operations.
  final Duration dragSnapInterval;

  /// When drag gesture starts.
  final TideDragStartBehavior dragStartBehavior;

  /// Whether to show the built-in header. Defaults to true.
  final bool showHeader;

  /// First day of the week (1 = Monday, 7 = Sunday). Uses system default
  /// if null.
  final int? firstDayOfWeek;

  // ─── Callbacks ──────────────────────────────────────────

  /// Called when an event is tapped.
  final void Function(TideEvent event)? onEventTap;

  /// Called when an event is double-tapped.
  final void Function(TideEvent event)? onEventDoubleTap;

  /// Called when an empty time slot is tapped.
  final void Function(DateTime dateTime)? onEmptySlotTap;

  /// Called when an empty time slot is long-pressed.
  final void Function(DateTime dateTime)? onEmptySlotLongPress;

  /// Called when a drag operation completes.
  final void Function(TideDragEndDetails details)? onDragEnd;

  /// Called when a resize operation completes.
  final void Function(TideResizeEndDetails details)? onResizeEnd;

  /// Called when the active view changes.
  final void Function(TideView view)? onViewChanged;

  /// Called when the event selection changes.
  final void Function(List<TideEvent> events)? onSelectionChanged;

  /// Called when a date cell is tapped (month view).
  final void Function(DateTime date)? onDateTap;

  /// Called when the "new event" keyboard shortcut fires.
  final VoidCallback? onNewEvent;

  /// Called when the "delete" keyboard shortcut fires with selected events.
  final VoidCallback? onDeleteSelected;

  // ─── Builders ──────────────────────────────────────────

  /// Custom builder for event tiles.
  final Widget Function(BuildContext context, TideEvent event)? eventBuilder;

  /// Custom builder for resource headers.
  final Widget Function(BuildContext context, TideResource resource)?
      resourceHeaderBuilder;

  /// Custom builder for day column headers.
  final Widget Function(BuildContext context, DateTime date)? dayHeaderBuilder;

  /// Custom builder for month view cells.
  final Widget Function(
      BuildContext context, DateTime date, List<TideEvent> events)?
      monthCellBuilder;

  /// Custom builder for the entire header area. When set, replaces the
  /// default [TideCalendarHeader].
  final Widget Function(BuildContext context, TideController controller)?
      headerBuilder;

  /// Custom builder for event tooltips.
  final Widget Function(BuildContext context, TideEvent event)? tooltipBuilder;

  /// Custom builder for context menus.
  final Widget Function(BuildContext context, TideEvent event)?
      contextMenuBuilder;

  /// Custom builder for all-day event tiles.
  final Widget Function(BuildContext context, TideEvent event)?
      allDayEventBuilder;

  // ─── Theming & Localization ────────────────────────────

  /// Theme data for the calendar. If null, uses default [TideThemeData].
  final TideThemeData? themeData;

  /// Localized strings. If null, uses English defaults.
  final TideLocalizations? localizations;

  @override
  State<TideCalendar> createState() => _TideCalendarState();
}

class _TideCalendarState extends State<TideCalendar> {
  late TideController _controller;
  bool _ownsController = false;

  TideLocalizations get _l10n =>
      widget.localizations ?? TideLocalizations.en();

  @override
  void initState() {
    super.initState();
    _initController();
    _controller.currentViewNotifier.addListener(_onViewChanged);
    _controller.selectedEventsNotifier.addListener(_onSelectionChanged);
  }

  @override
  void didUpdateWidget(TideCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.currentViewNotifier.removeListener(_onViewChanged);
      _controller.selectedEventsNotifier.removeListener(_onSelectionChanged);
      _disposeControllerIfOwned();
      _initController();
      _controller.currentViewNotifier.addListener(_onViewChanged);
      _controller.selectedEventsNotifier.addListener(_onSelectionChanged);
    }
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = TideController(
        datasource: widget.datasource,
        initialView: widget.initialView,
        initialDate: widget.initialDate,
      );
      _ownsController = true;
    }
  }

  void _disposeControllerIfOwned() {
    if (_ownsController) {
      _controller.dispose();
    }
  }

  void _onViewChanged() {
    widget.onViewChanged?.call(_controller.currentView);
  }

  void _onSelectionChanged() {
    widget.onSelectionChanged?.call(_controller.selectedEvents);
  }

  @override
  void dispose() {
    _controller.currentViewNotifier.removeListener(_onViewChanged);
    _controller.selectedEventsNotifier.removeListener(_onSelectionChanged);
    _disposeControllerIfOwned();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = TideShortcutHandler(
      controller: _controller,
      onNewEvent: widget.onNewEvent,
      onDeleteSelected: widget.onDeleteSelected,
      child: Column(
        children: [
          if (widget.showHeader) _buildHeader(),
          Expanded(
            child: TideViewSwitcher(
              controller: _controller,
              transition: widget.viewTransition,
              viewBuilder: _buildView,
            ),
          ),
        ],
      ),
    );

    if (widget.themeData != null) {
      body = TideTheme(data: widget.themeData!, child: body);
    }

    return Semantics(
      label: 'Calendar',
      child: TideExternalDragScope(child: body),
    );
  }

  Widget _buildHeader() {
    if (widget.headerBuilder != null) {
      return widget.headerBuilder!(context, _controller);
    }
    return TideCalendarHeader(
      controller: _controller,
      localizations: _l10n,
      allowedViews: widget.allowedViews,
    );
  }

  Widget _buildView(BuildContext context, TideView view) {
    switch (view) {
      case TideView.day:
        return TideDayView(
          controller: _controller,
          timeSlotInterval: widget.timeSlotInterval,
          startHour: widget.startHour,
          endHour: widget.endHour,
          eventOverlapStrategy: widget.eventOverlapStrategy,
          onEventTap: widget.onEventTap,
          onEmptySlotTap: widget.onEmptySlotTap,
          eventBuilder: widget.eventBuilder,
          allDayEventBuilder: widget.allDayEventBuilder,
          allowDragAndDrop: widget.allowDragAndDrop,
          allowResize: widget.allowResize,
          dragSnapInterval: widget.dragSnapInterval,
          dragStartBehavior: widget.dragStartBehavior,
          onDragEnd: widget.onDragEnd,
          onResizeEnd: widget.onResizeEnd,
        );
      case TideView.week:
        return TideWeekView(
          controller: _controller,
          timeSlotInterval: widget.timeSlotInterval,
          startHour: widget.startHour,
          endHour: widget.endHour,
          eventOverlapStrategy: widget.eventOverlapStrategy,
          onEventTap: widget.onEventTap,
          onEmptySlotTap: widget.onEmptySlotTap,
          eventBuilder: widget.eventBuilder,
          allDayEventBuilder: widget.allDayEventBuilder,
          firstDayOfWeek: widget.firstDayOfWeek ?? DateTime.monday,
          allowDragAndDrop: widget.allowDragAndDrop,
          allowResize: widget.allowResize,
          dragSnapInterval: widget.dragSnapInterval,
          dragStartBehavior: widget.dragStartBehavior,
          onDragEnd: widget.onDragEnd,
          onResizeEnd: widget.onResizeEnd,
        );
      case TideView.workWeek:
        return TideWorkWeekView(
          controller: _controller,
          timeSlotInterval: widget.timeSlotInterval,
          startHour: widget.startHour,
          endHour: widget.endHour,
          eventOverlapStrategy: widget.eventOverlapStrategy,
          onEventTap: widget.onEventTap,
          onEmptySlotTap: widget.onEmptySlotTap,
          eventBuilder: widget.eventBuilder,
          allDayEventBuilder: widget.allDayEventBuilder,
          allowDragAndDrop: widget.allowDragAndDrop,
          allowResize: widget.allowResize,
          dragSnapInterval: widget.dragSnapInterval,
          dragStartBehavior: widget.dragStartBehavior,
          onDragEnd: widget.onDragEnd,
          onResizeEnd: widget.onResizeEnd,
        );
      case TideView.month:
        return TideMonthView(
          controller: _controller,
          onEventTap: widget.onEventTap,
          onDateTap: widget.onDateTap,
          eventBuilder: widget.eventBuilder,
          firstDayOfWeek: widget.firstDayOfWeek ?? DateTime.monday,
        );
      case TideView.schedule:
        return TideScheduleView(
          controller: _controller,
          onEventTap: widget.onEventTap,
          eventBuilder: widget.eventBuilder,
        );
      case TideView.timelineDay:
        return TideTimelineDayView(
          controller: _controller,
          startHour: widget.startHour,
          endHour: widget.endHour,
          resourceHeaderWidth: widget.resourceHeaderWidth,
          onEventTap: widget.onEventTap,
          onEmptySlotTap: widget.onEmptySlotTap,
          resourceHeaderBuilder: widget.resourceHeaderBuilder,
          allowDragAndDrop: widget.allowDragAndDrop,
          allowResize: widget.allowResize,
          dragSnapInterval: widget.dragSnapInterval,
          dragStartBehavior: widget.dragStartBehavior,
          onDragEnd: widget.onDragEnd,
          onResizeEnd: widget.onResizeEnd,
        );
      case TideView.timelineWeek:
        return TideTimelineWeekView(
          controller: _controller,
          startHour: widget.startHour,
          endHour: widget.endHour,
          resourceHeaderWidth: widget.resourceHeaderWidth,
          onEventTap: widget.onEventTap,
          resourceHeaderBuilder: widget.resourceHeaderBuilder,
          allowDragAndDrop: widget.allowDragAndDrop,
          allowResize: widget.allowResize,
          dragSnapInterval: widget.dragSnapInterval,
          dragStartBehavior: widget.dragStartBehavior,
          onDragEnd: widget.onDragEnd,
          onResizeEnd: widget.onResizeEnd,
        );
      case TideView.timelineWorkWeek:
        return TideTimelineWorkWeekView(
          controller: _controller,
          startHour: widget.startHour,
          endHour: widget.endHour,
          resourceHeaderWidth: widget.resourceHeaderWidth,
          onEventTap: widget.onEventTap,
          resourceHeaderBuilder: widget.resourceHeaderBuilder,
          allowDragAndDrop: widget.allowDragAndDrop,
          allowResize: widget.allowResize,
          dragSnapInterval: widget.dragSnapInterval,
          dragStartBehavior: widget.dragStartBehavior,
          onDragEnd: widget.onDragEnd,
          onResizeEnd: widget.onResizeEnd,
        );
      case TideView.timelineMonth:
        return TideTimelineMonthView(
          controller: _controller,
          resourceHeaderWidth: widget.resourceHeaderWidth,
          onEventTap: widget.onEventTap,
          resourceHeaderBuilder: widget.resourceHeaderBuilder,
        );
      case TideView.multiWeek:
        return TideMultiWeekView(
          controller: _controller,
          onEventTap: widget.onEventTap,
          onDateTap: widget.onDateTap,
          eventBuilder: widget.eventBuilder,
        );
      case TideView.year:
        return TideYearView(
          controller: _controller,
          onDayTap: widget.onDateTap,
        );
      case TideView.resourceDay:
        return TideResourceDayView(
          controller: _controller,
          timeSlotInterval: widget.timeSlotInterval,
          startHour: widget.startHour,
          endHour: widget.endHour,
          eventOverlapStrategy: widget.eventOverlapStrategy,
          onEventTap: widget.onEventTap,
          onEmptySlotTap: widget.onEmptySlotTap,
          eventBuilder: widget.eventBuilder,
          allDayEventBuilder: widget.allDayEventBuilder,
          resourceHeaderBuilder: widget.resourceHeaderBuilder,
          allowDragAndDrop: widget.allowDragAndDrop,
          allowResize: widget.allowResize,
          dragSnapInterval: widget.dragSnapInterval,
          dragStartBehavior: widget.dragStartBehavior,
          onDragEnd: widget.onDragEnd,
          onResizeEnd: widget.onResizeEnd,
        );
      case TideView.resourceWeek:
        return TideResourceWeekView(
          controller: _controller,
          timeSlotInterval: widget.timeSlotInterval,
          startHour: widget.startHour,
          endHour: widget.endHour,
          eventOverlapStrategy: widget.eventOverlapStrategy,
          onEventTap: widget.onEventTap,
          onEmptySlotTap: widget.onEmptySlotTap,
          eventBuilder: widget.eventBuilder,
          allDayEventBuilder: widget.allDayEventBuilder,
          resourceHeaderBuilder: widget.resourceHeaderBuilder,
          allowDragAndDrop: widget.allowDragAndDrop,
          allowResize: widget.allowResize,
          dragSnapInterval: widget.dragSnapInterval,
          dragStartBehavior: widget.dragStartBehavior,
          onDragEnd: widget.onDragEnd,
          onResizeEnd: widget.onResizeEnd,
          firstDayOfWeek: widget.firstDayOfWeek ?? DateTime.monday,
        );
    }
  }
}

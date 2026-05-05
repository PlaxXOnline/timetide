import 'dart:math' show Random;

import 'package:flutter/widgets.dart';

import '../../core/models/drag_details.dart';
import '../../core/models/event.dart';
import '../../core/models/resource.dart';
import '../../core/models/template_slot.dart' show TideTimeOfDay;
import '../../interaction/drag_drop/external_drag.dart';
import '../../l10n/tide_localizations.dart';
import 'closed_day_predicate.dart' as cdp;
import 'shift_drag_mode.dart';
import 'shift_resource_palette.dart';
import 'shift_week_grid.dart';
import 'tide_shift_planner_controller.dart';

/// Signature for an optional builder that produces a custom shift card.
///
/// Receives the [BuildContext], the [TideEvent] backing the card, and the
/// [TideResource] the event is assigned to. When provided to a
/// [TideShiftPlanner], it replaces the default `ShiftCard` for every
/// renderable event whose resource resolves successfully.
typedef TideShiftCardBuilder = Widget Function(
  BuildContext context,
  TideEvent event,
  TideResource resource,
);

/// Signature for an asynchronous prompt that lets the consumer customize the
/// shift before it is committed.
///
/// Called from [TideShiftPlanner] when the configured [ShiftDragMode] is
/// [ShiftDragMode.promptForTime]. Return `null` to cancel; return a
/// [TideEvent] to fire `onShiftCreated`.
typedef TideShiftPromptBuilder = Future<TideEvent?> Function(
  BuildContext context,
  TideResource resource,
  DateTime droppedDate,
);

/// Signature for an asynchronous prompt that lets the consumer edit an
/// existing shift on tap.
///
/// Called from [TideShiftPlanner] when [TideShiftPlanner.shiftEditPromptBuilder]
/// is provided and a shift card is tapped. Return `null` to cancel; return a
/// [TideEvent] to fire `onShiftUpdated` with the edited event.
typedef TideShiftEditPromptBuilder = Future<TideEvent?> Function(
  BuildContext context,
  TideEvent event,
  TideResource resource,
);

/// High-level shift-planner companion widget that composes a sidebar
/// resource palette and a 7-column weekly grid into a drag-and-drop
/// scheduling surface.
///
/// The widget is purely presentational: it never persists state, never
/// mutates [events], and never owns the event collection. Instead, it
/// surfaces creation / tap / add / update / delete intents via the various
/// callbacks and lets the consumer commit them to its own datasource.
///
/// ## Composition
///
/// * Sidebar — [ShiftResourcePalette] wraps each resource in a
///   [TideDragSource]. The drag payload always carries
///   `metadata['resourceId']`.
/// * Body — [ShiftWeekGrid] renders seven [ShiftDayColumn]s for the active
///   week. Each open column is a [TideDragTarget] whose drop time defaults
///   to [defaultShiftStart].
/// * Drag glue — both halves share one [TideExternalDragScope] injected by
///   this widget.
///
/// ## Drag modes
///
/// * [ShiftDragMode.instantWithDefaults] *(default)* — On drop the planner
///   immediately constructs a [TideEvent] using
///   [defaultShiftStart] / [defaultShiftEnd] and fires [onShiftCreated].
/// * [ShiftDragMode.promptForTime] — On drop the planner invokes
///   [shiftPromptBuilder] (which **must** be supplied) and fires
///   [onShiftCreated] only when the future resolves to a non-null event.
///
/// ## Closed days
///
/// Drops onto closed days are silently dropped (no callback). A day is
/// considered closed when **any** of [closedDaysOfWeek], [closedDates], or
/// [isDayClosed] match — the same semantics implemented by
/// `closed_day_predicate.dart`.
///
/// ## Controller
///
/// When [controller] is supplied, [TideShiftPlannerController.currentWeekStart]
/// overrides [weekStart] and changes notify the planner to rebuild.
///
/// ## ADR-001 compliance
///
/// Imports only `package:flutter/widgets.dart`. `TideTimeOfDay` is the
/// material-free alternative to Flutter's `TimeOfDay`.
class TideShiftPlanner extends StatefulWidget {
  /// Creates a [TideShiftPlanner].
  const TideShiftPlanner({
    super.key,
    required this.resources,
    required this.events,
    required this.weekStart,
    this.controller,
    this.dragMode = ShiftDragMode.instantWithDefaults,
    this.defaultShiftStart = const TideTimeOfDay(hour: 9, minute: 0),
    this.defaultShiftEnd = const TideTimeOfDay(hour: 17, minute: 0),
    this.closedDaysOfWeek = const <int>{},
    this.closedDates = const <DateTime>{},
    this.isDayClosed,
    this.onShiftCreated,
    this.onShiftUpdated,
    this.onShiftDeleted,
    this.onShiftTap,
    this.onAddShiftPressed,
    this.shiftPromptBuilder,
    this.shiftEditPromptBuilder,
    this.cardBuilder,
    this.paletteHeaderBuilder,
    this.paletteFooterBuilder,
    this.paletteDragFeedbackBuilder,
    this.localeOverride,
  });

  /// Bookable resources rendered in the sidebar palette.
  final List<TideResource> resources;

  /// Events to render in the week grid. The list is read-only; updates are
  /// surfaced via callbacks.
  final List<TideEvent> events;

  /// Anchor date for the visible week. Normalised to the previous Monday
  /// when not already a Monday. Overridden by [controller] when provided.
  final DateTime weekStart;

  /// Optional view-state controller for week navigation and bulk-copy
  /// helpers.
  final TideShiftPlannerController? controller;

  /// Strategy for handling external drops onto a day column.
  final ShiftDragMode dragMode;

  /// Start-of-day default applied to events created via
  /// [ShiftDragMode.instantWithDefaults].
  final TideTimeOfDay defaultShiftStart;

  /// End-of-day default applied to events created via
  /// [ShiftDragMode.instantWithDefaults].
  final TideTimeOfDay defaultShiftEnd;

  /// Weekdays (`DateTime.monday` .. `DateTime.sunday`) treated as closed.
  /// OR-combined with [closedDates] and [isDayClosed].
  final Set<int> closedDaysOfWeek;

  /// Concrete calendar dates treated as closed. Time components are
  /// ignored. OR-combined with [closedDaysOfWeek] and [isDayClosed].
  final Set<DateTime> closedDates;

  /// Optional custom predicate; returning `true` marks the day closed.
  /// OR-combined with [closedDaysOfWeek] and [closedDates].
  final bool Function(DateTime date)? isDayClosed;

  /// Fired when a new shift is created (either via instant defaults or via
  /// a prompt). The consumer is responsible for adding the event to its
  /// datasource.
  final ValueChanged<TideEvent>? onShiftCreated;

  /// Invoked when [shiftEditPromptBuilder] resolves to a non-null event.
  ///
  /// The consumer is responsible for committing the updated event to its
  /// own datasource. Not triggered by drag, resize, or tap on its own —
  /// pair this with [shiftEditPromptBuilder] to wire an active edit flow.
  final ValueChanged<TideEvent>? onShiftUpdated;

  /// Reserved hook for shift deletions. The current implementation does
  /// not trigger this directly; it is exposed so future delete affordances
  /// can surface intents without changing the widget signature.
  final ValueChanged<TideEvent>? onShiftDeleted;

  /// Fired when an existing shift card is tapped.
  ///
  /// Called only when [shiftEditPromptBuilder] is `null`. For active edit
  /// flows, use [shiftEditPromptBuilder] together with [onShiftUpdated];
  /// the prompt builder takes precedence and [onShiftTap] is then skipped.
  final ValueChanged<TideEvent>? onShiftTap;

  /// Fired when the "+ Shift" button at the bottom of an open day column is
  /// pressed. The argument is the column's date.
  final ValueChanged<DateTime>? onAddShiftPressed;

  /// Required when [dragMode] is [ShiftDragMode.promptForTime]. Asynchronous
  /// builder that returns either a fully-formed [TideEvent] or `null` to
  /// cancel.
  final TideShiftPromptBuilder? shiftPromptBuilder;

  /// Optional builder invoked on shift-card tap to enable active edit flows.
  ///
  /// When provided, tapping a shift card invokes this builder with the
  /// tapped [TideEvent] and its resolved [TideResource]. If the returned
  /// [Future] resolves to a non-null [TideEvent], [onShiftUpdated] is
  /// called with that event. A `null` result is treated as a cancelled
  /// edit (no callback). When [shiftEditPromptBuilder] is `null`,
  /// [onShiftTap] is invoked instead (legacy notify-only path).
  ///
  /// Symmetric to [shiftPromptBuilder] for the create flow.
  final TideShiftEditPromptBuilder? shiftEditPromptBuilder;

  /// Optional builder to replace the default shift card. When provided,
  /// this is invoked for every event with the matching resource.
  final TideShiftCardBuilder? cardBuilder;

  /// Optional builder for a custom widget rendered above the resource rows
  /// in the sidebar palette. Forwarded to
  /// [ShiftResourcePalette.headerBuilder].
  ///
  /// Use this to inject branding, a section title, or a hint box on top of
  /// the palette without forking the widget.
  final WidgetBuilder? paletteHeaderBuilder;

  /// Optional builder for a custom widget rendered below the resource rows
  /// in the sidebar palette. Forwarded to
  /// [ShiftResourcePalette.footerBuilder].
  final WidgetBuilder? paletteFooterBuilder;

  /// Optional builder for the drag-feedback widget shown under the pointer
  /// while a resource row is being dragged. Forwarded to
  /// [ShiftResourcePalette.dragFeedbackBuilder].
  final Widget Function(TideExternalDragData data)? paletteDragFeedbackBuilder;

  /// Optional [TideLocalizations] override. Falls back to
  /// [TideLocalizations.en] when not provided. The widget never reads from
  /// the [Localizations] inherited widget — keeping the widget free of any
  /// dependency on Material's localizations machinery.
  final TideLocalizations? localeOverride;

  @override
  State<TideShiftPlanner> createState() => _TideShiftPlannerState();
}

class _TideShiftPlannerState extends State<TideShiftPlanner> {
  static final Random _random = Random();

  /// Cached resource lookup. Rebuilt only when [TideShiftPlanner.resources]
  /// changes (identity OR id-set difference) so descendant widgets receive
  /// a stable reference between rebuilds when the list is unchanged.
  late Map<String, TideResource> _resourceMap;

  @override
  void initState() {
    super.initState();
    _resourceMap = _buildResourceMap(widget.resources);
    widget.controller?.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(covariant TideShiftPlanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.resources, widget.resources)) {
      _resourceMap = _buildResourceMap(widget.resources);
    }

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChange);
      widget.controller?.addListener(_handleControllerChange);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    if (!mounted) return;
    setState(() {});
  }

  static Map<String, TideResource> _buildResourceMap(
    List<TideResource> resources,
  ) {
    return <String, TideResource>{
      for (final r in resources) r.id: r,
    };
  }

  /// Effective week anchor: controller wins over the widget property when
  /// the controller is supplied.
  DateTime get _effectiveWeekStart =>
      widget.controller?.currentWeekStart ?? widget.weekStart;

  /// Composes the closed-day predicate from all three sources.
  bool _isClosed(DateTime date) {
    return cdp.isDayClosed(
      date,
      daysOfWeek: widget.closedDaysOfWeek,
      dates: widget.closedDates,
      predicate: widget.isDayClosed,
    );
  }

  /// Combines a date with a [TideTimeOfDay] to produce a concrete
  /// [DateTime] in local time.
  DateTime _combine(DateTime date, TideTimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _generateId() {
    return 'shift-${DateTime.now().microsecondsSinceEpoch}-'
        '${_random.nextInt(99999)}';
  }

  /// Handles a drop produced by the grid's [TideDragTarget].
  ///
  /// 1. Resolves the resource from `metadata['resourceId']` — silently
  ///    skips when missing or unknown (defensive: keeps the planner from
  ///    crashing on malformed payloads).
  /// 2. Re-checks the closed-day predicate against the drop date — closed
  ///    days never produce events even when the source-side guard misses.
  /// 3. Dispatches according to [TideShiftPlanner.dragMode].
  Future<void> _handleDrop(TideExternalDragEndDetails details) async {
    final resourceId = details.data.metadata?['resourceId'] as String?;
    if (resourceId == null) return;

    final resource = _resourceMap[resourceId];
    if (resource == null) return;

    final dropDate = cdp.dayOnly(details.dropTime);
    if (_isClosed(dropDate)) return;

    switch (widget.dragMode) {
      case ShiftDragMode.instantWithDefaults:
        final event = TideEvent(
          id: _generateId(),
          subject: resource.displayName,
          startTime: _combine(dropDate, widget.defaultShiftStart),
          endTime: _combine(dropDate, widget.defaultShiftEnd),
          color: resource.color,
          resourceIds: <String>[resource.id],
        );
        widget.onShiftCreated?.call(event);
        break;

      case ShiftDragMode.promptForTime:
        assert(
          widget.shiftPromptBuilder != null,
          'shiftPromptBuilder is required when dragMode is '
          'ShiftDragMode.promptForTime',
        );
        final builder = widget.shiftPromptBuilder;
        if (builder == null) return;
        final result = await builder(context, resource, dropDate);
        if (result != null) {
          widget.onShiftCreated?.call(result);
        }
        break;
    }
  }

  /// Handles a tap on an existing shift card.
  ///
  /// When [TideShiftPlanner.shiftEditPromptBuilder] is provided, this
  /// invokes the builder, awaits the result, and forwards a non-null
  /// result to [TideShiftPlanner.onShiftUpdated]. A `null` result is
  /// treated as a cancelled edit. If the event's resource cannot be
  /// resolved (empty or unknown id) the tap is silently dropped — the
  /// builder requires a [TideResource] argument and we never invoke it
  /// with stale data.
  ///
  /// When the prompt builder is not provided, this falls back to the
  /// legacy notify-only path: [TideShiftPlanner.onShiftTap].
  Future<void> _handleCardTap(TideEvent event) async {
    final builder = widget.shiftEditPromptBuilder;
    if (builder != null) {
      final ids = event.resourceIds;
      if (ids == null || ids.isEmpty) return;
      final resource = _resourceMap[ids.first];
      if (resource == null) return; // silent skip: stale event
      final result = await builder(context, event, resource);
      if (!mounted) return;
      if (result != null) widget.onShiftUpdated?.call(result);
      return;
    }
    widget.onShiftTap?.call(event);
  }

  /// Default shift duration used by the sidebar's drag payload. Computed
  /// from [defaultShiftStart] / [defaultShiftEnd]; falls back to one hour
  /// when the configured range is non-positive (defensive).
  Duration get _defaultShiftDuration {
    final minutes =
        widget.defaultShiftEnd.totalMinutes - widget.defaultShiftStart.totalMinutes;
    return minutes > 0
        ? Duration(minutes: minutes)
        : const Duration(hours: 1);
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.localeOverride ?? TideLocalizations.en();

    return TideExternalDragScope(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Sidebar — mode-agnostic; the drag payload is identical regardless
          // of dragMode and the drop target decides what to do with it.
          ShiftResourcePalette(
            resources: widget.resources,
            dragMode: widget.dragMode,
            defaultShiftDuration: _defaultShiftDuration,
            headerBuilder: widget.paletteHeaderBuilder,
            footerBuilder: widget.paletteFooterBuilder,
            dragFeedbackBuilder: widget.paletteDragFeedbackBuilder,
          ),
          Expanded(
            child: ShiftWeekGrid(
              weekStart: _effectiveWeekStart,
              events: widget.events,
              resourceById: _resourceMap,
              closedDaysOfWeek: widget.closedDaysOfWeek,
              closedDates: widget.closedDates,
              isDayClosed: widget.isDayClosed,
              defaultDropHour: widget.defaultShiftStart.hour,
              onShiftTap: _handleCardTap,
              onAddShiftPressed: widget.onAddShiftPressed,
              onExternalDragEnd: _handleDrop,
              locale: loc,
              cardBuilder: widget.cardBuilder,
            ),
          ),
        ],
      ),
    );
  }
}

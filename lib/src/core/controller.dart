import 'dart:async';

import 'package:flutter/foundation.dart';

import 'datasource.dart';
import 'datasource_in_memory.dart';
import 'models/conflict.dart';
import 'models/date_time_range.dart';
import 'models/event.dart';
import 'models/event_changes.dart';
import 'models/view.dart';

/// An undo-able action recorded on the undo stack.
class _UndoEntry {
  const _UndoEntry({required this.undo, required this.redo});
  final VoidCallback undo;
  final VoidCallback redo;
}

/// Central controller for calendar navigation, selection, undo/redo, zoom,
/// resource management, and state persistence.
///
/// Extends [ChangeNotifier] and exposes fine-grained [ValueNotifier]s so that
/// widgets can rebuild only when the specific aspect they depend on changes.
///
/// ```dart
/// final controller = TideController(
///   datasource: myDatasource,
///   initialView: TideView.week,
///   initialDate: DateTime.now(),
/// );
/// ```
class TideController extends ChangeNotifier {
  /// Creates a [TideController].
  ///
  /// [datasource] supplies events, resources, and time regions. If null,
  /// an empty [TideInMemoryDatasource] is created internally.
  ///
  /// [initialView] defaults to [TideView.week].
  /// [initialDate] defaults to [DateTime.now].
  /// [numberOfWeeksInMultiWeek] is used for [TideView.multiWeek] navigation
  /// step size (default: 2).
  TideController({
    TideDatasource? datasource,
    TideView initialView = TideView.week,
    DateTime? initialDate,
    this.undoHistoryLimit = 20,
    this.minZoomLevel = 0.5,
    this.maxZoomLevel = 3.0,
    this.numberOfWeeksInMultiWeek = 2,
  })  : _ownsDatasource = datasource == null,
        _datasource = datasource ?? TideInMemoryDatasource(),
        displayDateNotifier =
            ValueNotifier<DateTime>(initialDate ?? DateTime.now()),
        currentViewNotifier = ValueNotifier<TideView>(initialView),
        selectedEventsNotifier = ValueNotifier<List<TideEvent>>(const []),
        zoomLevelNotifier = ValueNotifier<double>(1.0),
        visibleResourcesNotifier = ValueNotifier<Set<String>>({}) {
    _datasourceSubscription = _datasource.changes.listen(_onDatasourceChange);
  }

  // ─── Datasource ──────────────────────────────────────────

  final TideDatasource _datasource;
  final bool _ownsDatasource;
  late final StreamSubscription<TideDatasourceChange> _datasourceSubscription;

  /// The datasource backing this controller.
  TideDatasource get datasource => _datasource;

  // ─── Value Notifiers (for granular rebuilds) ─────────────

  /// Notifier for the currently focused display date.
  final ValueNotifier<DateTime> displayDateNotifier;

  /// Notifier for the current calendar view.
  final ValueNotifier<TideView> currentViewNotifier;

  /// Notifier for the list of currently selected events.
  final ValueNotifier<List<TideEvent>> selectedEventsNotifier;

  /// Notifier for the current zoom level.
  final ValueNotifier<double> zoomLevelNotifier;

  /// Notifier for the set of visible resource IDs.
  final ValueNotifier<Set<String>> visibleResourcesNotifier;

  // ─── Navigation ──────────────────────────────────────────

  /// The currently focused date that determines which day/week/month is
  /// visible.
  DateTime get displayDate => displayDateNotifier.value;
  set displayDate(DateTime date) {
    if (displayDateNotifier.value == date) return;
    displayDateNotifier.value = date;
    notifyListeners();
  }

  /// Navigates forward by a step determined by [currentView].
  void forward() {
    displayDate = _stepDate(1);
  }

  /// Navigates backward by a step determined by [currentView].
  void backward() {
    displayDate = _stepDate(-1);
  }

  /// Navigates to today's date.
  void today() {
    displayDate = DateTime.now();
  }

  /// Animates to [date].
  ///
  /// Currently equivalent to setting [displayDate] directly. Animation
  /// support will be implemented when the rendering layer is available.
  // TODO: Implement animation via ScrollController when rendering layer exists.
  void animateToDate(DateTime date) {
    displayDate = date;
  }

  /// The visible date range based on [currentView] and [displayDate].
  TideDateTimeRange get visibleDateRange {
    final d = displayDate;
    switch (currentView) {
      case TideView.day:
      case TideView.timelineDay:
        return TideDateTimeRange(
          start: DateTime(d.year, d.month, d.day),
          end: DateTime(d.year, d.month, d.day + 1),
        );
      case TideView.week:
      case TideView.timelineWeek:
        final weekStart = d.subtract(Duration(days: d.weekday - 1));
        return TideDateTimeRange(
          start: DateTime(weekStart.year, weekStart.month, weekStart.day),
          end: DateTime(
              weekStart.year, weekStart.month, weekStart.day + 7),
        );
      case TideView.workWeek:
      case TideView.timelineWorkWeek:
        final weekStart = d.subtract(Duration(days: d.weekday - 1));
        return TideDateTimeRange(
          start: DateTime(weekStart.year, weekStart.month, weekStart.day),
          end: DateTime(
              weekStart.year, weekStart.month, weekStart.day + 5),
        );
      case TideView.month:
      case TideView.timelineMonth:
        return TideDateTimeRange(
          start: DateTime(d.year, d.month),
          end: DateTime(d.year, d.month + 1),
        );
      case TideView.multiWeek:
        final weekStart = d.subtract(Duration(days: d.weekday - 1));
        return TideDateTimeRange(
          start: DateTime(weekStart.year, weekStart.month, weekStart.day),
          end: DateTime(weekStart.year, weekStart.month,
              weekStart.day + 7 * numberOfWeeksInMultiWeek),
        );
      case TideView.year:
        return TideDateTimeRange(
          start: DateTime(d.year),
          end: DateTime(d.year + 1),
        );
      case TideView.schedule:
        return TideDateTimeRange(
          start: DateTime(d.year, d.month, d.day),
          end: DateTime(d.year, d.month, d.day + 7),
        );
    }
  }

  DateTime _stepDate(int direction) {
    final d = displayDate;
    switch (currentView) {
      case TideView.day:
      case TideView.timelineDay:
        return DateTime(d.year, d.month, d.day + direction);
      case TideView.week:
      case TideView.timelineWeek:
        return DateTime(d.year, d.month, d.day + 7 * direction);
      case TideView.workWeek:
      case TideView.timelineWorkWeek:
        return DateTime(d.year, d.month, d.day + 5 * direction);
      case TideView.month:
      case TideView.timelineMonth:
        return DateTime(d.year, d.month + direction, d.day);
      case TideView.multiWeek:
        return DateTime(d.year, d.month,
            d.day + 7 * numberOfWeeksInMultiWeek * direction);
      case TideView.year:
        return DateTime(d.year + direction, d.month, d.day);
      case TideView.schedule:
        return DateTime(d.year, d.month, d.day + 7 * direction);
    }
  }

  // ─── View Management ─────────────────────────────────────

  /// The currently active calendar view.
  TideView get currentView => currentViewNotifier.value;
  set currentView(TideView view) {
    if (currentViewNotifier.value == view) return;
    currentViewNotifier.value = view;
    notifyListeners();
  }

  /// Number of weeks shown in [TideView.multiWeek].
  final int numberOfWeeksInMultiWeek;

  // ─── Selection ───────────────────────────────────────────

  /// The currently selected events.
  List<TideEvent> get selectedEvents => selectedEventsNotifier.value;

  /// Selects an event.
  ///
  /// When [additive] is true, the event is added to the current selection.
  /// Otherwise it replaces the entire selection.
  void selectEvent(TideEvent event, {bool additive = false}) {
    if (additive) {
      final current = List<TideEvent>.of(selectedEventsNotifier.value);
      if (current.contains(event)) {
        current.remove(event);
      } else {
        current.add(event);
      }
      selectedEventsNotifier.value = current;
    } else {
      selectedEventsNotifier.value = [event];
    }
    notifyListeners();
  }

  /// Deselects all events, selected date, and selected date range.
  void deselectAll() {
    final hadSelection = selectedEventsNotifier.value.isNotEmpty ||
        _selectedDate != null ||
        _selectedDateRange != null;
    selectedEventsNotifier.value = const [];
    _selectedDate = null;
    _selectedDateRange = null;
    if (hadSelection) notifyListeners();
  }

  DateTime? _selectedDate;

  /// The currently selected date (e.g., in month view).
  DateTime? get selectedDate => _selectedDate;

  /// Selects a single date.
  void selectDate(DateTime date) {
    _selectedDate = date;
    _selectedDateRange = null;
    notifyListeners();
  }

  TideDateTimeRange? _selectedDateRange;

  /// The currently selected date range.
  TideDateTimeRange? get selectedDateRange => _selectedDateRange;

  /// Selects a contiguous date range.
  void selectDateRange(DateTime start, DateTime end) {
    _selectedDateRange = TideDateTimeRange(start: start, end: end);
    _selectedDate = null;
    notifyListeners();
  }

  // ─── Undo / Redo ─────────────────────────────────────────

  final List<_UndoEntry> _undoStack = [];
  final List<_UndoEntry> _redoStack = [];

  /// Maximum number of undo operations to keep in history.
  int undoHistoryLimit;

  /// Whether there is an action to undo.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether there is an action to redo.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Undoes the last action.
  void undo() {
    if (!canUndo) return;
    final entry = _undoStack.removeLast();
    entry.undo();
    _redoStack.add(entry);
    notifyListeners();
  }

  /// Redoes the last undone action.
  void redo() {
    if (!canRedo) return;
    final entry = _redoStack.removeLast();
    entry.redo();
    _undoStack.add(entry);
    notifyListeners();
  }

  void _pushUndo(_UndoEntry entry) {
    _undoStack.add(entry);
    _redoStack.clear();
    // Trim if exceeding limit.
    while (_undoStack.length > undoHistoryLimit) {
      _undoStack.removeAt(0);
    }
  }

  // ─── Zoom ────────────────────────────────────────────────

  /// Minimum allowed zoom level.
  double minZoomLevel;

  /// Maximum allowed zoom level.
  double maxZoomLevel;

  /// The current zoom level for time-axis views.
  double get zoomLevel => zoomLevelNotifier.value;
  set zoomLevel(double level) {
    final clamped = level.clamp(minZoomLevel, maxZoomLevel);
    if (zoomLevelNotifier.value == clamped) return;
    zoomLevelNotifier.value = clamped;
    notifyListeners();
  }

  // ─── Scroll ──────────────────────────────────────────────

  /// Scrolls to the given time of day.
  ///
  /// Requires the rendering layer to be connected. Currently a no-op.
  // TODO: Implement when rendering layer (L4) is available.
  void scrollToTime(int hour, int minute, {bool animate = true}) {
    // No-op until rendering layer provides scroll controller access.
  }

  /// Scrolls to the given resource.
  ///
  /// Requires the rendering layer to be connected. Currently a no-op.
  // TODO: Implement when rendering layer (L4) is available.
  void scrollToResource(String resourceId, {bool animate = true}) {
    // No-op until rendering layer provides scroll controller access.
  }

  // ─── Resource Management ─────────────────────────────────

  /// The set of currently visible resource IDs.
  ///
  /// An empty set means all resources are visible.
  Set<String> get visibleResourceIds => visibleResourcesNotifier.value;

  /// Hides the resource with the given [resourceId].
  void hideResource(String resourceId) {
    final current = Set<String>.of(visibleResourcesNotifier.value);
    current.remove(resourceId);
    visibleResourcesNotifier.value = current;
    notifyListeners();
  }

  /// Shows the resource with the given [resourceId].
  void showResource(String resourceId) {
    final current = Set<String>.of(visibleResourcesNotifier.value);
    current.add(resourceId);
    visibleResourcesNotifier.value = current;
    notifyListeners();
  }

  List<String> _resourceOrder = [];

  /// Returns the current resource display order.
  List<String> get resourceOrder => List.unmodifiable(_resourceOrder);

  /// Reorders resources to match [orderedIds].
  void reorderResources(List<String> orderedIds) {
    _resourceOrder = List<String>.of(orderedIds);
    notifyListeners();
  }

  // ─── Event Management (delegates to datasource) ──────────

  /// Adds an event via the datasource and records it for undo.
  void addEvent(TideEvent event) {
    final ds = _datasource;
    if (ds is TideInMemoryDatasource) {
      ds.addEvent(event);
      _pushUndo(_UndoEntry(
        undo: () => ds.removeEvent(event.id),
        redo: () => ds.addEvent(event),
      ));
    }
  }

  /// Updates an event via the datasource and records it for undo.
  void updateEvent(TideEvent event) {
    final ds = _datasource;
    if (ds is TideInMemoryDatasource) {
      _captureEventForUndo(ds, event.id, () {
        ds.updateEvent(event);
      });
    }
  }

  /// Removes an event via the datasource and records it for undo.
  void removeEvent(String eventId) {
    final ds = _datasource;
    if (ds is TideInMemoryDatasource) {
      _captureEventForUndo(ds, eventId, () {
        ds.removeEvent(eventId);
      });
    }
  }

  /// Helper that looks up the event before a mutation so undo can restore it.
  void _captureEventForUndo(
    TideInMemoryDatasource ds,
    String eventId,
    VoidCallback mutation,
  ) {
    // Look up the current version of the event synchronously via getEvents
    // over a very wide range. Since InMemoryDatasource is synchronous under
    // the hood, we schedule the undo entry creation after retrieving it.
    ds.getEvents(DateTime(1970), DateTime(2100)).then((events) {
      final old = events.where((e) => e.id == eventId).firstOrNull;
      mutation();
      if (old != null) {
        _pushUndo(_UndoEntry(
          undo: () {
            // Re-add or restore the original event.
            ds.removeEvent(eventId);
            ds.addEvent(old);
          },
          redo: () => mutation(),
        ));
      }
    });
  }

  // ─── Recurrence Editing ──────────────────────────────────

  /// Edits a single occurrence of a recurring event.
  ///
  /// Depends on the RRULE engine (L2b) which is not yet implemented.
  // TODO: Implement when RRULE engine is available.
  void editOccurrence({
    required TideEvent seriesEvent,
    required DateTime occurrenceDate,
    required TideEventChanges changes,
  }) {
    throw UnimplementedError(
      'editOccurrence requires the RRULE engine (L2b).',
    );
  }

  /// Deletes a single occurrence of a recurring event.
  ///
  /// Depends on the RRULE engine (L2b) which is not yet implemented.
  // TODO: Implement when RRULE engine is available.
  void deleteOccurrence({
    required TideEvent seriesEvent,
    required DateTime occurrenceDate,
  }) {
    throw UnimplementedError(
      'deleteOccurrence requires the RRULE engine (L2b).',
    );
  }

  /// Edits this and all following occurrences of a recurring event.
  ///
  /// Depends on the RRULE engine (L2b) which is not yet implemented.
  // TODO: Implement when RRULE engine is available.
  void editThisAndFollowing({
    required TideEvent seriesEvent,
    required DateTime fromDate,
    required TideEventChanges changes,
  }) {
    throw UnimplementedError(
      'editThisAndFollowing requires the RRULE engine (L2b).',
    );
  }

  /// Edits all occurrences of a recurring event series.
  ///
  /// Depends on the RRULE engine (L2b) which is not yet implemented.
  // TODO: Implement when RRULE engine is available.
  void editSeries({
    required TideEvent seriesEvent,
    required TideEventChanges changes,
  }) {
    throw UnimplementedError(
      'editSeries requires the RRULE engine (L2b).',
    );
  }

  /// Checks for conflicts caused by a recurring event within [checkRange].
  ///
  /// Depends on the RRULE engine (L2b) which is not yet implemented.
  // TODO: Implement when RRULE engine is available.
  Future<List<TideConflict>> checkRecurrenceConflicts({
    required TideEvent event,
    required TideDateTimeRange checkRange,
  }) {
    throw UnimplementedError(
      'checkRecurrenceConflicts requires the RRULE engine (L2b).',
    );
  }

  // ─── State Persistence ───────────────────────────────────

  /// Serializes the current UI state to a JSON-compatible map.
  ///
  /// The returned map can be persisted (e.g. via SharedPreferences) and
  /// later restored with [restoreState].
  Map<String, dynamic> saveState() {
    return {
      'displayDate': displayDate.toIso8601String(),
      'currentView': currentView.name,
      'zoomLevel': zoomLevel,
      'visibleResourceIds': visibleResourceIds.toList(),
    };
  }

  /// Restores a previously saved UI state.
  ///
  /// Unknown keys are silently ignored, allowing forward-compatible state
  /// maps.
  void restoreState(Map<String, dynamic> state) {
    if (state.containsKey('displayDate')) {
      final parsed = DateTime.tryParse(state['displayDate'] as String);
      if (parsed != null) displayDate = parsed;
    }
    if (state.containsKey('currentView')) {
      final viewName = state['currentView'] as String;
      final view = TideView.values.where((v) => v.name == viewName).firstOrNull;
      if (view != null) currentView = view;
    }
    if (state.containsKey('zoomLevel')) {
      zoomLevel = (state['zoomLevel'] as num).toDouble();
    }
    if (state.containsKey('visibleResourceIds')) {
      final ids = (state['visibleResourceIds'] as List<dynamic>)
          .cast<String>()
          .toSet();
      visibleResourcesNotifier.value = ids;
    }
  }

  // ─── Datasource Change Handling ──────────────────────────

  void _onDatasourceChange(TideDatasourceChange change) {
    // Notify listeners so widgets can react to data changes.
    notifyListeners();
  }

  // ─── Dispose ─────────────────────────────────────────────

  bool _isDisposed = false;

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _datasourceSubscription.cancel();
    if (_ownsDatasource) {
      _datasource.dispose();
    }
    displayDateNotifier.dispose();
    currentViewNotifier.dispose();
    selectedEventsNotifier.dispose();
    zoomLevelNotifier.dispose();
    visibleResourcesNotifier.dispose();
    super.dispose();
  }
}

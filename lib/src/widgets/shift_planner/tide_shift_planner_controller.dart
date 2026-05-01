import 'dart:math' show Random;

import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../core/models/date_time_range.dart';
import '../../core/models/event.dart';
import 'closed_day_predicate.dart' show dayOnly;
import 'shift_drag_mode.dart' show ShiftCopyMode;

/// Transient view-state controller for the [TideShiftPlanner] companion
/// widget.
///
/// The controller exposes:
///
/// * Week-navigation state (the currently visible Monday).
/// * Pure helper methods that compute *new* shift events from existing ones
///   (bulk-copy / month-fill / range-fill).
///
/// Per the package vision the controller holds **no domain state**: it never
/// stores the events themselves and never persists. All bulk-copy methods are
/// pure functions — they accept the source events and return freshly created
/// [TideEvent]s. The caller is responsible for committing the result to the
/// underlying datasource.
///
/// All week starts are normalised to the Monday of the containing ISO week
/// at `00:00:00` local time.
class TideShiftPlannerController extends ChangeNotifier {
  /// Creates a [TideShiftPlannerController].
  ///
  /// * [initialWeekStart] — any date inside the desired starting week. The
  ///   value is normalised to the Monday of that week. When `null`, today's
  ///   week is used.
  /// * [idGenerator] — factory for IDs assigned to copied events. The default
  ///   produces unique IDs of the form
  ///   `'shift-<microsecondsSinceEpoch>-<random>'`.
  TideShiftPlannerController({
    DateTime? initialWeekStart,
    String Function()? idGenerator,
  })  : _idGenerator = idGenerator ?? _defaultIdGenerator,
        _currentWeekStart = _normalizeToMonday(
          initialWeekStart ?? DateTime.now(),
        );

  static final Random _random = Random();

  static String _defaultIdGenerator() =>
      'shift-${DateTime.now().microsecondsSinceEpoch}-'
      '${_random.nextInt(99999)}';

  /// Returns the Monday of the week containing [date] at `00:00:00` local
  /// time. The time component is dropped entirely.
  static DateTime _normalizeToMonday(DateTime date) {
    final delta = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - delta);
  }

  final String Function() _idGenerator;
  DateTime _currentWeekStart;

  /// The Monday of the currently visible week, normalised to `00:00:00`.
  DateTime get currentWeekStart => _currentWeekStart;

  /// Jumps to the week containing [weekStart].
  ///
  /// The supplied date is normalised to its containing Monday before being
  /// stored. Listeners are notified.
  void goToWeek(DateTime weekStart) {
    _currentWeekStart = _normalizeToMonday(weekStart);
    notifyListeners();
  }

  /// Moves the visible week one week into the past.
  void goToPreviousWeek() {
    _currentWeekStart = _normalizeToMonday(
      _currentWeekStart.subtract(const Duration(days: 7)),
    );
    notifyListeners();
  }

  /// Moves the visible week one week into the future.
  void goToNextWeek() {
    _currentWeekStart = _normalizeToMonday(
      _currentWeekStart.add(const Duration(days: 7)),
    );
    notifyListeners();
  }

  /// Notifies listeners without changing any state.
  ///
  /// Useful when external state (e.g. the consumer's event list) has changed
  /// and a redraw is required.
  void refresh() {
    notifyListeners();
  }

  /// Computes copies of [sourceEvents] that span [source], replicated across
  /// [target].
  ///
  /// This is a **pure** function: it never mutates [sourceEvents] and it
  /// never persists anything. The caller is responsible for adding the
  /// returned events to the underlying datasource.
  ///
  /// Behaviour:
  ///
  /// * Returns an empty list when [sourceEvents] is empty.
  /// * Throws [ArgumentError] when [target] is shorter than [source].
  /// * When [target] is exactly as long as [source] the events are mapped
  ///   1:1 with new IDs.
  /// * For [ShiftCopyMode.replicateWeekly] the source is replicated as full
  ///   weeks until [target] is filled. The number of replications is
  ///   `ceil(target.duration / 7 days)`.
  /// * When [skipClosedDays] is `true` and [isDayClosed] is supplied, copied
  ///   events whose start day is closed are omitted.
  /// * Each generated event receives a fresh ID via the configured
  ///   `idGenerator`.
  /// * No conflict checking is performed.
  List<TideEvent> generateCopiedShifts({
    required TideDateTimeRange source,
    required TideDateTimeRange target,
    required List<TideEvent> sourceEvents,
    ShiftCopyMode mode = ShiftCopyMode.replicateWeekly,
    bool skipClosedDays = true,
    bool Function(DateTime)? isDayClosed,
  }) {
    if (target.duration < source.duration) {
      throw ArgumentError(
        'target range must be at least as long as source range '
        '(target.duration=${target.duration}, '
        'source.duration=${source.duration})',
      );
    }
    if (sourceEvents.isEmpty) {
      return const <TideEvent>[];
    }

    // ShiftCopyMode currently has a single value (replicateWeekly). We
    // reference it so the parameter is meaningful and to make future modes
    // an additive change.
    assert(mode == ShiftCopyMode.replicateWeekly);

    final repetitions = _replicationCount(source, target);
    final baseShift = target.start.difference(source.start);
    final result = <TideEvent>[];

    for (var i = 0; i < repetitions; i++) {
      final shift = baseShift + Duration(days: 7 * i);
      for (final src in sourceEvents) {
        final newStart = src.startTime.add(shift);
        final newEnd = src.endTime.add(shift);

        if (skipClosedDays &&
            isDayClosed != null &&
            isDayClosed(dayOnly(newStart))) {
          continue;
        }

        result.add(
          src.copyWith(
            id: _idGenerator(),
            startTime: newStart,
            endTime: newEnd,
          ),
        );
      }
    }

    return result;
  }

  /// Builds a [TideDateTimeRange] that spans exactly one week starting at
  /// [weekStart] (Mon 00:00 → Sun 23:59:59.999999).
  static TideDateTimeRange _weekRange(DateTime weekStart) {
    return TideDateTimeRange(
      start: weekStart,
      end: weekStart
          .add(const Duration(days: 7))
          .subtract(const Duration(microseconds: 1)),
    );
  }

  /// Number of times the source week must be replicated to fill [target].
  ///
  /// `ceil(target.duration / 7 days)` — guaranteed to be at least 1 because
  /// the caller has already verified `target.duration >= source.duration`.
  int _replicationCount(TideDateTimeRange source, TideDateTimeRange target) {
    const oneWeek = Duration(days: 7);
    final targetDays = target.duration.inMicroseconds;
    final weekUs = oneWeek.inMicroseconds;
    final count = (targetDays + weekUs - 1) ~/ weekUs;
    return count < 1 ? 1 : count;
  }

  /// Convenience wrapper that copies the previous calendar week into the
  /// current one.
  ///
  /// The source range is `[currentWeekStart - 7d, currentWeekStart)`; the
  /// target range is the current week. [previousWeekEvents] should contain
  /// the events of the source week as known to the caller.
  List<TideEvent> copyPreviousWeek({
    required List<TideEvent> previousWeekEvents,
    bool skipClosedDays = true,
    bool Function(DateTime)? isDayClosed,
  }) {
    final previousMon =
        _currentWeekStart.subtract(const Duration(days: 7));
    return generateCopiedShifts(
      source: _weekRange(previousMon),
      target: _weekRange(_currentWeekStart),
      sourceEvents: previousWeekEvents,
      skipClosedDays: skipClosedDays,
      isDayClosed: isDayClosed,
    );
  }

  /// Replicates the source week onto every Monday-aligned week that
  /// overlaps the calendar month containing [monthStart].
  ///
  /// The target range starts at the first Monday on or after [monthStart]
  /// and ends at the last Sunday on or before the last day of that month.
  List<TideEvent> generateMonthFromWeek({
    required DateTime sourceWeekStart,
    required DateTime monthStart,
    required List<TideEvent> sourceEvents,
    bool skipClosedDays = true,
    bool Function(DateTime)? isDayClosed,
  }) {
    final srcMon = _normalizeToMonday(sourceWeekStart);
    final monthFirst = DateTime(monthStart.year, monthStart.month, 1);
    final nextMonthFirst = DateTime(monthStart.year, monthStart.month + 1, 1);
    final monthLast =
        nextMonthFirst.subtract(const Duration(days: 1)); // last day, 00:00

    // First Monday on or after monthFirst.
    final firstMonOffset =
        (DateTime.monday - monthFirst.weekday + 7) % 7;
    final firstMon = DateTime(
      monthFirst.year,
      monthFirst.month,
      monthFirst.day + firstMonOffset,
    );

    // Count complete weeks (Mon..Sun) that fit within the month.
    var weekCount = 0;
    var cursor = firstMon;
    while (true) {
      final sunday = cursor.add(const Duration(days: 6));
      if (sunday.isAfter(monthLast)) break;
      weekCount++;
      cursor = cursor.add(const Duration(days: 7));
    }
    if (weekCount == 0) {
      return const <TideEvent>[];
    }

    final target = TideDateTimeRange(
      start: firstMon,
      end: firstMon
          .add(Duration(days: 7 * weekCount))
          .subtract(const Duration(microseconds: 1)),
    );

    return generateCopiedShifts(
      source: _weekRange(srcMon),
      target: target,
      sourceEvents: sourceEvents,
      skipClosedDays: skipClosedDays,
      isDayClosed: isDayClosed,
    );
  }

  /// Replicates the source week [weekCount] times starting **one week
  /// after** [sourceWeekStart].
  ///
  /// Returns an empty list when [weekCount] is zero or negative.
  List<TideEvent> generateRangeFromWeek({
    required DateTime sourceWeekStart,
    required List<TideEvent> sourceEvents,
    required int weekCount,
    bool skipClosedDays = true,
    bool Function(DateTime)? isDayClosed,
  }) {
    if (weekCount <= 0) return const <TideEvent>[];
    final srcMon = _normalizeToMonday(sourceWeekStart);
    final targetStart = srcMon.add(const Duration(days: 7));
    final target = TideDateTimeRange(
      start: targetStart,
      end: targetStart
          .add(Duration(days: 7 * weekCount))
          .subtract(const Duration(microseconds: 1)),
    );
    return generateCopiedShifts(
      source: _weekRange(srcMon),
      target: target,
      sourceEvents: sourceEvents,
      skipClosedDays: skipClosedDays,
      isDayClosed: isDayClosed,
    );
  }
}

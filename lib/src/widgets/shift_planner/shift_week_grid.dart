import 'package:flutter/widgets.dart';

import '../../core/models/event.dart';
import '../../core/models/resource.dart';
import '../../interaction/drag_drop/external_drag.dart';
import '../../l10n/tide_localizations.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';
import 'closed_day_predicate.dart' as cdp;
import 'shift_day_column.dart';
import 'tide_shift_planner.dart' show TideShiftCardBuilder;

/// Internal widget that lays out a Monday→Sunday week grid of seven
/// [ShiftDayColumn]s with a header row above.
///
/// ## Contract
///
/// * The first column is **always** the Monday of the week containing
///   [weekStart]. If [weekStart] falls on any other weekday, it is
///   normalized to the previous Monday (see [_normalizedWeekStart]).
/// * Events are routed to a column by **start day only**: an event whose
///   `startTime` is on the column's date is included. Multi-day events that
///   span a midnight boundary therefore appear only in their start-day
///   column — they are *not* split across columns.
/// * "Closed" status for a day is the OR of three sources: [closedDaysOfWeek],
///   [closedDates], and the optional [isDayClosed] predicate. Delegated to
///   [cdp.isDayClosed] from `closed_day_predicate.dart`.
/// * The [defaultDropHour] (default 9) is combined with each column's date
///   to form the [ShiftDayColumn.dropTime] passed to descendants.
/// * Callbacks ([onShiftTap], [onAddShiftPressed], [onExternalDragEnd]) are
///   forwarded to every column unchanged.
///
/// This widget is internal to the shift planner; the class name therefore
/// omits the public `Tide` prefix per project convention.
class ShiftWeekGrid extends StatelessWidget {
  /// Creates a [ShiftWeekGrid].
  const ShiftWeekGrid({
    super.key,
    required this.weekStart,
    required this.events,
    required this.resourceById,
    this.closedDaysOfWeek = const <int>{},
    this.closedDates = const <DateTime>{},
    this.isDayClosed,
    this.defaultDropHour = 9,
    this.onShiftTap,
    this.onAddShiftPressed,
    this.onExternalDragEnd,
    this.locale,
    this.cardBuilder,
  });

  /// Anchor date for the week. Normalized to the previous Monday if it does
  /// not already fall on a Monday.
  final DateTime weekStart;

  /// All events the grid may render. Each event is routed to exactly one
  /// column based on the calendar day of its [TideEvent.startTime].
  final List<TideEvent> events;

  /// Lookup map for the resource referenced by each event's
  /// `resourceIds.first`. Forwarded verbatim to descendant columns.
  final Map<String, TideResource> resourceById;

  /// Weekdays (`DateTime.monday` .. `DateTime.sunday`) that should always be
  /// treated as closed. OR-combined with [closedDates] and [isDayClosed].
  final Set<int> closedDaysOfWeek;

  /// Concrete calendar dates that should be treated as closed. Time
  /// components are ignored. OR-combined with [closedDaysOfWeek] and
  /// [isDayClosed].
  final Set<DateTime> closedDates;

  /// Optional custom predicate. Returning `true` marks the day closed.
  /// OR-combined with [closedDaysOfWeek] and [closedDates].
  final bool Function(DateTime date)? isDayClosed;

  /// Hour of day used to build each column's drop time. Defaults to 9.
  final int defaultDropHour;

  /// Forwarded to every column's [ShiftDayColumn.onShiftTap].
  final ValueChanged<TideEvent>? onShiftTap;

  /// Forwarded to every column's [ShiftDayColumn.onAddShiftPressed].
  final ValueChanged<DateTime>? onAddShiftPressed;

  /// Forwarded to every column's [ShiftDayColumn.onExternalDragEnd].
  final TideExternalDragEndCallback? onExternalDragEnd;

  /// Optional [TideLocalizations] override. Falls back to
  /// [TideLocalizations.en] when not provided.
  final TideLocalizations? locale;

  /// Optional builder forwarded to each [ShiftDayColumn]. When non-null it
  /// replaces the default [ShiftCard] for every event the column renders.
  final TideShiftCardBuilder? cardBuilder;

  /// Returns the Monday of the week containing [weekStart].
  ///
  /// `weekday` is 1..7 with Monday=1; we subtract `weekday - Monday` days.
  DateTime get _normalizedWeekStart {
    final delta = weekStart.weekday - DateTime.monday;
    return DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day - delta,
    );
  }

  /// Returns the subset of [events] whose start day matches [date].
  List<TideEvent> _eventsForDate(DateTime date) {
    return events
        .where((e) =>
            e.startTime.year == date.year &&
            e.startTime.month == date.month &&
            e.startTime.day == date.day)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final l10n = locale ?? TideLocalizations.en();
    final monday = _normalizedWeekStart;
    final dates = List<DateTime>.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Header row — keyed for tests and a11y semantics.
        Container(
          key: const ValueKey<String>('shift-week-grid-header'),
          child: Row(
            children: dates
                .map((d) => Expanded(child: _headerCell(d, theme, l10n)))
                .toList(growable: false),
          ),
        ),
        // Body row — Expanded so columns share the available height when
        // hosted inside a bounded parent.
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: dates.map((d) {
              final closed = cdp.isDayClosed(
                d,
                daysOfWeek: closedDaysOfWeek,
                dates: closedDates,
                predicate: isDayClosed,
              );
              return Expanded(
                child: ShiftDayColumn(
                  date: d,
                  closed: closed,
                  events: _eventsForDate(d),
                  resourceById: resourceById,
                  dropTime:
                      DateTime(d.year, d.month, d.day, defaultDropHour, 0),
                  onShiftTap: onShiftTap,
                  onAddShiftPressed: onAddShiftPressed,
                  onExternalDragEnd: onExternalDragEnd,
                  locale: l10n,
                  cardBuilder: cardBuilder,
                ),
              );
            }).toList(growable: false),
          ),
        ),
      ],
    );
  }

  Widget _headerCell(
    DateTime date,
    TideThemeData theme,
    TideLocalizations l10n,
  ) {
    final weekdayLabel = l10n.weekdayAbbr(date.weekday);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(weekdayLabel, style: theme.shiftPlannerColumnHeaderTextStyle),
          const SizedBox(height: 2),
          Text('${date.day}', style: theme.shiftPlannerColumnDateStyle),
        ],
      ),
    );
  }
}

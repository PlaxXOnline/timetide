import 'package:flutter/widgets.dart';

import '../../l10n/tide_localizations.dart';
import '../../theme/tide_theme.dart';

/// Returns the ISO-8601 week number for [date].
///
/// Per ISO 8601 / RFC 5445, week 1 is the week containing the first Thursday
/// of the year. Equivalently, the week is owned by the calendar year of the
/// Thursday of that week. This means dates near year boundaries can fall into
/// week 1 of the following year (e.g. 2025-12-29) or week 52/53 of the
/// previous year (e.g. 2021-01-03 → week 53 of 2020).
///
/// The algorithm:
///   1. Shift [date] to the Thursday of the same ISO week
///      (`date + (4 - weekday)` days, with `weekday` 1=Mon..7=Sun).
///   2. Locate January 4th of that Thursday's year — January 4th is, by
///      definition, always part of ISO week 1.
///   3. Shift January 4th to its own Thursday, giving a stable anchor for
///      week 1.
///   4. The week number is `((thursday - week1Thursday) / 7).floor() + 1`.
///
/// The implementation is independent of leap years and the day-of-year
/// computation, which makes it robust across all year boundaries.
int isoWeekNumber(DateTime date) {
  // Use the date portion only — time-of-day is irrelevant for week numbers.
  final day = DateTime(date.year, date.month, date.day);
  // Step 1: Thursday of this ISO week.
  final thursday = day.add(Duration(days: 4 - day.weekday));
  // Step 2 & 3: Thursday of ISO week 1 (anchored on January 4th).
  final jan4 = DateTime(thursday.year, 1, 4);
  final week1Thursday = jan4.add(Duration(days: 4 - jan4.weekday));
  // Step 4: number of full weeks between the two Thursdays, plus one.
  final diffDays = thursday.difference(week1Thursday).inDays;
  return (diffDays / 7).floor() + 1;
}

/// A small badge that renders the ISO-8601 calendar-week label for a given
/// week, e.g. `Week 13` (English) or `KW 13` (German).
///
/// Visual reference: shift-planner column header. The badge is intentionally
/// just a [Text] node so it composes cleanly inside any header layout.
///
/// Localization follows the same pattern as the other companion widgets in
/// this package: a [TideLocalizations] instance can be injected via [locale],
/// otherwise the widget falls back to [TideLocalizations.en].
class TideKwBadge extends StatelessWidget {
  /// The Monday (or any date) within the week to label. Only the ISO week
  /// number derived from this date is displayed.
  final DateTime weekStart;

  /// Optional text style override. When `null`, the badge uses
  /// [TideThemeData.shiftPlannerColumnHeaderTextStyle] from the nearest
  /// [TideTheme] ancestor (or the default theme when no ancestor exists).
  final TextStyle? style;

  /// Optional explicit localization. When `null`, [TideLocalizations.en] is
  /// used.
  final TideLocalizations? locale;

  /// Creates a [TideKwBadge].
  const TideKwBadge({
    super.key,
    required this.weekStart,
    this.style,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final l10n = locale ?? TideLocalizations.en();
    final week = isoWeekNumber(weekStart);
    return Text(
      l10n.weekNumberLabel(week),
      style: style ?? theme.shiftPlannerColumnHeaderTextStyle,
    );
  }
}

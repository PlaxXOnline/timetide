import 'package:flutter/widgets.dart';

import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';

/// Day-column header for the week view showing weekday name and date.
///
/// Highlights today using [TideThemeData.todayHighlightColor].
class TideWeekHeader extends StatelessWidget {
  /// Creates a [TideWeekHeader].
  const TideWeekHeader({
    super.key,
    required this.dates,
    this.timeAxisWidth = 56.0,
  });

  /// The dates to display as column headers.
  final List<DateTime> dates;

  /// Width of the time-axis column on the left (for alignment).
  final double timeAxisWidth;

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Spacer matching the time axis width
          SizedBox(width: timeAxisWidth),
          // Day headers
          for (final date in dates)
            Expanded(
              child: _buildDayHeader(context, theme, date, today),
            ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(
    BuildContext context,
    TideThemeData theme,
    DateTime date,
    DateTime today,
  ) {
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final weekdayName = _shortWeekday(date.weekday);

    return Semantics(
      label: '$weekdayName ${date.day}, ${isToday ? "today" : ""}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              weekdayName,
              style: theme.dayHeaderTextStyle.copyWith(
                color: isToday ? theme.todayHighlightColor : null,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: isToday
                  ? BoxDecoration(
                      color: theme.todayHighlightColor,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Text(
                '${date.day}',
                style: theme.dayHeaderTextStyle.copyWith(
                  color: isToday
                      ? const Color(0xFFFFFFFF)
                      : theme.dayHeaderTextStyle.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _shortWeekday(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }
}

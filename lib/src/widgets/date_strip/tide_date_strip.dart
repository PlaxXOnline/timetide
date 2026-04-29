import 'package:flutter/widgets.dart';

import '../../l10n/tide_localizations.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';

/// A horizontal scrollable date picker strip for booking flows.
///
/// Displays [dayCount] days starting from [startDate], allowing the user to
/// select a date by tapping. Highlights the selected date, optionally shows a
/// today indicator dot, and respects disabled dates.
class TideDateStrip extends StatefulWidget {
  /// Creates a [TideDateStrip].
  const TideDateStrip({
    required this.selectedDate,
    required this.onDateSelected,
    this.startDate,
    this.dayCount = 14,
    this.disabledDates,
    this.showTodayIndicator = true,
    this.locale,
    super.key,
  });

  /// The currently selected date.
  final DateTime selectedDate;

  /// Called when the user taps a non-disabled date.
  final ValueChanged<DateTime> onDateSelected;

  /// First date shown in the strip. Defaults to [DateTime.now].
  final DateTime? startDate;

  /// Number of days displayed in the strip.
  final int dayCount;

  /// Dates that cannot be selected (tapping them is a no-op).
  final List<DateTime>? disabledDates;

  /// Whether to show a small dot below today's date circle.
  final bool showTodayIndicator;

  /// Optional localization for weekday abbreviations.
  ///
  /// When omitted, English abbreviations (Mon, Tue, …) are used.
  final TideLocalizations? locale;

  @override
  State<TideDateStrip> createState() => _TideDateStripState();
}

class _TideDateStripState extends State<TideDateStrip> {
  late final ScrollController _scrollController;

  static const double _itemWidth = 56.0;
  static const double _itemMargin = 4.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime get _start =>
      widget.startDate ?? _stripTime(DateTime.now());

  /// Removes time component for day-level comparison.
  DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isDisabled(DateTime date) {
    final disabled = widget.disabledDates;
    if (disabled == null) return false;
    for (final d in disabled) {
      if (_isSameDay(d, date)) return true;
    }
    return false;
  }

  void _scrollToSelected() {
    final start = _stripTime(_start);
    final selected = _stripTime(widget.selectedDate);
    final diff = selected.difference(start).inDays;
    if (diff < 0 || diff >= widget.dayCount) return;

    final offset = diff * (_itemWidth + _itemMargin * 2);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _weekdayLabel(int weekday) {
    final l = widget.locale;
    if (l != null) return l.weekdayAbbr(weekday);
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[(weekday - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final today = _stripTime(DateTime.now());

    Widget itemFor(int index) {
      final date = _stripTime(_start).add(Duration(days: index));
      final isSelected = _isSameDay(date, widget.selectedDate);
      final isToday = _isSameDay(date, today);
      final isDisabled = _isDisabled(date);

      return _DateStripItem(
        date: date,
        weekdayLabel: _weekdayLabel(date.weekday),
        isSelected: isSelected,
        isToday: isToday,
        isDisabled: isDisabled,
        showTodayIndicator: widget.showTodayIndicator,
        onTap: isDisabled ? null : () => widget.onDateSelected(date),
        theme: theme,
      );
    }

    return SizedBox(
      height: theme.dateStripHeight,
      child: Semantics(
        label: 'Date picker strip',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth =
                widget.dayCount * (_itemWidth + _itemMargin * 2);
            final fitsWithoutScroll = totalWidth <= constraints.maxWidth;

            if (fitsWithoutScroll) {
              // Stretch the row to full width and center each item inside
              // its evenly-sized cell — no dead space on the right.
              return Row(
                children: [
                  for (var i = 0; i < widget.dayCount; i++)
                    Expanded(child: Center(child: itemFor(i))),
                ],
              );
            }

            return ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.dayCount,
              itemBuilder: (context, index) => itemFor(index),
            );
          },
        ),
      ),
    );
  }
}

class _DateStripItem extends StatelessWidget {
  const _DateStripItem({
    required this.date,
    required this.weekdayLabel,
    required this.isSelected,
    required this.isToday,
    required this.isDisabled,
    required this.showTodayIndicator,
    required this.onTap,
    required this.theme,
  });

  final DateTime date;
  final String weekdayLabel;
  final bool isSelected;
  final bool isToday;
  final bool isDisabled;
  final bool showTodayIndicator;
  final VoidCallback? onTap;
  final TideThemeData theme;

  static const double _circleSize = 36.0;
  static const double _dotSize = 5.0;

  Color get _circleColor {
    if (isSelected) return theme.dateStripSelectedColor;
    return const Color(0x00000000); // transparent
  }

  Color get _textColor {
    if (isDisabled) return theme.dateStripDisabledColor;
    if (isSelected) return const Color(0xFFFFFFFF);
    return theme.dateStripTextStyle.color ?? const Color(0xFF212121);
  }

  Color get _weekdayColor {
    if (isDisabled) return theme.dateStripDisabledColor;
    return theme.dateStripWeekdayTextStyle.color ?? const Color(0xFF757575);
  }

  @override
  Widget build(BuildContext context) {
    final semanticLabel = '$weekdayLabel ${date.day}'
        '${isSelected ? ', selected' : ''}'
        '${showTodayIndicator && isToday ? ', today' : ''}'
        '${isDisabled ? ', disabled' : ''}';

    return Semantics(
      label: semanticLabel,
      button: !isDisabled,
      selected: isSelected,
      enabled: !isDisabled,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Weekday abbreviation
              Text(
                weekdayLabel,
                style: theme.dateStripWeekdayTextStyle.copyWith(
                  color: _weekdayColor,
                ),
              ),
              const SizedBox(height: 4),
              // Day circle
              Container(
                width: _circleSize,
                height: _circleSize,
                decoration: BoxDecoration(
                  color: _circleColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: theme.dateStripTextStyle.copyWith(color: _textColor),
                ),
              ),
              // Today indicator dot
              const SizedBox(height: 3),
              if (showTodayIndicator && isToday)
                Container(
                  width: _dotSize,
                  height: _dotSize,
                  decoration: BoxDecoration(
                    color: theme.dateStripTodayIndicatorColor,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: _dotSize),
            ],
          ),
        ),
      ),
    );
  }
}

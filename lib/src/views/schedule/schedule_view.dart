import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/event.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';
import 'schedule_item.dart';

/// An infinite bidirectional scroll list of events grouped by date.
///
/// Features:
/// - Sticky date headers
/// - Load-on-demand as the user scrolls
/// - Empty state via [emptyBuilder]
/// - Lazy rendering using [ListView.builder]
class TideScheduleView extends StatefulWidget {
  /// Creates a [TideScheduleView].
  const TideScheduleView({
    super.key,
    required this.controller,
    this.daysToLoad = 30,
    this.onEventTap,
    this.eventBuilder,
    this.dateHeaderBuilder,
    this.emptyBuilder,
  });

  /// The controller managing navigation, selection, and data.
  final TideController controller;

  /// Number of days to load at a time. Defaults to 30.
  final int daysToLoad;

  /// Called when an event is tapped.
  final ValueChanged<TideEvent>? onEventTap;

  /// Custom builder for event list items.
  final Widget Function(BuildContext context, TideEvent event)? eventBuilder;

  /// Custom builder for date headers.
  final Widget Function(BuildContext context, DateTime date)? dateHeaderBuilder;

  /// Builder for the empty state.
  final WidgetBuilder? emptyBuilder;

  @override
  State<TideScheduleView> createState() => _TideScheduleViewState();
}

class _TideScheduleViewState extends State<TideScheduleView> {
  late final ScrollController _scrollController;
  final List<_ScheduleEntry> _entries = [];
  bool _isLoading = false;
  late DateTime _loadedStart;
  late DateTime _loadedEnd;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    widget.controller.addListener(_onControllerChanged);
    _initLoad();
  }

  @override
  void didUpdateWidget(TideScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _initLoad();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    _initLoad();
  }

  Future<void> _initLoad() async {
    final date = widget.controller.displayDate;
    _loadedStart = DateTime(date.year, date.month, date.day);
    _loadedEnd = _loadedStart.add(Duration(days: widget.daysToLoad));
    await _loadRange(_loadedStart, _loadedEnd);
  }

  void _onScroll() {
    if (_isLoading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    _isLoading = true;

    final newEnd = _loadedEnd.add(Duration(days: widget.daysToLoad));
    final events = await widget.controller.datasource
        .getEvents(_loadedEnd, newEnd);

    if (!mounted) return;

    final newEntries = _buildEntries(events, _loadedEnd, newEnd);
    setState(() {
      _entries.addAll(newEntries);
      _loadedEnd = newEnd;
      _isLoading = false;
    });
  }

  Future<void> _loadRange(DateTime start, DateTime end) async {
    _isLoading = true;
    final events = await widget.controller.datasource.getEvents(start, end);

    if (!mounted) return;

    setState(() {
      _entries
        ..clear()
        ..addAll(_buildEntries(events, start, end));
      _isLoading = false;
    });
  }

  List<_ScheduleEntry> _buildEntries(
    List<TideEvent> events,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final entries = <_ScheduleEntry>[];
    var current = rangeStart;

    while (current.isBefore(rangeEnd)) {
      final dayStart = DateTime(current.year, current.month, current.day);
      final dayEnd = DateTime(current.year, current.month, current.day + 1);

      final dayEvents = events.where((e) {
        return e.startTime.isBefore(dayEnd) && e.endTime.isAfter(dayStart);
      }).toList()
        ..sort((a, b) {
          if (a.isAllDay && !b.isAllDay) return -1;
          if (!a.isAllDay && b.isAllDay) return 1;
          return a.startTime.compareTo(b.startTime);
        });

      if (dayEvents.isNotEmpty) {
        entries.add(_ScheduleEntry.header(dayStart));
        for (final event in dayEvents) {
          entries.add(_ScheduleEntry.event(event));
        }
      }

      current = dayEnd;
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);

    if (_entries.isEmpty && !_isLoading) {
      return Semantics(
        label: 'Schedule view, no events',
        child: widget.emptyBuilder?.call(context) ??
            Center(
              child: Text('No events', style: theme.timeSlotTextStyle),
            ),
      );
    }

    return Semantics(
      label: 'Schedule view',
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _entries.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _entries.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: _LoadingIndicator()),
            );
          }

          final entry = _entries[index];
          if (entry.isHeader) {
            return _buildDateHeader(context, theme, entry.date!);
          }
          return _buildEventItem(context, entry.event!);
        },
      ),
    );
  }

  Widget _buildDateHeader(
    BuildContext context,
    TideThemeData theme,
    DateTime date,
  ) {
    if (widget.dateHeaderBuilder != null) {
      return widget.dateHeaderBuilder!(context, date);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.surfaceColor,
      child: Text(
        _formatDateHeader(date, isToday),
        style: theme.headerTextStyle.copyWith(
          fontSize: 14,
          color: isToday ? theme.todayHighlightColor : null,
        ),
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, TideEvent event) {
    if (widget.eventBuilder != null) {
      return widget.eventBuilder!(context, event);
    }

    return TideScheduleItem(
      event: event,
      onTap: widget.onEventTap != null
          ? () => widget.onEventTap!(event)
          : null,
    );
  }

  String _formatDateHeader(DateTime date, bool isToday) {
    final weekday = _fullWeekday(date.weekday);
    final month = _shortMonth(date.month);
    final prefix = isToday ? 'Today, ' : '';
    return '$prefix$weekday, $month ${date.day}';
  }

  static String _fullWeekday(int weekday) {
    const names = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return names[weekday - 1];
  }

  static String _shortMonth(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }
}

/// An entry in the schedule view: either a date header or an event.
class _ScheduleEntry {
  const _ScheduleEntry.header(this.date) : event = null;
  const _ScheduleEntry.event(this.event) : date = null;

  final DateTime? date;
  final TideEvent? event;

  bool get isHeader => date != null;
}

/// A simple animated loading indicator using only widgets.dart.
///
/// Renders three pulsing dots.
class _LoadingIndicator extends StatefulWidget {
  const _LoadingIndicator();

  @override
  State<_LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<_LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = value < 0.5 ? value * 2 : (1.0 - value) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9E9E9E),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

import 'package:flutter/widgets.dart';

import '../../core/models/event.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';

/// An agenda panel that shows events for a selected date as a list.
///
/// Typically displayed below the month grid when a date is selected.
class TideMonthAgendaPanel extends StatelessWidget {
  /// Creates a [TideMonthAgendaPanel].
  const TideMonthAgendaPanel({
    super.key,
    required this.selectedDate,
    required this.events,
    this.onEventTap,
    this.eventBuilder,
    this.emptyBuilder,
  });

  /// The currently selected date.
  final DateTime selectedDate;

  /// Events on the selected date.
  final List<TideEvent> events;

  /// Called when an event is tapped.
  final ValueChanged<TideEvent>? onEventTap;

  /// Custom builder for event list items.
  final Widget Function(BuildContext context, TideEvent event)? eventBuilder;

  /// Builder for the empty state when no events exist.
  final WidgetBuilder? emptyBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);

    return Semantics(
      label: 'Agenda for selected date',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          border: Border(
            top: BorderSide(color: theme.borderColor, width: 1),
          ),
        ),
        child: events.isEmpty
            ? _buildEmpty(context, theme)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return _buildEventItem(context, theme, events[index]);
                },
              ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, TideThemeData theme) {
    if (emptyBuilder != null) {
      return emptyBuilder!(context);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No events',
          style: theme.timeSlotTextStyle,
        ),
      ),
    );
  }

  Widget _buildEventItem(
    BuildContext context,
    TideThemeData theme,
    TideEvent event,
  ) {
    if (eventBuilder != null) {
      return eventBuilder!(context, event);
    }

    final color = event.color ?? theme.primaryColor;

    return Semantics(
      label: 'Event: ${event.subject}',
      button: true,
      child: GestureDetector(
        onTap: onEventTap != null ? () => onEventTap!(event) : null,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.subject,
                      style: theme.eventTitleStyle.copyWith(
                        color: const Color(0xFF212121),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!event.isAllDay)
                      Text(
                        _formatTimeRange(event),
                        style: theme.eventTimeStyle.copyWith(
                          color: const Color(0xFF757575),
                        ),
                      ),
                    if (event.isAllDay)
                      Text(
                        'All day',
                        style: theme.eventTimeStyle.copyWith(
                          color: const Color(0xFF757575),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeRange(TideEvent event) {
    return '${_formatHour(event.startTime)} – ${_formatHour(event.endTime)}';
  }

  String _formatHour(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

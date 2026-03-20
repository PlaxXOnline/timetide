import 'package:flutter/widgets.dart';

import '../../core/models/event.dart';
import '../../theme/tide_theme.dart';

/// A single event entry in the schedule view list.
///
/// Shows the event color bar, subject, time range, and optional location.
class TideScheduleItem extends StatelessWidget {
  /// Creates a [TideScheduleItem].
  const TideScheduleItem({
    super.key,
    required this.event,
    this.onTap,
  });

  /// The event to display.
  final TideEvent event;

  /// Called when this item is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final color = event.color ?? theme.primaryColor;

    return Semantics(
      label: 'Event: ${event.subject}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color bar
              Container(
                width: 4,
                height: 44,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                ),
              ),
              const SizedBox(width: 12),

              // Event details
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.isAllDay
                          ? 'All day'
                          : '${_formatHour(event.startTime)} – ${_formatHour(event.endTime)}',
                      style: theme.eventTimeStyle.copyWith(
                        color: const Color(0xFF757575),
                      ),
                    ),
                    if (event.location != null && event.location!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          event.location!,
                          style: theme.eventTimeStyle.copyWith(
                            color: const Color(0xFF9E9E9E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  String _formatHour(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

import 'package:flutter/widgets.dart';

import '../../core/models/event.dart';
import '../../core/models/resource.dart';
import '../../theme/tide_theme.dart';

/// Internal card widget rendering a single shift entry inside the shift
/// planner grid.
///
/// Layout (top → bottom):
/// 1. Avatar circle (initial of [TideResource.displayName]) + first name of
///    [TideEvent.subject].
/// 2. Time range formatted as `HH:mm–HH:mm` using an en-dash.
///
/// Color resolution: when [TideEvent.color] is set it takes priority over
/// [TideResource.color]; the resolved color is used both for the 30%-tinted
/// background and the left accent border.
///
/// This widget is internal to the shift planner and therefore intentionally
/// omits the public `Tide` prefix. Future extension: render
/// [TideResource.avatar] when provided instead of the initial.
class ShiftCard extends StatelessWidget {
  /// Creates a [ShiftCard].
  const ShiftCard({
    super.key,
    required this.event,
    required this.resource,
    this.onTap,
  });

  /// The event whose data drives the card content.
  final TideEvent event;

  /// The resource the [event] is assigned to. Provides the fallback color and
  /// the avatar initial.
  final TideResource resource;

  /// Optional tap callback. When `null` the card is still rendered but does
  /// not respond to pointer events.
  final VoidCallback? onTap;

  /// Returns the first whitespace-delimited token of [subject], or the full
  /// trimmed subject when no whitespace is present. Falls back to an empty
  /// string for a blank subject.
  String _firstName(String subject) {
    final trimmed = subject.trim();
    if (trimmed.isEmpty) return '';
    final spaceIdx = trimmed.indexOf(RegExp(r'\s'));
    return spaceIdx == -1 ? trimmed : trimmed.substring(0, spaceIdx);
  }

  /// Formats [time] as `HH:mm` with zero-padded hour and minute components.
  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Returns the uppercased first character of [displayName], or an empty
  /// string when the name is blank.
  String _initial(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final displayColor = event.color ?? resource.color;

    // Background tint: alpha-blend the display color at 30% over white,
    // matching the JSX reference `color-mix(in oklch, color 30%, white)`.
    final backgroundColor = Color.alphaBlend(
      displayColor.withValues(alpha: 0.3),
      const Color(0xFFFFFFFF),
    );

    final firstName = _firstName(event.subject);
    final timeRange = '${_formatTime(event.startTime)}'
        '–${_formatTime(event.endTime)}';
    final initial = _initial(resource.displayName);

    final titleStyle = theme.shiftPlannerCardTitleStyle;
    final timeStyle = theme.shiftPlannerCardTimeStyle;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        key: const ValueKey('shift-card-container'),
        padding: theme.shiftPlannerCardPadding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: theme.shiftPlannerCardBorderRadius,
          border: Border(
            left: BorderSide(
              color: displayColor,
              width: theme.shiftPlannerCardLeftBorderWidth,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: displayColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initial,
                    style: theme.shiftPlannerCardAvatarTextStyle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              timeRange,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: timeStyle,
            ),
          ],
        ),
      ),
    );
  }
}

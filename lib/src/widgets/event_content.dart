import 'package:flutter/widgets.dart';

/// Adaptive event content widget that adjusts its layout based on
/// available height.
///
/// Three display modes are used depending on [availableHeight]:
///
/// - **Full** -- subject line plus time range (when [timeRange] is non-null).
/// - **Compact** -- subject line only with normal padding.
/// - **Minimal** -- subject line with reduced vertical padding.
class TideEventContent extends StatelessWidget {
  /// Creates an adaptive event content widget.
  const TideEventContent({
    super.key,
    required this.subject,
    this.timeRange,
    required this.titleStyle,
    this.timeStyle,
    required this.padding,
    required this.availableHeight,
  });

  /// The event title / subject line.
  final String subject;

  /// Optional formatted time range string (e.g. "09:00 – 10:00").
  final String? timeRange;

  /// Text style applied to the subject line.
  final TextStyle titleStyle;

  /// Text style applied to the time range line.
  final TextStyle? timeStyle;

  /// Padding around the content area.
  final EdgeInsets padding;

  /// The total height available for this widget, used to choose the
  /// display mode without needing a [LayoutBuilder].
  final double availableHeight;

  @override
  Widget build(BuildContext context) {
    final double titleLineHeight =
        (titleStyle.fontSize ?? 14.0) * (titleStyle.height ?? 1.2);
    final double timeLineHeight =
        (timeStyle?.fontSize ?? 0) * (timeStyle?.height ?? 1.2);
    final double verticalPadding = padding.vertical;

    final bool canFitFull = timeRange != null &&
        availableHeight >=
            verticalPadding + titleLineHeight + timeLineHeight + 2;

    final bool canFitCompact =
        availableHeight >= verticalPadding + titleLineHeight;

    if (canFitFull) {
      // Full mode: title + time range
      return Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              subject,
              style: titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              timeRange!,
              style: timeStyle,
              maxLines: 1,
            ),
          ],
        ),
      );
    } else if (canFitCompact) {
      // Compact mode: title only
      return Padding(
        padding: padding,
        child: Text(
          subject,
          style: titleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    } else {
      // Minimal mode: title with reduced vertical padding
      return Padding(
        padding: padding.copyWith(top: 1, bottom: 1),
        child: Text(
          subject,
          style: titleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
  }
}

import 'package:flutter/widgets.dart';

import '../../core/models/event.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';

/// Display mode for events inside a month cell.
enum TideEventDisplayMode {
  /// Show coloured dots as event indicators.
  indicator,

  /// Show event subject text.
  text,

  /// Use a custom builder.
  custom,
}

/// A single cell in the month view grid.
///
/// Shows the date number, event indicators or text, and a "+N" badge when
/// events exceed [maxEvents]. Applies today/selected/leading-trailing styling
/// from [TideThemeData].
class TideMonthCell extends StatelessWidget {
  /// Creates a [TideMonthCell].
  const TideMonthCell({
    super.key,
    required this.date,
    required this.events,
    this.isToday = false,
    this.isSelected = false,
    this.isLeadingTrailing = false,
    this.maxEvents = 3,
    this.eventDisplayMode = TideEventDisplayMode.indicator,
    this.onTap,
    this.onEventTap,
    this.eventBuilder,
  });

  /// The date this cell represents.
  final DateTime date;

  /// Events on this date.
  final List<TideEvent> events;

  /// Whether this cell represents today.
  final bool isToday;

  /// Whether this cell is currently selected.
  final bool isSelected;

  /// Whether this date belongs to a leading/trailing month.
  final bool isLeadingTrailing;

  /// Maximum number of events to display before showing "+N".
  final int maxEvents;

  /// How events are displayed in the cell.
  final TideEventDisplayMode eventDisplayMode;

  /// Called when the cell is tapped.
  final VoidCallback? onTap;

  /// Called when an event within the cell is tapped.
  final ValueChanged<TideEvent>? onEventTap;

  /// Custom builder for event display in the cell.
  final Widget Function(BuildContext context, TideEvent event)? eventBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final visibleEvents = events.take(maxEvents).toList();
    final overflow = events.length - maxEvents;

    Color backgroundColor;
    if (isSelected) {
      backgroundColor = theme.selectedCellColor;
    } else if (isToday) {
      backgroundColor = theme.todayCellColor;
    } else {
      backgroundColor = theme.backgroundColor;
    }

    return Semantics(
      label: _buildSemanticLabel(),
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: theme.monthCellBorderColor,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date number
              _buildDateNumber(theme),

              // Events (clipped if they overflow the cell)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      height: constraints.maxHeight,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...visibleEvents.map(
                              (event) =>
                                  _buildEventEntry(context, theme, event),
                            ),

                            // "+N" badge
                            if (overflow > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Text(
                                  '+$overflow',
                                  style: theme.monthDateTextStyle.copyWith(
                                    fontSize: 10,
                                    color: theme.primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateNumber(TideThemeData theme) {
    final textColor = isLeadingTrailing
        ? theme.leadingTrailingDatesColor
        : theme.monthDateTextStyle.color;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: isToday
            ? BoxDecoration(
                color: theme.todayHighlightColor,
                shape: BoxShape.circle,
              )
            : null,
        child: Text(
          '${date.day}',
          style: theme.monthDateTextStyle.copyWith(
            color: isToday ? const Color(0xFFFFFFFF) : textColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEventEntry(
    BuildContext context,
    TideThemeData theme,
    TideEvent event,
  ) {
    if (eventDisplayMode == TideEventDisplayMode.custom &&
        eventBuilder != null) {
      return eventBuilder!(context, event);
    }

    if (eventDisplayMode == TideEventDisplayMode.indicator) {
      final color = event.color ?? theme.primaryColor;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                event.subject,
                style: theme.monthDateTextStyle.copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Text mode
    final color = event.color ?? theme.primaryColor;
    return Semantics(
      label: 'Event: ${event.subject}',
      button: true,
      child: GestureDetector(
        onTap: onEventTap != null ? () => onEventTap!(event) : null,
        child: Container(
          margin: const EdgeInsets.only(top: 1),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
          child: Text(
            event.subject,
            style: theme.eventTitleStyle.copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  String _buildSemanticLabel() {
    final parts = <String>[
      '${date.day}',
      if (isToday) 'today',
      if (isSelected) 'selected',
      if (events.isNotEmpty) '${events.length} events',
    ];
    return parts.join(', ');
  }
}

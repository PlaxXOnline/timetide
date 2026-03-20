import 'package:flutter/widgets.dart';

import '../../theme/tide_theme.dart';

/// Display modes for the resource load indicator.
enum TideLoadDisplayMode {
  /// Shows a colored bar representing load percentage.
  percentage,

  /// Displays a text label like "N events".
  eventCount,

  /// Delegates rendering to a user-provided builder.
  custom,
}

/// Shows the scheduling load for a resource.
///
/// Supports three display modes: a percentage bar, an event count label, or a
/// fully custom builder. Uses only `widgets.dart`.
class TideResourceLoadIndicator extends StatelessWidget {
  /// Creates a [TideResourceLoadIndicator].
  const TideResourceLoadIndicator({
    super.key,
    required this.mode,
    this.percentage = 0.0,
    this.eventCount = 0,
    this.customBuilder,
    this.barColor,
    this.barHeight = 4.0,
  }) : assert(
          mode != TideLoadDisplayMode.custom || customBuilder != null,
          'customBuilder must be provided when mode is custom',
        );

  /// Which display mode to use.
  final TideLoadDisplayMode mode;

  /// Load percentage (0.0–1.0) for [TideLoadDisplayMode.percentage].
  final double percentage;

  /// Number of events for [TideLoadDisplayMode.eventCount].
  final int eventCount;

  /// Builder for [TideLoadDisplayMode.custom].
  final Widget Function(BuildContext context)? customBuilder;

  /// Color of the percentage bar. Uses [TideThemeData.primaryColor] if null.
  final Color? barColor;

  /// Height of the percentage bar.
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case TideLoadDisplayMode.percentage:
        return _buildPercentageBar(context);
      case TideLoadDisplayMode.eventCount:
        return _buildEventCount(context);
      case TideLoadDisplayMode.custom:
        return customBuilder!(context);
    }
  }

  Widget _buildPercentageBar(BuildContext context) {
    final theme = TideTheme.of(context);
    final color = barColor ?? theme.primaryColor;
    final clamped = percentage.clamp(0.0, 1.0);

    return Semantics(
      label: 'Load: ${(clamped * 100).round()}%',
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          color: theme.borderColor,
          borderRadius: BorderRadius.circular(barHeight / 2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: clamped,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCount(BuildContext context) {
    final theme = TideTheme.of(context);

    return Semantics(
      label: '$eventCount events',
      child: Text(
        '$eventCount events',
        style: theme.timeSlotTextStyle,
      ),
    );
  }
}

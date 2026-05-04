import 'package:flutter/widgets.dart';

import '../../core/models/event.dart';
import '../../core/models/resource.dart';
import '../../interaction/drag_drop/external_drag.dart';
import '../../l10n/tide_localizations.dart';
import '../../theme/tide_theme.dart';
import 'shift_card.dart';
import 'tide_shift_planner.dart' show TideShiftCardBuilder;

/// Internal column widget representing a single calendar day inside the
/// shift planner grid.
///
/// Layout (top → bottom, when [closed] is `false`):
/// 1. One [ShiftCard] per event in [events], sorted ascending by
///    [TideEvent.startTime]. Events whose `resourceIds.first` does not
///    resolve via [resourceById] are silently skipped (no crash).
/// 2. A "+ Shift" button that invokes [onAddShiftPressed] with [date].
///
/// When [closed] is `true` the column instead renders a diagonal-hatch
/// background with a centered, localized "Closed" label, no shift cards,
/// no add button, and no [TideDragTarget] — drops are not accepted on
/// closed days.
///
/// External drops (from a [TideDragSource]) are accepted via a
/// [TideDragTarget] that uses [dropTime] as the resolved start time. The
/// caller is responsible for computing [dropTime] (typically by combining
/// [date] with the planner's default start hour).
///
/// This widget is internal to the shift planner and therefore intentionally
/// omits the public `Tide` prefix. Future extensions: dashed border on the
/// add button, refined hatch pattern, drop-position-derived snap times.
class ShiftDayColumn extends StatelessWidget {
  /// Creates a [ShiftDayColumn].
  const ShiftDayColumn({
    super.key,
    required this.date,
    required this.closed,
    required this.events,
    required this.resourceById,
    required this.dropTime,
    this.onShiftTap,
    this.onAddShiftPressed,
    this.onExternalDragEnd,
    this.locale,
    this.cardBuilder,
  });

  /// The calendar day this column represents (date-only; time component
  /// is ignored for layout purposes).
  final DateTime date;

  /// Whether this day is closed. Closed days render a hatch + label only,
  /// no drop target, and no add button.
  final bool closed;

  /// Events to render in this column. Will be sorted ascending by
  /// [TideEvent.startTime] before display; the input list is not mutated.
  final List<TideEvent> events;

  /// Lookup map for the resource referenced by each event's
  /// `resourceIds.first`. Events with a missing or unknown resourceId are
  /// silently skipped.
  final Map<String, TideResource> resourceById;

  /// The [DateTime] an external drag should snap to when dropped on this
  /// column. Typically `date.copyWith(hour: defaultStartHour, minute: 0)`.
  final DateTime dropTime;

  /// Optional callback invoked when a [ShiftCard] is tapped.
  final ValueChanged<TideEvent>? onShiftTap;

  /// Optional callback invoked when the "+ Shift" button is pressed; the
  /// argument is [date].
  final ValueChanged<DateTime>? onAddShiftPressed;

  /// Optional callback invoked when an external drag is dropped on this
  /// column.
  final TideExternalDragEndCallback? onExternalDragEnd;

  /// Optional [TideLocalizations] override. Falls back to
  /// [TideLocalizations.en] when not provided.
  final TideLocalizations? locale;

  /// Optional builder that replaces the default [ShiftCard]. When supplied,
  /// it is invoked for every renderable event with its resolved
  /// [TideResource]. Events whose resource cannot be resolved are skipped
  /// regardless of this builder.
  final TideShiftCardBuilder? cardBuilder;

  ValueKey<String> get _outerKey => ValueKey<String>(
        'shift-day-column-${date.year}-${date.month}-${date.day}',
      );

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final l10n = locale ?? TideLocalizations.en();

    if (closed) {
      return _ClosedColumn(
        key: _outerKey,
        label: l10n.closed,
        labelStyle: theme.shiftPlannerClosedLabelStyle,
        patternColor: theme.shiftPlannerClosedDayPatternColor,
        patternSpacing: theme.shiftPlannerClosedDayPatternSpacing,
      );
    }

    final sorted = <TideEvent>[...events]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final cards = <Widget>[];
    for (final event in sorted) {
      final ids = event.resourceIds;
      final rid = (ids != null && ids.isNotEmpty) ? ids.first : null;
      final resource = rid != null ? resourceById[rid] : null;
      if (resource == null) {
        // Silently skip — caller is responsible for keeping the map in sync.
        continue;
      }
      final Widget card = cardBuilder != null
          ? cardBuilder!(context, event, resource)
          : ShiftCard(
              event: event,
              resource: resource,
              onTap: onShiftTap == null ? null : () => onShiftTap!(event),
            );
      cards.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: card,
      ));
    }

    return TideDragTarget(
      key: _outerKey,
      dropTime: dropTime,
      onExternalDragEnd: onExternalDragEnd,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ...cards,
            _AddShiftButton(
              label: l10n.addShift,
              labelStyle: theme.shiftPlannerAddButtonStyle,
              borderColor: theme.shiftPlannerAddButtonBorderColor,
              onPressed: onAddShiftPressed == null
                  ? null
                  : () => onAddShiftPressed!(date),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the closed-day visual: diagonal hatch background plus a centered
/// label. Intentionally not wrapped in a [TideDragTarget] — closed days do
/// not accept drops.
class _ClosedColumn extends StatelessWidget {
  const _ClosedColumn({
    super.key,
    required this.label,
    required this.labelStyle,
    required this.patternColor,
    required this.patternSpacing,
  });

  final String label;
  final TextStyle labelStyle;
  final Color patternColor;
  final double patternSpacing;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DiagonalHatchPainter(
        color: patternColor,
        spacing: patternSpacing,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: Text(
            label,
            key: const ValueKey<String>('closed-label'),
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
        ),
      ),
    );
  }
}

/// Paints repeating 135° diagonal hatch lines mimicking the JSX reference's
/// `repeating-linear-gradient` for closed days.
class _DiagonalHatchPainter extends CustomPainter {
  _DiagonalHatchPainter({required this.color, required this.spacing});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Clip so diagonal strokes never bleed into neighbouring day columns.
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Lines go bottom-left → top-right (135°). Iterate by horizontal offset
    // so both halves of the rectangle are covered.
    final maxOffset = size.width + size.height;
    for (double x = -size.height; x < maxOffset; x += spacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DiagonalHatchPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.spacing != spacing;
  }
}

/// Tap target for the "+ Shift" button at the bottom of an open day column.
///
/// Uses a solid border rendered with [TideThemeData.shiftPlannerAddButtonBorderColor].
class _AddShiftButton extends StatelessWidget {
  const _AddShiftButton({
    required this.label,
    required this.labelStyle,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final TextStyle labelStyle;
  final Color borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey<String>('add-shift-button'),
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x00000000),
          border: Border.all(color: borderColor),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: labelStyle,
        ),
      ),
    );
  }
}

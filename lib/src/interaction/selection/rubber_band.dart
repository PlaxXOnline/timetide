import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/event.dart';
import '../../theme/tide_theme.dart';

/// Callback that resolves which events intersect a given rectangle.
typedef TideEventHitTest = List<TideEvent> Function(Rect selectionRect);

/// Desktop/web rubber-band (lasso) selection overlay.
///
/// Draws a selection rectangle when the user drags on an empty area and selects
/// all events whose rendered bounds intersect the rectangle.
///
/// Only active on desktop and web platforms; no-ops on mobile.
class TideRubberBand extends StatefulWidget {
  /// Creates a [TideRubberBand].
  ///
  /// [controller] is used to update the event selection.
  /// [hitTest] resolves which events intersect a given rectangle in the
  /// coordinate space of this widget.
  const TideRubberBand({
    super.key,
    required this.controller,
    required this.hitTest,
    required this.child,
  });

  /// The calendar controller whose selection is updated.
  final TideController controller;

  /// Resolves events that intersect the rubber-band rectangle.
  final TideEventHitTest hitTest;

  /// The child widget (typically the calendar body).
  final Widget child;

  @override
  State<TideRubberBand> createState() => _TideRubberBandState();
}

class _TideRubberBandState extends State<TideRubberBand> {
  Offset? _startOffset;
  Offset? _currentOffset;

  bool get _isDesktopOrWeb {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  Rect? get _selectionRect {
    if (_startOffset == null || _currentOffset == null) return null;
    return Rect.fromPoints(_startOffset!, _currentOffset!);
  }

  void _onPanStart(DragStartDetails details) {
    if (!_isDesktopOrWeb) return;
    setState(() {
      _startOffset = details.localPosition;
      _currentOffset = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDesktopOrWeb || _startOffset == null) return;
    setState(() {
      _currentOffset = details.localPosition;
    });
    final rect = _selectionRect;
    if (rect != null && rect.width > 4 && rect.height > 4) {
      final events = widget.hitTest(rect);
      widget.controller.deselectAll();
      for (final event in events) {
        widget.controller.selectEvent(event, additive: true);
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDesktopOrWeb) return;
    setState(() {
      _startOffset = null;
      _currentOffset = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          widget.child,
          if (_selectionRect != null)
            Positioned.fromRect(
              rect: _selectionRect!,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _RubberBandPainter(
                    color: TideTheme.of(context).selectionColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Paints the rubber-band selection rectangle.
///
/// Draws a dashed border with a semi-transparent fill using the theme's
/// selection color.
class _RubberBandPainter extends CustomPainter {
  _RubberBandPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Semi-transparent fill.
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // Dashed border.
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    _drawDashedRect(canvas, rect, borderPaint, dashLength: 4, gapLength: 3);
  }

  void _drawDashedRect(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    final sides = [
      [rect.topLeft, rect.topRight],
      [rect.topRight, rect.bottomRight],
      [rect.bottomRight, rect.bottomLeft],
      [rect.bottomLeft, rect.topLeft],
    ];
    for (final side in sides) {
      _drawDashedLine(canvas, side[0], side[1], paint, dashLength, gapLength);
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashLength,
    double gapLength,
  ) {
    final totalLength = (end - start).distance;
    final unitVector = (end - start) / totalLength;
    var drawn = 0.0;
    var isDash = true;
    while (drawn < totalLength) {
      final segmentLength = isDash ? dashLength : gapLength;
      final remaining = totalLength - drawn;
      final length = segmentLength < remaining ? segmentLength : remaining;
      if (isDash) {
        final segStart = start + unitVector * drawn;
        final segEnd = start + unitVector * (drawn + length);
        canvas.drawLine(segStart, segEnd, paint);
      }
      drawn += length;
      isDash = !isDash;
    }
  }

  @override
  bool shouldRepaint(_RubberBandPainter oldDelegate) =>
      color != oldDelegate.color;
}

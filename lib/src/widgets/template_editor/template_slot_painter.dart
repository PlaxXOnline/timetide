import 'package:flutter/widgets.dart';

/// Paints the grid lines (hour marks and day dividers) for the template editor.
class TemplateGridPainter extends CustomPainter {
  /// Creates a [TemplateGridPainter].
  const TemplateGridPainter({
    required this.hourCount,
    required this.hourHeight,
    required this.dayColumnWidth,
    required this.gridLineColor,
    required this.timeColumnWidth,
  });

  /// Number of hour rows to draw.
  final int hourCount;

  /// Height of each hour row in logical pixels.
  final double hourHeight;

  /// Width of each day column in logical pixels.
  final double dayColumnWidth;

  /// Color for grid lines.
  final Color gridLineColor;

  /// Width of the time labels column on the left.
  final double timeColumnWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridLineColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Horizontal hour lines.
    for (var i = 0; i <= hourCount; i++) {
      final y = i * hourHeight;
      canvas.drawLine(
        Offset(timeColumnWidth, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Vertical day dividers.
    for (var d = 0; d <= 7; d++) {
      final x = timeColumnWidth + d * dayColumnWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, hourCount * hourHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TemplateGridPainter oldDelegate) {
    return hourCount != oldDelegate.hourCount ||
        hourHeight != oldDelegate.hourHeight ||
        dayColumnWidth != oldDelegate.dayColumnWidth ||
        gridLineColor != oldDelegate.gridLineColor ||
        timeColumnWidth != oldDelegate.timeColumnWidth;
  }
}

/// Paints a diagonal stripe pattern over break slots.
class BreakPatternPainter extends CustomPainter {
  /// Creates a [BreakPatternPainter].
  const BreakPatternPainter({
    required this.color,
    required this.spacing,
  });

  /// Color of the diagonal stripes.
  final Color color;

  /// Distance between stripes in logical pixels.
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw diagonal lines from bottom-left to top-right.
    final maxDimension = size.width + size.height;
    for (var offset = -maxDimension; offset < maxDimension; offset += spacing) {
      canvas.drawLine(
        Offset(offset, size.height),
        Offset(offset + size.height, 0),
        paint,
      );
    }

    // Clip to the widget bounds via saveLayer/restore is not needed since
    // the parent widget applies ClipRect.
  }

  @override
  bool shouldRepaint(BreakPatternPainter oldDelegate) {
    return color != oldDelegate.color || spacing != oldDelegate.spacing;
  }
}

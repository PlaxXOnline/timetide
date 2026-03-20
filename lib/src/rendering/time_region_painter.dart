import 'package:flutter/widgets.dart';

import '../core/models/time_region.dart';

/// Pre-computed position data for a [TideTimeRegion] within a day column.
///
/// The view layer maps each [TideTimeRegion] to a [TidePositionedRegion] so the
/// painter can draw without re-calculating positions.
class TidePositionedRegion {
  /// Creates a [TidePositionedRegion].
  const TidePositionedRegion({
    required this.type,
    required this.top,
    required this.height,
    this.color,
    this.text,
  });

  /// Semantic type that drives the rendering style.
  final TimeRegionType type;

  /// Y-offset from the top of the paint area.
  final double top;

  /// Vertical extent of the region in pixels.
  final double height;

  /// Optional override colour. Falls back to painter defaults when null.
  final Color? color;

  /// Optional label drawn centred inside the region.
  final String? text;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TidePositionedRegion &&
        other.type == type &&
        other.top == top &&
        other.height == height &&
        other.color == color &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hash(type, top, height, color, text);
}

/// Paints time-region overlays (blocked, highlight, non-working, etc.).
///
/// Each region is drawn according to its [TimeRegionType]:
///
/// * [TimeRegionType.blocked] — diagonal hatching lines.
/// * [TimeRegionType.highlight] — solid colour fill with a 1 px border.
/// * [TimeRegionType.nonWorking] — semi-transparent grey overlay.
/// * [TimeRegionType.working] — no special rendering.
/// * [TimeRegionType.custom] — skipped (handled by a builder widget).
class TideTimeRegionPainter extends CustomPainter {
  /// Creates a [TideTimeRegionPainter].
  const TideTimeRegionPainter({
    required this.regions,
    this.defaultHighlightColor = const Color(0x332196F3),
    this.defaultBlockedColor = const Color(0xFF9E9E9E),
    this.textStyle,
  });

  /// The positioned regions to paint.
  final List<TidePositionedRegion> regions;

  /// Fallback colour for [TimeRegionType.highlight] when the region has no
  /// [TidePositionedRegion.color].
  final Color defaultHighlightColor;

  /// Colour of the hatching lines for [TimeRegionType.blocked].
  final Color defaultBlockedColor;

  /// Optional text style for region labels. If null, labels are not drawn.
  final TextStyle? textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      switch (region.type) {
        case TimeRegionType.blocked:
          _paintBlocked(canvas, size.width, region);
        case TimeRegionType.highlight:
          _paintHighlight(canvas, size.width, region);
        case TimeRegionType.nonWorking:
          _paintNonWorking(canvas, size.width, region);
        case TimeRegionType.working:
          break; // No special rendering.
        case TimeRegionType.custom:
          break; // Handled by builder.
      }

      // Draw optional text label.
      if (region.text != null && textStyle != null) {
        _paintLabel(canvas, size.width, region);
      }
    }
  }

  void _paintBlocked(Canvas canvas, double width, TidePositionedRegion region) {
    final hatchPaint = Paint()
      ..color = region.color ?? defaultBlockedColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 8.0;
    final regionTop = region.top;
    final regionHeight = region.height;

    // Clip to region bounds.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, regionTop, width, regionHeight));

    // Draw diagonal lines from top-left to bottom-right.
    for (var x = -regionHeight; x < width + regionHeight; x += spacing) {
      canvas.drawLine(
        Offset(x, regionTop),
        Offset(x + regionHeight, regionTop + regionHeight),
        hatchPaint,
      );
    }

    canvas.restore();
  }

  void _paintHighlight(
    Canvas canvas,
    double width,
    TidePositionedRegion region,
  ) {
    final fillColor = region.color ?? defaultHighlightColor;

    // Solid fill.
    final fillPaint = Paint()..color = fillColor;
    canvas.drawRect(
      Rect.fromLTWH(0, region.top, width, region.height),
      fillPaint,
    );

    // 1 px border.
    final borderPaint = Paint()
      ..color = fillColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(0, region.top, width, region.height),
      borderPaint,
    );
  }

  void _paintNonWorking(
    Canvas canvas,
    double width,
    TidePositionedRegion region,
  ) {
    final paint = Paint()..color = region.color ?? const Color(0x1A000000);
    canvas.drawRect(
      Rect.fromLTWH(0, region.top, width, region.height),
      paint,
    );
  }

  void _paintLabel(Canvas canvas, double width, TidePositionedRegion region) {
    final painter = TextPainter(
      text: TextSpan(text: region.text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: width);

    final offset = Offset(
      (width - painter.width) / 2,
      region.top + (region.height - painter.height) / 2,
    );
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant TideTimeRegionPainter oldDelegate) {
    if (regions.length != oldDelegate.regions.length) return true;
    if (defaultHighlightColor != oldDelegate.defaultHighlightColor) return true;
    if (defaultBlockedColor != oldDelegate.defaultBlockedColor) return true;
    if (textStyle != oldDelegate.textStyle) return true;
    for (var i = 0; i < regions.length; i++) {
      if (regions[i] != oldDelegate.regions[i]) return true;
    }
    return false;
  }
}

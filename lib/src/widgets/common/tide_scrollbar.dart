import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';

/// A custom-painted scrollbar widget (no Material dependency).
///
/// Paints a thumb via [CustomPainter], themed from [TideThemeData].
/// Fades in when scrolling and fades out after inactivity. The thumb
/// can be dragged to scroll the associated [ScrollController].
///
/// ```dart
/// TideScrollbar(
///   controller: _scrollController,
///   child: ListView(...),
/// )
/// ```
class TideScrollbar extends StatefulWidget {
  /// Creates a [TideScrollbar].
  const TideScrollbar({
    super.key,
    required this.controller,
    required this.child,
    this.fadeInDuration = const Duration(milliseconds: 200),
    this.fadeOutDuration = const Duration(milliseconds: 600),
    this.hideDelay = const Duration(seconds: 2),
  });

  /// The scroll controller to observe and drive.
  final ScrollController controller;

  /// The scrollable content.
  final Widget child;

  /// Duration for the fade-in animation.
  final Duration fadeInDuration;

  /// Duration for the fade-out animation.
  final Duration fadeOutDuration;

  /// Delay before the scrollbar fades out after scroll activity stops.
  final Duration hideDelay;

  @override
  State<TideScrollbar> createState() => _TideScrollbarState();
}

class _TideScrollbarState extends State<TideScrollbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  Timer? _fadeTimer;
  bool _isDragging = false;
  double? _dragStartScrollOffset;
  double? _dragStartThumbOffset;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.fadeInDuration,
      reverseDuration: widget.fadeOutDuration,
    );
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(TideScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _fadeTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    _fadeController.forward();
    _scheduleFade();
    setState(() {});
  }

  void _scheduleFade() {
    _fadeTimer?.cancel();
    if (_isDragging) return;
    _fadeTimer = Timer(widget.hideDelay, () {
      if (mounted && !_isDragging) {
        _fadeController.reverse();
      }
    });
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.controller.hasClients) return;
    final position = widget.controller.position;
    if (position.maxScrollExtent <= 0) return;

    _isDragging = true;
    _fadeTimer?.cancel();
    _fadeController.forward();
    _dragStartScrollOffset = position.pixels;
    _dragStartThumbOffset = details.localPosition.dy;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || !widget.controller.hasClients) return;
    final position = widget.controller.position;
    final viewportExtent = position.viewportDimension;
    final contentExtent = position.maxScrollExtent + viewportExtent;
    if (contentExtent <= viewportExtent) return;

    final theme = TideTheme.of(context);
    final trackHeight = viewportExtent - theme.scrollbarThickness;
    final thumbHeight = (viewportExtent / contentExtent) * trackHeight;
    final scrollableTrack = trackHeight - thumbHeight;
    if (scrollableTrack <= 0) return;

    final dragDelta = details.localPosition.dy - _dragStartThumbOffset!;
    final scrollDelta =
        (dragDelta / scrollableTrack) * position.maxScrollExtent;
    final newOffset =
        (_dragStartScrollOffset! + scrollDelta).clamp(0.0, position.maxScrollExtent);
    widget.controller.jumpTo(newOffset);
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
    _dragStartScrollOffset = null;
    _dragStartThumbOffset = null;
    _scheduleFade();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);

    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: theme.scrollbarThickness + 4, // Hit area padding.
          child: FadeTransition(
            opacity: _fadeController,
            child: GestureDetector(
              onVerticalDragStart: _onDragStart,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              child: AnimatedBuilder(
                animation: widget.controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ScrollbarPainter(
                      controller: widget.controller,
                      color: theme.scrollbarColor,
                      thickness: theme.scrollbarThickness,
                      radius: theme.scrollbarRadius,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScrollbarPainter extends CustomPainter {
  _ScrollbarPainter({
    required this.controller,
    required this.color,
    required this.thickness,
    required this.radius,
  });

  final ScrollController controller;
  final Color color;
  final double thickness;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (!controller.hasClients) return;

    final position = controller.position;
    final viewportExtent = position.viewportDimension;
    final contentExtent = position.maxScrollExtent + viewportExtent;
    if (contentExtent <= viewportExtent) return;

    final trackHeight = size.height;
    final thumbHeight =
        (viewportExtent / contentExtent * trackHeight).clamp(20.0, trackHeight);
    final scrollableTrack = trackHeight - thumbHeight;
    final scrollFraction =
        position.maxScrollExtent > 0
            ? position.pixels / position.maxScrollExtent
            : 0.0;
    final thumbTop = scrollFraction * scrollableTrack;

    final left = size.width - thickness;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, thumbTop, thickness, thumbHeight),
      Radius.circular(radius),
    );

    canvas.drawRRect(rrect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ScrollbarPainter oldDelegate) {
    return color != oldDelegate.color ||
        thickness != oldDelegate.thickness ||
        radius != oldDelegate.radius;
  }
}

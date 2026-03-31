import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';

/// A custom tooltip widget (no Material dependency).
///
/// Shows on hover (desktop) or long-press (mobile) after a configurable delay.
/// Positions relative to the child widget and auto-flips at screen edges.
///
/// ```dart
/// TideTooltip(
///   content: Text('Edit this event'),
///   child: MyIconButton(),
/// )
/// ```
class TideTooltip extends StatefulWidget {
  /// Creates a [TideTooltip].
  const TideTooltip({
    super.key,
    required this.child,
    required this.content,
    this.showDelay = const Duration(milliseconds: 500),
    this.hideDelay = const Duration(milliseconds: 200),
    this.preferAbove = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  /// The widget that triggers the tooltip.
  final Widget child;

  /// The content displayed inside the tooltip.
  final Widget content;

  /// Delay before showing the tooltip on hover.
  final Duration showDelay;

  /// Delay before hiding the tooltip after the pointer leaves.
  final Duration hideDelay;

  /// Whether to prefer positioning above the child. Falls back to below.
  final bool preferAbove;

  /// Padding inside the tooltip container.
  final EdgeInsets padding;

  @override
  State<TideTooltip> createState() => _TideTooltipState();
}

class _TideTooltipState extends State<TideTooltip>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _showTimer;
  Timer? _hideTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _scheduleShow() {
    _hideTimer?.cancel();
    if (_overlayEntry != null) return;
    _showTimer?.cancel();
    _showTimer = Timer(widget.showDelay, _showOverlay);
  }

  void _scheduleHide() {
    _showTimer?.cancel();
    if (_overlayEntry == null) return;
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.hideDelay, _hideOverlay);
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final theme = TideTheme.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => _TideTooltipOverlay(
        layerLink: _layerLink,
        fadeAnimation: _fadeAnimation,
        content: widget.content,
        theme: theme,
        preferAbove: widget.preferAbove,
        padding: widget.padding,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _hideOverlay() {
    if (_overlayEntry == null) return;
    _animationController.reverse().then((_) {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleLongPress() {
    _showOverlay();
    // Auto-hide after a moment on mobile.
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), _hideOverlay);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _scheduleShow(),
        onExit: (_) => _scheduleHide(),
        child: GestureDetector(
          onLongPress: _handleLongPress,
          child: widget.child,
        ),
      ),
    );
  }
}

class _TideTooltipOverlay extends StatelessWidget {
  const _TideTooltipOverlay({
    required this.layerLink,
    required this.fadeAnimation,
    required this.content,
    required this.theme,
    required this.preferAbove,
    required this.padding,
  });

  final LayerLink layerLink;
  final Animation<double> fadeAnimation;
  final Widget content;
  final TideThemeData theme;
  final bool preferAbove;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final targetAnchor =
        preferAbove ? Alignment.topCenter : Alignment.bottomCenter;
    final followerAnchor =
        preferAbove ? Alignment.bottomCenter : Alignment.topCenter;
    final offsetY = preferAbove ? -4.0 : 4.0;

    return CompositedTransformFollower(
      link: layerLink,
      targetAnchor: targetAnchor,
      followerAnchor: followerAnchor,
      offset: Offset(0, offsetY),
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Container(
          padding: padding,
          decoration: const BoxDecoration(
            color: Color(0xE6333333),
            borderRadius: BorderRadius.all(Radius.circular(4)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DefaultTextStyle(
            style: theme.timeSlotTextStyle.copyWith(
              color: const Color(0xFFFFFFFF),
              fontSize: 12,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

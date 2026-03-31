import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Determines how a [TidePopup] is positioned relative to its anchor.
enum TidePopupAlignment {
  /// Position above the anchor.
  above,

  /// Position below the anchor.
  below,

  /// Position to the left of the anchor.
  left,

  /// Position to the right of the anchor.
  right,
}

/// Generic overlay popup positioned relative to an anchor point.
///
/// Used as the base positioning mechanism for [TideContextMenu] and
/// [TideTooltip]. Shows an [OverlayEntry] that auto-positions itself
/// above, below, left, or right of the anchor based on available space.
///
/// Animates in/out with a fade transition and dismisses on outside tap.
class TidePopup extends StatefulWidget {
  /// Creates a [TidePopup].
  const TidePopup({
    super.key,
    required this.child,
    required this.content,
    required this.visible,
    this.preferredAlignment = TidePopupAlignment.below,
    this.offset = Offset.zero,
    this.onDismiss,
    this.barrierDismissible = true,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  /// The widget that acts as the anchor for popup positioning.
  final Widget child;

  /// The content displayed inside the popup overlay.
  final Widget content;

  /// Whether the popup is currently visible.
  final bool visible;

  /// Preferred alignment relative to the anchor.
  final TidePopupAlignment preferredAlignment;

  /// Additional offset applied after positioning.
  final Offset offset;

  /// Called when the popup is dismissed by an outside tap.
  final VoidCallback? onDismiss;

  /// Whether tapping outside the popup dismisses it.
  final bool barrierDismissible;

  /// Duration of the fade-in/out animation.
  final Duration animationDuration;

  @override
  State<TidePopup> createState() => _TidePopupState();
}

class _TidePopupState extends State<TidePopup>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    if (widget.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOverlay());
    }
  }

  @override
  void didUpdateWidget(TidePopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _showOverlay();
    } else if (!widget.visible && oldWidget.visible) {
      _hideOverlay();
    } else if (widget.visible && _overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _TidePopupOverlay(
        layerLink: _layerLink,
        fadeAnimation: _fadeAnimation,
        content: widget.content,
        preferredAlignment: widget.preferredAlignment,
        offset: widget.offset,
        barrierDismissible: widget.barrierDismissible,
        onDismiss: () {
          widget.onDismiss?.call();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _hideOverlay() {
    _animationController.reverse().then((_) {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: widget.child,
    );
  }
}

class _TidePopupOverlay extends StatelessWidget {
  const _TidePopupOverlay({
    required this.layerLink,
    required this.fadeAnimation,
    required this.content,
    required this.preferredAlignment,
    required this.offset,
    required this.barrierDismissible,
    required this.onDismiss,
  });

  final LayerLink layerLink;
  final Animation<double> fadeAnimation;
  final Widget content;
  final TidePopupAlignment preferredAlignment;
  final Offset offset;
  final bool barrierDismissible;
  final VoidCallback onDismiss;

  Offset _alignmentOffset(TidePopupAlignment alignment) {
    switch (alignment) {
      case TidePopupAlignment.above:
        return const Offset(0, -8) + offset;
      case TidePopupAlignment.below:
        return const Offset(0, 8) + offset;
      case TidePopupAlignment.left:
        return const Offset(-8, 0) + offset;
      case TidePopupAlignment.right:
        return const Offset(8, 0) + offset;
    }
  }

  Alignment _targetAnchor(TidePopupAlignment alignment) {
    switch (alignment) {
      case TidePopupAlignment.above:
        return Alignment.topCenter;
      case TidePopupAlignment.below:
        return Alignment.bottomCenter;
      case TidePopupAlignment.left:
        return Alignment.centerLeft;
      case TidePopupAlignment.right:
        return Alignment.centerRight;
    }
  }

  Alignment _followerAnchor(TidePopupAlignment alignment) {
    switch (alignment) {
      case TidePopupAlignment.above:
        return Alignment.bottomCenter;
      case TidePopupAlignment.below:
        return Alignment.topCenter;
      case TidePopupAlignment.left:
        return Alignment.centerRight;
      case TidePopupAlignment.right:
        return Alignment.centerLeft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Barrier for outside taps.
        if (barrierDismissible)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onDismiss,
              child: const SizedBox.expand(),
            ),
          ),
        CompositedTransformFollower(
          link: layerLink,
          targetAnchor: _targetAnchor(preferredAlignment),
          followerAnchor: _followerAnchor(preferredAlignment),
          offset: _alignmentOffset(preferredAlignment),
          child: FadeTransition(
            opacity: fadeAnimation,
            child: content,
          ),
        ),
      ],
    );
  }
}

/// Shows a popup overlay at the given [position] with the given [content].
///
/// Returns a function that removes the overlay when called.
/// This is a lower-level API used by [TideContextMenu.show].
VoidCallback showTidePopupAtPosition({
  required BuildContext context,
  required Offset position,
  required Widget content,
  VoidCallback? onDismiss,
  Duration animationDuration = const Duration(milliseconds: 150),
}) {
  late OverlayEntry entry;
  late AnimationController controller;

  final overlayState = Overlay.of(context);
  final tickerProvider = _PopupTickerProvider();

  controller = AnimationController(
    vsync: tickerProvider,
    duration: animationDuration,
  );

  final fadeAnimation = CurvedAnimation(
    parent: controller,
    curve: Curves.easeOut,
  );

  bool removed = false;
  void remove() {
    if (removed) return;
    removed = true;
    // If the ticker is no longer active (e.g. during widget dispose),
    // skip the animation and clean up immediately.
    if (!tickerProvider.isActive) {
      entry.remove();
      controller.dispose();
      tickerProvider.dispose();
      onDismiss?.call();
      return;
    }
    controller.reverse().then((_) {
      entry.remove();
      controller.dispose();
      tickerProvider.dispose();
      onDismiss?.call();
    });
  }

  entry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: remove,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: position.dx,
          top: position.dy,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: content,
          ),
        ),
      ],
    ),
  );

  overlayState.insert(entry);
  controller.forward();

  return remove;
}

/// A minimal [TickerProvider] for standalone popup animations.
class _PopupTickerProvider extends TickerProvider {
  Ticker? _ticker;
  bool _disposed = false;

  /// Whether the ticker is still active (not disposed).
  bool get isActive => !_disposed && _ticker != null && _ticker!.isActive;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _ticker = Ticker(onTick);
    return _ticker!;
  }

  void dispose() {
    _disposed = true;
    _ticker?.dispose();
  }
}

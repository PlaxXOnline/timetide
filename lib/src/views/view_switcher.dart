import 'package:flutter/widgets.dart';

import '../core/controller.dart';
import '../core/models/view.dart';

/// Transition style used by [TideViewSwitcher] when animating between views.
enum TideViewTransition {
  /// Cross-fade between views.
  fade,

  /// Slide the new view in from the right.
  slide,

  /// Scale the new view in from the center.
  scale,

  /// No transition animation.
  none,
}

/// Animates between calendar views based on [TideController.currentViewNotifier].
///
/// Listens to the controller's current view and dispatches to the correct view
/// widget returned by [viewBuilder]. Uses a custom transition animation
/// (without Material dependencies).
class TideViewSwitcher extends StatefulWidget {
  /// Creates a [TideViewSwitcher].
  const TideViewSwitcher({
    super.key,
    required this.controller,
    required this.viewBuilder,
    this.transition = TideViewTransition.fade,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  /// The controller whose [TideController.currentViewNotifier] drives view
  /// switching.
  final TideController controller;

  /// Builds the widget for a given [TideView].
  ///
  /// This function is called whenever the current view changes. Return the
  /// appropriate view widget for each [TideView] value.
  final Widget Function(BuildContext context, TideView view) viewBuilder;

  /// The transition style to use when switching views.
  final TideViewTransition transition;

  /// Duration of the transition animation.
  final Duration duration;

  /// Curve of the transition animation.
  final Curve curve;

  @override
  State<TideViewSwitcher> createState() => _TideViewSwitcherState();
}

class _TideViewSwitcherState extends State<TideViewSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  TideView? _previousView;
  Widget? _previousChild;
  Widget? _currentChild;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.curve,
    );
    _animationController.value = 1.0;

    widget.controller.currentViewNotifier.addListener(_onViewChanged);
  }

  @override
  void didUpdateWidget(TideViewSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.currentViewNotifier.removeListener(_onViewChanged);
      widget.controller.currentViewNotifier.addListener(_onViewChanged);
    }
    if (oldWidget.duration != widget.duration) {
      _animationController.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    widget.controller.currentViewNotifier.removeListener(_onViewChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onViewChanged() {
    final newView = widget.controller.currentView;
    if (newView == _previousView) return;

    _previousView = newView;

    if (widget.transition == TideViewTransition.none) {
      setState(() {
        _previousChild = null;
        _currentChild = null;
      });
      return;
    }

    setState(() {
      _previousChild = _currentChild;
      _currentChild = null;
    });

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final currentView = widget.controller.currentView;
    _currentChild ??= KeyedSubtree(
      key: ValueKey(currentView),
      child: widget.viewBuilder(context, currentView),
    );

    if (widget.transition == TideViewTransition.none ||
        _previousChild == null) {
      return _currentChild!;
    }

    return Semantics(
      label: 'Calendar view: ${currentView.name}',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Previous view (fading out).
              if (_previousChild != null && _animation.value < 1.0)
                _buildTransitionOut(_previousChild!),
              // Current view (fading in).
              _buildTransitionIn(_currentChild!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransitionIn(Widget child) {
    switch (widget.transition) {
      case TideViewTransition.fade:
        return Opacity(
          opacity: _animation.value,
          child: child,
        );
      case TideViewTransition.slide:
        return FractionalTranslation(
          translation: Offset(1.0 - _animation.value, 0),
          child: child,
        );
      case TideViewTransition.scale:
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      case TideViewTransition.none:
        return child;
    }
  }

  Widget _buildTransitionOut(Widget child) {
    switch (widget.transition) {
      case TideViewTransition.fade:
        return Opacity(
          opacity: 1.0 - _animation.value,
          child: child,
        );
      case TideViewTransition.slide:
        return FractionalTranslation(
          translation: Offset(-_animation.value, 0),
          child: child,
        );
      case TideViewTransition.scale:
        return Transform.scale(
          scale: 1.0 + (_animation.value * 0.1),
          child: Opacity(
            opacity: 1.0 - _animation.value,
            child: child,
          ),
        );
      case TideViewTransition.none:
        return child;
    }
  }
}

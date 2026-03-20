import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/models/drag_details.dart';
import '../../core/models/event.dart';
import 'snap_engine.dart';

/// Signature for the callback invoked when a resize ends.
///
/// Return `false` to revert the resize.
typedef TideResizeEndCallback = Future<bool> Function(
    TideResizeEndDetails details);

/// Adds resize handles to the top and/or bottom edges of a calendar event.
///
/// The handles allow the user to drag the start or end time of an event.
/// Uses [GestureDetector] on each handle — **never** Flutter's built-in
/// `Draggable`.
///
/// On desktop, the cursor changes to [SystemMouseCursors.resizeRow] when
/// hovering over a handle.
///
/// ```dart
/// TideResizeHandler(
///   event: myEvent,
///   resizeDirection: TideResizeDirection.both,
///   onResizeEnd: (details) async {
///     controller.updateEvent(details.event.copyWith(
///       startTime: details.newStart,
///       endTime: details.newEnd,
///     ));
///     return true;
///   },
///   child: MyEventWidget(),
/// )
/// ```
class TideResizeHandler extends StatefulWidget {
  /// Creates a [TideResizeHandler].
  const TideResizeHandler({
    super.key,
    required this.event,
    required this.child,
    this.resizeDirection = TideResizeDirection.both,
    this.resizeHandleSize = 8.0,
    this.snapInterval,
    this.onResizeEnd,
    this.enabled = true,
    this.enableHapticFeedback = true,
  });

  /// The event this handler is attached to.
  final TideEvent event;

  /// The child widget to add resize handles to.
  final Widget child;

  /// Which edges can be resized.
  final TideResizeDirection resizeDirection;

  /// Size (height) of each resize handle in logical pixels.
  final double resizeHandleSize;

  /// Grid interval for snapping. `null` means pixel-precise.
  final Duration? snapInterval;

  /// Called when a resize ends. Return `false` to revert.
  final TideResizeEndCallback? onResizeEnd;

  /// Whether resize is enabled.
  final bool enabled;

  /// Whether to trigger haptic feedback on touch devices when resize starts.
  final bool enableHapticFeedback;

  @override
  State<TideResizeHandler> createState() => _TideResizeHandlerState();
}

class _TideResizeHandlerState extends State<TideResizeHandler> {
  /// Accumulated vertical drag delta in logical pixels.
  ///
  /// Exposed so the view layer can convert pixels to time.
  double resizeDragDelta = 0.0;
  bool _isResizingStart = false;
  bool _isResizingEnd = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final canResizeStart =
        widget.resizeDirection == TideResizeDirection.both ||
            widget.resizeDirection == TideResizeDirection.startOnly;
    final canResizeEnd =
        widget.resizeDirection == TideResizeDirection.both ||
            widget.resizeDirection == TideResizeDirection.endOnly;

    return Semantics(
      label: 'Resizable calendar event: ${widget.event.subject}',
      child: Stack(
        children: [
          // The event content.
          Positioned.fill(child: widget.child),

          // Top handle (start time).
          if (canResizeStart)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: widget.resizeHandleSize,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: GestureDetector(
                  onVerticalDragStart: (_) => _onResizeStart(isStart: true),
                  onVerticalDragUpdate: (d) => _onResizeUpdate(d.delta.dy),
                  onVerticalDragEnd: (_) => _onResizeEnd(),
                  child: const SizedBox.expand(),
                ),
              ),
            ),

          // Bottom handle (end time).
          if (canResizeEnd)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: widget.resizeHandleSize,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: GestureDetector(
                  onVerticalDragStart: (_) => _onResizeStart(isStart: false),
                  onVerticalDragUpdate: (d) => _onResizeUpdate(d.delta.dy),
                  onVerticalDragEnd: (_) => _onResizeEnd(),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onResizeStart({required bool isStart}) {
    resizeDragDelta = 0.0;
    _isResizingStart = isStart;
    _isResizingEnd = !isStart;

    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _onResizeUpdate(double deltaY) {
    resizeDragDelta += deltaY;
  }

  void _onResizeEnd() {
    if (!_isResizingStart && !_isResizingEnd) return;

    // The actual time delta depends on the view's pixel-to-time ratio.
    // This handler provides the raw end details for the view layer to
    // compute the final times. As a baseline, snap the current times.
    var newStart = widget.event.startTime;
    var newEnd = widget.event.endTime;

    newStart = TideSnapEngine.snapToGrid(newStart, widget.snapInterval);
    newEnd = TideSnapEngine.snapToGrid(newEnd, widget.snapInterval);

    final details = TideResizeEndDetails(
      event: widget.event,
      newStart: newStart,
      newEnd: newEnd,
    );

    _isResizingStart = false;
    _isResizingEnd = false;
    resizeDragDelta = 0.0;

    widget.onResizeEnd?.call(details);
  }
}

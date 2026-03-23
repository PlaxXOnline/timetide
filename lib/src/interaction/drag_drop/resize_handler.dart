import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/models/drag_details.dart';
import '../../core/models/event.dart';
import 'snap_engine.dart';
import 'time_axis.dart';

/// Signature for the callback invoked when a resize ends.
///
/// Return `false` to revert the resize.
typedef TideResizeEndCallback = Future<bool> Function(
    TideResizeEndDetails details);

/// Adds resize handles to the top and/or bottom edges of a calendar event
/// (or leading/trailing edges for horizontal timeline views).
///
/// The handles allow the user to drag the start or end time of an event.
/// Uses [GestureDetector] on each handle — **never** Flutter's built-in
/// `Draggable`.
///
/// On desktop, the cursor changes to [SystemMouseCursors.resizeRow] (vertical)
/// or [SystemMouseCursors.resizeColumn] (horizontal) when hovering over a
/// handle.
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
    this.timeAxis,
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

  /// The time axis used to convert pixel deltas to time deltas.
  /// When null, the handler reports the event's original times
  /// (backward-compatible).
  final TideTimeAxis? timeAxis;

  /// Which edges can be resized.
  final TideResizeDirection resizeDirection;

  /// Size (height or width) of each resize handle in logical pixels.
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
  /// Accumulated drag delta in logical pixels along the time axis.
  ///
  /// Exposed so the view layer can convert pixels to time.
  double resizeDragDelta = 0.0;
  bool _isResizingStart = false;
  bool _isResizingEnd = false;

  /// Whether the time axis flows horizontally.
  bool get _isHorizontal =>
      widget.timeAxis != null &&
      widget.timeAxis!.direction == Axis.horizontal;

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

    final resizeCursor = _isHorizontal
        ? SystemMouseCursors.resizeColumn
        : SystemMouseCursors.resizeRow;

    return Semantics(
      label: 'Resizable calendar event: ${widget.event.subject}',
      child: Stack(
        children: [
          // The event content.
          Positioned.fill(child: widget.child),

          // Start handle (top for vertical, left for horizontal).
          if (canResizeStart)
            _isHorizontal
                ? Positioned(
                    top: 0,
                    left: 0,
                    bottom: 0,
                    width: widget.resizeHandleSize,
                    child: _buildHandle(resizeCursor, isStart: true),
                  )
                : Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: widget.resizeHandleSize,
                    child: _buildHandle(resizeCursor, isStart: true),
                  ),

          // End handle (bottom for vertical, right for horizontal).
          if (canResizeEnd)
            _isHorizontal
                ? Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: widget.resizeHandleSize,
                    child: _buildHandle(resizeCursor, isStart: false),
                  )
                : Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: widget.resizeHandleSize,
                    child: _buildHandle(resizeCursor, isStart: false),
                  ),
        ],
      ),
    );
  }

  Widget _buildHandle(MouseCursor cursor, {required bool isStart}) {
    if (_isHorizontal) {
      return MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          onHorizontalDragStart: (_) => _onResizeStart(isStart: isStart),
          onHorizontalDragUpdate: (d) => _onResizeUpdate(d.delta.dx),
          onHorizontalDragEnd: (_) => _onResizeEnd(),
          child: const SizedBox.expand(),
        ),
      );
    }
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        onVerticalDragStart: (_) => _onResizeStart(isStart: isStart),
        onVerticalDragUpdate: (d) => _onResizeUpdate(d.delta.dy),
        onVerticalDragEnd: (_) => _onResizeEnd(),
        child: const SizedBox.expand(),
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

  void _onResizeUpdate(double delta) {
    resizeDragDelta += delta;
  }

  void _onResizeEnd() {
    if (!_isResizingStart && !_isResizingEnd) return;

    var newStart = widget.event.startTime;
    var newEnd = widget.event.endTime;

    if (widget.timeAxis != null) {
      // Convert pixel delta to time delta.
      // Use the event's edge as the reference point.
      if (_isResizingStart) {
        final startPixel = widget.timeAxis!.timeToPixel(widget.event.startTime);
        final newStartTime = widget.timeAxis!.pixelToTime(startPixel + resizeDragDelta);
        newStart = newStartTime;
      }
      if (_isResizingEnd) {
        final endPixel = widget.timeAxis!.timeToPixel(widget.event.endTime);
        final newEndTime = widget.timeAxis!.pixelToTime(endPixel + resizeDragDelta);
        newEnd = newEndTime;
      }
    }

    newStart = TideSnapEngine.snapToGrid(newStart, widget.snapInterval);
    newEnd = TideSnapEngine.snapToGrid(newEnd, widget.snapInterval);

    // Prevent inverted range.
    if (newEnd.isBefore(newStart) || newEnd.isAtSameMomentAs(newStart)) {
      final minDuration = widget.snapInterval ?? const Duration(minutes: 15);
      if (_isResizingStart) {
        newStart = newEnd.subtract(minDuration);
      } else {
        newEnd = newStart.add(minDuration);
      }
    }

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

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/drag_details.dart';
import '../../core/models/event.dart';
import 'conflict_detector.dart';
import 'resize_handler.dart' show TideResizeEndCallback;
import 'snap_engine.dart';
import 'time_axis.dart';

/// Signature for the callback invoked when a drag starts.
typedef TideDragStartCallback = void Function(TideEvent event, Offset offset);

/// Signature for the callback invoked on every drag update.
typedef TideDragUpdateCallback = void Function(
    TideDragUpdateDetails details);

/// Signature for the callback invoked when a drag ends.
///
/// Return `false` to trigger a snap-back animation (the event returns to its
/// original position).
typedef TideDragEndCallback = Future<bool> Function(
    TideDragEndDetails details);

/// Signature for a predicate that determines whether a drop is allowed at
/// the given position.
typedef TideCanDropPredicate = bool Function(
    TideEvent event, DateTime proposedStart, DateTime proposedEnd,
    {String? proposedResourceId});

/// Internal mode for distinguishing move vs resize gestures.
enum _DragMode {
  /// No active gesture.
  none,

  /// Moving the entire event.
  move,

  /// Resizing the start edge (top for vertical, left for horizontal).
  resizeStart,

  /// Resizing the end edge (bottom for vertical, right for horizontal).
  resizeEnd,
}

/// Platform-adaptive drag handler for calendar events.
///
/// Uses [GestureDetector] + [Listener] + [Overlay] for a fully custom drag
/// implementation. **Never** uses Flutter's `Draggable`/`DragTarget`.
///
/// Wraps a child widget and makes it draggable. During drag, a semi-transparent
/// ghost preview follows the pointer via an [OverlayEntry] (when [showGhost]
/// is true).
///
/// When [allowResize] is true, touches near the start/end edges of the event
/// initiate a resize instead of a move. This eliminates the gesture-arena
/// conflict that occurs when a separate [TideResizeHandler] wraps this widget.
///
/// ```dart
/// TideDragHandler(
///   event: myEvent,
///   controller: controller,
///   dragStartBehavior: TideDragStartBehavior.adaptive,
///   allowResize: true,
///   onDragEnd: (details) async {
///     controller.updateEvent(details.event.copyWith(
///       startTime: details.newStart,
///       endTime: details.newEnd,
///     ));
///     return true;
///   },
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
class TideDragHandler extends StatefulWidget {
  /// Creates a [TideDragHandler].
  const TideDragHandler({
    super.key,
    required this.event,
    required this.controller,
    required this.child,
    this.timeAxis,
    this.sourceResourceId,
    this.dragStartBehavior = TideDragStartBehavior.adaptive,
    this.snapInterval,
    this.onTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.canDropAt,
    this.existingEvents = const [],
    this.ghostBuilder,
    this.enabled = true,
    this.enableHapticFeedback = true,
    this.showGhost = true,
    this.longPressDuration = const Duration(milliseconds: 300),
    this.allowResize = false,
    this.resizeHandleSize = 8.0,
    this.resizeDirection = TideResizeDirection.both,
    this.onResizeEnd,
  });

  /// The event this handler is attached to.
  final TideEvent event;

  /// The calendar controller (used for multi-select drag).
  final TideController controller;

  /// The child widget to make draggable.
  final Widget child;

  /// The time axis used to convert pixel positions to times.
  /// Required for proper time-based drag. When null, the handler
  /// reports the event's original times (backward-compatible).
  final TideTimeAxis? timeAxis;

  /// The resource ID this event is displayed in.
  ///
  /// Passed through to [TideDragEndDetails.sourceResourceId] so the app
  /// layer can perform a targeted resource replacement instead of
  /// overwriting all resource assignments.
  final String? sourceResourceId;

  /// Determines when the drag gesture begins.
  final TideDragStartBehavior dragStartBehavior;

  /// Grid interval for snapping. `null` means pixel-precise.
  final Duration? snapInterval;

  /// Called when the event is tapped (not dragged).
  ///
  /// When provided, the handler's [GestureDetector] handles both tap and
  /// drag gestures, avoiding the need for a nested [GestureDetector] on the
  /// child widget. This eliminates gesture-arena conflicts.
  final VoidCallback? onTap;

  /// Called when a drag starts.
  final TideDragStartCallback? onDragStart;

  /// Called on every drag update.
  final TideDragUpdateCallback? onDragUpdate;

  /// Called when a drag ends. Return `false` for snap-back.
  final TideDragEndCallback? onDragEnd;

  /// Business-rule predicate for drop validation.
  final TideCanDropPredicate? canDropAt;

  /// Other events used for live conflict detection.
  final List<TideEvent> existingEvents;

  /// Optional builder for the ghost preview widget.
  /// Receives the event and should return the ghost widget.
  final Widget Function(TideEvent event)? ghostBuilder;

  /// Whether drag is enabled.
  final bool enabled;

  /// Whether to trigger haptic feedback on mobile when drag starts.
  final bool enableHapticFeedback;

  /// Whether to show a floating ghost overlay during drag.
  ///
  /// When `false`, the view should handle visual feedback itself via the
  /// [onDragUpdate] callback (e.g. by repositioning the event tile to the
  /// proposed snap slot).
  final bool showGhost;

  /// Duration before a long press is recognized.
  ///
  /// Defaults to 300 ms for a snappier feel compared to Flutter's 500 ms
  /// default.
  final Duration longPressDuration;

  /// Whether resize is enabled.
  ///
  /// When true, touches near the start/end edges of the event initiate a
  /// resize instead of a move. This merges resize handling into the drag
  /// handler to avoid gesture-arena conflicts with a separate resize widget.
  final bool allowResize;

  /// Size of the resize handles in logical pixels.
  ///
  /// Defines how many pixels from each edge count as the resize zone.
  final double resizeHandleSize;

  /// Which edges can be resized when [allowResize] is true.
  final TideResizeDirection resizeDirection;

  /// Called when a resize operation completes.
  final TideResizeEndCallback? onResizeEnd;

  @override
  State<TideDragHandler> createState() => _TideDragHandlerState();
}

class _TideDragHandlerState extends State<TideDragHandler> {
  OverlayEntry? _ghostEntry;
  /// The global position where the drag started. Exposed so the view layer
  /// can compute the pixel delta for time mapping.
  Offset dragStartOffset = Offset.zero;
  Offset _currentDragOffset = Offset.zero;
  bool _isDragging = false;

  /// The current gesture mode — move or resize.
  _DragMode _dragMode = _DragMode.none;

  /// The current mouse cursor shown over the widget.
  MouseCursor _currentCursor = SystemMouseCursors.basic;

  /// Accumulated resize delta in logical pixels along the time axis.
  double _resizeDragDelta = 0.0;

  /// Previous drag position, used to compute incremental deltas for resize.
  Offset _previousDragPosition = Offset.zero;

  /// Whether a Ctrl/Meta key is held (for copy-drag on desktop).
  ///
  /// Exposed to the view layer so it can differentiate move vs. copy.
  bool isCopyDrag = false;

  /// The original event start time captured at drag start.
  ///
  /// Used instead of [widget.event.startTime] to avoid a double-delta bug:
  /// when the view replaces the event with a display copy at the proposed
  /// (snapped) position, [widget.event.startTime] changes every frame.
  /// Adding the cumulative drag delta to that already-adjusted time would
  /// double the movement, causing the event to fly away or oscillate.
  DateTime? _originalStartTime;

  /// The original event end time captured at drag start. See [_originalStartTime].
  DateTime? _originalEndTime;

  @override
  void dispose() {
    _removeGhost();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Semantics(
        label: 'Calendar event: ${widget.event.subject}',
        child: widget.child,
      );
    }

    final useLongPress =
        widget.dragStartBehavior == TideDragStartBehavior.longPress ||
            (widget.dragStartBehavior == TideDragStartBehavior.adaptive &&
                _isTouchDevice(context));

    Widget child = Semantics(
      label: 'Draggable calendar event: ${widget.event.subject}',
      hint: useLongPress
          ? 'Long press and drag to move'
          : 'Drag to move',
      child: widget.child,
    );

    // Wrap with Listener to detect keyboard modifiers on desktop.
    child = Listener(
      onPointerDown: _onPointerDown,
      child: child,
    );

    Widget result;
    if (useLongPress) {
      // Use RawGestureDetector with a custom long-press duration so we can
      // make the activation faster than Flutter's default 500 ms.
      result = RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(
              duration: widget.longPressDuration,
            ),
            (LongPressGestureRecognizer recognizer) {
              recognizer
                ..onLongPressStart = _onLongPressStart
                ..onLongPressMoveUpdate = _onLongPressMoveUpdate
                ..onLongPressEnd = _onLongPressEnd;
            },
          ),
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(),
            (TapGestureRecognizer recognizer) {
              recognizer.onTap = widget.onTap;
            },
          ),
        },
        child: child,
      );
    } else {
      result = GestureDetector(
        onTap: widget.onTap,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: child,
      );
    }

    // Add cursor feedback for resize handles on desktop/pointer devices.
    if (widget.allowResize && widget.timeAxis != null) {
      return MouseRegion(
        cursor: _currentCursor,
        onHover: (event) => _updateCursorForPosition(event.localPosition),
        onExit: (_) {
          if (_currentCursor != SystemMouseCursors.basic) {
            setState(() {
              _currentCursor = SystemMouseCursors.basic;
            });
          }
        },
        child: result,
      );
    }

    return result;
  }

  // ─── Pointer Handling ───────────────────────────────────

  void _onPointerDown(PointerDownEvent event) {
    // Detect Ctrl key for copy-drag on desktop.
    isCopyDrag = event.buttons == kPrimaryButton &&
        (HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.controlLeft) ||
            HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.controlRight) ||
            HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.metaLeft) ||
            HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.metaRight));
  }

  // ─── Cursor Feedback ────────────────────────────────────

  /// Updates [_currentCursor] based on the hover position relative to the
  /// resize handle zones. No-op during active drag to avoid interfering.
  void _updateCursorForPosition(Offset localPosition) {
    if (!widget.allowResize || widget.timeAxis == null || _isDragging) {
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final isVertical = widget.timeAxis!.direction == Axis.vertical;
    final pos = isVertical ? localPosition.dy : localPosition.dx;
    final length = isVertical ? size.height : size.width;

    final canResizeStart =
        widget.resizeDirection == TideResizeDirection.both ||
            widget.resizeDirection == TideResizeDirection.startOnly;
    final canResizeEnd =
        widget.resizeDirection == TideResizeDirection.both ||
            widget.resizeDirection == TideResizeDirection.endOnly;

    MouseCursor newCursor = SystemMouseCursors.basic;

    if (canResizeStart && pos <= widget.resizeHandleSize) {
      newCursor = isVertical
          ? SystemMouseCursors.resizeRow
          : SystemMouseCursors.resizeColumn;
    } else if (canResizeEnd && pos >= length - widget.resizeHandleSize) {
      newCursor = isVertical
          ? SystemMouseCursors.resizeRow
          : SystemMouseCursors.resizeColumn;
    }

    if (newCursor != _currentCursor) {
      setState(() {
        _currentCursor = newCursor;
      });
    }
  }

  // ─── Long Press Gesture (mobile / longPress mode) ──────

  void _onLongPressStart(LongPressStartDetails details) {
    _startDrag(details.globalPosition);
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _updateDrag(details.globalPosition);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    debugPrint('[HANDLER] _onLongPressEnd called');
    _endDrag(details.globalPosition);
  }

  // ─── Pan Gesture (desktop / immediate mode) ────────────

  void _onPanStart(DragStartDetails details) {
    _startDrag(details.globalPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _updateDrag(details.globalPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    debugPrint('[HANDLER] _onPanEnd called');
    _endDrag(_currentDragOffset);
  }

  // ─── Drag Lifecycle ────────────────────────────────────

  void _startDrag(Offset globalPosition) {
    if (_isDragging) return;

    // Determine drag mode based on where the touch landed.
    _dragMode = _resolveDragMode(globalPosition);

    _isDragging = true;
    dragStartOffset = globalPosition;
    _currentDragOffset = globalPosition;
    _previousDragPosition = globalPosition;
    _resizeDragDelta = 0.0;
    _originalStartTime = widget.event.startTime;
    _originalEndTime = widget.event.endTime;

    // Haptic feedback on touch devices.
    if (widget.enableHapticFeedback && _isTouchDevice(context)) {
      if (_dragMode == _DragMode.move) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }

    if (_dragMode == _DragMode.move) {
      widget.onDragStart?.call(widget.event, globalPosition);
      if (widget.showGhost) {
        _insertGhost();
      }
    } else {
      // Resize — notify view so it can track the resizing event.
      widget.onDragStart?.call(widget.event, globalPosition);
    }
  }

  /// Determines whether the touch position is on a resize handle edge or
  /// in the move zone (center).
  _DragMode _resolveDragMode(Offset globalPosition) {
    if (!widget.allowResize || widget.timeAxis == null) {
      return _DragMode.move;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return _DragMode.move;

    final local = renderBox.globalToLocal(globalPosition);
    final size = renderBox.size;
    final isVertical = widget.timeAxis!.direction == Axis.vertical;
    final pos = isVertical ? local.dy : local.dx;
    final length = isVertical ? size.height : size.width;

    final canResizeStart =
        widget.resizeDirection == TideResizeDirection.both ||
            widget.resizeDirection == TideResizeDirection.startOnly;
    final canResizeEnd =
        widget.resizeDirection == TideResizeDirection.both ||
            widget.resizeDirection == TideResizeDirection.endOnly;

    if (canResizeStart && pos <= widget.resizeHandleSize) {
      return _DragMode.resizeStart;
    }
    if (canResizeEnd && pos >= length - widget.resizeHandleSize) {
      return _DragMode.resizeEnd;
    }

    return _DragMode.move;
  }

  void _updateDrag(Offset globalPosition) {
    if (!_isDragging) return;
    _currentDragOffset = globalPosition;

    if (_dragMode == _DragMode.move) {
      _updateMoveDrag(globalPosition);
    } else {
      // Resize mode — accumulate delta along the time axis.
      if (widget.timeAxis != null) {
        final delta = globalPosition - _previousDragPosition;
        _resizeDragDelta += widget.timeAxis!.direction == Axis.vertical
            ? delta.dy
            : delta.dx;
      }
      _updateResizeFeedback();
    }

    _previousDragPosition = globalPosition;
  }

  void _updateMoveDrag(Offset globalPosition) {
    if (widget.showGhost) {
      _updateGhostPosition();
    }

    // Convert pixel delta to time delta using the time axis.
    DateTime proposedStart;
    DateTime proposedEnd;

    if (widget.timeAxis != null) {
      final axis = widget.timeAxis!;

      // Compute delta from RAW GLOBAL positions — these are stable and
      // don't depend on the event tile's current position (which moves
      // during snap-to-slot, causing oscillation if we used globalToLocal).
      final globalDelta = globalPosition - dragStartOffset;
      final pixelDelta = axis.offsetToPixel(globalDelta);

      // Convert pixel delta to time delta using two reference points.
      // Since pixelToTime is linear, pixelToTime(d) - pixelToTime(0)
      // gives us the exact Duration for d pixels.
      final baseTime = axis.pixelToTime(0);
      final deltaTime = axis.pixelToTime(pixelDelta);
      final delta = deltaTime.difference(baseTime);

      proposedStart = _originalStartTime!.add(delta);
      proposedEnd = _originalEndTime!.add(delta);
    } else {
      proposedStart = _originalStartTime ?? widget.event.startTime;
      proposedEnd = _originalEndTime ?? widget.event.endTime;
    }

    // Apply snap during update for live feedback.
    proposedStart = TideSnapEngine.snapToGrid(proposedStart, widget.snapInterval);
    proposedEnd = TideSnapEngine.snapToGrid(proposedEnd, widget.snapInterval);

    final conflicts = TideConflictDetector.detectConflicts(
      draggedEvent: widget.event,
      proposedStart: proposedStart,
      proposedEnd: proposedEnd,
      existingEvents: widget.existingEvents,
    );

    widget.onDragUpdate?.call(TideDragUpdateDetails(
      event: widget.event,
      proposedStart: proposedStart,
      conflicts: conflicts.map((c) => c.eventB).toList(),
      globalPosition: globalPosition,
    ));
  }

  void _updateResizeFeedback() {
    if (widget.timeAxis == null) return;

    final originalStart = _originalStartTime ?? widget.event.startTime;
    final originalEnd = _originalEndTime ?? widget.event.endTime;
    var proposedStart = originalStart;
    var proposedEnd = originalEnd;

    if (_dragMode == _DragMode.resizeStart) {
      final startPixel = widget.timeAxis!.timeToPixel(originalStart);
      proposedStart =
          widget.timeAxis!.pixelToTime(startPixel + _resizeDragDelta);
      proposedStart =
          TideSnapEngine.snapToGrid(proposedStart, widget.snapInterval);
    } else if (_dragMode == _DragMode.resizeEnd) {
      final endPixel = widget.timeAxis!.timeToPixel(originalEnd);
      proposedEnd =
          widget.timeAxis!.pixelToTime(endPixel + _resizeDragDelta);
      proposedEnd =
          TideSnapEngine.snapToGrid(proposedEnd, widget.snapInterval);
    }

    // Prevent inverted range.
    if (proposedEnd.isBefore(proposedStart) ||
        proposedEnd.isAtSameMomentAs(proposedStart)) {
      final minDuration =
          widget.snapInterval ?? const Duration(minutes: 15);
      if (_dragMode == _DragMode.resizeStart) {
        proposedStart = proposedEnd.subtract(minDuration);
      } else {
        proposedEnd = proposedStart.add(minDuration);
      }
    }

    widget.onDragUpdate?.call(TideDragUpdateDetails(
      event: widget.event,
      proposedStart: proposedStart,
      proposedEnd: proposedEnd,
      globalPosition: _currentDragOffset,
    ));
  }

  void _endDrag(Offset globalPosition) {
    debugPrint('[HANDLER] _endDrag called, _isDragging=$_isDragging, _dragMode=$_dragMode');
    if (!_isDragging) return;
    _isDragging = false;

    if (_dragMode == _DragMode.move) {
      _endMoveDrag(globalPosition);
    } else {
      _endResizeDrag();
    }

    _dragMode = _DragMode.none;
    _originalStartTime = null;
    _originalEndTime = null;
  }

  void _endMoveDrag(Offset globalPosition) {
    _removeGhost();

    DateTime proposedStart;
    DateTime proposedEnd;

    if (widget.timeAxis != null) {
      final axis = widget.timeAxis!;

      // Compute delta from RAW GLOBAL positions — these are stable and
      // don't depend on the event tile's current position (which moves
      // during snap-to-slot, causing oscillation if we used globalToLocal).
      final globalDelta = globalPosition - dragStartOffset;
      final pixelDelta = axis.offsetToPixel(globalDelta);

      // Convert pixel delta to time delta using two reference points.
      // Since pixelToTime is linear, pixelToTime(d) - pixelToTime(0)
      // gives us the exact Duration for d pixels.
      final baseTime = axis.pixelToTime(0);
      final deltaTime = axis.pixelToTime(pixelDelta);
      final delta = deltaTime.difference(baseTime);

      proposedStart = _originalStartTime!.add(delta);
      proposedEnd = _originalEndTime!.add(delta);
    } else {
      proposedStart = _originalStartTime ?? widget.event.startTime;
      proposedEnd = _originalEndTime ?? widget.event.endTime;
    }

    // Snap to grid.
    proposedStart = TideSnapEngine.snapToGrid(proposedStart, widget.snapInterval);
    proposedEnd = TideSnapEngine.snapToGrid(proposedEnd, widget.snapInterval);

    // Validate drop.
    if (widget.canDropAt != null &&
        !widget.canDropAt!(widget.event, proposedStart, proposedEnd)) {
      return;
    }

    widget.onDragEnd?.call(TideDragEndDetails(
      event: widget.event,
      newStart: proposedStart,
      newEnd: proposedEnd,
      sourceResourceId: widget.sourceResourceId,
      dropPosition: globalPosition,
    ));
  }

  void _endResizeDrag() {
    final originalStart = _originalStartTime ?? widget.event.startTime;
    final originalEnd = _originalEndTime ?? widget.event.endTime;
    var newStart = originalStart;
    var newEnd = originalEnd;

    if (widget.timeAxis != null) {
      if (_dragMode == _DragMode.resizeStart) {
        final startPixel = widget.timeAxis!.timeToPixel(originalStart);
        newStart = widget.timeAxis!.pixelToTime(startPixel + _resizeDragDelta);
      } else {
        final endPixel = widget.timeAxis!.timeToPixel(originalEnd);
        newEnd = widget.timeAxis!.pixelToTime(endPixel + _resizeDragDelta);
      }
    }

    newStart = TideSnapEngine.snapToGrid(newStart, widget.snapInterval);
    newEnd = TideSnapEngine.snapToGrid(newEnd, widget.snapInterval);

    // Prevent inverted range.
    if (newEnd.isBefore(newStart) || newEnd.isAtSameMomentAs(newStart)) {
      final minDuration = widget.snapInterval ?? const Duration(minutes: 15);
      if (_dragMode == _DragMode.resizeStart) {
        newStart = newEnd.subtract(minDuration);
      } else {
        newEnd = newStart.add(minDuration);
      }
    }

    widget.onResizeEnd?.call(TideResizeEndDetails(
      event: widget.event,
      newStart: newStart,
      newEnd: newEnd,
    ));
  }

  // ─── Ghost Overlay ─────────────────────────────────────

  void _insertGhost() {
    _removeGhost();
    _ghostEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: _currentDragOffset.dx - 40,
          top: _currentDragOffset.dy - 20,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.5,
              child: widget.ghostBuilder?.call(widget.event) ??
                  _DefaultDragGhost(event: widget.event),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_ghostEntry!);
  }

  void _updateGhostPosition() {
    _ghostEntry?.markNeedsBuild();
  }

  void _removeGhost() {
    _ghostEntry?.remove();
    _ghostEntry?.dispose();
    _ghostEntry = null;
  }

  // ─── Helpers ───────────────────────────────────────────

  /// Heuristic: touch device if the platform default pointer device kind
  /// indicates touch. This is a simplified check; views can override
  /// [dragStartBehavior] explicitly.
  static bool _isTouchDevice(BuildContext context) {
    final platform = WidgetsBinding.instance.platformDispatcher;
    // Use display size heuristic: devices with density > 2 are typically mobile.
    final display = platform.displays.firstOrNull;
    if (display == null) return false;
    return display.devicePixelRatio > 2.0;
  }
}

/// A minimal default ghost widget shown during drag when no custom
/// [ghostBuilder] is provided.
class _DefaultDragGhost extends StatelessWidget {
  const _DefaultDragGhost({required this.event});

  final TideEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: event.color ?? const Color(0xFF2196F3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        event.subject,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 13,
        ),
      ),
    );
  }
}

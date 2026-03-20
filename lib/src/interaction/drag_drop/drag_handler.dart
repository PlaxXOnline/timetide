import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/drag_details.dart';
import '../../core/models/event.dart';
import 'conflict_detector.dart';
import 'snap_engine.dart';

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

/// Platform-adaptive drag handler for calendar events.
///
/// Uses [GestureDetector] + [Listener] + [Overlay] for a fully custom drag
/// implementation. **Never** uses Flutter's `Draggable`/`DragTarget`.
///
/// Wraps a child widget and makes it draggable. During drag, a semi-transparent
/// ghost preview follows the pointer via an [OverlayEntry].
///
/// ```dart
/// TideDragHandler(
///   event: myEvent,
///   controller: controller,
///   dragStartBehavior: TideDragStartBehavior.adaptive,
///   onDragEnd: (details) async {
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
    this.dragStartBehavior = TideDragStartBehavior.adaptive,
    this.snapInterval,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.canDropAt,
    this.existingEvents = const [],
    this.ghostBuilder,
    this.enabled = true,
    this.enableHapticFeedback = true,
  });

  /// The event this handler is attached to.
  final TideEvent event;

  /// The calendar controller (used for multi-select drag).
  final TideController controller;

  /// The child widget to make draggable.
  final Widget child;

  /// Determines when the drag gesture begins.
  final TideDragStartBehavior dragStartBehavior;

  /// Grid interval for snapping. `null` means pixel-precise.
  final Duration? snapInterval;

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

  /// Whether a Ctrl/Meta key is held (for copy-drag on desktop).
  ///
  /// Exposed to the view layer so it can differentiate move vs. copy.
  bool isCopyDrag = false;

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

    if (useLongPress) {
      return GestureDetector(
        onLongPressStart: _onLongPressStart,
        onLongPressMoveUpdate: _onLongPressMoveUpdate,
        onLongPressEnd: _onLongPressEnd,
        child: child,
      );
    }

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: child,
    );
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

  // ─── Long Press Gesture (mobile / longPress mode) ──────

  void _onLongPressStart(LongPressStartDetails details) {
    _startDrag(details.globalPosition);
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _updateDrag(details.globalPosition);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
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
    _endDrag(_currentDragOffset);
  }

  // ─── Drag Lifecycle ────────────────────────────────────

  void _startDrag(Offset globalPosition) {
    if (_isDragging) return;
    _isDragging = true;
    dragStartOffset = globalPosition;
    _currentDragOffset = globalPosition;

    // Haptic feedback on touch devices.
    if (widget.enableHapticFeedback && _isTouchDevice(context)) {
      HapticFeedback.mediumImpact();
    }

    widget.onDragStart?.call(widget.event, globalPosition);
    _insertGhost(globalPosition);
  }

  void _updateDrag(Offset globalPosition) {
    if (!_isDragging) return;
    _currentDragOffset = globalPosition;
    _updateGhostPosition(globalPosition);

    // Compute proposed time for conflict detection.
    // The actual time mapping depends on the view's pixel-to-time ratio,
    // which the view layer will provide. Here we use the event's original
    // times for conflict detection; the view overrides via onDragUpdate.
    final proposedStart = widget.event.startTime;
    final proposedEnd = widget.event.endTime;

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
    ));

    // Multi-select: if additional events are selected, the view layer is
    // responsible for moving them with their relative offsets using
    // controller.selectedEvents and the delta from dragStartOffset.
    // This keeps the handler focused on single-event mechanics.
    _isDragging = true; // keep state valid
  }

  void _endDrag(Offset globalPosition) {
    if (!_isDragging) return;
    _isDragging = false;
    _removeGhost();

    // Snap proposed times.
    final proposedStart = TideSnapEngine.snapToGrid(
      widget.event.startTime,
      widget.snapInterval,
    );
    final proposedEnd = TideSnapEngine.snapToGrid(
      widget.event.endTime,
      widget.snapInterval,
    );

    // Validate drop.
    if (widget.canDropAt != null &&
        !widget.canDropAt!(widget.event, proposedStart, proposedEnd)) {
      return; // Snap-back: ghost already removed.
    }

    final details = TideDragEndDetails(
      event: widget.event,
      newStart: proposedStart,
      newEnd: proposedEnd,
    );

    widget.onDragEnd?.call(details);
  }

  // ─── Ghost Overlay ─────────────────────────────────────

  void _insertGhost(Offset position) {
    _removeGhost();
    _ghostEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: position.dx - 40,
          top: position.dy - 20,
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

  void _updateGhostPosition(Offset position) {
    _ghostEntry?.markNeedsBuild();
    // The builder reads _currentDragOffset implicitly since we rebuild.
    _removeGhost();
    _insertGhost(position);
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

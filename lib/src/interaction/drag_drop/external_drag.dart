import 'package:flutter/widgets.dart';

import '../../core/models/drag_details.dart';

/// Signature for the callback invoked when an external item is dropped
/// onto the calendar.
typedef TideExternalDragEndCallback = void Function(
    TideExternalDragEndDetails details);

/// Wraps a child widget to make it draggable onto a [TideDragTarget].
///
/// Carries a [TideExternalDragData] payload that the target receives on drop.
/// Uses [Listener] for custom pointer tracking — **never** Flutter's
/// `Draggable`.
///
/// ```dart
/// TideDragSource(
///   data: TideExternalDragData(
///     subject: 'Meeting',
///     duration: Duration(hours: 1),
///   ),
///   child: Text('Drag me onto calendar'),
/// )
/// ```
class TideDragSource extends StatefulWidget {
  /// Creates a [TideDragSource].
  const TideDragSource({
    super.key,
    required this.data,
    required this.child,
    this.feedbackBuilder,
    this.enabled = true,
  });

  /// The data payload to deliver on drop.
  final TideExternalDragData data;

  /// The child widget that can be dragged.
  final Widget child;

  /// Optional builder for the drag feedback widget shown under the pointer.
  final Widget Function(TideExternalDragData data)? feedbackBuilder;

  /// Whether this source is enabled for dragging.
  final bool enabled;

  @override
  State<TideDragSource> createState() => _TideDragSourceState();
}

class _TideDragSourceState extends State<TideDragSource> {
  OverlayEntry? _feedbackEntry;
  bool _isDragging = false;

  @override
  void dispose() {
    _removeFeedback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Semantics(
      label: 'Draggable item: ${widget.data.subject}',
      hint: 'Drag onto the calendar to create an event',
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: widget.child,
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    // Intentionally empty — drag starts on first move.
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDragging) {
      // Start drag after a small movement threshold.
      _isDragging = true;
      _insertFeedback(event.position);
    } else {
      _updateFeedbackPosition(event.position);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isDragging) {
      _isDragging = false;
      _removeFeedback();
      // The actual drop handling is done by TideDragTarget via
      // _TideDragTargetState — it listens for the active source data
      // through the inherited notification mechanism.
      _TideExternalDragNotification(data: widget.data, position: event.position)
          .dispatch(context);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _isDragging = false;
    _removeFeedback();
  }

  void _insertFeedback(Offset position) {
    _removeFeedback();
    _feedbackEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: position.dx - 30,
        top: position.dy - 15,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.7,
            child: widget.feedbackBuilder?.call(widget.data) ??
                _DefaultExternalDragFeedback(data: widget.data),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_feedbackEntry!);
  }

  void _updateFeedbackPosition(Offset position) {
    // Rebuild the overlay entry at the new position.
    _removeFeedback();
    _insertFeedback(position);
  }

  void _removeFeedback() {
    _feedbackEntry?.remove();
    _feedbackEntry?.dispose();
    _feedbackEntry = null;
  }
}

/// A calendar slot that accepts drops from [TideDragSource].
///
/// ```dart
/// TideDragTarget(
///   dropTime: DateTime(2024, 1, 1, 10, 0),
///   onExternalDragEnd: (details) {
///     controller.addEvent(TideEvent(
///       id: uuid(),
///       subject: details.data.subject,
///       startTime: details.dropTime,
///       endTime: details.dropTime.add(details.data.duration),
///     ));
///   },
///   child: TimeSlotWidget(),
/// )
/// ```
class TideDragTarget extends StatelessWidget {
  /// Creates a [TideDragTarget].
  const TideDragTarget({
    super.key,
    required this.dropTime,
    required this.child,
    this.dropResourceId,
    this.onExternalDragEnd,
  });

  /// The time this target slot represents.
  final DateTime dropTime;

  /// The resource this target belongs to, if any.
  final String? dropResourceId;

  /// Called when an external item is dropped here.
  final TideExternalDragEndCallback? onExternalDragEnd;

  /// The child widget for this target area.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<_TideExternalDragNotification>(
      onNotification: (notification) {
        onExternalDragEnd?.call(TideExternalDragEndDetails(
          data: notification.data,
          dropTime: dropTime,
          dropResourceId: dropResourceId,
        ));
        return true;
      },
      child: child,
    );
  }
}

/// Internal notification dispatched by [TideDragSource] on pointer up.
class _TideExternalDragNotification extends Notification {
  const _TideExternalDragNotification({
    required this.data,
    required this.position,
  });

  final TideExternalDragData data;
  final Offset position;
}

/// Default feedback widget for external drags.
class _DefaultExternalDragFeedback extends StatelessWidget {
  const _DefaultExternalDragFeedback({required this.data});

  final TideExternalDragData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: data.color ?? const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        data.subject,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 13,
        ),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

import '../../core/models/drag_details.dart';

/// Signature for the callback invoked when an external item is dropped
/// onto the calendar.
typedef TideExternalDragEndCallback = void Function(
    TideExternalDragEndDetails details);

/// Provides a communication channel for external drag operations.
///
/// Wrap both [TideDragSource] and [TideDragTarget] descendants in a
/// [TideExternalDragScope] so they can communicate regardless of their
/// position in the widget tree.
class TideExternalDragScope extends StatefulWidget {
  const TideExternalDragScope({super.key, required this.child});
  final Widget child;

  /// Returns the nearest [TideExternalDragNotifier] or null.
  static TideExternalDragNotifier? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_TideExternalDragInherited>()
        ?.notifier;
  }

  @override
  State<TideExternalDragScope> createState() => _TideExternalDragScopeState();
}

class _TideExternalDragScopeState extends State<TideExternalDragScope> {
  final TideExternalDragNotifier _notifier = TideExternalDragNotifier();

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _TideExternalDragInherited(
      notifier: _notifier,
      child: widget.child,
    );
  }
}

/// Notifier carrying the latest external drag drop event.
class TideExternalDragNotifier extends ChangeNotifier {
  TideExternalDragData? _data;
  Offset? _position;

  TideExternalDragData? get data => _data;
  Offset? get position => _position;

  void drop(TideExternalDragData data, Offset position) {
    _data = data;
    _position = position;
    notifyListeners();
    // Clear after notification cycle.
    _data = null;
    _position = null;
  }
}

class _TideExternalDragInherited
    extends InheritedNotifier<TideExternalDragNotifier> {
  const _TideExternalDragInherited({
    required super.notifier,
    required super.child,
  });
}

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
      // Use shared notifier instead of Notification.dispatch.
      final scope = TideExternalDragScope.of(context);
      scope?.drop(widget.data, event.position);
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
class TideDragTarget extends StatefulWidget {
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
  State<TideDragTarget> createState() => _TideDragTargetState();
}

class _TideDragTargetState extends State<TideDragTarget> {
  TideExternalDragNotifier? _notifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newNotifier = TideExternalDragScope.of(context);
    if (newNotifier != _notifier) {
      _notifier?.removeListener(_onDrop);
      _notifier = newNotifier;
      _notifier?.addListener(_onDrop);
    }
  }

  @override
  void dispose() {
    _notifier?.removeListener(_onDrop);
    super.dispose();
  }

  void _onDrop() {
    final data = _notifier?.data;
    final position = _notifier?.position;
    if (data == null || position == null) return;

    // Hit test: only handle if the drop position is within this target.
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPos = renderBox.globalToLocal(position);
    if (!renderBox.paintBounds.contains(localPos)) return;

    widget.onExternalDragEnd?.call(TideExternalDragEndDetails(
      data: data,
      dropTime: widget.dropTime,
      dropResourceId: widget.dropResourceId,
    ));
  }

  @override
  Widget build(BuildContext context) => widget.child;
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

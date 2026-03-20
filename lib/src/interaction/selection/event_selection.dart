import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/event.dart';

/// Manages event selection logic for the calendar.
///
/// Supports single select (tap), additive multi-select (Ctrl+Click),
/// range select (Shift+Click), and deselect (tap on empty area).
///
/// Wrap a calendar event widget with [buildEventDetector] to enable selection,
/// or call the methods directly from custom gesture callbacks.
class TideEventSelectionHandler {
  /// Creates a [TideEventSelectionHandler].
  ///
  /// [controller] is the calendar controller whose selection state is managed.
  /// [allEvents] provides the ordered list of all visible events, used for
  /// range selection.
  TideEventSelectionHandler({
    required this.controller,
    required this.allEvents,
  });

  /// The calendar controller managing selection state.
  final TideController controller;

  /// Ordered list of all visible events (for range selection).
  final List<TideEvent> allEvents;

  TideEvent? _lastSelectedEvent;

  /// Handles a tap on an event.
  ///
  /// - Default tap: replaces selection with [event].
  /// - With [isAdditive] (Ctrl+Click): toggles [event] in the selection.
  /// - With [isRange] (Shift+Click): selects all events between the last
  ///   selected event and [event] (inclusive).
  void handleEventTap(
    TideEvent event, {
    bool isAdditive = false,
    bool isRange = false,
  }) {
    if (isRange && _lastSelectedEvent != null) {
      _selectRange(_lastSelectedEvent!, event);
      return;
    }

    if (isAdditive) {
      controller.selectEvent(event, additive: true);
    } else {
      controller.selectEvent(event);
    }
    _lastSelectedEvent = event;
  }

  /// Handles a tap on an empty area — deselects all events and dates.
  void handleEmptyTap() {
    controller.deselectAll();
    _lastSelectedEvent = null;
  }

  void _selectRange(TideEvent from, TideEvent to) {
    final fromIndex = allEvents.indexOf(from);
    final toIndex = allEvents.indexOf(to);
    if (fromIndex == -1 || toIndex == -1) {
      // Fallback to single selection when range boundaries are not found.
      controller.selectEvent(to);
      _lastSelectedEvent = to;
      return;
    }

    final start = fromIndex < toIndex ? fromIndex : toIndex;
    final end = fromIndex < toIndex ? toIndex : fromIndex;
    final rangeEvents = allEvents.sublist(start, end + 1);

    // Replace selection with the range.
    controller.deselectAll();
    for (final e in rangeEvents) {
      controller.selectEvent(e, additive: true);
    }
    _lastSelectedEvent = to;
  }

  /// Wraps [child] with a [GestureDetector] that handles selection on tap.
  ///
  /// Detects Ctrl and Shift modifier keys on desktop platforms.
  Widget buildEventDetector({
    required TideEvent event,
    required Widget child,
  }) {
    return _TideEventSelectionDetector(
      handler: this,
      event: event,
      child: child,
    );
  }

  /// Wraps [child] with a [GestureDetector] that deselects on tap.
  Widget buildEmptyAreaDetector({required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: handleEmptyTap,
      child: child,
    );
  }
}

class _TideEventSelectionDetector extends StatelessWidget {
  const _TideEventSelectionDetector({
    required this.handler,
    required this.event,
    required this.child,
  });

  final TideEventSelectionHandler handler;
  final TideEvent event;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final isCtrl = HardwareKeyboard.instance.logicalKeysPressed.any(
          (key) =>
              key == LogicalKeyboardKey.controlLeft ||
              key == LogicalKeyboardKey.controlRight ||
              key == LogicalKeyboardKey.metaLeft ||
              key == LogicalKeyboardKey.metaRight,
        );
        final isShift = HardwareKeyboard.instance.logicalKeysPressed.any(
          (key) =>
              key == LogicalKeyboardKey.shiftLeft ||
              key == LogicalKeyboardKey.shiftRight,
        );
        handler.handleEventTap(
          event,
          isAdditive: isCtrl,
          isRange: isShift,
        );
      },
      child: Semantics(
        button: true,
        label: 'Select event: ${event.subject}',
        child: child,
      ),
    );
  }
}

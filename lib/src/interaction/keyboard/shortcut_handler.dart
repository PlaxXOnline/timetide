import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/view.dart';

/// Widget that wraps the calendar with keyboard shortcut handling.
///
/// Uses Flutter's [Shortcuts] + [Actions] system (from `widgets.dart`).
///
/// Default shortcuts:
/// - Arrow Left/Right: navigate dates
/// - Arrow Up/Down: navigate events
/// - T: jump to today
/// - 1-9: switch view
/// - Ctrl+Z / Cmd+Z: undo
/// - Shift+Ctrl+Z / Shift+Cmd+Z: redo
/// - Ctrl+N / Cmd+N: new event
/// - Delete/Backspace: delete selected events
/// - Escape: deselect all
/// - +/−: zoom in/out
/// - Tab: focus traversal (handled by Flutter's focus system)
/// - Enter: open event
class TideShortcutHandler extends StatelessWidget {
  /// Creates a [TideShortcutHandler].
  ///
  /// [controller] drives navigation, view switching, and undo.
  /// Callbacks are invoked for actions that require user-provided logic
  /// (new event, delete, open).
  const TideShortcutHandler({
    super.key,
    required this.controller,
    required this.child,
    this.onNewEvent,
    this.onDeleteSelected,
    this.onOpenEvent,
    this.onNavigateEvents,
    this.customShortcuts,
    this.enabled = true,
  });

  /// The calendar controller.
  final TideController controller;

  /// The child widget (calendar body).
  final Widget child;

  /// Called when Ctrl+N / Cmd+N is pressed.
  final VoidCallback? onNewEvent;

  /// Called when Delete/Backspace is pressed with selected events.
  final VoidCallback? onDeleteSelected;

  /// Called when Enter is pressed on a focused/selected event.
  final VoidCallback? onOpenEvent;

  /// Called when Arrow Up/Down is pressed.
  /// Parameter is the direction: -1 for up, +1 for down.
  final void Function(int direction)? onNavigateEvents;

  /// Additional user-defined shortcuts that extend or override defaults.
  final Map<ShortcutActivator, VoidCallback>? customShortcuts;

  /// Whether shortcuts are active.
  final bool enabled;

  /// View map: keys 1-9 map to [TideView] values.
  static const _viewKeys = <int, TideView>{
    1: TideView.day,
    2: TideView.week,
    3: TideView.workWeek,
    4: TideView.month,
    5: TideView.schedule,
    6: TideView.timelineDay,
    7: TideView.timelineWeek,
    8: TideView.timelineWorkWeek,
    9: TideView.timelineMonth,
  };

  Map<ShortcutActivator, Intent> _buildShortcuts() {
    final shortcuts = <ShortcutActivator, Intent>{
      // Navigation
      const SingleActivator(LogicalKeyboardKey.arrowLeft):
          const _TideNavigateBackwardIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowRight):
          const _TideNavigateForwardIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowUp):
          const _TideNavigateEventIntent(-1),
      const SingleActivator(LogicalKeyboardKey.arrowDown):
          const _TideNavigateEventIntent(1),

      // Today
      const SingleActivator(LogicalKeyboardKey.keyT): const _TideTodayIntent(),

      // Undo / Redo
      const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
          const _TideUndoIntent(),
      const SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
          const _TideUndoIntent(),
      const SingleActivator(LogicalKeyboardKey.keyZ,
          control: true, shift: true): const _TideRedoIntent(),
      const SingleActivator(LogicalKeyboardKey.keyZ,
          meta: true, shift: true): const _TideRedoIntent(),

      // New event
      const SingleActivator(LogicalKeyboardKey.keyN, control: true):
          const _TideNewEventIntent(),
      const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
          const _TideNewEventIntent(),

      // Delete
      const SingleActivator(LogicalKeyboardKey.delete):
          const _TideDeleteIntent(),
      const SingleActivator(LogicalKeyboardKey.backspace):
          const _TideDeleteIntent(),

      // Escape
      const SingleActivator(LogicalKeyboardKey.escape):
          const _TideDeselectAllIntent(),

      // Zoom
      const SingleActivator(LogicalKeyboardKey.equal): // + key
          const _TideZoomInIntent(),
      const SingleActivator(LogicalKeyboardKey.minus):
          const _TideZoomOutIntent(),

      // Open event
      const SingleActivator(LogicalKeyboardKey.enter):
          const _TideOpenEventIntent(),
    };

    // View switching: keys 1-9
    const digitKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    for (final entry in _viewKeys.entries) {
      final key = digitKeys[entry.key - 1];
      shortcuts[SingleActivator(key)] = _TideSwitchViewIntent(entry.value);
    }

    // Custom shortcuts override defaults.
    if (customShortcuts != null) {
      for (final entry in customShortcuts!.entries) {
        shortcuts[entry.key] = _TideCustomCallbackIntent(entry.value);
      }
    }

    return shortcuts;
  }

  Map<Type, Action<Intent>> _buildActions() {
    return {
      _TideNavigateBackwardIntent: CallbackAction<_TideNavigateBackwardIntent>(
        onInvoke: (_) {
          controller.backward();
          return null;
        },
      ),
      _TideNavigateForwardIntent: CallbackAction<_TideNavigateForwardIntent>(
        onInvoke: (_) {
          controller.forward();
          return null;
        },
      ),
      _TideNavigateEventIntent: CallbackAction<_TideNavigateEventIntent>(
        onInvoke: (intent) {
          onNavigateEvents?.call(intent.direction);
          return null;
        },
      ),
      _TideTodayIntent: CallbackAction<_TideTodayIntent>(
        onInvoke: (_) {
          controller.today();
          return null;
        },
      ),
      _TideSwitchViewIntent: CallbackAction<_TideSwitchViewIntent>(
        onInvoke: (intent) {
          controller.currentView = intent.view;
          return null;
        },
      ),
      _TideUndoIntent: CallbackAction<_TideUndoIntent>(
        onInvoke: (_) {
          controller.undo();
          return null;
        },
      ),
      _TideRedoIntent: CallbackAction<_TideRedoIntent>(
        onInvoke: (_) {
          controller.redo();
          return null;
        },
      ),
      _TideNewEventIntent: CallbackAction<_TideNewEventIntent>(
        onInvoke: (_) {
          onNewEvent?.call();
          return null;
        },
      ),
      _TideDeleteIntent: CallbackAction<_TideDeleteIntent>(
        onInvoke: (_) {
          onDeleteSelected?.call();
          return null;
        },
      ),
      _TideDeselectAllIntent: CallbackAction<_TideDeselectAllIntent>(
        onInvoke: (_) {
          controller.deselectAll();
          return null;
        },
      ),
      _TideZoomInIntent: CallbackAction<_TideZoomInIntent>(
        onInvoke: (_) {
          controller.zoomLevel += 0.1;
          return null;
        },
      ),
      _TideZoomOutIntent: CallbackAction<_TideZoomOutIntent>(
        onInvoke: (_) {
          controller.zoomLevel -= 0.1;
          return null;
        },
      ),
      _TideOpenEventIntent: CallbackAction<_TideOpenEventIntent>(
        onInvoke: (_) {
          onOpenEvent?.call();
          return null;
        },
      ),
      _TideCustomCallbackIntent: CallbackAction<_TideCustomCallbackIntent>(
        onInvoke: (intent) {
          intent.callback();
          return null;
        },
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Shortcuts(
      shortcuts: _buildShortcuts(),
      child: Actions(
        actions: _buildActions(),
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

// ─── Intent classes ──────────────────────────────────────

class _TideNavigateBackwardIntent extends Intent {
  const _TideNavigateBackwardIntent();
}

class _TideNavigateForwardIntent extends Intent {
  const _TideNavigateForwardIntent();
}

class _TideNavigateEventIntent extends Intent {
  const _TideNavigateEventIntent(this.direction);
  final int direction;
}

class _TideTodayIntent extends Intent {
  const _TideTodayIntent();
}

class _TideSwitchViewIntent extends Intent {
  const _TideSwitchViewIntent(this.view);
  final TideView view;
}

class _TideUndoIntent extends Intent {
  const _TideUndoIntent();
}

class _TideRedoIntent extends Intent {
  const _TideRedoIntent();
}

class _TideNewEventIntent extends Intent {
  const _TideNewEventIntent();
}

class _TideDeleteIntent extends Intent {
  const _TideDeleteIntent();
}

class _TideDeselectAllIntent extends Intent {
  const _TideDeselectAllIntent();
}

class _TideZoomInIntent extends Intent {
  const _TideZoomInIntent();
}

class _TideZoomOutIntent extends Intent {
  const _TideZoomOutIntent();
}

class _TideOpenEventIntent extends Intent {
  const _TideOpenEventIntent();
}

class _TideCustomCallbackIntent extends Intent {
  const _TideCustomCallbackIntent(this.callback);
  final VoidCallback callback;
}

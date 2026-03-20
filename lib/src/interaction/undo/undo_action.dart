import '../../core/models/event.dart';

/// Abstract base class for undo-able calendar actions.
///
/// Each subclass stores the pre-mutation state so that [revert] can restore it
/// and [execute] can re-apply it (for redo).
abstract class TideUndoAction {
  /// Applies (or re-applies) this action.
  void execute();

  /// Reverts this action to its pre-mutation state.
  void revert();

  /// Human-readable label for this action (used in UI undo history).
  String get label;
}

/// Undo action for adding an event.
///
/// [execute] adds the event; [revert] removes it.
class TideAddEventAction extends TideUndoAction {
  /// Creates a [TideAddEventAction].
  TideAddEventAction({
    required this.event,
    required this.onExecute,
    required this.onRevert,
  });

  /// The event that was added.
  final TideEvent event;

  /// Callback that adds the event (called on execute/redo).
  final void Function(TideEvent event) onExecute;

  /// Callback that removes the event (called on undo).
  final void Function(String eventId) onRevert;

  @override
  void execute() => onExecute(event);

  @override
  void revert() => onRevert(event.id);

  @override
  String get label => 'Add "${event.subject}"';
}

/// Undo action for updating an event.
///
/// [execute] applies the new version; [revert] restores the previous version.
class TideUpdateEventAction extends TideUndoAction {
  /// Creates a [TideUpdateEventAction].
  TideUpdateEventAction({
    required this.previousEvent,
    required this.updatedEvent,
    required this.onApply,
  });

  /// The event state before the update.
  final TideEvent previousEvent;

  /// The event state after the update.
  final TideEvent updatedEvent;

  /// Callback that applies a given event version.
  final void Function(TideEvent event) onApply;

  @override
  void execute() => onApply(updatedEvent);

  @override
  void revert() => onApply(previousEvent);

  @override
  String get label => 'Update "${updatedEvent.subject}"';
}

/// Undo action for removing an event.
///
/// [execute] removes the event; [revert] re-adds it.
class TideRemoveEventAction extends TideUndoAction {
  /// Creates a [TideRemoveEventAction].
  TideRemoveEventAction({
    required this.event,
    required this.onExecute,
    required this.onRevert,
  });

  /// The event that was removed.
  final TideEvent event;

  /// Callback that removes the event (called on execute/redo).
  final void Function(String eventId) onExecute;

  /// Callback that re-adds the event (called on undo).
  final void Function(TideEvent event) onRevert;

  @override
  void execute() => onExecute(event.id);

  @override
  void revert() => onRevert(event);

  @override
  String get label => 'Remove "${event.subject}"';
}

import 'package:flutter/foundation.dart';

import 'undo_action.dart';

/// Standalone undo/redo stack management.
///
/// Maintains two stacks — undo and redo — and notifies listeners on changes.
/// Use [push] to record new actions, [undo] / [redo] to traverse the history.
///
/// ```dart
/// final manager = TideUndoManager(historyLimit: 50);
/// manager.push(myAction);
/// manager.undo(); // reverts myAction
/// manager.redo(); // re-applies myAction
/// ```
class TideUndoManager extends ChangeNotifier {
  /// Creates a [TideUndoManager].
  ///
  /// [historyLimit] caps the number of undo entries retained. When exceeded,
  /// the oldest entries are dropped.
  TideUndoManager({this.historyLimit = 50});

  /// Maximum number of undo entries to keep.
  final int historyLimit;

  final List<TideUndoAction> _undoStack = [];
  final List<TideUndoAction> _redoStack = [];

  /// Whether there is an action available to undo.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether there is an action available to redo.
  bool get canRedo => _redoStack.isNotEmpty;

  /// The number of actions on the undo stack.
  int get undoCount => _undoStack.length;

  /// The number of actions on the redo stack.
  int get redoCount => _redoStack.length;

  /// Pushes [action] onto the undo stack and clears the redo stack.
  ///
  /// If the undo stack exceeds [historyLimit], the oldest entry is dropped.
  void push(TideUndoAction action) {
    _undoStack.add(action);
    _redoStack.clear();
    while (_undoStack.length > historyLimit) {
      _undoStack.removeAt(0);
    }
    notifyListeners();
  }

  /// Undoes the most recent action.
  ///
  /// Pops from the undo stack, calls [TideUndoAction.revert], and pushes
  /// the action onto the redo stack. Returns the reverted action, or `null`
  /// if the undo stack was empty.
  TideUndoAction? undo() {
    if (!canUndo) return null;
    final action = _undoStack.removeLast();
    action.revert();
    _redoStack.add(action);
    notifyListeners();
    return action;
  }

  /// Redoes the most recently undone action.
  ///
  /// Pops from the redo stack, calls [TideUndoAction.execute], and pushes
  /// the action back onto the undo stack. Returns the re-applied action,
  /// or `null` if the redo stack was empty.
  TideUndoAction? redo() {
    if (!canRedo) return null;
    final action = _redoStack.removeLast();
    action.execute();
    _undoStack.add(action);
    notifyListeners();
    return action;
  }

  /// Clears both the undo and redo stacks.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}

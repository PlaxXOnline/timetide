import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/interaction/undo/undo_action.dart';
import 'package:timetide/src/interaction/undo/undo_manager.dart';

/// Simple tracking action for tests.
class _TrackingAction extends TideUndoAction {
  _TrackingAction(this.label);

  @override
  final String label;

  int executeCount = 0;
  int revertCount = 0;

  @override
  void execute() => executeCount++;

  @override
  void revert() => revertCount++;
}

void main() {
  group('TideUndoManager', () {
    late TideUndoManager manager;

    setUp(() {
      manager = TideUndoManager(historyLimit: 5);
    });

    test('initially has no undo/redo', () {
      expect(manager.canUndo, isFalse);
      expect(manager.canRedo, isFalse);
      expect(manager.undoCount, 0);
      expect(manager.redoCount, 0);
    });

    test('push adds to undo stack', () {
      final action = _TrackingAction('test');
      manager.push(action);
      expect(manager.canUndo, isTrue);
      expect(manager.canRedo, isFalse);
      expect(manager.undoCount, 1);
    });

    test('undo pops from undo and pushes to redo', () {
      final action = _TrackingAction('test');
      manager.push(action);

      final result = manager.undo();
      expect(result, same(action));
      expect(action.revertCount, 1);
      expect(manager.canUndo, isFalse);
      expect(manager.canRedo, isTrue);
      expect(manager.redoCount, 1);
    });

    test('redo pops from redo and pushes to undo', () {
      final action = _TrackingAction('test');
      manager.push(action);
      manager.undo();

      final result = manager.redo();
      expect(result, same(action));
      expect(action.executeCount, 1);
      expect(manager.canUndo, isTrue);
      expect(manager.canRedo, isFalse);
    });

    test('undo returns null when stack is empty', () {
      expect(manager.undo(), isNull);
    });

    test('redo returns null when stack is empty', () {
      expect(manager.redo(), isNull);
    });

    test('push clears redo stack', () {
      manager.push(_TrackingAction('a'));
      manager.undo();
      expect(manager.canRedo, isTrue);

      manager.push(_TrackingAction('b'));
      expect(manager.canRedo, isFalse);
      expect(manager.redoCount, 0);
    });

    test('respects history limit', () {
      for (var i = 0; i < 10; i++) {
        manager.push(_TrackingAction('action $i'));
      }
      // Limit is 5, so only the last 5 remain.
      expect(manager.undoCount, 5);
    });

    test('clear empties both stacks', () {
      manager.push(_TrackingAction('a'));
      manager.push(_TrackingAction('b'));
      manager.undo();
      expect(manager.canUndo, isTrue);
      expect(manager.canRedo, isTrue);

      manager.clear();
      expect(manager.canUndo, isFalse);
      expect(manager.canRedo, isFalse);
    });

    test('notifies listeners on push', () {
      var notified = false;
      manager.addListener(() => notified = true);
      manager.push(_TrackingAction('a'));
      expect(notified, isTrue);
    });

    test('notifies listeners on undo', () {
      manager.push(_TrackingAction('a'));
      var notified = false;
      manager.addListener(() => notified = true);
      manager.undo();
      expect(notified, isTrue);
    });

    test('notifies listeners on redo', () {
      manager.push(_TrackingAction('a'));
      manager.undo();
      var notified = false;
      manager.addListener(() => notified = true);
      manager.redo();
      expect(notified, isTrue);
    });

    test('multiple undo/redo cycle works correctly', () {
      final a = _TrackingAction('a');
      final b = _TrackingAction('b');
      final c = _TrackingAction('c');

      manager.push(a);
      manager.push(b);
      manager.push(c);

      expect(manager.undo(), same(c));
      expect(manager.undo(), same(b));
      expect(manager.redo(), same(b));
      expect(manager.redo(), same(c));
      expect(manager.undoCount, 3);
      expect(manager.redoCount, 0);
    });
  });

  group('TideUndoAction subclasses', () {
    test('TideAddEventAction execute adds, revert removes', () {
      final event = TideEvent(
        id: '1',
        subject: 'Meeting',
        startTime: DateTime(2024, 1, 1, 9),
        endTime: DateTime(2024, 1, 1, 10),
      );
      String? removedId;
      TideEvent? addedEvent;

      final action = TideAddEventAction(
        event: event,
        onExecute: (e) => addedEvent = e,
        onRevert: (id) => removedId = id,
      );

      action.execute();
      expect(addedEvent, same(event));

      action.revert();
      expect(removedId, '1');
      expect(action.label, contains('Meeting'));
    });

    test('TideUpdateEventAction execute applies new, revert restores old', () {
      final oldEvent = TideEvent(
        id: '1',
        subject: 'Old',
        startTime: DateTime(2024, 1, 1, 9),
        endTime: DateTime(2024, 1, 1, 10),
      );
      final newEvent = oldEvent.copyWith(subject: 'New');
      TideEvent? applied;

      final action = TideUpdateEventAction(
        previousEvent: oldEvent,
        updatedEvent: newEvent,
        onApply: (e) => applied = e,
      );

      action.execute();
      expect(applied!.subject, 'New');

      action.revert();
      expect(applied!.subject, 'Old');
      expect(action.label, contains('New'));
    });

    test('TideRemoveEventAction execute removes, revert re-adds', () {
      final event = TideEvent(
        id: '1',
        subject: 'Deleted',
        startTime: DateTime(2024, 1, 1, 9),
        endTime: DateTime(2024, 1, 1, 10),
      );
      String? removedId;
      TideEvent? restored;

      final action = TideRemoveEventAction(
        event: event,
        onExecute: (id) => removedId = id,
        onRevert: (e) => restored = e,
      );

      action.execute();
      expect(removedId, '1');

      action.revert();
      expect(restored, same(event));
      expect(action.label, contains('Deleted'));
    });
  });
}

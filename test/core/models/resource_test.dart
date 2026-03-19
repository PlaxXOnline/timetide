import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/resource.dart';

void main() {
  const red = Color(0xFFFF0000);
  const blue = Color(0xFF0000FF);

  group('TideResource construction', () {
    test('required fields only', () {
      const resource = TideResource(
        id: 'r1',
        displayName: 'Alice',
        color: red,
      );
      expect(resource.id, 'r1');
      expect(resource.displayName, 'Alice');
      expect(resource.color, red);
      expect(resource.avatar, isNull);
      expect(resource.sortOrder, 0);
      expect(resource.groupId, isNull);
      expect(resource.metadata, isNull);
    });

    test('all fields populated', () {
      final resource = TideResource(
        id: 'r2',
        displayName: 'Bob',
        color: blue,
        avatar: const NetworkImage('https://example.com/avatar.png'),
        sortOrder: 5,
        groupId: 'grp-1',
        metadata: {'role': 'lead'},
      );
      expect(resource.sortOrder, 5);
      expect(resource.groupId, 'grp-1');
      expect(resource.metadata, {'role': 'lead'});
    });

    test('default sortOrder is 0', () {
      const resource = TideResource(id: 'r3', displayName: 'Carol', color: red);
      expect(resource.sortOrder, 0);
    });
  });

  group('TideResource copyWith', () {
    test('returns new instance with changed field', () {
      const original = TideResource(id: 'r1', displayName: 'Alice', color: red);
      final copy = original.copyWith(displayName: 'Alicia', color: blue);
      expect(copy.displayName, 'Alicia');
      expect(copy.color, blue);
      expect(copy.id, 'r1');
    });
  });

  group('TideResource equality', () {
    test('same id — equal', () {
      const a = TideResource(id: 'r1', displayName: 'Alice', color: red);
      const b = TideResource(id: 'r1', displayName: 'Bob', color: blue);
      expect(a, equals(b));
    });

    test('different id — not equal', () {
      const a = TideResource(id: 'r1', displayName: 'Alice', color: red);
      const b = TideResource(id: 'r2', displayName: 'Alice', color: red);
      expect(a, isNot(equals(b)));
    });
  });

  group('TideResourceGroup construction', () {
    test('required fields', () {
      const group = TideResourceGroup(id: 'g1', displayName: 'Team Alpha');
      expect(group.id, 'g1');
      expect(group.displayName, 'Team Alpha');
    });

    test('default initiallyExpanded is true', () {
      const group = TideResourceGroup(id: 'g1', displayName: 'Team Alpha');
      expect(group.initiallyExpanded, isTrue);
    });

    test('initiallyExpanded can be set to false', () {
      const group = TideResourceGroup(
        id: 'g2',
        displayName: 'Team Beta',
        initiallyExpanded: false,
      );
      expect(group.initiallyExpanded, isFalse);
    });
  });

  group('TideResourceGroup copyWith', () {
    test('returns new instance with changed field', () {
      const original = TideResourceGroup(id: 'g1', displayName: 'Team Alpha');
      final copy = original.copyWith(displayName: 'Team Bravo', initiallyExpanded: false);
      expect(copy.displayName, 'Team Bravo');
      expect(copy.initiallyExpanded, isFalse);
      expect(copy.id, 'g1');
    });
  });

  group('TideResourceGroup equality', () {
    test('same id — equal', () {
      const a = TideResourceGroup(id: 'g1', displayName: 'Alpha');
      const b = TideResourceGroup(id: 'g1', displayName: 'Beta');
      expect(a, equals(b));
    });

    test('different id — not equal', () {
      const a = TideResourceGroup(id: 'g1', displayName: 'Alpha');
      const b = TideResourceGroup(id: 'g2', displayName: 'Alpha');
      expect(a, isNot(equals(b)));
    });
  });
}

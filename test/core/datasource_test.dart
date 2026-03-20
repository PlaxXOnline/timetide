import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/datasource.dart';
import 'package:timetide/src/core/datasource_in_memory.dart';
import 'package:timetide/src/core/datasource_stream.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/core/models/resource.dart';
import 'package:timetide/src/core/models/time_region.dart';

void main() {
  // ─── Helpers ──────────────────────────────────────────────

  final june1at9 = DateTime(2024, 6, 1, 9, 0);
  final june1at10 = DateTime(2024, 6, 1, 10, 0);
  final june2at9 = DateTime(2024, 6, 2, 9, 0);
  final june2at10 = DateTime(2024, 6, 2, 10, 0);
  final june3at9 = DateTime(2024, 6, 3, 9, 0);
  final june3at10 = DateTime(2024, 6, 3, 10, 0);

  TideEvent makeEvent({
    String id = 'evt-1',
    String subject = 'Meeting',
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return TideEvent(
      id: id,
      subject: subject,
      startTime: startTime ?? june1at9,
      endTime: endTime ?? june1at10,
    );
  }

  TideResource makeResource({
    String id = 'res-1',
    String displayName = 'Alice',
  }) {
    return TideResource(
      id: id,
      displayName: displayName,
      color: const Color(0xFF0000FF),
    );
  }

  TideTimeRegion makeRegion({
    String id = 'region-1',
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return TideTimeRegion(
      id: id,
      startTime: startTime ?? june1at9,
      endTime: endTime ?? june1at10,
    );
  }

  // ─── TideDatasourceChange sealed class ────────────────────

  group('TideDatasourceChange', () {
    test('EventsAdded holds events', () {
      final events = [makeEvent()];
      final change = EventsAdded(events);
      expect(change.events, events);
      expect(change, isA<TideDatasourceChange>());
    });

    test('EventsUpdated holds events', () {
      final events = [makeEvent()];
      final change = EventsUpdated(events);
      expect(change.events, events);
    });

    test('EventsRemoved holds event IDs', () {
      const change = EventsRemoved(['evt-1', 'evt-2']);
      expect(change.eventIds, ['evt-1', 'evt-2']);
    });

    test('ResourcesChanged is const-constructable', () {
      const change = ResourcesChanged();
      expect(change, isA<TideDatasourceChange>());
    });

    test('TimeRegionsChanged is const-constructable', () {
      const change = TimeRegionsChanged();
      expect(change, isA<TideDatasourceChange>());
    });

    test('FullReload is const-constructable', () {
      const change = FullReload();
      expect(change, isA<TideDatasourceChange>());
    });

    test('switch exhaustiveness over sealed subtypes', () {
      final changes = <TideDatasourceChange>[
        EventsAdded([makeEvent()]),
        EventsUpdated([makeEvent()]),
        const EventsRemoved(['evt-1']),
        const ResourcesChanged(),
        const TimeRegionsChanged(),
        const FullReload(),
      ];

      for (final change in changes) {
        // This switch must compile without a default case because the class
        // is sealed — verifying exhaustiveness.
        final label = switch (change) {
          EventsAdded() => 'added',
          EventsUpdated() => 'updated',
          EventsRemoved() => 'removed',
          ResourcesChanged() => 'resources',
          TimeRegionsChanged() => 'regions',
          FullReload() => 'reload',
        };
        expect(label, isNotEmpty);
      }
    });
  });

  // ─── TideInMemoryDatasource ──────────────────────────────

  group('TideInMemoryDatasource', () {
    late TideInMemoryDatasource datasource;

    setUp(() {
      datasource = TideInMemoryDatasource();
    });

    tearDown(() {
      datasource.dispose();
    });

    group('construction', () {
      test('empty by default', () async {
        final events = await datasource.getEvents(
          DateTime(2024),
          DateTime(2025),
        );
        expect(events, isEmpty);

        final resources = await datasource.getResources();
        expect(resources, isEmpty);

        final regions = await datasource.getTimeRegions(
          DateTime(2024),
          DateTime(2025),
        );
        expect(regions, isEmpty);
      });

      test('accepts initial data', () async {
        final ds = TideInMemoryDatasource(
          events: [makeEvent()],
          resources: [makeResource()],
          timeRegions: [makeRegion()],
        );
        addTearDown(ds.dispose);

        final events = await ds.getEvents(DateTime(2024), DateTime(2025));
        expect(events, hasLength(1));

        final resources = await ds.getResources();
        expect(resources, hasLength(1));

        final regions = await ds.getTimeRegions(
          DateTime(2024),
          DateTime(2025),
        );
        expect(regions, hasLength(1));
      });

      test('initial data is copied — external mutation does not affect', () async {
        final originalList = [makeEvent()];
        final ds = TideInMemoryDatasource(events: originalList);
        addTearDown(ds.dispose);

        originalList.clear();
        final events = await ds.getEvents(DateTime(2024), DateTime(2025));
        expect(events, hasLength(1));
      });
    });

    group('getEvents — date range filtering', () {
      test('returns events within range', () async {
        datasource.addEvent(makeEvent(
          id: 'e1',
          startTime: june1at9,
          endTime: june1at10,
        ));
        datasource.addEvent(makeEvent(
          id: 'e2',
          startTime: june2at9,
          endTime: june2at10,
        ));
        datasource.addEvent(makeEvent(
          id: 'e3',
          startTime: june3at9,
          endTime: june3at10,
        ));

        // Query only June 1-2
        final events = await datasource.getEvents(
          DateTime(2024, 6, 1),
          DateTime(2024, 6, 3),
        );
        expect(events.map((e) => e.id), containsAll(['e1', 'e2']));
      });

      test('excludes events entirely outside range', () async {
        datasource.addEvent(makeEvent(
          id: 'e1',
          startTime: june3at9,
          endTime: june3at10,
        ));

        final events = await datasource.getEvents(
          DateTime(2024, 6, 1),
          DateTime(2024, 6, 2),
        );
        expect(events, isEmpty);
      });

      test('includes events that overlap range boundaries', () async {
        // Event spans June 1 9:00 - June 2 10:00
        datasource.addEvent(makeEvent(
          id: 'spanning',
          startTime: june1at9,
          endTime: june2at10,
        ));

        // Query June 2 only
        final events = await datasource.getEvents(
          DateTime(2024, 6, 2),
          DateTime(2024, 6, 3),
        );
        expect(events, hasLength(1));
        expect(events.first.id, 'spanning');
      });
    });

    group('getTimeRegions — date range filtering', () {
      test('returns regions within range', () async {
        datasource.addTimeRegion(makeRegion(
          id: 'r1',
          startTime: june1at9,
          endTime: june1at10,
        ));
        datasource.addTimeRegion(makeRegion(
          id: 'r2',
          startTime: june3at9,
          endTime: june3at10,
        ));

        final regions = await datasource.getTimeRegions(
          DateTime(2024, 6, 1),
          DateTime(2024, 6, 2),
        );
        expect(regions, hasLength(1));
        expect(regions.first.id, 'r1');
      });
    });

    group('event mutations', () {
      test('addEvent emits EventsAdded', () async {
        final event = makeEvent();
        expectLater(
          datasource.changes,
          emits(isA<EventsAdded>()),
        );
        datasource.addEvent(event);
      });

      test('addEvents emits EventsAdded with all events', () async {
        final events = [
          makeEvent(id: 'a'),
          makeEvent(id: 'b'),
        ];
        expectLater(
          datasource.changes,
          emits(isA<EventsAdded>().having(
            (c) => c.events.length,
            'events.length',
            2,
          )),
        );
        datasource.addEvents(events);
      });

      test('addEvents with empty list does not emit', () async {
        var emitted = false;
        final sub = datasource.changes.listen((_) => emitted = true);
        datasource.addEvents([]);
        await Future<void>.delayed(Duration.zero);
        expect(emitted, isFalse);
        await sub.cancel();
      });

      test('updateEvent emits EventsUpdated', () async {
        final event = makeEvent(id: 'evt-1');
        datasource.addEvent(event);

        final updated = event.copyWith(subject: 'Updated');
        expectLater(
          datasource.changes,
          emitsThrough(isA<EventsUpdated>()),
        );
        datasource.updateEvent(updated);
      });

      test('updateEvent with unknown ID does not emit', () async {
        datasource.addEvent(makeEvent(id: 'evt-1'));

        // Wait for addEvent notification to be delivered, then start listening.
        await Future<void>.delayed(Duration.zero);
        final changeFuture = datasource.changes.toList();

        // Try to update a non-existent event
        datasource.updateEvent(makeEvent(id: 'nonexistent'));

        // Close to end the stream
        datasource.dispose();
        final changes = await changeFuture;

        // No additional changes should have been emitted
        expect(changes, isEmpty);
      });

      test('updateEvent replaces the event in storage', () async {
        datasource.addEvent(makeEvent(id: 'evt-1', subject: 'Original'));
        datasource.updateEvent(
          makeEvent(id: 'evt-1', subject: 'Modified'),
        );

        final events = await datasource.getEvents(
          DateTime(2024),
          DateTime(2025),
        );
        expect(events.first.subject, 'Modified');
      });

      test('removeEvent emits EventsRemoved', () async {
        datasource.addEvent(makeEvent(id: 'evt-1'));
        expectLater(
          datasource.changes,
          emitsThrough(isA<EventsRemoved>()),
        );
        datasource.removeEvent('evt-1');
      });

      test('removeEvent with unknown ID does not emit', () async {
        final changeFuture = datasource.changes.toList();
        datasource.removeEvent('nonexistent');
        datasource.dispose();
        final changes = await changeFuture;
        expect(changes, isEmpty);
      });

      test('removeEvent actually removes the event', () async {
        datasource.addEvent(makeEvent(id: 'evt-1'));
        datasource.removeEvent('evt-1');

        final events = await datasource.getEvents(
          DateTime(2024),
          DateTime(2025),
        );
        expect(events, isEmpty);
      });
    });

    group('resource mutations', () {
      test('addResource emits ResourcesChanged', () async {
        expectLater(
          datasource.changes,
          emits(isA<ResourcesChanged>()),
        );
        datasource.addResource(makeResource());
      });

      test('removeResource emits ResourcesChanged', () async {
        datasource.addResource(makeResource(id: 'res-1'));
        expectLater(
          datasource.changes,
          emitsThrough(isA<ResourcesChanged>()),
        );
        datasource.removeResource('res-1');
      });

      test('removeResource with unknown ID does not emit', () async {
        final changeFuture = datasource.changes.toList();
        datasource.removeResource('nonexistent');
        datasource.dispose();
        final changes = await changeFuture;
        expect(changes, isEmpty);
      });

      test('updateResource emits ResourcesChanged', () async {
        datasource.addResource(makeResource(id: 'res-1'));
        expectLater(
          datasource.changes,
          emitsThrough(isA<ResourcesChanged>()),
        );
        datasource.updateResource(
          makeResource(id: 'res-1', displayName: 'Updated'),
        );
      });

      test('updateResource with unknown ID does not emit', () async {
        final changeFuture = datasource.changes.toList();
        datasource.updateResource(makeResource(id: 'nonexistent'));
        datasource.dispose();
        final changes = await changeFuture;
        expect(changes, isEmpty);
      });

      test('updateResource replaces the resource', () async {
        datasource.addResource(makeResource(id: 'res-1', displayName: 'Old'));
        datasource.updateResource(
          makeResource(id: 'res-1', displayName: 'New'),
        );
        final resources = await datasource.getResources();
        expect(
          resources.firstWhere((r) => r.id == 'res-1').displayName,
          'New',
        );
      });
    });

    group('time region mutations', () {
      test('addTimeRegion emits TimeRegionsChanged', () async {
        expectLater(
          datasource.changes,
          emits(isA<TimeRegionsChanged>()),
        );
        datasource.addTimeRegion(makeRegion());
      });

      test('removeTimeRegion emits TimeRegionsChanged', () async {
        datasource.addTimeRegion(makeRegion(id: 'region-1'));
        expectLater(
          datasource.changes,
          emitsThrough(isA<TimeRegionsChanged>()),
        );
        datasource.removeTimeRegion('region-1');
      });

      test('removeTimeRegion with unknown ID does not emit', () async {
        final changeFuture = datasource.changes.toList();
        datasource.removeTimeRegion('nonexistent');
        datasource.dispose();
        final changes = await changeFuture;
        expect(changes, isEmpty);
      });
    });

    group('changes stream', () {
      test('is broadcast — multiple listeners allowed', () async {
        final results1 = <TideDatasourceChange>[];
        final results2 = <TideDatasourceChange>[];

        final sub1 = datasource.changes.listen(results1.add);
        final sub2 = datasource.changes.listen(results2.add);

        datasource.addEvent(makeEvent());

        await Future<void>.delayed(Duration.zero);

        expect(results1, hasLength(1));
        expect(results2, hasLength(1));

        await sub1.cancel();
        await sub2.cancel();
      });

      test('sequence of mutations produces correct notification order',
          () async {
        final changes = <TideDatasourceChange>[];
        final sub = datasource.changes.listen(changes.add);

        datasource.addEvent(makeEvent(id: 'e1'));
        datasource.updateEvent(makeEvent(id: 'e1', subject: 'Updated'));
        datasource.removeEvent('e1');
        datasource.addResource(makeResource());
        datasource.addTimeRegion(makeRegion());

        await Future<void>.delayed(Duration.zero);

        expect(changes, hasLength(5));
        expect(changes[0], isA<EventsAdded>());
        expect(changes[1], isA<EventsUpdated>());
        expect(changes[2], isA<EventsRemoved>());
        expect(changes[3], isA<ResourcesChanged>());
        expect(changes[4], isA<TimeRegionsChanged>());

        await sub.cancel();
      });
    });

    group('mapping', () {
      test('returns null by default', () {
        expect(datasource.mapping, isNull);
      });
    });

    group('dispose', () {
      test('closes the changes stream', () async {
        expectLater(datasource.changes, emitsDone);
        datasource.dispose();
      });
    });
  });

  // ─── TideStreamDatasource ────────────────────────────────

  group('TideStreamDatasource', () {
    test('emits FullReload when stream provides events', () async {
      final controller = StreamController<List<TideEvent>>();
      final datasource = TideStreamDatasource(
        eventsStream: controller.stream,
        resources: Future.value([makeResource()]),
      );
      addTearDown(() {
        datasource.dispose();
        controller.close();
      });

      expectLater(datasource.changes, emits(isA<FullReload>()));

      controller.add([makeEvent()]);
    });

    test('getEvents returns latest stream emission filtered by range',
        () async {
      final controller = StreamController<List<TideEvent>>();
      final datasource = TideStreamDatasource(
        eventsStream: controller.stream,
        resources: Future.value([]),
      );
      addTearDown(() {
        datasource.dispose();
        controller.close();
      });

      controller.add([
        makeEvent(id: 'e1', startTime: june1at9, endTime: june1at10),
        makeEvent(id: 'e2', startTime: june3at9, endTime: june3at10),
      ]);

      // Let the stream event propagate.
      await Future<void>.delayed(Duration.zero);

      final events = await datasource.getEvents(
        DateTime(2024, 6, 1),
        DateTime(2024, 6, 2),
      );
      expect(events, hasLength(1));
      expect(events.first.id, 'e1');
    });

    test('subsequent stream emissions replace previous events', () async {
      final controller = StreamController<List<TideEvent>>();
      final datasource = TideStreamDatasource(
        eventsStream: controller.stream,
        resources: Future.value([]),
      );
      addTearDown(() {
        datasource.dispose();
        controller.close();
      });

      controller.add([makeEvent(id: 'e1')]);
      await Future<void>.delayed(Duration.zero);

      controller.add([makeEvent(id: 'e2')]);
      await Future<void>.delayed(Duration.zero);

      final events = await datasource.getEvents(
        DateTime(2024),
        DateTime(2025),
      );
      expect(events, hasLength(1));
      expect(events.first.id, 'e2');
    });

    test('getResources returns the provided future', () async {
      final resources = [makeResource(id: 'r1'), makeResource(id: 'r2')];
      final datasource = TideStreamDatasource(
        eventsStream: const Stream.empty(),
        resources: Future.value(resources),
      );
      addTearDown(datasource.dispose);

      final result = await datasource.getResources();
      expect(result, hasLength(2));
    });

    test('getTimeRegions returns filtered regions', () async {
      final regions = [
        makeRegion(id: 'r1', startTime: june1at9, endTime: june1at10),
        makeRegion(id: 'r2', startTime: june3at9, endTime: june3at10),
      ];
      final datasource = TideStreamDatasource(
        eventsStream: const Stream.empty(),
        resources: Future.value([]),
        timeRegions: Future.value(regions),
      );
      addTearDown(datasource.dispose);

      final result = await datasource.getTimeRegions(
        DateTime(2024, 6, 1),
        DateTime(2024, 6, 2),
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'r1');
    });

    test('defaults to empty time regions when not provided', () async {
      final datasource = TideStreamDatasource(
        eventsStream: const Stream.empty(),
        resources: Future.value([]),
      );
      addTearDown(datasource.dispose);

      final regions = await datasource.getTimeRegions(
        DateTime(2024),
        DateTime(2025),
      );
      expect(regions, isEmpty);
    });

    test('mapping returns null by default', () {
      final datasource = TideStreamDatasource(
        eventsStream: const Stream.empty(),
        resources: Future.value([]),
      );
      addTearDown(datasource.dispose);
      expect(datasource.mapping, isNull);
    });

    test('propagates stream errors through changes', () async {
      final controller = StreamController<List<TideEvent>>();
      final datasource = TideStreamDatasource(
        eventsStream: controller.stream,
        resources: Future.value([]),
      );
      addTearDown(() {
        datasource.dispose();
        controller.close();
      });

      expectLater(
        datasource.changes,
        emitsError(isA<Exception>()),
      );

      controller.addError(Exception('test error'));
    });

    test('dispose closes the changes stream', () async {
      final controller = StreamController<List<TideEvent>>();
      final datasource = TideStreamDatasource(
        eventsStream: controller.stream,
        resources: Future.value([]),
      );

      expectLater(datasource.changes, emitsDone);

      datasource.dispose();
      await controller.close();
    });

    test('getEvents returns empty before first stream emission', () async {
      final controller = StreamController<List<TideEvent>>();
      final datasource = TideStreamDatasource(
        eventsStream: controller.stream,
        resources: Future.value([]),
      );
      addTearDown(() {
        datasource.dispose();
        controller.close();
      });

      final events = await datasource.getEvents(
        DateTime(2024),
        DateTime(2025),
      );
      expect(events, isEmpty);
    });
  });

  // ─── TideEventMapping ────────────────────────────────────

  group('TideEventMapping', () {
    test('can implement custom mapping', () {
      final mapping = _TestMapping();
      final event = makeEvent(id: 'e1', subject: 'Test');

      final dto = mapping.fromTideEvent(event);
      expect(dto['id'], 'e1');
      expect(dto['subject'], 'Test');

      final backToEvent = mapping.toTideEvent(dto);
      expect(backToEvent.id, 'e1');
      expect(backToEvent.subject, 'Test');
    });
  });
}

/// A trivial mapping for testing that [TideEventMapping] can be subclassed.
class _TestMapping extends TideEventMapping<Map<String, dynamic>> {
  @override
  TideEvent toTideEvent(Map<String, dynamic> source) {
    return TideEvent(
      id: source['id'] as String,
      subject: source['subject'] as String,
      startTime: source['start'] as DateTime,
      endTime: source['end'] as DateTime,
    );
  }

  @override
  Map<String, dynamic> fromTideEvent(TideEvent event) {
    return {
      'id': event.id,
      'subject': event.subject,
      'start': event.startTime,
      'end': event.endTime,
    };
  }
}

import 'dart:async';

import 'datasource.dart';
import 'models/event.dart';
import 'models/resource.dart';
import 'models/time_region.dart';

/// An in-memory [TideDatasource] that stores events, resources, and time
/// regions in local lists.
///
/// Ideal for local data, prototyping, and testing. Mutation methods
/// ([addEvent], [updateEvent], [removeEvent], etc.) automatically emit
/// change notifications on the [changes] stream.
///
/// ```dart
/// final datasource = TideInMemoryDatasource(
///   events: [event1, event2],
///   resources: [lisa, max],
/// );
/// datasource.addEvent(newEvent);
/// ```
class TideInMemoryDatasource extends TideDatasource {
  /// Creates a [TideInMemoryDatasource] with optional initial data.
  TideInMemoryDatasource({
    List<TideEvent>? events,
    List<TideResource>? resources,
    List<TideTimeRegion>? timeRegions,
  })  : _events = List<TideEvent>.of(events ?? const []),
        _resources = List<TideResource>.of(resources ?? const []),
        _timeRegions = List<TideTimeRegion>.of(timeRegions ?? const []);

  final List<TideEvent> _events;
  final List<TideResource> _resources;
  final List<TideTimeRegion> _timeRegions;

  final StreamController<TideDatasourceChange> _changesController =
      StreamController<TideDatasourceChange>.broadcast();

  bool _isDisposed = false;

  @override
  Future<List<TideEvent>> getEvents(DateTime start, DateTime end) async {
    return _events.where((event) {
      return event.startTime.isBefore(end) && event.endTime.isAfter(start);
    }).toList();
  }

  @override
  Future<List<TideResource>> getResources() async {
    return List<TideResource>.unmodifiable(_resources);
  }

  @override
  Future<List<TideTimeRegion>> getTimeRegions(
    DateTime start,
    DateTime end,
  ) async {
    return _timeRegions.where((region) {
      return region.startTime.isBefore(end) && region.endTime.isAfter(start);
    }).toList();
  }

  @override
  Stream<TideDatasourceChange> get changes => _changesController.stream;

  // ─── Event Mutations ─────────────────────────────────────

  /// Adds a single event and emits an [EventsAdded] notification.
  void addEvent(TideEvent event) {
    _assertNotDisposed();
    _events.add(event);
    _changesController.add(EventsAdded([event]));
  }

  /// Adds multiple events at once and emits an [EventsAdded] notification.
  void addEvents(List<TideEvent> events) {
    _assertNotDisposed();
    if (events.isEmpty) return;
    _events.addAll(events);
    _changesController.add(EventsAdded(events));
  }

  /// Updates an existing event (matched by [TideEvent.id]) and emits an
  /// [EventsUpdated] notification.
  ///
  /// Does nothing if no event with the given ID exists.
  void updateEvent(TideEvent event) {
    _assertNotDisposed();
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index == -1) return;
    _events[index] = event;
    _changesController.add(EventsUpdated([event]));
  }

  /// Removes the event with the given [eventId] and emits an
  /// [EventsRemoved] notification.
  ///
  /// Does nothing if no event with the given ID exists.
  void removeEvent(String eventId) {
    _assertNotDisposed();
    final removed = _events.where((e) => e.id == eventId).toList();
    if (removed.isEmpty) return;
    _events.removeWhere((e) => e.id == eventId);
    _changesController.add(EventsRemoved([eventId]));
  }

  // ─── Resource Mutations ──────────────────────────────────

  /// Adds a resource and emits a [ResourcesChanged] notification.
  void addResource(TideResource resource) {
    _assertNotDisposed();
    _resources.add(resource);
    _changesController.add(const ResourcesChanged());
  }

  /// Removes the resource with the given [resourceId] and emits a
  /// [ResourcesChanged] notification.
  ///
  /// Does nothing if no resource with the given ID exists.
  void removeResource(String resourceId) {
    _assertNotDisposed();
    final removed = _resources.where((r) => r.id == resourceId).toList();
    if (removed.isEmpty) return;
    _resources.removeWhere((r) => r.id == resourceId);
    _changesController.add(const ResourcesChanged());
  }

  /// Updates an existing resource (matched by [TideResource.id]) and emits
  /// a [ResourcesChanged] notification.
  ///
  /// Does nothing if no resource with the given ID exists.
  void updateResource(TideResource resource) {
    _assertNotDisposed();
    final index = _resources.indexWhere((r) => r.id == resource.id);
    if (index == -1) return;
    _resources[index] = resource;
    _changesController.add(const ResourcesChanged());
  }

  // ─── Time Region Mutations ───────────────────────────────

  /// Adds a time region and emits a [TimeRegionsChanged] notification.
  void addTimeRegion(TideTimeRegion region) {
    _assertNotDisposed();
    _timeRegions.add(region);
    _changesController.add(const TimeRegionsChanged());
  }

  /// Removes the time region with the given [regionId] and emits a
  /// [TimeRegionsChanged] notification.
  ///
  /// Does nothing if no time region with the given ID exists.
  void removeTimeRegion(String regionId) {
    _assertNotDisposed();
    final removed = _timeRegions.where((r) => r.id == regionId).toList();
    if (removed.isEmpty) return;
    _timeRegions.removeWhere((r) => r.id == regionId);
    _changesController.add(const TimeRegionsChanged());
  }

  // ─── Internals ───────────────────────────────────────────

  void _assertNotDisposed() {
    assert(!_isDisposed, 'TideInMemoryDatasource has been disposed.');
  }

  @override
  void dispose() {
    _isDisposed = true;
    _changesController.close();
  }
}

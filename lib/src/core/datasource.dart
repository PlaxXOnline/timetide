import 'dart:async';

import 'models/event.dart';
import 'models/resource.dart';
import 'models/time_region.dart';

/// Change notifications emitted by a [TideDatasource].
///
/// The calendar listens to these changes and updates only the affected areas:
/// - [EventsAdded], [EventsUpdated], [EventsRemoved] re-render affected events.
/// - [ResourcesChanged] rebuilds resource headers and layout.
/// - [TimeRegionsChanged] re-renders time regions.
/// - [FullReload] triggers a complete data refresh.
sealed class TideDatasourceChange {
  const TideDatasourceChange();
}

/// New events have been added to the datasource.
class EventsAdded extends TideDatasourceChange {
  /// Creates an [EventsAdded] change.
  const EventsAdded(this.events);

  /// The events that were added.
  final List<TideEvent> events;
}

/// Existing events have been updated in the datasource.
class EventsUpdated extends TideDatasourceChange {
  /// Creates an [EventsUpdated] change.
  const EventsUpdated(this.events);

  /// The updated events.
  final List<TideEvent> events;
}

/// Events have been removed from the datasource.
class EventsRemoved extends TideDatasourceChange {
  /// Creates an [EventsRemoved] change.
  const EventsRemoved(this.eventIds);

  /// The IDs of the removed events.
  final List<String> eventIds;
}

/// Resources have changed (added, removed, or updated).
class ResourcesChanged extends TideDatasourceChange {
  /// Creates a [ResourcesChanged] change.
  const ResourcesChanged();
}

/// Time regions have changed.
class TimeRegionsChanged extends TideDatasourceChange {
  /// Creates a [TimeRegionsChanged] change.
  const TimeRegionsChanged();
}

/// All data should be fully reloaded.
class FullReload extends TideDatasourceChange {
  /// Creates a [FullReload] change.
  const FullReload();
}

/// Optional mapping interface for converting custom business objects
/// to and from [TideEvent].
///
/// Implement this when the application uses domain-specific types instead
/// of [TideEvent] directly.
abstract class TideEventMapping<T> {
  /// Converts a business object to a [TideEvent].
  TideEvent toTideEvent(T source);

  /// Converts a [TideEvent] back to a business object.
  T fromTideEvent(TideEvent event);
}

/// Abstract datasource that provides events, resources, and time regions
/// to the calendar.
///
/// Subclasses must implement data retrieval methods and expose a [changes]
/// stream so the calendar can react to data mutations. The calendar calls
/// [getEvents] automatically when navigating to a new date range.
///
/// See [TideInMemoryDatasource] for a simple in-memory implementation and
/// [TideStreamDatasource] for wrapping reactive streams.
abstract class TideDatasource {
  /// Loads events for the given date range.
  ///
  /// Called automatically when the user navigates to a new visible range.
  Future<List<TideEvent>> getEvents(DateTime start, DateTime end);

  /// Loads all resources.
  ///
  /// Called once during initialization and again when a [ResourcesChanged]
  /// notification is received.
  Future<List<TideResource>> getResources();

  /// Loads time regions for the given date range.
  Future<List<TideTimeRegion>> getTimeRegions(DateTime start, DateTime end);

  /// Stream of change notifications.
  ///
  /// The calendar subscribes to this stream and updates the UI accordingly.
  Stream<TideDatasourceChange> get changes;

  /// Optional mapping for custom business objects.
  ///
  /// Override this to provide a [TideEventMapping] when the application
  /// uses domain-specific types instead of [TideEvent].
  TideEventMapping<dynamic>? get mapping => null;

  /// Adds a single event to the datasource.
  ///
  /// Subclasses that support mutation should override this method to
  /// persist the event and emit an [EventsAdded] notification on the
  /// [changes] stream.
  Future<void> addEvent(TideEvent event) async {}

  /// Updates a single existing event (matched by [TideEvent.id]).
  ///
  /// Subclasses that support mutation should override this method to
  /// persist the change and emit an [EventsUpdated] notification on the
  /// [changes] stream.
  Future<void> updateEvent(TideEvent event) async {}

  /// Removes the event with the given [eventId].
  ///
  /// Subclasses that support mutation should override this method to
  /// remove the event and emit an [EventsRemoved] notification on the
  /// [changes] stream.
  Future<void> removeEvent(String eventId) async {}

  /// Adds multiple events at once.
  ///
  /// The default implementation iterates over [events] and calls
  /// [addEvent] for each entry. Subclasses can override this to provide
  /// a more efficient bulk operation (e.g. a single transaction or a
  /// single [EventsAdded] notification).
  Future<void> addEvents(List<TideEvent> events) async {
    for (final event in events) {
      await addEvent(event);
    }
  }

  /// Updates multiple existing events at once.
  ///
  /// The default implementation iterates over [events] and calls
  /// [updateEvent] for each entry. Subclasses can override this to
  /// provide a more efficient bulk operation.
  Future<void> updateEvents(List<TideEvent> events) async {
    for (final event in events) {
      await updateEvent(event);
    }
  }

  /// Removes multiple events at once, identified by their IDs.
  ///
  /// The default implementation iterates over [eventIds] and calls
  /// [removeEvent] for each entry. Subclasses can override this to
  /// provide a more efficient bulk operation.
  Future<void> removeEvents(List<String> eventIds) async {
    for (final id in eventIds) {
      await removeEvent(id);
    }
  }

  /// Releases resources held by this datasource.
  void dispose();
}

import 'dart:async';

import 'datasource.dart';
import 'models/event.dart';
import 'models/resource.dart';
import 'models/time_region.dart';

/// A [TideDatasource] that wraps a `Stream<List<TideEvent>>` for reactive
/// data sources like Supabase Realtime or Firebase Firestore.
///
/// Events are sourced from the stream, while resources and time regions
/// are provided as [Future]s. Each stream emission replaces the previous
/// event list and triggers a [FullReload] notification.
///
/// ```dart
/// final datasource = TideStreamDatasource(
///   eventsStream: supabase
///     .from('appointments')
///     .stream(primaryKey: ['id'])
///     .map((rows) => rows.map(TideEvent.fromJson).toList()),
///   resources: Future.value([lisa, max]),
///   timeRegions: Future.value([lunchBreak]),
/// );
/// ```
class TideStreamDatasource extends TideDatasource {
  /// Creates a [TideStreamDatasource].
  ///
  /// [eventsStream] provides a reactive list of events. Each emission
  /// replaces all currently held events.
  ///
  /// [resources] and [timeRegions] are loaded once via their respective
  /// futures. Provide [Future.value] for static data.
  TideStreamDatasource({
    required Stream<List<TideEvent>> eventsStream,
    required Future<List<TideResource>> resources,
    Future<List<TideTimeRegion>>? timeRegions,
  })  : _resourcesFuture = resources,
        _timeRegionsFuture = timeRegions ?? Future.value(const []) {
    _subscription = eventsStream.listen(
      (events) {
        _latestEvents = events;
        _changesController.add(const FullReload());
      },
      onError: (Object error) {
        // Propagate errors through the changes stream so the calendar
        // can surface them to the user.
        _changesController.addError(error);
      },
    );
  }

  List<TideEvent> _latestEvents = const [];
  final Future<List<TideResource>> _resourcesFuture;
  final Future<List<TideTimeRegion>> _timeRegionsFuture;
  late final StreamSubscription<List<TideEvent>> _subscription;

  final StreamController<TideDatasourceChange> _changesController =
      StreamController<TideDatasourceChange>.broadcast();

  @override
  Future<List<TideEvent>> getEvents(DateTime start, DateTime end) async {
    return _latestEvents.where((event) {
      return event.startTime.isBefore(end) && event.endTime.isAfter(start);
    }).toList();
  }

  @override
  Future<List<TideResource>> getResources() => _resourcesFuture;

  @override
  Future<List<TideTimeRegion>> getTimeRegions(
    DateTime start,
    DateTime end,
  ) async {
    final all = await _timeRegionsFuture;
    return all.where((region) {
      return region.startTime.isBefore(end) && region.endTime.isAfter(start);
    }).toList();
  }

  @override
  Stream<TideDatasourceChange> get changes => _changesController.stream;

  @override
  void dispose() {
    _subscription.cancel();
    _changesController.close();
  }
}

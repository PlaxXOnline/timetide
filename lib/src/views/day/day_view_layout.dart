import '../../core/models/event.dart';
import '../../rendering/event_layout_engine.dart';

/// Helper that maps events to screen positions for day-based views.
///
/// Converts event times to pixel offsets based on [hourHeight] and [startHour],
/// then delegates overlap resolution to [TideEventLayoutEngine].
class TideDayViewLayout {
  const TideDayViewLayout._();

  /// Converts a [DateTime] to a y-pixel offset relative to [startHour].
  static double timeToY({
    required DateTime time,
    required double startHour,
    required double hourHeight,
  }) {
    final fractionalHour =
        time.hour + time.minute / 60.0 + time.second / 3600.0;
    return (fractionalHour - startHour) * hourHeight;
  }

  /// Converts a y-pixel offset back to a [DateTime] on the given [date].
  static DateTime yToTime({
    required double y,
    required DateTime date,
    required double startHour,
    required double hourHeight,
  }) {
    final fractionalHour = startHour + y / hourHeight;
    final hour = fractionalHour.floor();
    final minute = ((fractionalHour - hour) * 60).round();
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Lays out [events] within the available space using the given [strategy].
  ///
  /// Returns a [TideEventLayoutResult] for every non-all-day event.
  static List<TideEventLayoutResult> layoutEvents({
    required List<TideEvent> events,
    required TideOverlapStrategy strategy,
    required double startHour,
    required double endHour,
    required double availableWidth,
    required double hourHeight,
  }) {
    final totalHours = endHour - startHour;
    final availableHeight = totalHours * hourHeight;

    return TideEventLayoutEngine.layout(
      events: events,
      strategy: strategy,
      startHour: startHour,
      endHour: endHour,
      availableWidth: availableWidth,
      availableHeight: availableHeight,
    );
  }

  /// Filters all-day events from a list.
  static List<TideEvent> allDayEvents(List<TideEvent> events) {
    return events.where((e) => e.isAllDay).toList();
  }

  /// Filters timed (non-all-day) events from a list.
  static List<TideEvent> timedEvents(List<TideEvent> events) {
    return events.where((e) => !e.isAllDay).toList();
  }
}

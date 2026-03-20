import 'models/view.dart';

/// Predefined calendar configurations for common use cases.
///
/// Each preset maps to a [TidePresetConfig] that provides sensible defaults
/// for view, time slots, working hours, and more.
enum TidePreset {
  /// Salon / appointment-booking day view with 15-minute slots.
  salonDay,

  /// Team planning week view with resource rows.
  teamPlanning,

  /// Simple monthly overview.
  monthOverview,

  /// Doctor/clinic schedule with 10-minute slots.
  clinicSchedule,

  /// Conference / multi-day event layout.
  conference,

  /// School timetable with fixed period slots.
  schoolTimetable,
}

/// Configuration values produced by a [TidePreset].
///
/// Consumers use [TidePreset.config] to obtain a [TidePresetConfig] and apply
/// the values to a [TideController] or widget.
class TidePresetConfig {
  /// Creates a [TidePresetConfig].
  const TidePresetConfig({
    required this.initialView,
    required this.timeSlotDuration,
    required this.workDayStart,
    required this.workDayEnd,
    this.showWeekends = true,
    this.resourcesEnabled = false,
    this.defaultZoomLevel = 1.0,
  });

  /// The default view to show.
  final TideView initialView;

  /// Duration of each time slot in the day/timeline views.
  final Duration timeSlotDuration;

  /// Start hour of the working day.
  final int workDayStart;

  /// End hour of the working day.
  final int workDayEnd;

  /// Whether to display weekend days.
  final bool showWeekends;

  /// Whether multi-resource layout is enabled.
  final bool resourcesEnabled;

  /// Default zoom level for time-axis views.
  final double defaultZoomLevel;
}

/// Extension providing [config] getter on [TidePreset].
extension TidePresetExtension on TidePreset {
  /// Returns the [TidePresetConfig] for this preset.
  TidePresetConfig get config {
    switch (this) {
      case TidePreset.salonDay:
        return const TidePresetConfig(
          initialView: TideView.timelineDay,
          timeSlotDuration: Duration(minutes: 15),
          workDayStart: 8,
          workDayEnd: 20,
          resourcesEnabled: true,
        );
      case TidePreset.teamPlanning:
        return const TidePresetConfig(
          initialView: TideView.timelineWeek,
          timeSlotDuration: Duration(minutes: 30),
          workDayStart: 8,
          workDayEnd: 18,
          resourcesEnabled: true,
        );
      case TidePreset.monthOverview:
        return const TidePresetConfig(
          initialView: TideView.month,
          timeSlotDuration: Duration(minutes: 30),
          workDayStart: 0,
          workDayEnd: 24,
        );
      case TidePreset.clinicSchedule:
        return const TidePresetConfig(
          initialView: TideView.timelineDay,
          timeSlotDuration: Duration(minutes: 10),
          workDayStart: 7,
          workDayEnd: 19,
          resourcesEnabled: true,
          defaultZoomLevel: 1.5,
        );
      case TidePreset.conference:
        return const TidePresetConfig(
          initialView: TideView.timelineWeek,
          timeSlotDuration: Duration(minutes: 30),
          workDayStart: 8,
          workDayEnd: 22,
          resourcesEnabled: true,
        );
      case TidePreset.schoolTimetable:
        return const TidePresetConfig(
          initialView: TideView.workWeek,
          timeSlotDuration: Duration(minutes: 45),
          workDayStart: 8,
          workDayEnd: 16,
          showWeekends: false,
        );
    }
  }
}

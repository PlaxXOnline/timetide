/// All 11 calendar view types supported by timetide.
enum TideView {
  /// Single day view showing hours vertically.
  day,

  /// 7-day week view.
  week,

  /// Work week view (typically Mon-Fri).
  workWeek,

  /// Monthly calendar grid.
  month,

  /// Scrollable agenda/schedule list.
  schedule,

  /// Single day timeline with horizontal resources.
  timelineDay,

  /// Week timeline with horizontal resources.
  timelineWeek,

  /// Work week timeline with horizontal resources.
  timelineWorkWeek,

  /// Month timeline with horizontal resources.
  timelineMonth,

  /// Multi-week view showing configurable number of weeks.
  multiWeek,

  /// Yearly overview.
  year,
}

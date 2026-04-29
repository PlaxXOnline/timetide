/// Holds all user-facing strings for timetide widgets.
///
/// This is **not** a [LocalizationsDelegate]. It is injected directly as a
/// parameter on the calendar widget, giving consumers full control without
/// requiring the Flutter localizations machinery.
///
/// Use the named factory constructors [TideLocalizations.en] and
/// [TideLocalizations.de] for built-in locales or create a custom instance.
class TideLocalizations {
  /// Label for "today" navigation action.
  final String today;

  /// Display name for the month view.
  final String monthView;

  /// Display name for the week view.
  final String weekView;

  /// Display name for the day view.
  final String dayView;

  /// Display name for the schedule / agenda view.
  final String scheduleView;

  /// Shown when there are no events in the visible range.
  final String noEvents;

  /// Label for all-day events.
  final String allDay;

  /// Template for the "+N more" overflow indicator.
  ///
  /// Use `{count}` as a placeholder for the number, e.g. `"+{count} more"`.
  final String moreEvents;

  /// Label for the "new event" action.
  final String newEvent;

  /// Label for the "delete event" action.
  final String deleteEvent;

  /// Label for the "edit event" action.
  final String editEvent;

  /// Label for editing the entire recurrence series.
  final String editSeries;

  /// Label for editing only the selected occurrence.
  final String editOccurrence;

  /// Label for editing this and all following occurrences.
  final String editThisAndFollowing;

  /// Display name for the timeline day view.
  final String timelineDay;

  /// Display name for the timeline week view.
  final String timelineWeek;

  /// Display name for the timeline month view.
  final String timelineMonth;

  /// Display name for the multi-week view.
  final String multiWeek;

  /// Display name for the year view.
  final String year;

  /// Display name for the work-week view.
  final String workWeek;

  // ─── Companion Widget Strings ────────────────────────

  /// Shown when no time slots are available.
  final String noSlotsAvailable;

  /// Label for the date selection action.
  final String selectDate;

  /// Label for the time selection action.
  final String selectTime;

  /// Abbreviated label for Monday.
  final String monday;

  /// Abbreviated label for Tuesday.
  final String tuesday;

  /// Abbreviated label for Wednesday.
  final String wednesday;

  /// Abbreviated label for Thursday.
  final String thursday;

  /// Abbreviated label for Friday.
  final String friday;

  /// Abbreviated label for Saturday.
  final String saturday;

  /// Abbreviated label for Sunday.
  final String sunday;

  /// Display name for the template/schedule editor.
  final String templateEditor;

  /// Label for break periods.
  final String breakLabel;

  /// Creates a [TideLocalizations] with the given strings.
  const TideLocalizations({
    required this.today,
    required this.monthView,
    required this.weekView,
    required this.dayView,
    required this.scheduleView,
    required this.noEvents,
    required this.allDay,
    required this.moreEvents,
    required this.newEvent,
    required this.deleteEvent,
    required this.editEvent,
    required this.editSeries,
    required this.editOccurrence,
    required this.editThisAndFollowing,
    required this.timelineDay,
    required this.timelineWeek,
    required this.timelineMonth,
    required this.multiWeek,
    required this.year,
    required this.workWeek,
    required this.noSlotsAvailable,
    required this.selectDate,
    required this.selectTime,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
    required this.templateEditor,
    required this.breakLabel,
  });

  /// English localizations.
  factory TideLocalizations.en() {
    return const TideLocalizations(
      today: 'Today',
      monthView: 'Month',
      weekView: 'Week',
      dayView: 'Day',
      scheduleView: 'Schedule',
      noEvents: 'No events',
      allDay: 'All day',
      moreEvents: '+{count} more',
      newEvent: 'New event',
      deleteEvent: 'Delete',
      editEvent: 'Edit',
      editSeries: 'Edit series',
      editOccurrence: 'This event only',
      editThisAndFollowing: 'This and following',
      timelineDay: 'Timeline day',
      timelineWeek: 'Timeline week',
      timelineMonth: 'Timeline month',
      multiWeek: 'Multi-week',
      year: 'Year',
      workWeek: 'Work week',
      noSlotsAvailable: 'No slots available',
      selectDate: 'Select date',
      selectTime: 'Select time',
      monday: 'Mon',
      tuesday: 'Tue',
      wednesday: 'Wed',
      thursday: 'Thu',
      friday: 'Fri',
      saturday: 'Sat',
      sunday: 'Sun',
      templateEditor: 'Schedule Editor',
      breakLabel: 'Break',
    );
  }

  /// German localizations.
  factory TideLocalizations.de() {
    return const TideLocalizations(
      today: 'Heute',
      monthView: 'Monat',
      weekView: 'Woche',
      dayView: 'Tag',
      scheduleView: 'Agenda',
      noEvents: 'Keine Termine',
      allDay: 'Ganztägig',
      moreEvents: '+{count} weitere',
      newEvent: 'Neuer Termin',
      deleteEvent: 'Löschen',
      editEvent: 'Bearbeiten',
      editSeries: 'Serie bearbeiten',
      editOccurrence: 'Nur diesen Termin',
      editThisAndFollowing: 'Diesen und folgende',
      timelineDay: 'Zeitleiste Tag',
      timelineWeek: 'Zeitleiste Woche',
      timelineMonth: 'Zeitleiste Monat',
      multiWeek: 'Mehrere Wochen',
      year: 'Jahr',
      workWeek: 'Arbeitswoche',
      noSlotsAvailable: 'Keine Termine verfügbar',
      selectDate: 'Datum wählen',
      selectTime: 'Uhrzeit wählen',
      monday: 'Mo',
      tuesday: 'Di',
      wednesday: 'Mi',
      thursday: 'Do',
      friday: 'Fr',
      saturday: 'Sa',
      sunday: 'So',
      templateEditor: 'Wochenplan-Editor',
      breakLabel: 'Pause',
    );
  }

  /// Returns the abbreviated weekday name for the given ISO 8601 weekday
  /// (1 = Monday, 7 = Sunday).
  String weekdayAbbr(int isoWeekday) {
    return switch (isoWeekday) {
      1 => monday,
      2 => tuesday,
      3 => wednesday,
      4 => thursday,
      5 => friday,
      6 => saturday,
      7 => sunday,
      _ => '',
    };
  }

  /// Formats the [moreEvents] template by replacing `{count}` with [count].
  String formatMoreEvents(int count) {
    return moreEvents.replaceAll('{count}', count.toString());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TideLocalizations) return false;
    return today == other.today &&
        monthView == other.monthView &&
        weekView == other.weekView &&
        dayView == other.dayView &&
        scheduleView == other.scheduleView &&
        noEvents == other.noEvents &&
        allDay == other.allDay &&
        moreEvents == other.moreEvents &&
        newEvent == other.newEvent &&
        deleteEvent == other.deleteEvent &&
        editEvent == other.editEvent &&
        editSeries == other.editSeries &&
        editOccurrence == other.editOccurrence &&
        editThisAndFollowing == other.editThisAndFollowing &&
        timelineDay == other.timelineDay &&
        timelineWeek == other.timelineWeek &&
        timelineMonth == other.timelineMonth &&
        multiWeek == other.multiWeek &&
        year == other.year &&
        workWeek == other.workWeek &&
        noSlotsAvailable == other.noSlotsAvailable &&
        selectDate == other.selectDate &&
        selectTime == other.selectTime &&
        monday == other.monday &&
        tuesday == other.tuesday &&
        wednesday == other.wednesday &&
        thursday == other.thursday &&
        friday == other.friday &&
        saturday == other.saturday &&
        sunday == other.sunday &&
        templateEditor == other.templateEditor &&
        breakLabel == other.breakLabel;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hash(
        today,
        monthView,
        weekView,
        dayView,
        scheduleView,
        noEvents,
        allDay,
        moreEvents,
        newEvent,
        deleteEvent,
        editEvent,
        editSeries,
        editOccurrence,
        editThisAndFollowing,
        timelineDay,
        timelineWeek,
        timelineMonth,
        multiWeek,
        year,
        workWeek,
      ),
      Object.hash(
        noSlotsAvailable,
        selectDate,
        selectTime,
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday,
        templateEditor,
        breakLabel,
      ),
    );
  }

  @override
  String toString() => 'TideLocalizations(today: $today)';
}

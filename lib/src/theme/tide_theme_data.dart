import 'dart:ui' show Color, lerpDouble;

import 'package:flutter/widgets.dart';

/// Flat data class holding all visual properties for timetide widgets.
///
/// Every property has a sensible const default so that callers only need to
/// override the values they care about. Use [copyWith] to derive a tweaked
/// copy and [lerp] to animate between two themes.
class TideThemeData {
  // ─── Global ────────────────────────────────────────────

  /// Background color of the calendar surface.
  final Color backgroundColor;

  /// Secondary surface color (e.g. month cell backgrounds).
  final Color surfaceColor;

  /// Default border color used throughout the calendar.
  final Color borderColor;

  /// Highlight color for today's date.
  final Color todayHighlightColor;

  /// Color used for the current selection.
  final Color selectionColor;

  /// Primary accent color for interactive elements.
  final Color primaryColor;

  // ─── Typography ────────────────────────────────────────

  /// Text style for the calendar header (month name, week range, etc.).
  final TextStyle headerTextStyle;

  /// Text style for day-column headers in week/day views.
  final TextStyle dayHeaderTextStyle;

  /// Text style for time labels along the left edge.
  final TextStyle timeSlotTextStyle;

  /// Text style for event titles.
  final TextStyle eventTitleStyle;

  /// Text style for event time annotations.
  final TextStyle eventTimeStyle;

  /// Text style for date numbers inside month view cells.
  final TextStyle monthDateTextStyle;

  // ─── Time Slots ────────────────────────────────────────

  /// Border color between time slot rows.
  final Color timeSlotBorderColor;

  /// Width of the border between time slot rows.
  final double timeSlotBorderWidth;

  /// Background color for working-hours time slots.
  final Color workingHoursColor;

  /// Background color for non-working-hours time slots.
  final Color nonWorkingHoursColor;

  // ─── Events ────────────────────────────────────────────

  /// Corner radius applied to event tiles.
  final BorderRadius eventBorderRadius;

  /// Minimum rendered height for an event tile.
  final double eventMinHeight;

  /// Internal padding inside an event tile.
  final EdgeInsets eventPadding;

  /// Spacing between side-by-side events.
  final double eventSpacing;

  // ─── Resources ─────────────────────────────────────────

  /// Width of the resource header column.
  final double resourceHeaderWidth;

  /// Color of the divider between resource rows.
  final Color resourceDividerColor;

  /// Width of the divider between resource rows.
  final double resourceDividerWidth;

  // ─── Current Time ──────────────────────────────────────

  /// Color of the current-time indicator line.
  final Color currentTimeIndicatorColor;

  /// Height (thickness) of the current-time indicator line.
  final double currentTimeIndicatorHeight;

  // ─── Month View ────────────────────────────────────────

  /// Border color of month view cells.
  final Color monthCellBorderColor;

  /// Text/number color for dates outside the visible month.
  final Color leadingTrailingDatesColor;

  /// Background color for today's cell in month view.
  final Color todayCellColor;

  /// Background color for the selected cell in month view.
  final Color selectedCellColor;

  // ─── Drag & Drop ───────────────────────────────────────

  /// Color of the drag ghost overlay.
  final Color dragGhostColor;

  /// Opacity of the drag ghost overlay (0.0–1.0).
  final double dragGhostOpacity;

  /// Color highlighting a scheduling conflict during drag.
  final Color dragConflictColor;

  // ─── Scrollbar ─────────────────────────────────────────

  /// Thumb color of the calendar scrollbar.
  final Color scrollbarColor;

  /// Thickness of the calendar scrollbar thumb.
  final double scrollbarThickness;

  /// Corner radius of the scrollbar thumb.
  final double scrollbarRadius;

  // ─── Accessibility ─────────────────────────────────────

  /// Color of the keyboard-focus indicator ring.
  final Color focusIndicatorColor;

  /// Width of the keyboard-focus indicator ring.
  final double focusIndicatorWidth;

  /// Creates a [TideThemeData] with sensible defaults.
  const TideThemeData({
    // Global
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.surfaceColor = const Color(0xFFF5F5F5),
    this.borderColor = const Color(0xFFE0E0E0),
    this.todayHighlightColor = const Color(0xFF2196F3),
    this.selectionColor = const Color(0x422196F3),
    this.primaryColor = const Color(0xFF2196F3),
    // Typography
    this.headerTextStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Color(0xFF212121),
    ),
    this.dayHeaderTextStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF616161),
    ),
    this.timeSlotTextStyle = const TextStyle(
      fontSize: 12,
      color: Color(0xFF9E9E9E),
    ),
    this.eventTitleStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFFFFFFFF),
    ),
    this.eventTimeStyle = const TextStyle(
      fontSize: 11,
      color: Color(0xB3FFFFFF),
    ),
    this.monthDateTextStyle = const TextStyle(
      fontSize: 14,
      color: Color(0xFF212121),
    ),
    // Time Slots
    this.timeSlotBorderColor = const Color(0xFFEEEEEE),
    this.timeSlotBorderWidth = 0.5,
    this.workingHoursColor = const Color(0xFFFFFFFF),
    this.nonWorkingHoursColor = const Color(0xFFFAFAFA),
    // Events
    this.eventBorderRadius = const BorderRadius.all(Radius.circular(4)),
    this.eventMinHeight = 20.0,
    this.eventPadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.eventSpacing = 1.0,
    // Resources
    this.resourceHeaderWidth = 150.0,
    this.resourceDividerColor = const Color(0xFFE0E0E0),
    this.resourceDividerWidth = 1.0,
    // Current Time
    this.currentTimeIndicatorColor = const Color(0xFFFF1744),
    this.currentTimeIndicatorHeight = 2.0,
    // Month View
    this.monthCellBorderColor = const Color(0xFFE0E0E0),
    this.leadingTrailingDatesColor = const Color(0xFFBDBDBD),
    this.todayCellColor = const Color(0xFFE3F2FD),
    this.selectedCellColor = const Color(0x422196F3),
    // Drag & Drop
    this.dragGhostColor = const Color(0xFF2196F3),
    this.dragGhostOpacity = 0.5,
    this.dragConflictColor = const Color(0xFFFF5252),
    // Scrollbar
    this.scrollbarColor = const Color(0x66000000),
    this.scrollbarThickness = 6.0,
    this.scrollbarRadius = 3.0,
    // Accessibility
    this.focusIndicatorColor = const Color(0xFF000000),
    this.focusIndicatorWidth = 2.0,
  });

  /// Returns a copy of this theme with the given fields replaced.
  TideThemeData copyWith({
    // Global
    Color? backgroundColor,
    Color? surfaceColor,
    Color? borderColor,
    Color? todayHighlightColor,
    Color? selectionColor,
    Color? primaryColor,
    // Typography
    TextStyle? headerTextStyle,
    TextStyle? dayHeaderTextStyle,
    TextStyle? timeSlotTextStyle,
    TextStyle? eventTitleStyle,
    TextStyle? eventTimeStyle,
    TextStyle? monthDateTextStyle,
    // Time Slots
    Color? timeSlotBorderColor,
    double? timeSlotBorderWidth,
    Color? workingHoursColor,
    Color? nonWorkingHoursColor,
    // Events
    BorderRadius? eventBorderRadius,
    double? eventMinHeight,
    EdgeInsets? eventPadding,
    double? eventSpacing,
    // Resources
    double? resourceHeaderWidth,
    Color? resourceDividerColor,
    double? resourceDividerWidth,
    // Current Time
    Color? currentTimeIndicatorColor,
    double? currentTimeIndicatorHeight,
    // Month View
    Color? monthCellBorderColor,
    Color? leadingTrailingDatesColor,
    Color? todayCellColor,
    Color? selectedCellColor,
    // Drag & Drop
    Color? dragGhostColor,
    double? dragGhostOpacity,
    Color? dragConflictColor,
    // Scrollbar
    Color? scrollbarColor,
    double? scrollbarThickness,
    double? scrollbarRadius,
    // Accessibility
    Color? focusIndicatorColor,
    double? focusIndicatorWidth,
  }) {
    return TideThemeData(
      // Global
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      borderColor: borderColor ?? this.borderColor,
      todayHighlightColor: todayHighlightColor ?? this.todayHighlightColor,
      selectionColor: selectionColor ?? this.selectionColor,
      primaryColor: primaryColor ?? this.primaryColor,
      // Typography
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      dayHeaderTextStyle: dayHeaderTextStyle ?? this.dayHeaderTextStyle,
      timeSlotTextStyle: timeSlotTextStyle ?? this.timeSlotTextStyle,
      eventTitleStyle: eventTitleStyle ?? this.eventTitleStyle,
      eventTimeStyle: eventTimeStyle ?? this.eventTimeStyle,
      monthDateTextStyle: monthDateTextStyle ?? this.monthDateTextStyle,
      // Time Slots
      timeSlotBorderColor: timeSlotBorderColor ?? this.timeSlotBorderColor,
      timeSlotBorderWidth: timeSlotBorderWidth ?? this.timeSlotBorderWidth,
      workingHoursColor: workingHoursColor ?? this.workingHoursColor,
      nonWorkingHoursColor: nonWorkingHoursColor ?? this.nonWorkingHoursColor,
      // Events
      eventBorderRadius: eventBorderRadius ?? this.eventBorderRadius,
      eventMinHeight: eventMinHeight ?? this.eventMinHeight,
      eventPadding: eventPadding ?? this.eventPadding,
      eventSpacing: eventSpacing ?? this.eventSpacing,
      // Resources
      resourceHeaderWidth: resourceHeaderWidth ?? this.resourceHeaderWidth,
      resourceDividerColor: resourceDividerColor ?? this.resourceDividerColor,
      resourceDividerWidth: resourceDividerWidth ?? this.resourceDividerWidth,
      // Current Time
      currentTimeIndicatorColor:
          currentTimeIndicatorColor ?? this.currentTimeIndicatorColor,
      currentTimeIndicatorHeight:
          currentTimeIndicatorHeight ?? this.currentTimeIndicatorHeight,
      // Month View
      monthCellBorderColor: monthCellBorderColor ?? this.monthCellBorderColor,
      leadingTrailingDatesColor:
          leadingTrailingDatesColor ?? this.leadingTrailingDatesColor,
      todayCellColor: todayCellColor ?? this.todayCellColor,
      selectedCellColor: selectedCellColor ?? this.selectedCellColor,
      // Drag & Drop
      dragGhostColor: dragGhostColor ?? this.dragGhostColor,
      dragGhostOpacity: dragGhostOpacity ?? this.dragGhostOpacity,
      dragConflictColor: dragConflictColor ?? this.dragConflictColor,
      // Scrollbar
      scrollbarColor: scrollbarColor ?? this.scrollbarColor,
      scrollbarThickness: scrollbarThickness ?? this.scrollbarThickness,
      scrollbarRadius: scrollbarRadius ?? this.scrollbarRadius,
      // Accessibility
      focusIndicatorColor: focusIndicatorColor ?? this.focusIndicatorColor,
      focusIndicatorWidth: focusIndicatorWidth ?? this.focusIndicatorWidth,
    );
  }

  /// Linearly interpolates between two [TideThemeData] instances.
  ///
  /// Used to animate theme transitions. The parameter [t] ranges from 0.0
  /// (returning [a]) to 1.0 (returning [b]).
  static TideThemeData lerp(TideThemeData a, TideThemeData b, double t) {
    return TideThemeData(
      // Global
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t)!,
      surfaceColor: Color.lerp(a.surfaceColor, b.surfaceColor, t)!,
      borderColor: Color.lerp(a.borderColor, b.borderColor, t)!,
      todayHighlightColor:
          Color.lerp(a.todayHighlightColor, b.todayHighlightColor, t)!,
      selectionColor: Color.lerp(a.selectionColor, b.selectionColor, t)!,
      primaryColor: Color.lerp(a.primaryColor, b.primaryColor, t)!,
      // Typography
      headerTextStyle: TextStyle.lerp(a.headerTextStyle, b.headerTextStyle, t)!,
      dayHeaderTextStyle:
          TextStyle.lerp(a.dayHeaderTextStyle, b.dayHeaderTextStyle, t)!,
      timeSlotTextStyle:
          TextStyle.lerp(a.timeSlotTextStyle, b.timeSlotTextStyle, t)!,
      eventTitleStyle:
          TextStyle.lerp(a.eventTitleStyle, b.eventTitleStyle, t)!,
      eventTimeStyle: TextStyle.lerp(a.eventTimeStyle, b.eventTimeStyle, t)!,
      monthDateTextStyle:
          TextStyle.lerp(a.monthDateTextStyle, b.monthDateTextStyle, t)!,
      // Time Slots
      timeSlotBorderColor:
          Color.lerp(a.timeSlotBorderColor, b.timeSlotBorderColor, t)!,
      timeSlotBorderWidth:
          lerpDouble(a.timeSlotBorderWidth, b.timeSlotBorderWidth, t)!,
      workingHoursColor:
          Color.lerp(a.workingHoursColor, b.workingHoursColor, t)!,
      nonWorkingHoursColor:
          Color.lerp(a.nonWorkingHoursColor, b.nonWorkingHoursColor, t)!,
      // Events
      eventBorderRadius:
          BorderRadius.lerp(a.eventBorderRadius, b.eventBorderRadius, t)!,
      eventMinHeight: lerpDouble(a.eventMinHeight, b.eventMinHeight, t)!,
      eventPadding: EdgeInsets.lerp(a.eventPadding, b.eventPadding, t)!,
      eventSpacing: lerpDouble(a.eventSpacing, b.eventSpacing, t)!,
      // Resources
      resourceHeaderWidth:
          lerpDouble(a.resourceHeaderWidth, b.resourceHeaderWidth, t)!,
      resourceDividerColor:
          Color.lerp(a.resourceDividerColor, b.resourceDividerColor, t)!,
      resourceDividerWidth:
          lerpDouble(a.resourceDividerWidth, b.resourceDividerWidth, t)!,
      // Current Time
      currentTimeIndicatorColor: Color.lerp(
          a.currentTimeIndicatorColor, b.currentTimeIndicatorColor, t)!,
      currentTimeIndicatorHeight: lerpDouble(
          a.currentTimeIndicatorHeight, b.currentTimeIndicatorHeight, t)!,
      // Month View
      monthCellBorderColor:
          Color.lerp(a.monthCellBorderColor, b.monthCellBorderColor, t)!,
      leadingTrailingDatesColor: Color.lerp(
          a.leadingTrailingDatesColor, b.leadingTrailingDatesColor, t)!,
      todayCellColor: Color.lerp(a.todayCellColor, b.todayCellColor, t)!,
      selectedCellColor:
          Color.lerp(a.selectedCellColor, b.selectedCellColor, t)!,
      // Drag & Drop
      dragGhostColor: Color.lerp(a.dragGhostColor, b.dragGhostColor, t)!,
      dragGhostOpacity:
          lerpDouble(a.dragGhostOpacity, b.dragGhostOpacity, t)!,
      dragConflictColor:
          Color.lerp(a.dragConflictColor, b.dragConflictColor, t)!,
      // Scrollbar
      scrollbarColor: Color.lerp(a.scrollbarColor, b.scrollbarColor, t)!,
      scrollbarThickness:
          lerpDouble(a.scrollbarThickness, b.scrollbarThickness, t)!,
      scrollbarRadius: lerpDouble(a.scrollbarRadius, b.scrollbarRadius, t)!,
      // Accessibility
      focusIndicatorColor:
          Color.lerp(a.focusIndicatorColor, b.focusIndicatorColor, t)!,
      focusIndicatorWidth:
          lerpDouble(a.focusIndicatorWidth, b.focusIndicatorWidth, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TideThemeData) return false;
    return backgroundColor == other.backgroundColor &&
        surfaceColor == other.surfaceColor &&
        borderColor == other.borderColor &&
        todayHighlightColor == other.todayHighlightColor &&
        selectionColor == other.selectionColor &&
        primaryColor == other.primaryColor &&
        headerTextStyle == other.headerTextStyle &&
        dayHeaderTextStyle == other.dayHeaderTextStyle &&
        timeSlotTextStyle == other.timeSlotTextStyle &&
        eventTitleStyle == other.eventTitleStyle &&
        eventTimeStyle == other.eventTimeStyle &&
        monthDateTextStyle == other.monthDateTextStyle &&
        timeSlotBorderColor == other.timeSlotBorderColor &&
        timeSlotBorderWidth == other.timeSlotBorderWidth &&
        workingHoursColor == other.workingHoursColor &&
        nonWorkingHoursColor == other.nonWorkingHoursColor &&
        eventBorderRadius == other.eventBorderRadius &&
        eventMinHeight == other.eventMinHeight &&
        eventPadding == other.eventPadding &&
        eventSpacing == other.eventSpacing &&
        resourceHeaderWidth == other.resourceHeaderWidth &&
        resourceDividerColor == other.resourceDividerColor &&
        resourceDividerWidth == other.resourceDividerWidth &&
        currentTimeIndicatorColor == other.currentTimeIndicatorColor &&
        currentTimeIndicatorHeight == other.currentTimeIndicatorHeight &&
        monthCellBorderColor == other.monthCellBorderColor &&
        leadingTrailingDatesColor == other.leadingTrailingDatesColor &&
        todayCellColor == other.todayCellColor &&
        selectedCellColor == other.selectedCellColor &&
        dragGhostColor == other.dragGhostColor &&
        dragGhostOpacity == other.dragGhostOpacity &&
        dragConflictColor == other.dragConflictColor &&
        scrollbarColor == other.scrollbarColor &&
        scrollbarThickness == other.scrollbarThickness &&
        scrollbarRadius == other.scrollbarRadius &&
        focusIndicatorColor == other.focusIndicatorColor &&
        focusIndicatorWidth == other.focusIndicatorWidth;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hash(
        backgroundColor,
        surfaceColor,
        borderColor,
        todayHighlightColor,
        selectionColor,
        primaryColor,
        headerTextStyle,
        dayHeaderTextStyle,
        timeSlotTextStyle,
        eventTitleStyle,
        eventTimeStyle,
        monthDateTextStyle,
        timeSlotBorderColor,
        timeSlotBorderWidth,
        workingHoursColor,
        nonWorkingHoursColor,
        eventBorderRadius,
        eventMinHeight,
        eventPadding,
        eventSpacing,
      ),
      Object.hash(
        resourceHeaderWidth,
        resourceDividerColor,
        resourceDividerWidth,
        currentTimeIndicatorColor,
        currentTimeIndicatorHeight,
        monthCellBorderColor,
        leadingTrailingDatesColor,
        todayCellColor,
        selectedCellColor,
        dragGhostColor,
        dragGhostOpacity,
        dragConflictColor,
        scrollbarColor,
        scrollbarThickness,
        scrollbarRadius,
        focusIndicatorColor,
        focusIndicatorWidth,
      ),
    );
  }

  @override
  String toString() => 'TideThemeData(primaryColor: $primaryColor)';
}

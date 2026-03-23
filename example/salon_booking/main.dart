// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/widgets.dart';
import 'package:timetide/src/core/controller.dart';
import 'package:timetide/src/core/models/drag_details.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/core/models/view.dart';
import 'package:timetide/src/core/presets.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/widgets/tide_calendar.dart';

import 'data/salon_datasource.dart';
import 'widgets/service_drag_list.dart';

/// Full salon booking example using TideCalendar.preset(TidePreset.salonDay).
///
/// Demonstrates:
/// - Preset-based configuration
/// - Custom event builder
/// - Resource headers with avatars and load indicators
/// - Service sidebar for drag-in booking
/// - Dark mode toggle
/// - View switcher
void main() {
  runApp(const SalonBookingApp());
}

class SalonBookingApp extends StatefulWidget {
  const SalonBookingApp({super.key});

  @override
  State<SalonBookingApp> createState() => _SalonBookingAppState();
}

class _SalonBookingAppState extends State<SalonBookingApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Salon Booking',
      color: const Color(0xFFE91E63),
      home: SalonBookingScreen(
        isDarkMode: _isDarkMode,
        onToggleDarkMode: () => setState(() => _isDarkMode = !_isDarkMode),
      ),
    );
  }
}

class SalonBookingScreen extends StatefulWidget {
  const SalonBookingScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  @override
  State<SalonBookingScreen> createState() => _SalonBookingScreenState();
}

class _SalonBookingScreenState extends State<SalonBookingScreen> {
  late final SalonDatasource _datasource;
  late final TideController _controller;

  @override
  void initState() {
    super.initState();
    _datasource = SalonDatasource();

    final presetConfig = TidePreset.salonDay.config;
    _controller = TideController(
      datasource: _datasource,
      initialView: presetConfig.initialView,
      initialDate: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TideThemeData get _theme => widget.isDarkMode ? _darkTheme : _lightTheme;

  static const _lightTheme = TideThemeData(
    primaryColor: Color(0xFFE91E63),
    todayHighlightColor: Color(0xFFE91E63),
    backgroundColor: Color(0xFFFFFFFF),
    surfaceColor: Color(0xFFFCE4EC),
    headerTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Color(0xFF212121),
    ),
  );

  static const _darkTheme = TideThemeData(
    primaryColor: Color(0xFFFF80AB),
    todayHighlightColor: Color(0xFFFF80AB),
    backgroundColor: Color(0xFF121212),
    surfaceColor: Color(0xFF1E1E1E),
    borderColor: Color(0xFF333333),
    timeSlotBorderColor: Color(0xFF2A2A2A),
    workingHoursColor: Color(0xFF1A1A1A),
    nonWorkingHoursColor: Color(0xFF0F0F0F),
    headerTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE0E0E0),
    ),
    dayHeaderTextStyle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFFBDBDBD),
    ),
    timeSlotTextStyle: TextStyle(
      fontSize: 12,
      color: Color(0xFF757575),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _theme.backgroundColor,
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: Row(
              children: [
                ServiceDragList(
                  onServiceTap: (service) {
                    debugPrint('Selected service: ${service.name}');
                  },
                ),
                Expanded(
                  child: TideCalendar.preset(
                    TidePreset.salonDay,
                    datasource: _datasource,
                    controller: _controller,
                    allowedViews: [
                      TideView.timelineDay,
                      TideView.timelineWeek,
                      TideView.day,
                    ],
                    themeData: _theme,
                    onEventTap: _onEventTap,
                    onDragEnd: (TideDragEndDetails details) {
                      List<String>? updatedResourceIds =
                          details.event.resourceIds;

                      if (details.newResourceId != null &&
                          updatedResourceIds != null) {
                        // Event has specific resource assignments — update them.
                        if (details.sourceResourceId != null &&
                            updatedResourceIds
                                .contains(details.sourceResourceId)) {
                          // Replace only the source resource with the target.
                          updatedResourceIds = updatedResourceIds
                              .map((id) => id == details.sourceResourceId
                                  ? details.newResourceId!
                                  : id)
                              .toList();
                        } else {
                          // Single-resource or source unknown — assign to target.
                          updatedResourceIds = [details.newResourceId!];
                        }
                      }
                      // If resourceIds is null → stays null (event visible in
                      // all resources). Only the time changes.

                      _datasource.updateEvent(details.event.copyWith(
                        startTime: details.newStart,
                        endTime: details.newEnd,
                        resourceIds: updatedResourceIds,
                      ));
                    },
                    onResizeEnd: (TideResizeEndDetails details) {
                      _datasource.updateEvent(details.event.copyWith(
                        startTime: details.newStart,
                        endTime: details.newEnd,
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _theme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: _theme.borderColor),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Salon Booking',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE91E63),
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: widget.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
            child: GestureDetector(
              onTap: widget.onToggleDarkMode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: _theme.borderColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
                  style: TextStyle(
                    fontSize: 12,
                    color: _theme.headerTextStyle.color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onEventTap(TideEvent event) {
    final customer = event.metadata?['customer'] ?? 'Unknown';
    final price = event.metadata?['price'] as double?;
    debugPrint(
      'Appointment: ${event.subject} | Customer: $customer | '
      'Price: ${price != null ? "\u20AC${price.toStringAsFixed(0)}" : "N/A"}',
    );
  }
}

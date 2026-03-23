// Core — Models
export 'src/core/models/conflict.dart';
export 'src/core/models/date_time_range.dart';
export 'src/core/models/drag_details.dart';
export 'src/core/models/event.dart';
export 'src/core/models/event_changes.dart';
export 'src/core/models/resource.dart';
export 'src/core/models/time_region.dart';
export 'src/core/models/view.dart';

// Core — Recurrence
export 'src/core/recurrence/recurrence.dart';
export 'src/core/recurrence/rrule_description.dart';
export 'src/core/recurrence/rrule_generator.dart';
export 'src/core/recurrence/rrule_model.dart';
export 'src/core/recurrence/rrule_parser.dart';
export 'src/core/recurrence/occurrence_engine.dart';

// Core — Datasources & Controller
export 'src/core/controller.dart';
export 'src/core/datasource.dart';
export 'src/core/datasource_in_memory.dart';
export 'src/core/datasource_stream.dart';
export 'src/core/presets.dart';

// Theme
export 'src/theme/tide_theme.dart';
export 'src/theme/tide_theme_data.dart';

// Rendering
export 'src/rendering/current_time_painter.dart';
export 'src/rendering/event_layout_engine.dart';
export 'src/rendering/resource_layout.dart';
export 'src/rendering/time_region_painter.dart';
export 'src/rendering/time_slot_painter.dart';

// Views — Day
export 'src/views/day/day_view.dart';
export 'src/views/day/day_view_layout.dart';
export 'src/views/day/time_slot_widget.dart';

// Views — Week
export 'src/views/week/week_view.dart';
export 'src/views/week/week_header.dart';

// Views — Work Week
export 'src/views/work_week/work_week_view.dart';

// Views — Month
export 'src/views/month/month_view.dart';
export 'src/views/month/month_cell.dart';
export 'src/views/month/month_agenda_panel.dart';

// Views — Schedule
export 'src/views/schedule/schedule_view.dart';
export 'src/views/schedule/schedule_item.dart';

// Views — Timeline
export 'src/views/timeline_day/timeline_day_view.dart';
export 'src/views/timeline_day/resource_row.dart';
export 'src/views/timeline_week/timeline_week_view.dart';
export 'src/views/timeline_work_week/timeline_work_week_view.dart';
export 'src/views/timeline_month/timeline_month_view.dart';

// Views — Resource (vertical time axis, side-by-side resource columns)
export 'src/views/resource_day/resource_day_view.dart';
export 'src/views/resource_week/resource_week_view.dart';

// Views — Multi-Week, Year, View Switcher
export 'src/views/multi_week/multi_week_view.dart';
export 'src/views/year/year_view.dart';
export 'src/views/view_switcher.dart';

// Interaction — Drag & Drop
export 'src/interaction/drag_drop/drag_handler.dart';
export 'src/interaction/drag_drop/resize_handler.dart';
export 'src/interaction/drag_drop/auto_scroll.dart';
export 'src/interaction/drag_drop/external_drag.dart';
export 'src/interaction/drag_drop/snap_engine.dart';
export 'src/interaction/drag_drop/conflict_detector.dart';
export 'src/interaction/drag_drop/time_axis.dart';

// Interaction — Selection
export 'src/interaction/selection/event_selection.dart';
export 'src/interaction/selection/date_selection.dart';
export 'src/interaction/selection/rubber_band.dart';

// Interaction — Keyboard
export 'src/interaction/keyboard/shortcut_handler.dart';
export 'src/interaction/keyboard/focus_traversal.dart';

// Interaction — Undo
export 'src/interaction/undo/undo_action.dart';
export 'src/interaction/undo/undo_manager.dart';

// Localization
export 'src/l10n/tide_localizations.dart';

// Widgets — Main
export 'src/widgets/tide_calendar.dart';

// Widgets — Headers
export 'src/widgets/header/calendar_header.dart';
export 'src/widgets/header/view_switcher_bar.dart';

// Widgets — Resource Header
export 'src/widgets/resource_header/resource_header.dart';
export 'src/widgets/resource_header/resource_load_indicator.dart';

// Widgets — Common
export 'src/widgets/common/tide_popup.dart';
export 'src/widgets/common/tide_scrollbar.dart';
export 'src/widgets/common/adaptive_layout.dart';
export 'src/widgets/common/scroll_sync.dart';

// Widgets — Context Menu
export 'src/widgets/context_menu/tide_context_menu.dart';

// Widgets — Tooltip
export 'src/widgets/tooltip/tide_tooltip.dart';

// Widgets — Recurrence Editor
export 'src/widgets/recurrence_editor/recurrence_editor.dart';

// Export / Import
export 'src/core/export/ical_export.dart';
export 'src/core/export/ical_import.dart';

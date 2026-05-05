## 1.2.1

### Fixes
- `TideShiftPlanner` now forwards `headerBuilder`, `footerBuilder`, and `dragFeedbackBuilder` to its internal `ShiftResourcePalette`. Exposed as new `paletteHeaderBuilder`, `paletteFooterBuilder`, and `paletteDragFeedbackBuilder` parameters so consumers can render branding, hint boxes, or custom drag-ghosts above/below the resource list and under the pointer without forking the widget.

## 1.2.0

### Companion Widget — TideShiftPlanner
- `TideShiftPlanner` — week-based shift scheduling companion widget composing a sidebar resource palette with a 7-column week grid and drag-and-drop shift creation.
- `cardBuilder` parameter for custom shift card rendering (replaces default `ShiftCard` when provided).
- `shiftEditPromptBuilder` parameter to enable active edit flows; pairs with `onShiftUpdated` callback (analogous to `shiftPromptBuilder` + `onShiftCreated` for creation).
- `TideShiftPlannerController` — `ChangeNotifier`-based view-state controller with week navigation (`goToWeek`, `goToPreviousWeek`, `goToNextWeek`) and pure-function bulk-copy helpers (`generateCopiedShifts`, `copyPreviousWeek`, `generateMonthFromWeek`, `generateRangeFromWeek`). Holds no domain state.
- `TideKwBadge` — toolbar building block rendering the ISO-8601 calendar-week label (e.g. `KW 13` / `Week 13`).
- `ShiftDragMode` enum (`instantWithDefaults`, `promptForTime`) and `ShiftCopyMode` enum (`replicateWeekly`).
- Closed-day predicate with three-fold OR logic: `closedDaysOfWeek` (set of weekdays), `closedDates` (set of concrete dates), and `isDayClosed` (custom callback).

### Theme
- 17 new `TideThemeData` properties for shift-planner styling: `shiftPlannerSidebarWidth`, `shiftPlannerSidebarBackground`, `shiftPlannerCardPadding`, `shiftPlannerCardBorderRadius`, `shiftPlannerCardLeftBorderWidth`, `shiftPlannerClosedDayPatternColor`, `shiftPlannerClosedDayPatternSpacing`, `shiftPlannerColumnHeaderTextStyle`, `shiftPlannerColumnDateStyle`, `shiftPlannerCardTitleStyle`, `shiftPlannerCardTimeStyle`, `shiftPlannerClosedLabelStyle`, `shiftPlannerAddButtonStyle`, `shiftPlannerAddButtonBorderColor`, `shiftPlannerSidebarAvatarTextStyle`, `shiftPlannerSidebarItemTextStyle`, `shiftPlannerCardAvatarTextStyle`.

### Localization
- Added 5 new `TideLocalizations` strings (DE + EN): `closed`, `addShift`, `staff`, `dragToDay`, and the templated `weekNumberLabel(int week)` helper backed by `weekNumberTemplate`.

### Datasource
- Bulk methods on `TideDatasource`: `addEvents`, `updateEvents`, `removeEvents` with default `forEach`-based implementations and overrides on `TideInMemoryDatasource`.

### Example
- New example app at `example/shift_planner/main.dart` demonstrating the planner with controller, toolbar, closed days, and bulk-copy.

## 1.1.1

### Documentation
- Rewrote README with hero banner, light/dark theme comparison, mobile previews, and per-feature screenshots.
- Added brand assets in `docs/brand/`: SVG vector logo plus light/dark PNG variants for the square mark and wordmark.
- Added 19 product screenshots in `docs/screenshots/` covering the calendar views, companion widgets, and the recurrence editor.
- Adjusted `.gitignore` and `.pubignore` so README assets ship with the package while internal docs stay private.

## 1.1.0

### Companion Widgets
- `TideDateStrip` — horizontal scrollable date picker strip with selection, today indicator, and disabled dates
- `TideSlotPicker` — time slot selection widget with optional resource grouping, loading, and empty states
- `TideTemplateEditor` — weekly template editor for shift/schedule planning with drag-to-create, resize, break overlays, and resource legend

### New Models
- `TideSlot` — bookable time slot data model for `TideSlotPicker`
- `TideTemplateSlot` — weekly template slot data model for `TideTemplateEditor`
- `TideTimeOfDay` — lightweight time-of-day class (widget-layer alternative to Material's `TimeOfDay`)

### Theme
- Added 21 new `TideThemeData` properties for companion widget styling (date strip, slot picker, template editor sections)

### Localization
- Added 13 new `TideLocalizations` strings for companion widgets (weekday abbreviations, labels)
- Added `TideLocalizations.weekdayAbbr(int isoWeekday)` helper method

## 1.0.3

- Fix automated publishing with tag-based OIDC workflow.

## 1.0.2

- Fix automated publishing via GitHub Actions OIDC.

## 1.0.1

- Fix repository and issue tracker URLs in pubspec.yaml.

## 1.0.0

Initial stable release of timetide.

### Views
- 13 calendar views: day, week, work week, month, schedule, timeline day/week/work week/month, multi-week, year, resource day, resource week
- `TideResourceDayView` — vertical time axis with side-by-side resource columns and avatar+name headers
- `TideResourceWeekView` — same layout with day sub-columns per resource and two-level headers
- 2 new `TideView` enum values: `resourceDay`, `resourceWeek`
- Shared time axis (`TideTimeAxis`) and synchronized scrolling (`TideScrollSync`) across timeline views
- Timeline views migrated to the shared `TideScrollSync` utility, reducing duplication
- All-day event panels with collapsible headers
- Current time indicator

### Core
- `TideController` — central state management with `ValueNotifier`s for granular rebuilds
- `TideDatasource` abstraction with `TideInMemoryDatasource` and `TideStreamDatasource`
- `TideEvent`, `TideResource`, `TideTimeRegion` data models
- Preset configurations via `TidePreset`

### Recurrence
- RFC 5545 RRULE parser (`TideRRuleParser`) and generator (`TideRRuleGenerator`)
- Lazy occurrence engine (`TideOccurrenceEngine`) using `sync*` generators
- Human-readable descriptions in English and German
- EXDATE and RDATE support

### Interaction
- `TideDragHandler` wired end-to-end into all 7 drag-capable views (day, week, work week, timeline day, timeline week, timeline work week, resource day, resource week)
- Platform-adaptive drag: long-press on mobile, click-and-drag on desktop
- Cross-resource drag — dragging an event to a different resource column updates `resourceId` automatically
- `TideResizeHandler` — event edge resize (drag start or end boundary) with snap-to-grid
- `TideSnapEngine` — configurable grid snapping for both drag and resize
- `TideConflictDetector` — live overlap detection computed during drag, before the event is committed
- `TideAutoScroll` — edge-scrolling activates when the pointer approaches a viewport boundary
- `TideExternalDragScope` — enables dragging events into the calendar from an external sidebar or widget tree
- `TideTimeAxis` — pixel-to-time and time-to-pixel conversion abstraction shared by all time-based views
- Event and date selection with rubber-band
- Keyboard shortcuts and focus traversal
- Undo/redo with configurable history

### Widgets
- `TideCalendar` — main entry-point widget
- `TideCalendarHeader` — navigation and view switcher
- `TideResourceHeader` — resource display for timeline views
- `TideContextMenu` — design-agnostic overlay context menu
- `TideTooltip` — custom overlay tooltip
- `TideRecurrenceEditor` — visual RRULE builder with live preview
- `TideScrollbar` — custom painted scrollbar
- `TideAdaptiveLayout` — responsive breakpoint layout

### Theme
- `TideThemeData` with 40+ visual properties
- `TideTheme` InheritedWidget for injection
- `lerp()` support for animated theme transitions

### Export/Import
- iCalendar (`.ics`) export and import
- RFC 5545 compliant VEVENT generation

### Localization
- Built-in English and German translations
- Custom locale support via `TideLocalizations`

### Architecture
- Widget-layer only — no Material or Cupertino imports
- Monolithic package with tree-shaking
- Custom RRULE parser — no external dependency

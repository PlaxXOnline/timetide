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

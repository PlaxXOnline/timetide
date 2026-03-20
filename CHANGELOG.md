## 0.1.0

Initial release of timetide.

### Views
- 11 calendar views: day, week, work week, month, schedule, timeline day/week/work week/month, multi-week, year
- Shared time axis and synchronized scrolling across timeline views
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
- Custom drag & drop (no Flutter `Draggable`)
- Event resize with snap-to-grid
- Auto-scroll near viewport edges
- External drag-in support
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

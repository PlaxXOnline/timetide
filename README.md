# timetide

A comprehensive Flutter scheduling calendar package with 11 views, multi-resource scheduling, drag & drop, RRULE recurrence, and iCalendar export/import.

**Widget-layer only** — imports only `package:flutter/widgets.dart`. No Material or Cupertino dependency. You control the look and feel.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  timetide: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:timetide/timetide.dart';

final datasource = TideInMemoryDatasource(
  events: [
    TideEvent(
      id: '1',
      subject: 'Team Meeting',
      startTime: DateTime(2026, 3, 20, 10, 0),
      endTime: DateTime(2026, 3, 20, 11, 0),
    ),
  ],
);

TideCalendar(
  datasource: datasource,
  initialView: TideView.week,
)
```

## Features

### 11 Calendar Views

| View | Class | Description |
|------|-------|-------------|
| Day | `TideDayView` | Single day, vertical time axis |
| Week | `TideWeekView` | 7-column week layout |
| Work Week | `TideWorkWeekView` | Monday through Friday |
| Month | `TideMonthView` | Grid with event indicators |
| Schedule | `TideScheduleView` | Scrollable agenda list |
| Timeline Day | `TideTimelineDayView` | Day + horizontal resources |
| Timeline Week | `TideTimelineWeekView` | Week + horizontal resources |
| Timeline Work Week | `TideTimelineWorkWeekView` | Work week + resources |
| Timeline Month | `TideTimelineMonthView` | Month + resources |
| Multi-Week | `TideMultiWeekView` | Configurable N-week view |
| Year | `TideYearView` | 12-month overview |

### Multi-Resource Scheduling

Assign events to rooms, people, or equipment with `TideResource`. Timeline views display resources as rows with synchronized scrolling.

### Drag & Drop

Move and resize events with custom gesture handling. Supports:
- Drag to reschedule
- Resize start/end times
- Auto-scroll near edges
- Snap to time slots
- Conflict detection during drag
- External drag-in

### RRULE Recurrence

Built-in RFC 5545 RRULE parser, generator, and lazy occurrence engine:

```dart
final rule = TideRecurrence.parse('RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR');
final dates = rule!.occurrences(start: DateTime(2026, 3, 1));
final desc = rule.describe(locale: 'en'); // "Every week on Monday, Wednesday, Friday"
```

### Visual Recurrence Editor

`TideRecurrenceEditor` provides a fully custom RRULE builder widget with live occurrence preview — no Material widgets required.

### iCalendar Export/Import

Export events to `.ics` format and import iCalendar files back into the datasource. Full RFC 5545 compliance.

### Custom Theming

`TideThemeData` provides 40+ properties for colors, typography, spacing, and more. Inject via `TideTheme` (InheritedWidget):

```dart
TideTheme(
  data: TideThemeData(
    primaryColor: Color(0xFF6200EE),
    eventBorderRadius: BorderRadius.circular(8),
  ),
  child: TideCalendar(datasource: datasource),
)
```

### Localization

Built-in English and German support via `TideLocalizations`. Add custom locales by creating a `TideLocalizations` instance.

### Responsive Layout

`TideAdaptiveLayout` + `TideBreakpoints` automatically switch between mobile, tablet, and desktop layouts.

### Context Menu & Tooltip

Design-agnostic `TideContextMenu` (right-click/long-press) and `TideTooltip` (hover/long-press) — all custom, no Material.

## Architecture

- **Widget-layer only**: `flutter/widgets.dart` + `gestures.dart` + `services.dart` + `rendering.dart` + `foundation.dart`
- **Monolithic package**: All 11 views in a single package. Tree-shaking removes unused code.
- **Custom RRULE engine**: RFC 5545 parser with lazy `sync*` occurrence generation.
- **No external dependencies** beyond `flutter` and `collection`.

## API Overview

| Class | Purpose |
|-------|---------|
| `TideCalendar` | Main entry-point widget |
| `TideController` | Central state manager |
| `TideDatasource` | Abstract data interface |
| `TideInMemoryDatasource` | Local in-memory data |
| `TideStreamDatasource` | Reactive stream data |
| `TideEvent` | Event data model |
| `TideResource` | Resource data model |
| `TideThemeData` | Theme configuration |
| `TideRecurrence` | RRULE facade |
| `TideRecurrenceEditor` | Visual RRULE builder |
| `TideContextMenu` | Overlay context menu |
| `TideTooltip` | Overlay tooltip |

All public types use the `Tide` prefix for discoverability.

## License

MIT

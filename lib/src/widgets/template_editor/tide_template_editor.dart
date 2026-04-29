import 'dart:math' as math;
import 'dart:ui' as ui show Color;

import 'package:flutter/widgets.dart';

import '../../core/models/resource.dart';
import '../../core/models/template_slot.dart';
import '../../l10n/tide_localizations.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';
import 'template_slot_painter.dart';

/// A weekly template editor for shift and schedule planning.
///
/// Displays a 7-day grid (Monday–Sunday) with configurable hour range. Each
/// [TideTemplateSlot] is rendered as a positioned block within its day column.
/// Supports tap-to-edit, drag-to-create, and edge-drag-to-resize interactions.
class TideTemplateEditor extends StatefulWidget {
  /// Creates a [TideTemplateEditor].
  const TideTemplateEditor({
    required this.resources,
    required this.slots,
    this.onSlotCreated,
    this.onSlotUpdated,
    this.onSlotDeleted,
    this.readOnly = false,
    this.startHour = 7,
    this.endHour = 21,
    this.slotGranularity = const Duration(minutes: 15),
    this.showBreaks = true,
    this.resourceColors,
    this.locale,
    super.key,
  });

  /// Resources displayed in the legend and used for color mapping.
  final List<TideResource> resources;

  /// Template slots to display on the grid.
  final List<TideTemplateSlot> slots;

  /// Called when a new slot is created via drag-to-create.
  final ValueChanged<TideTemplateSlot>? onSlotCreated;

  /// Called when a slot is tapped (for editing) or resized.
  final ValueChanged<TideTemplateSlot>? onSlotUpdated;

  /// Called when a slot is deleted.
  final ValueChanged<TideTemplateSlot>? onSlotDeleted;

  /// When true, disables all interaction callbacks.
  final bool readOnly;

  /// First visible hour (inclusive). Defaults to 7.
  final int startHour;

  /// Last visible hour (exclusive). Defaults to 21.
  final int endHour;

  /// Time granularity for snapping slot start/end times.
  final Duration slotGranularity;

  /// Whether to render the break pattern overlay for break slots.
  final bool showBreaks;

  /// Optional per-resource color overrides keyed by resource ID.
  final Map<String, ui.Color>? resourceColors;

  /// Optional localizations for day headers and labels.
  final TideLocalizations? locale;

  @override
  State<TideTemplateEditor> createState() => _TideTemplateEditorState();
}

class _TideTemplateEditorState extends State<TideTemplateEditor> {
  static const double _timeColumnWidth = 60.0;
  static const double _headerHeight = 32.0;

  // ─── Drag-to-create state ──────────────────────────────
  int? _createDayOfWeek;
  TideTimeOfDay? _createStartTime;
  TideTimeOfDay? _createEndTime;

  // ─── Resize state ──────────────────────────────────────
  TideTemplateSlot? _resizingSlot;
  bool _resizingFromTop = false;
  TideTimeOfDay? _resizeTime;

  // ─── Helpers ───────────────────────────────────────────

  int get _hourCount => widget.endHour - widget.startHour;

  ui.Color _colorForSlot(TideTemplateSlot slot, TideThemeData theme) {
    // 1. Explicit resource color map.
    final explicit = widget.resourceColors?[slot.resourceId];
    if (explicit != null) return explicit;

    // 2. Resource's own color.
    for (final r in widget.resources) {
      if (r.id == slot.resourceId) return r.color;
    }

    // 3. Fallback to theme primary color.
    return theme.primaryColor;
  }

  TideResource? _resourceForSlot(TideTemplateSlot slot) {
    for (final r in widget.resources) {
      if (r.id == slot.resourceId) return r;
    }
    return null;
  }

  String _dayLabel(int dayOfWeek) {
    final l = widget.locale;
    if (l != null) return l.weekdayAbbr(dayOfWeek);
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[(dayOfWeek - 1) % 7];
  }

  /// Snap total minutes to the nearest granularity boundary.
  int _snap(int totalMinutes) {
    final g = widget.slotGranularity.inMinutes;
    if (g <= 0) return totalMinutes;
    return (totalMinutes / g).round() * g;
  }

  TideTimeOfDay _minutesToTime(int totalMinutes) {
    final clamped = totalMinutes.clamp(0, 24 * 60 - 1);
    return TideTimeOfDay(hour: clamped ~/ 60, minute: clamped % 60);
  }

  /// Convert a local y offset (within the grid body) to total minutes.
  int _yToMinutes(double y, double hourHeight) {
    return widget.startHour * 60 + (y / hourHeight * 60).round();
  }

  /// Convert total minutes to y offset within the grid body.
  double _minutesToY(int totalMinutes, double hourHeight) {
    return (totalMinutes - widget.startHour * 60) * hourHeight / 60;
  }

  /// Calculate which day column an x offset corresponds to.
  int _xToDayOfWeek(double x, double dayColumnWidth) {
    final col = ((x - _timeColumnWidth) / dayColumnWidth).floor();
    return (col.clamp(0, 6)) + 1; // 1=Mon … 7=Sun
  }

  // ─── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final dayColumnWidth = theme.templateEditorDayColumnWidth;
    final totalWidth = _timeColumnWidth + 7 * dayColumnWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid area — fills available vertical space, scrolls horizontally.
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final themeHourHeight = theme.templateEditorHourHeight;
              final themeGridHeight = _hourCount * themeHourHeight;
              final availableBodyHeight =
                  constraints.maxHeight - _headerHeight;

              // Use theme hour height when content fits, otherwise shrink to
              // fit available height (avoids inner vertical scroll, which
              // otherwise conflicts with drag-to-create gestures).
              final hourHeight = availableBodyHeight >= themeGridHeight
                  ? themeHourHeight
                  : math.max(availableBodyHeight / _hourCount, 1.0);
              final gridHeight = _hourCount * hourHeight;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalWidth,
                  height: gridHeight + _headerHeight,
                  child: Column(
                    children: [
                      _buildDayHeaders(theme, dayColumnWidth),
                      SizedBox(
                        height: gridHeight,
                        child: _buildGridBody(
                          theme,
                          hourHeight,
                          dayColumnWidth,
                          gridHeight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Resource legend.
        _buildLegend(theme),
      ],
    );
  }

  Widget _buildDayHeaders(TideThemeData theme, double dayColumnWidth) {
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          const SizedBox(width: _timeColumnWidth),
          for (var d = 1; d <= 7; d++)
            SizedBox(
              width: dayColumnWidth,
              child: Center(
                child: Text(
                  _dayLabel(d),
                  style: theme.templateEditorHeaderTextStyle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridBody(
    TideThemeData theme,
    double hourHeight,
    double dayColumnWidth,
    double gridHeight,
  ) {
    return SizedBox(
      width: _timeColumnWidth + 7 * dayColumnWidth,
      height: gridHeight,
      child: Stack(
        children: [
          // Grid lines.
          Positioned.fill(
            child: CustomPaint(
              painter: TemplateGridPainter(
                hourCount: _hourCount,
                hourHeight: hourHeight,
                dayColumnWidth: dayColumnWidth,
                gridLineColor: theme.templateEditorGridLineColor,
                timeColumnWidth: _timeColumnWidth,
              ),
            ),
          ),
          // Time labels.
          for (var h = 0; h < _hourCount; h++)
            Positioned(
              left: 0,
              top: h * hourHeight,
              width: _timeColumnWidth,
              height: hourHeight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 2),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Text(
                    '${(widget.startHour + h).toString().padLeft(2, '0')}:00',
                    style: theme.timeSlotTextStyle,
                  ),
                ),
              ),
            ),
          // Interaction layer — sits *below* the slots so slots still get
          // taps and resize drags, but empty cells receive pan gestures for
          // drag-to-create. Opaque so it wins over any parent scrollable.
          if (!widget.readOnly)
            Positioned(
              left: _timeColumnWidth,
              top: 0,
              width: 7 * dayColumnWidth,
              height: gridHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) =>
                    _onCreatePanStart(details, hourHeight, dayColumnWidth),
                onPanUpdate: (details) =>
                    _onCreatePanUpdate(details, hourHeight),
                onPanEnd: (_) => _onCreatePanEnd(),
                onPanCancel: _onCreatePanCancel,
              ),
            ),
          // Rendered slots — above the interaction layer so they capture
          // taps and edge-drag resize directly.
          ..._buildSlots(theme, hourHeight, dayColumnWidth),
          // Drag-to-create preview. Must be a direct Positioned child of
          // the Stack so its offsets are respected.
          if (_createDayOfWeek != null &&
              _createStartTime != null &&
              _createEndTime != null)
            _buildCreatePreview(theme, hourHeight, dayColumnWidth),
        ],
      ),
    );
  }

  List<Widget> _buildSlots(
    TideThemeData theme,
    double hourHeight,
    double dayColumnWidth,
  ) {
    final widgets = <Widget>[];

    for (final slot in widget.slots) {
      if (slot.dayOfWeek < 1 || slot.dayOfWeek > 7) continue;

      final left =
          _timeColumnWidth + (slot.dayOfWeek - 1) * dayColumnWidth + 2;
      final top = _minutesToY(slot.startTime.totalMinutes, hourHeight);
      final bottom = _minutesToY(slot.endTime.totalMinutes, hourHeight);
      final height = bottom - top;
      if (height <= 0) continue;

      final color = _colorForSlot(slot, theme);
      final resource = _resourceForSlot(slot);
      final isResizing = _resizingSlot?.id == slot.id;

      // Use resize preview time if currently resizing this slot.
      final displayTop = isResizing && _resizingFromTop && _resizeTime != null
          ? _minutesToY(_resizeTime!.totalMinutes, hourHeight)
          : top;
      final displayBottom =
          isResizing && !_resizingFromTop && _resizeTime != null
              ? _minutesToY(_resizeTime!.totalMinutes, hourHeight)
              : bottom;
      final displayHeight = displayBottom - displayTop;
      if (displayHeight <= 0) continue;

      widgets.add(
        Positioned(
          left: left,
          top: displayTop,
          width: dayColumnWidth - 4,
          height: displayHeight,
          child: _SlotWidget(
            slot: slot,
            color: color,
            resourceName: resource?.displayName,
            showBreaks: widget.showBreaks,
            readOnly: widget.readOnly,
            onTap: widget.readOnly
                ? null
                : () => widget.onSlotUpdated?.call(slot),
            onVerticalDragStart: widget.readOnly
                ? null
                : (details) =>
                    _onSlotDragStart(details, slot, displayHeight),
            onVerticalDragUpdate: widget.readOnly
                ? null
                : (details) => _onSlotDragUpdate(details, hourHeight),
            onVerticalDragEnd: widget.readOnly ? null : (_) => _onSlotDragEnd(),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildCreatePreview(
    TideThemeData theme,
    double hourHeight,
    double dayColumnWidth,
  ) {
    final startMin = _createStartTime!.totalMinutes;
    final endMin = _createEndTime!.totalMinutes;
    final topMin = math.min(startMin, endMin);
    final bottomMin = math.max(startMin, endMin);

    final top = _minutesToY(topMin, hourHeight);
    final bottom = _minutesToY(bottomMin, hourHeight);
    final left = _timeColumnWidth + (_createDayOfWeek! - 1) * dayColumnWidth + 2;

    return Positioned(
      left: left,
      top: top,
      width: dayColumnWidth - 4,
      height: math.max(bottom - top, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const ui.Color(0x332196F3),
          border: Border.all(
            color: const ui.Color(0xFF2196F3),
            width: 1,
          ),
          borderRadius: theme.templateEditorSlotBorderRadius,
        ),
      ),
    );
  }

  Widget _buildLegend(TideThemeData theme) {
    if (widget.resources.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            for (var i = 0; i < widget.resources.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              _LegendItem(
                resource: widget.resources[i],
                color: widget.resourceColors?[widget.resources[i].id] ??
                    widget.resources[i].color,
                textStyle: theme.timeSlotTextStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Interaction: Drag-to-Create ───────────────────────

  void _onCreatePanStart(
    DragStartDetails details,
    double hourHeight,
    double dayColumnWidth,
  ) {
    final localX = details.localPosition.dx;
    final localY = details.localPosition.dy;
    // Interaction layer is offset by _timeColumnWidth from the stack origin,
    // so the local x is already relative to the first day column.
    final day = _xToDayOfWeek(localX + _timeColumnWidth, dayColumnWidth);
    final minutes = _snap(_yToMinutes(localY, hourHeight));
    final time = _minutesToTime(minutes);

    setState(() {
      _createDayOfWeek = day;
      _createStartTime = time;
      _createEndTime = time;
    });
  }

  void _onCreatePanUpdate(
    DragUpdateDetails details,
    double hourHeight,
  ) {
    if (_createStartTime == null) return;
    final minutes = _snap(_yToMinutes(details.localPosition.dy, hourHeight));
    final time = _minutesToTime(minutes);

    setState(() {
      _createEndTime = time;
    });
  }

  void _onCreatePanEnd() {
    if (_createDayOfWeek != null &&
        _createStartTime != null &&
        _createEndTime != null) {
      final startMin = math.min(
          _createStartTime!.totalMinutes, _createEndTime!.totalMinutes);
      final endMin = math.max(
          _createStartTime!.totalMinutes, _createEndTime!.totalMinutes);

      if (endMin > startMin) {
        final slot = TideTemplateSlot(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          resourceId:
              widget.resources.isNotEmpty ? widget.resources.first.id : '',
          dayOfWeek: _createDayOfWeek!,
          startTime: _minutesToTime(startMin),
          endTime: _minutesToTime(endMin),
        );
        widget.onSlotCreated?.call(slot);
      }
    }

    setState(() {
      _createDayOfWeek = null;
      _createStartTime = null;
      _createEndTime = null;
    });
  }

  void _onCreatePanCancel() {
    if (_createDayOfWeek == null) return;
    setState(() {
      _createDayOfWeek = null;
      _createStartTime = null;
      _createEndTime = null;
    });
  }

  // ─── Interaction: Resize ───────────────────────────────

  void _onSlotDragStart(
    DragStartDetails details,
    TideTemplateSlot slot,
    double slotHeight,
  ) {
    final localY = details.localPosition.dy;
    final isTop = localY < 8;
    final isBottom = localY > slotHeight - 8;
    if (!isTop && !isBottom) return;

    setState(() {
      _resizingSlot = slot;
      _resizingFromTop = isTop;
      _resizeTime =
          isTop ? slot.startTime : slot.endTime;
    });
  }

  void _onSlotDragUpdate(DragUpdateDetails details, double hourHeight) {
    if (_resizingSlot == null || _resizeTime == null) return;

    final delta = details.delta.dy;
    final minutesDelta = (delta / hourHeight * 60).round();
    final newMinutes = _snap(_resizeTime!.totalMinutes + minutesDelta);
    final newTime = _minutesToTime(newMinutes);

    setState(() {
      _resizeTime = newTime;
    });
  }

  void _onSlotDragEnd() {
    if (_resizingSlot != null && _resizeTime != null) {
      final updated = _resizingFromTop
          ? _resizingSlot!.copyWith(startTime: _resizeTime)
          : _resizingSlot!.copyWith(endTime: _resizeTime);

      if (updated.startTime < updated.endTime) {
        widget.onSlotUpdated?.call(updated);
      }
    }

    setState(() {
      _resizingSlot = null;
      _resizeTime = null;
    });
  }
}

// ─── Private Widgets ─────────────────────────────────────

class _SlotWidget extends StatelessWidget {
  const _SlotWidget({
    required this.slot,
    required this.color,
    required this.resourceName,
    required this.showBreaks,
    required this.readOnly,
    this.onTap,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final TideTemplateSlot slot;
  final ui.Color color;
  final String? resourceName;
  final bool showBreaks;
  final bool readOnly;
  final VoidCallback? onTap;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: theme.templateEditorSlotBorderRadius,
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxHeight < 32) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(left: 8, top: 4, right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (resourceName != null)
                  Text(
                    resourceName!,
                    style: theme.eventTitleStyle.copyWith(
                      color: const ui.Color(0xFF212121),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                Text(
                  '${slot.startTime} – ${slot.endTime}',
                  style: theme.eventTimeStyle.copyWith(
                    color: const ui.Color(0xFF616161),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          );
        },
      ),
    );

    Widget child = content;

    // Break pattern overlay.
    if (slot.isBreak && showBreaks) {
      child = Stack(
        children: [
          content,
          Positioned.fill(
            child: ClipRRect(
              borderRadius: theme.templateEditorSlotBorderRadius,
              child: CustomPaint(
                painter: BreakPatternPainter(
                  color: theme.templateEditorBreakPatternColor,
                  spacing: theme.templateEditorBreakPatternSpacing,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (readOnly) return child;

    return GestureDetector(
      onTap: onTap,
      onVerticalDragStart: onVerticalDragStart,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.resource,
    required this.color,
    required this.textStyle,
  });

  final TideResource resource;
  final ui.Color color;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: resource.avatar != null
              ? ClipOval(
                  child: Image(
                    image: resource.avatar!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    resource.displayName.isNotEmpty
                        ? resource.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(resource.displayName, style: textStyle),
      ],
    );
  }
}

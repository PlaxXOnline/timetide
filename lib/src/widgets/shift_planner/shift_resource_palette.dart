import 'package:flutter/widgets.dart';

import '../../core/models/drag_details.dart';
import '../../core/models/resource.dart';
import '../../interaction/drag_drop/external_drag.dart';
import '../../theme/tide_theme.dart';
import 'shift_drag_mode.dart';

/// Sidebar palette listing the resources available for drag-and-drop
/// scheduling in the shift planner.
///
/// Each resource is rendered as a row containing a colored accent bar, an
/// initials avatar, and the resource's display name. Every row is wrapped in
/// a [TideDragSource] carrying a [TideExternalDragData] payload that the
/// receiving day column / shift target uses to create a new shift.
///
/// The palette itself is mode-agnostic: it forwards [dragMode] only so
/// callers can place the value where it is configured, but the produced
/// drag data is identical regardless of the mode. Whether the drop creates
/// the shift instantly or opens a prompt is decided by the drop target.
///
/// ```dart
/// ShiftResourcePalette(
///   resources: controller.resources,
///   dragMode: ShiftDragMode.instantWithDefaults,
///   defaultShiftDuration: const Duration(hours: 8),
///   headerBuilder: (_) => const Text('Staff'),
/// )
/// ```
class ShiftResourcePalette extends StatelessWidget {
  /// Creates a [ShiftResourcePalette].
  const ShiftResourcePalette({
    super.key,
    required this.resources,
    required this.dragMode,
    required this.defaultShiftDuration,
    this.headerBuilder,
    this.footerBuilder,
    this.dragFeedbackBuilder,
  });

  /// Resources rendered as draggable rows.
  final List<TideResource> resources;

  /// Informational drag-mode marker forwarded to consumers.
  ///
  /// The palette itself does not vary its output based on this value; the
  /// drop target decides whether to instantly create the shift or to prompt
  /// the user.
  final ShiftDragMode dragMode;

  /// Duration applied to a freshly created shift on drop.
  final Duration defaultShiftDuration;

  /// Optional widget rendered above the resource rows.
  final WidgetBuilder? headerBuilder;

  /// Optional widget rendered below the resource rows.
  final WidgetBuilder? footerBuilder;

  /// Optional builder for the drag feedback shown under the pointer.
  final Widget Function(TideExternalDragData data)? dragFeedbackBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);

    // Align lets the palette honor its desired sidebar width even when the
    // surrounding layout would otherwise stretch it.
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Container(
        key: const ValueKey('shift-resource-palette-surface'),
        width: theme.shiftPlannerSidebarWidth,
        color: theme.shiftPlannerSidebarBackground,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (headerBuilder != null) headerBuilder!(context),
            for (final resource in resources) _buildRow(resource),
            if (footerBuilder != null) footerBuilder!(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(TideResource resource) {
    final data = TideExternalDragData(
      subject: resource.displayName,
      duration: defaultShiftDuration,
      color: resource.color,
      metadata: <String, dynamic>{'resourceId': resource.id},
    );

    return TideDragSource(
      data: data,
      feedbackBuilder: dragFeedbackBuilder,
      child: _ResourceRow(resource: resource),
    );
  }
}

/// Visual row for a single resource: color bar + avatar + name.
class _ResourceRow extends StatelessWidget {
  const _ResourceRow({required this.resource});

  final TideResource resource;

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);
    final initial = _initialOf(resource.displayName);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: <Widget>[
          // 4px wide color accent bar.
          SizedBox(
            key: ValueKey('shift-resource-bar-${resource.id}'),
            width: 4,
            height: 28,
            child: ColoredBox(color: resource.color),
          ),
          const SizedBox(width: 10),
          // 28x28 initials circle.
          SizedBox(
            key: ValueKey('shift-resource-avatar-${resource.id}'),
            width: 28,
            height: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: resource.color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: theme.shiftPlannerSidebarAvatarTextStyle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              resource.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.shiftPlannerSidebarItemTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the first character of [name] in upper case, or `?` when empty.
  static String _initialOf(String name) {
    if (name.isEmpty) return '?';
    return name.characters.first.toUpperCase();
  }
}

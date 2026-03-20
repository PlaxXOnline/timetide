import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';
import '../common/tide_popup.dart';

/// A single item in a [TideContextMenu].
class TideContextMenuItem {
  /// Creates a context menu item.
  const TideContextMenuItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
  });

  /// Display text for the menu item.
  final String label;

  /// Called when the item is tapped.
  final VoidCallback onTap;

  /// Optional leading icon widget.
  final Widget? icon;

  /// Whether the item is interactive. Disabled items are visually muted.
  final bool enabled;
}

/// A design-agnostic context menu overlay (no Material dependency).
///
/// Triggered by right-click on desktop or long-press on mobile.
/// Uses [TidePopup] internally for overlay positioning and dismiss behavior.
///
/// ```dart
/// TideContextMenu(
///   items: [
///     TideContextMenuItem(label: 'Edit', onTap: () => edit()),
///     TideContextMenuItem(label: 'Delete', onTap: () => delete()),
///   ],
///   child: MyWidget(),
/// )
/// ```
class TideContextMenu extends StatefulWidget {
  /// Creates a [TideContextMenu] wrapping [child].
  const TideContextMenu({
    super.key,
    required this.child,
    required this.items,
    this.enabled = true,
  });

  /// The widget that triggers the context menu on right-click / long-press.
  final Widget child;

  /// Menu items to display.
  final List<TideContextMenuItem> items;

  /// Whether the context menu is enabled.
  final bool enabled;

  /// Shows a context menu at the given [position] with the given [items].
  ///
  /// Returns a function that removes the menu when called.
  static VoidCallback show({
    required BuildContext context,
    required Offset position,
    required List<TideContextMenuItem> items,
  }) {
    final theme = TideTheme.of(context);
    return showTidePopupAtPosition(
      context: context,
      position: position,
      content: _TideContextMenuPanel(items: items, theme: theme),
    );
  }

  @override
  State<TideContextMenu> createState() => _TideContextMenuState();
}

class _TideContextMenuState extends State<TideContextMenu> {
  VoidCallback? _removeOverlay;

  void _showMenu(Offset globalPosition) {
    if (!widget.enabled || widget.items.isEmpty) return;

    _removeOverlay?.call();

    final theme = TideTheme.of(context);
    _removeOverlay = showTidePopupAtPosition(
      context: context,
      position: globalPosition,
      content: _TideContextMenuPanel(
        items: widget.items,
        theme: theme,
        onItemTap: () {
          _removeOverlay?.call();
          _removeOverlay = null;
        },
      ),
      onDismiss: () {
        _removeOverlay = null;
      },
    );
  }

  @override
  void dispose() {
    _removeOverlay?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      // Desktop right-click detection.
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kSecondaryMouseButton) {
          _showMenu(event.position);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Mobile long-press detection.
        onLongPressStart: (details) {
          _showMenu(details.globalPosition);
        },
        child: widget.child,
      ),
    );
  }
}

/// The visual panel that displays context menu items.
class _TideContextMenuPanel extends StatelessWidget {
  const _TideContextMenuPanel({
    required this.items,
    required this.theme,
    this.onItemTap,
  });

  final List<TideContextMenuItem> items;
  final TideThemeData theme;
  final VoidCallback? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 280),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: theme.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in items)
              _TideContextMenuItemWidget(
                item: item,
                theme: theme,
                onItemTap: onItemTap,
              ),
          ],
        ),
      ),
    );
  }
}

class _TideContextMenuItemWidget extends StatefulWidget {
  const _TideContextMenuItemWidget({
    required this.item,
    required this.theme,
    this.onItemTap,
  });

  final TideContextMenuItem item;
  final TideThemeData theme;
  final VoidCallback? onItemTap;

  @override
  State<_TideContextMenuItemWidget> createState() =>
      _TideContextMenuItemWidgetState();
}

class _TideContextMenuItemWidgetState
    extends State<_TideContextMenuItemWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = widget.theme;
    final opacity = item.enabled ? 1.0 : 0.4;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: item.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: item.enabled
            ? () {
                item.onTap();
                widget.onItemTap?.call();
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: _hovered && item.enabled
              ? theme.selectionColor
              : const Color(0x00000000),
          child: Opacity(
            opacity: opacity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  item.icon!,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    item.label,
                    style: theme.eventTitleStyle.copyWith(
                      color: theme.headerTextStyle.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

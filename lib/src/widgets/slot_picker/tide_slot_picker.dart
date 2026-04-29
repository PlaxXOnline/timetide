import 'package:flutter/widgets.dart';

import '../../core/models/slot.dart';
import '../../l10n/tide_localizations.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';

/// A time slot selection widget with optional resource grouping.
///
/// Shows available [TideSlot]s as tappable chips. When [groupByResource] is
/// true and slots span more than one resource, they are rendered under their
/// respective resource name headers.
class TideSlotPicker extends StatelessWidget {
  /// Creates a [TideSlotPicker].
  const TideSlotPicker({
    required this.slots,
    required this.onSlotSelected,
    this.selectedSlot,
    this.isLoading = false,
    this.emptyWidget,
    this.loadingWidget,
    this.groupByResource = true,
    this.localizations,
    super.key,
  });

  /// The list of available slots to display.
  final List<TideSlot> slots;

  /// The currently selected slot, identified by [TideSlot.id].
  final TideSlot? selectedSlot;

  /// Called when the user taps a slot chip.
  final ValueChanged<TideSlot> onSlotSelected;

  /// Whether to show a loading state.
  final bool isLoading;

  /// Widget displayed when the slots list is empty.
  final Widget? emptyWidget;

  /// Widget displayed while slots are loading.
  final Widget? loadingWidget;

  /// When true, slots are grouped under resource headers if more than one
  /// unique [TideSlot.resourceId] is present in [slots].
  final bool groupByResource;

  /// Optional localizations. Falls back to English strings when omitted.
  final TideLocalizations? localizations;

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);

    return Semantics(
      label: 'Slot picker',
      child: _buildContent(theme),
    );
  }

  Widget _buildContent(TideThemeData theme) {
    if (isLoading) {
      return loadingWidget ?? _buildLoadingPlaceholder(theme);
    }
    if (slots.isEmpty) {
      return emptyWidget ?? _buildEmptyState(theme);
    }

    final uniqueResourceIds = slots.map((s) => s.resourceId).toSet();
    final shouldGroup = groupByResource && uniqueResourceIds.length > 1;

    return shouldGroup
        ? _buildGroupedView(theme)
        : _buildFlatView(theme, slots);
  }

  Widget _buildLoadingPlaceholder(TideThemeData theme) {
    return Wrap(
      spacing: theme.slotPickerSpacing,
      runSpacing: theme.slotPickerSpacing,
      children: List.generate(6, (_) {
        return Container(
          width: 72,
          height: 40,
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: theme.slotPickerChipBorderRadius,
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState(TideThemeData theme) {
    final label = localizations?.noSlotsAvailable ?? 'No slots available';
    return Text(label, style: theme.slotPickerTextStyle);
  }

  Widget _buildGroupedView(TideThemeData theme) {
    // Preserve insertion order while grouping by resourceId.
    final groups = <String?, List<TideSlot>>{};
    for (final slot in slots) {
      (groups[slot.resourceId] ??= []).add(slot);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: groups.entries.map((entry) {
        final groupSlots = entry.value;
        final headerLabel =
            groupSlots.first.resourceName ?? entry.key ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                headerLabel,
                style: theme.slotPickerHeaderTextStyle,
              ),
            ),
            _buildFlatView(theme, groupSlots),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFlatView(TideThemeData theme, List<TideSlot> visibleSlots) {
    return Wrap(
      spacing: theme.slotPickerSpacing,
      runSpacing: theme.slotPickerSpacing,
      children: visibleSlots.map((slot) => _buildChip(theme, slot)).toList(),
    );
  }

  Widget _buildChip(TideThemeData theme, TideSlot slot) {
    final isSelected = selectedSlot?.id == slot.id;
    final bgColor = isSelected
        ? theme.slotPickerSelectedColor
        : theme.slotPickerChipColor;
    final textStyle = isSelected
        ? theme.slotPickerTextStyle.copyWith(
            color: const Color(0xFFFFFFFF),
          )
        : theme.slotPickerTextStyle;

    return Semantics(
      label: 'Time slot ${_formatTime(slot.startTime)}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => onSlotSelected(slot),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: theme.slotPickerChipBorderRadius,
          ),
          child: Text(_formatTime(slot.startTime), style: textStyle),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

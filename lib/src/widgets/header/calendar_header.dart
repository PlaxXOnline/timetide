import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/view.dart';
import '../../l10n/tide_localizations.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';
import 'view_switcher_bar.dart';

/// Default header widget for [TideCalendar].
///
/// Displays navigation controls (back, today, forward), a date label, and
/// an optional view switcher. All interactive elements use [GestureDetector]
/// — no Material or Cupertino widgets are imported.
class TideCalendarHeader extends StatelessWidget {
  /// Creates a [TideCalendarHeader].
  const TideCalendarHeader({
    super.key,
    required this.controller,
    this.localizations,
    this.allowedViews,
  });

  /// The controller driving navigation and view state.
  final TideController controller;

  /// Localized strings. Falls back to English if null.
  final TideLocalizations? localizations;

  /// Views shown in the view switcher. If null, the switcher is hidden.
  final List<TideView>? allowedViews;

  TideLocalizations get _l10n => localizations ?? TideLocalizations.en();

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);

    return Semantics(
      label: 'Calendar navigation header',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          border: Border(
            bottom: BorderSide(color: theme.borderColor, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _NavigationButton(
                  label: 'Previous',
                  onTap: controller.backward,
                  child: const Text(
                    '\u25C0',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 4),
                _TodayButton(
                  label: _l10n.today,
                  onTap: controller.today,
                  theme: theme,
                ),
                const SizedBox(width: 4),
                _NavigationButton(
                  label: 'Next',
                  onTap: controller.forward,
                  child: const Text(
                    '\u25B6',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueListenableBuilder<DateTime>(
                    valueListenable: controller.displayDateNotifier,
                    builder: (context, date, _) {
                      return ValueListenableBuilder<TideView>(
                        valueListenable: controller.currentViewNotifier,
                        builder: (context, view, _) {
                          return Text(
                            _formatDateLabel(date, view),
                            style: theme.headerTextStyle,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            if (allowedViews != null && allowedViews!.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TideViewSwitcherBar(
                  controller: controller,
                  allowedViews: allowedViews!,
                  localizations: _l10n,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateLabel(DateTime date, TideView view) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    switch (view) {
      case TideView.day:
      case TideView.timelineDay:
      case TideView.resourceDay:
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      case TideView.week:
      case TideView.timelineWeek:
      case TideView.workWeek:
      case TideView.timelineWorkWeek:
      case TideView.resourceWeek:
      case TideView.schedule:
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        if (weekStart.month == weekEnd.month) {
          return '${months[weekStart.month - 1]} ${weekStart.day}–${weekEnd.day}, ${weekStart.year}';
        }
        return '${months[weekStart.month - 1]} ${weekStart.day} – ${months[weekEnd.month - 1]} ${weekEnd.day}, ${weekEnd.year}';
      case TideView.month:
      case TideView.timelineMonth:
        return '${months[date.month - 1]} ${date.year}';
      case TideView.multiWeek:
        return '${months[date.month - 1]} ${date.year}';
      case TideView.year:
        return '${date.year}';
    }
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.label,
    required this.child,
    required this.onTap,
  });

  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ),
    );
  }
}

class _TodayButton extends StatelessWidget {
  const _TodayButton({
    required this.label,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final VoidCallback onTap;
  final TideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: theme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

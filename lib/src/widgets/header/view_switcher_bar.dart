import 'package:flutter/widgets.dart';

import '../../core/controller.dart';
import '../../core/models/view.dart';
import '../../l10n/tide_localizations.dart';
import '../../theme/tide_theme.dart';

/// A horizontal row of view names that lets the user switch calendar views.
///
/// Highlights the [TideController.currentView] and notifies the controller
/// when a different view is tapped. Uses [TideLocalizations] for display names.
class TideViewSwitcherBar extends StatelessWidget {
  /// Creates a [TideViewSwitcherBar].
  const TideViewSwitcherBar({
    super.key,
    required this.controller,
    required this.allowedViews,
    this.localizations,
  });

  /// The controller to read/write the current view.
  final TideController controller;

  /// Views to display in the bar.
  final List<TideView> allowedViews;

  /// Localized view names. Falls back to English if null.
  final TideLocalizations? localizations;

  TideLocalizations get _l10n => localizations ?? TideLocalizations.en();

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);

    return Semantics(
      label: 'View switcher',
      child: ValueListenableBuilder<TideView>(
        valueListenable: controller.currentViewNotifier,
        builder: (context, currentView, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final view in allowedViews)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Semantics(
                    button: true,
                    label: 'Switch to ${_viewName(view)} view',
                    selected: view == currentView,
                    child: GestureDetector(
                      onTap: () => controller.currentView = view,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: view == currentView
                              ? theme.primaryColor
                              : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _viewName(view),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: view == currentView
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: view == currentView
                                ? const Color(0xFFFFFFFF)
                                : theme.headerTextStyle.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _viewName(TideView view) {
    switch (view) {
      case TideView.day:
        return _l10n.dayView;
      case TideView.week:
        return _l10n.weekView;
      case TideView.workWeek:
        return _l10n.workWeek;
      case TideView.month:
        return _l10n.monthView;
      case TideView.schedule:
        return _l10n.scheduleView;
      case TideView.timelineDay:
        return _l10n.timelineDay;
      case TideView.timelineWeek:
        return _l10n.timelineWeek;
      case TideView.timelineWorkWeek:
        return _l10n.workWeek;
      case TideView.timelineMonth:
        return _l10n.timelineMonth;
      case TideView.multiWeek:
        return _l10n.multiWeek;
      case TideView.year:
        return _l10n.year;
    }
  }
}

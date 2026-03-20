import 'package:flutter/widgets.dart';

import 'tide_theme_data.dart';

/// Injects a [TideThemeData] into the widget tree.
///
/// Descendants access the theme via [TideTheme.of], which returns the nearest
/// ancestor's [data] or a default [TideThemeData] when no [TideTheme] exists.
class TideTheme extends InheritedWidget {
  /// The theme data provided to descendant widgets.
  final TideThemeData data;

  /// Creates a [TideTheme] that provides [data] to its [child] subtree.
  const TideTheme({super.key, required this.data, required super.child});

  /// Returns the [TideThemeData] from the closest [TideTheme] ancestor,
  /// or a default [TideThemeData] if none is found.
  static TideThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<TideTheme>();
    return theme?.data ?? const TideThemeData();
  }

  @override
  bool updateShouldNotify(TideTheme oldWidget) => data != oldWidget.data;
}

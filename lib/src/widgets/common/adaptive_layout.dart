import 'package:flutter/widgets.dart';

/// Configurable breakpoints for responsive layout decisions.
///
/// Default breakpoints:
/// - Mobile: 0–599 px
/// - Tablet: 600–1023 px
/// - Desktop: 1024+ px
class TideBreakpoints {
  /// Creates [TideBreakpoints] with custom thresholds.
  const TideBreakpoints({
    this.tablet = 600,
    this.desktop = 1024,
  }) : assert(tablet > 0 && desktop > tablet,
            'desktop must be greater than tablet');

  /// Width at which the layout switches from mobile to tablet.
  final double tablet;

  /// Width at which the layout switches from tablet to desktop.
  final double desktop;

  /// Returns true if [width] falls in the mobile range.
  bool isMobile(double width) => width < tablet;

  /// Returns true if [width] falls in the tablet range.
  bool isTablet(double width) => width >= tablet && width < desktop;

  /// Returns true if [width] falls in the desktop range.
  bool isDesktop(double width) => width >= desktop;

  /// Default breakpoints.
  static const TideBreakpoints defaults = TideBreakpoints();
}

/// A responsive layout widget that selects a builder based on available width.
///
/// Uses [LayoutBuilder] to measure the available width, then calls the
/// appropriate builder based on [breakpoints].
///
/// ```dart
/// TideAdaptiveLayout(
///   mobile: (context) => MobileCalendar(),
///   tablet: (context) => TabletCalendar(),
///   desktop: (context) => DesktopCalendar(),
/// )
/// ```
class TideAdaptiveLayout extends StatelessWidget {
  /// Creates a [TideAdaptiveLayout].
  ///
  /// [mobile] and [desktop] builders are required. If [tablet] is omitted,
  /// the tablet range falls back to [desktop].
  const TideAdaptiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.breakpoints = TideBreakpoints.defaults,
  });

  /// Builder for mobile widths (< [TideBreakpoints.tablet]).
  final WidgetBuilder mobile;

  /// Builder for tablet widths ([TideBreakpoints.tablet] to
  /// [TideBreakpoints.desktop]). Falls back to [desktop] if null.
  final WidgetBuilder? tablet;

  /// Builder for desktop widths (>= [TideBreakpoints.desktop]).
  final WidgetBuilder desktop;

  /// Breakpoint thresholds.
  final TideBreakpoints breakpoints;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (breakpoints.isMobile(width)) {
          return mobile(context);
        }

        if (breakpoints.isTablet(width)) {
          return (tablet ?? desktop).call(context);
        }

        return desktop(context);
      },
    );
  }
}

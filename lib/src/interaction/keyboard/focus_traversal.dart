import 'package:flutter/widgets.dart';

/// Defines the tab-order focus traversal for the calendar.
///
/// Groups calendar elements into a logical tab order:
/// 1. Header buttons (Back, Today, Forward, View Switcher)
/// 2. Date cells / time slots
/// 3. Events (sorted chronologically)
/// 4. Resource headers
///
/// Uses Flutter's [FocusTraversalGroup] and [FocusTraversalOrder] from
/// `widgets.dart`.
class TideFocusTraversal extends StatelessWidget {
  /// Creates a [TideFocusTraversal].
  const TideFocusTraversal({
    super.key,
    required this.child,
    this.policy,
  });

  /// The child widget tree to apply focus traversal to.
  final Widget child;

  /// Custom traversal policy. Defaults to [OrderedTraversalPolicy].
  final FocusTraversalPolicy? policy;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: policy ?? OrderedTraversalPolicy(),
      child: child,
    );
  }

  /// Wraps [child] with a [FocusTraversalOrder] at the given [order].
  ///
  /// Lower [order] values receive focus first.
  static Widget ordered({
    required double order,
    required Widget child,
  }) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: child,
    );
  }
}

/// Predefined focus order groups for calendar elements.
///
/// Use these constants when wrapping calendar sections with
/// [TideFocusTraversal.ordered] to maintain consistent tab order.
abstract class TideFocusOrder {
  TideFocusOrder._();

  /// Focus order for the backward navigation button.
  static const double headerBack = 1.0;

  /// Focus order for the "Today" button.
  static const double headerToday = 2.0;

  /// Focus order for the forward navigation button.
  static const double headerForward = 3.0;

  /// Focus order for the view switcher.
  static const double headerViewSwitcher = 4.0;

  /// Base focus order for date cells / time slots.
  ///
  /// Individual cells should add their index to this base value.
  static const double dateCells = 100.0;

  /// Base focus order for events.
  ///
  /// Individual events should add their chronological index to this base.
  static const double events = 200.0;

  /// Base focus order for resource headers.
  ///
  /// Individual resources should add their index to this base.
  static const double resourceHeaders = 300.0;
}

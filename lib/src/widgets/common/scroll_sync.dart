import 'package:flutter/widgets.dart';

/// Bidirectional scroll synchronization between two [ScrollController]s.
///
/// Keeps [primary] and [secondary] in sync: scrolling either one
/// mirrors its offset to the other without triggering an infinite loop.
///
/// Usage:
/// ```dart
/// late final TideScrollSync _sync;
///
/// @override
/// void initState() {
///   super.initState();
///   _sync = TideScrollSync(primary: _headerScroll, secondary: _bodyScroll);
/// }
///
/// @override
/// void dispose() {
///   _sync.dispose();
///   super.dispose();
/// }
/// ```
class TideScrollSync {
  TideScrollSync({required this.primary, required this.secondary}) {
    primary.addListener(_onPrimaryScroll);
    secondary.addListener(_onSecondaryScroll);
  }

  final ScrollController primary;
  final ScrollController secondary;
  bool _syncing = false;

  void _onPrimaryScroll() {
    if (_syncing) return;
    _syncing = true;
    if (secondary.hasClients) secondary.jumpTo(primary.offset);
    _syncing = false;
  }

  void _onSecondaryScroll() {
    if (_syncing) return;
    _syncing = true;
    if (primary.hasClients) primary.jumpTo(secondary.offset);
    _syncing = false;
  }

  /// Removes all listeners. Call this in the owning widget's [dispose].
  void dispose() {
    primary.removeListener(_onPrimaryScroll);
    secondary.removeListener(_onSecondaryScroll);
  }
}

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Auto-scrolls a [ScrollController] when a drag approaches the viewport edge.
///
/// Start scrolling by calling [startIfNeeded] with the current drag position
/// on every drag update. Call [stop] when the drag ends. Uses a [Ticker] for
/// smooth, frame-synced animation.
class TideAutoScroll {
  /// Creates a [TideAutoScroll].
  ///
  /// [scrollController] is the controller to scroll.
  /// [tickerProvider] provides the [Ticker] for smooth animation.
  /// [autoScrollSpeed] is the maximum scroll speed in logical pixels per second.
  /// [autoScrollThreshold] is the distance in pixels from the viewport edge
  /// at which scrolling begins.
  TideAutoScroll({
    required this.scrollController,
    required TickerProvider tickerProvider,
    this.autoScrollSpeed = 300.0,
    this.autoScrollThreshold = 40.0,
  }) : _tickerProvider = tickerProvider;

  /// The scroll controller to drive.
  final ScrollController scrollController;

  /// Maximum scroll speed in logical pixels per second.
  final double autoScrollSpeed;

  /// Distance from viewport edge that triggers scrolling.
  final double autoScrollThreshold;

  final TickerProvider _tickerProvider;

  Ticker? _ticker;
  Duration? _lastTick;
  double _scrollDirection = 0.0; // -1.0 = up/left, 1.0 = down/right

  /// Evaluates whether auto-scroll should be active based on [dragPosition]
  /// within a viewport of [viewportSize] at [viewportOffset].
  ///
  /// Call this on every drag update. If the drag is within the threshold
  /// zone at either edge, scrolling starts automatically.
  void startIfNeeded({
    required double dragPosition,
    required double viewportOffset,
    required double viewportSize,
  }) {
    final relativePosition = dragPosition - viewportOffset;
    final distanceFromStart = relativePosition;
    final distanceFromEnd = viewportSize - relativePosition;

    if (distanceFromStart < autoScrollThreshold && distanceFromStart >= 0) {
      // Near the start edge — scroll backward.
      final intensity = 1.0 - (distanceFromStart / autoScrollThreshold);
      _scrollDirection = -intensity;
      _ensureTickerRunning();
    } else if (distanceFromEnd < autoScrollThreshold && distanceFromEnd >= 0) {
      // Near the end edge — scroll forward.
      final intensity = 1.0 - (distanceFromEnd / autoScrollThreshold);
      _scrollDirection = intensity;
      _ensureTickerRunning();
    } else {
      // Not in a threshold zone — stop scrolling.
      _stopTicker();
    }
  }

  /// Stops any active auto-scrolling.
  void stop() {
    _stopTicker();
  }

  /// Releases resources. Must be called when the handler is disposed.
  void dispose() {
    _stopTicker();
  }

  void _ensureTickerRunning() {
    if (_ticker != null) return;
    _lastTick = null;
    _ticker = _tickerProvider.createTicker(_onTick);
    _ticker!.start();
  }

  void _stopTicker() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _lastTick = null;
    _scrollDirection = 0.0;
  }

  void _onTick(Duration elapsed) {
    if (!scrollController.hasClients) return;

    final dt = _lastTick == null
        ? Duration.zero
        : elapsed - _lastTick!;
    _lastTick = elapsed;

    if (dt == Duration.zero) return;

    final seconds = dt.inMicroseconds / Duration.microsecondsPerSecond;
    final delta = _scrollDirection * autoScrollSpeed * seconds;

    final position = scrollController.position;
    final newOffset = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if (newOffset != position.pixels) {
      scrollController.jumpTo(newOffset);
    }
  }
}

/// Defines how a drop from the resource sidebar onto a day column behaves.
enum ShiftDragMode {
  /// On drop, immediately create a shift using the configured default
  /// start/end times. No additional UI is shown.
  instantWithDefaults,

  /// On drop, invoke the configured prompt builder so the consumer can
  /// show an edit dialog before committing the new shift.
  promptForTime,
}

/// Strategy for replicating a source date range across a target date range
/// when bulk-copying shifts.
enum ShiftCopyMode {
  /// Replicate the source week as-is for every full week in the target range.
  /// Stretching / partial weeks fall back to truncation.
  replicateWeekly,
}

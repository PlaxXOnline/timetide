import 'package:flutter/widgets.dart';

import '../../core/recurrence/occurrence_engine.dart';
import '../../core/recurrence/rrule_generator.dart';
import '../../core/recurrence/rrule_model.dart';
import '../../core/recurrence/rrule_parser.dart';
import '../../core/recurrence/rrule_description.dart';
import '../../l10n/tide_localizations.dart';
import '../../theme/tide_theme.dart';
import '../../theme/tide_theme_data.dart';

/// End condition mode for the recurrence rule.
enum _EndMode { never, afterCount, untilDate }

/// Visual RRULE builder widget with live occurrence preview.
///
/// All controls are custom-built (no Material widgets). The editor provides:
/// - Frequency picker (daily, weekly, monthly, yearly)
/// - Interval adjustment (+/- buttons)
/// - Weekday selector (for WEEKLY frequency)
/// - Monthly rule toggle ("On day N" vs "On the Nth weekday")
/// - End condition: "Never" / "After N times" / "Until date"
/// - Live preview of next 5 occurrences
///
/// ```dart
/// TideRecurrenceEditor(
///   onChanged: (rruleString) => setState(() => _rrule = rruleString),
///   initialRule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR',
///   locale: 'en',
/// )
/// ```
class TideRecurrenceEditor extends StatefulWidget {
  /// Creates a [TideRecurrenceEditor].
  const TideRecurrenceEditor({
    super.key,
    required this.onChanged,
    this.initialRule,
    this.allowedFrequencies,
    this.locale = 'en',
    this.localizations,
    this.previewStart,
  });

  /// Called when the recurrence rule changes.
  /// Receives `null` when recurrence is disabled (frequency deselected).
  final void Function(String? rruleString) onChanged;

  /// Initial RRULE string to populate the editor.
  final String? initialRule;

  /// Limits which frequencies are available. All frequencies shown if null.
  final List<TideFrequency>? allowedFrequencies;

  /// Locale for descriptions and day names.
  final String locale;

  /// Optional localizations override.
  final TideLocalizations? localizations;

  /// Start date for the occurrence preview. Defaults to now.
  final DateTime? previewStart;

  @override
  State<TideRecurrenceEditor> createState() => _TideRecurrenceEditorState();
}

class _TideRecurrenceEditorState extends State<TideRecurrenceEditor> {
  TideFrequency _frequency = TideFrequency.weekly;
  int _interval = 1;
  Set<TideWeekday> _selectedDays = {};
  _EndMode _endMode = _EndMode.never;
  int _count = 10;
  DateTime? _until;
  bool _useOrdinalWeekday = false;
  int _monthDay = 1;

  List<TideFrequency> get _frequencies =>
      widget.allowedFrequencies ?? TideFrequency.values;

  @override
  void initState() {
    super.initState();
    _parseInitialRule();
  }

  void _parseInitialRule() {
    if (widget.initialRule == null) return;
    final rule = TideRRuleParser.parse(widget.initialRule!);
    if (rule == null) return;

    _frequency = rule.frequency;
    _interval = rule.interval;

    if (rule.byDay != null) {
      _selectedDays = rule.byDay!.map((bd) => bd.weekday).toSet();
      if (rule.frequency == TideFrequency.monthly &&
          rule.byDay!.any((bd) => bd.ordinal != null)) {
        _useOrdinalWeekday = true;
      }
    }

    if (rule.byMonthDay != null && rule.byMonthDay!.isNotEmpty) {
      _monthDay = rule.byMonthDay!.first;
    }

    if (rule.count != null) {
      _endMode = _EndMode.afterCount;
      _count = rule.count!;
    } else if (rule.until != null) {
      _endMode = _EndMode.untilDate;
      _until = rule.until;
    }
  }

  TideRecurrenceRule _buildRule() {
    List<TideByDay>? byDay;
    List<int>? byMonthDay;

    switch (_frequency) {
      case TideFrequency.weekly:
        if (_selectedDays.isNotEmpty) {
          byDay = _selectedDays
              .map((wd) => TideByDay(weekday: wd))
              .toList();
        }
      case TideFrequency.monthly:
        if (_useOrdinalWeekday && _selectedDays.isNotEmpty) {
          final weekday = _selectedDays.first;
          byDay = [TideByDay(weekday: weekday, ordinal: 1)];
        } else {
          byMonthDay = [_monthDay];
        }
      default:
        break;
    }

    return TideRecurrenceRule(
      frequency: _frequency,
      interval: _interval,
      byDay: byDay,
      byMonthDay: byMonthDay,
      count: _endMode == _EndMode.afterCount ? _count : null,
      until: _endMode == _EndMode.untilDate ? _until : null,
    );
  }

  void _notifyChanged() {
    final rule = _buildRule();
    widget.onChanged(TideRRuleGenerator.generate(rule));
  }

  List<DateTime> _previewOccurrences() {
    final rule = _buildRule();
    final start = widget.previewStart ?? DateTime.now();
    return TideOccurrenceEngine.occurrences(
      rule,
      start,
      before: start.add(const Duration(days: 365 * 2)),
    ).take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Frequency selector.
        _buildFrequencySelector(theme),
        const SizedBox(height: 12),

        // Interval.
        _buildIntervalControl(theme),
        const SizedBox(height: 12),

        // Weekday selector (weekly only).
        if (_frequency == TideFrequency.weekly) ...[
          _buildWeekdaySelector(theme),
          const SizedBox(height: 12),
        ],

        // Monthly rule toggle.
        if (_frequency == TideFrequency.monthly) ...[
          _buildMonthlyOptions(theme),
          const SizedBox(height: 12),
        ],

        // End condition.
        _buildEndCondition(theme),
        const SizedBox(height: 16),

        // Description.
        _buildDescription(theme),
        const SizedBox(height: 12),

        // Live preview.
        _buildPreview(theme),
      ],
    );
  }

  Widget _buildFrequencySelector(TideThemeData theme) {
    return Wrap(
      spacing: 6,
      children: [
        for (final freq in _frequencies)
          _TideToggle(
            label: _frequencyLabel(freq),
            selected: _frequency == freq,
            theme: theme,
            onTap: () {
              setState(() => _frequency = freq);
              _notifyChanged();
            },
          ),
      ],
    );
  }

  Widget _buildIntervalControl(TideThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _intervalPrefix(),
          style: theme.dayHeaderTextStyle,
        ),
        const SizedBox(width: 8),
        _TideStepperButton(
          label: '-',
          theme: theme,
          onTap: _interval > 1
              ? () {
                  setState(() => _interval--);
                  _notifyChanged();
                }
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '$_interval',
            style: theme.headerTextStyle,
          ),
        ),
        _TideStepperButton(
          label: '+',
          theme: theme,
          onTap: () {
            setState(() => _interval++);
            _notifyChanged();
          },
        ),
        const SizedBox(width: 8),
        Text(
          _intervalSuffix(),
          style: theme.dayHeaderTextStyle,
        ),
      ],
    );
  }

  Widget _buildWeekdaySelector(TideThemeData theme) {
    const days = TideWeekday.values;
    return Wrap(
      spacing: 4,
      children: [
        for (final day in days)
          _TideToggle(
            label: _weekdayAbbr(day),
            selected: _selectedDays.contains(day),
            theme: theme,
            onTap: () {
              setState(() {
                if (_selectedDays.contains(day)) {
                  _selectedDays = Set.of(_selectedDays)..remove(day);
                } else {
                  _selectedDays = Set.of(_selectedDays)..add(day);
                }
              });
              _notifyChanged();
            },
          ),
      ],
    );
  }

  Widget _buildMonthlyOptions(TideThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TideToggle(
          label: 'On day $_monthDay',
          selected: !_useOrdinalWeekday,
          theme: theme,
          onTap: () {
            setState(() => _useOrdinalWeekday = false);
            _notifyChanged();
          },
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TideToggle(
              label: 'On the 1st weekday',
              selected: _useOrdinalWeekday,
              theme: theme,
              onTap: () {
                setState(() {
                  _useOrdinalWeekday = true;
                  if (_selectedDays.isEmpty) {
                    _selectedDays = {TideWeekday.monday};
                  }
                });
                _notifyChanged();
              },
            ),
            if (_useOrdinalWeekday) ...[
              const SizedBox(width: 8),
              _buildWeekdayPicker(theme),
            ],
          ],
        ),
        if (!_useOrdinalWeekday) ...[
          const SizedBox(height: 8),
          _buildMonthDayStepper(theme),
        ],
      ],
    );
  }

  Widget _buildWeekdayPicker(TideThemeData theme) {
    final current = _selectedDays.isNotEmpty
        ? _selectedDays.first
        : TideWeekday.monday;
    return Wrap(
      spacing: 4,
      children: [
        for (final day in TideWeekday.values)
          _TideToggle(
            label: _weekdayAbbr(day),
            selected: current == day,
            theme: theme,
            compact: true,
            onTap: () {
              setState(() => _selectedDays = {day});
              _notifyChanged();
            },
          ),
      ],
    );
  }

  Widget _buildMonthDayStepper(TideThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Day:', style: theme.dayHeaderTextStyle),
        const SizedBox(width: 8),
        _TideStepperButton(
          label: '-',
          theme: theme,
          onTap: _monthDay > 1
              ? () {
                  setState(() => _monthDay--);
                  _notifyChanged();
                }
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$_monthDay', style: theme.headerTextStyle),
        ),
        _TideStepperButton(
          label: '+',
          theme: theme,
          onTap: _monthDay < 31
              ? () {
                  setState(() => _monthDay++);
                  _notifyChanged();
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildEndCondition(TideThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Ends', style: theme.dayHeaderTextStyle),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _TideToggle(
              label: 'Never',
              selected: _endMode == _EndMode.never,
              theme: theme,
              onTap: () {
                setState(() => _endMode = _EndMode.never);
                _notifyChanged();
              },
            ),
            _TideToggle(
              label: 'After',
              selected: _endMode == _EndMode.afterCount,
              theme: theme,
              onTap: () {
                setState(() => _endMode = _EndMode.afterCount);
                _notifyChanged();
              },
            ),
            _TideToggle(
              label: 'On date',
              selected: _endMode == _EndMode.untilDate,
              theme: theme,
              onTap: () {
                setState(() {
                  _endMode = _EndMode.untilDate;
                  _until ??= DateTime.now().add(const Duration(days: 365));
                });
                _notifyChanged();
              },
            ),
          ],
        ),
        if (_endMode == _EndMode.afterCount) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TideStepperButton(
                label: '-',
                theme: theme,
                onTap: _count > 1
                    ? () {
                        setState(() => _count--);
                        _notifyChanged();
                      }
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$_count times', style: theme.headerTextStyle),
              ),
              _TideStepperButton(
                label: '+',
                theme: theme,
                onTap: () {
                  setState(() => _count++);
                  _notifyChanged();
                },
              ),
            ],
          ),
        ],
        if (_endMode == _EndMode.untilDate && _until != null) ...[
          const SizedBox(height: 8),
          Text(
            _formatDate(_until!),
            style: theme.dayHeaderTextStyle,
          ),
        ],
      ],
    );
  }

  Widget _buildDescription(TideThemeData theme) {
    final rule = _buildRule();
    final desc = TideRRuleDescription.describe(rule, locale: widget.locale);
    return Text(
      desc,
      style: theme.dayHeaderTextStyle.copyWith(
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildPreview(TideThemeData theme) {
    final occurrences = _previewOccurrences();
    if (occurrences.isEmpty) {
      return Text(
        'No upcoming occurrences',
        style: theme.timeSlotTextStyle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Next occurrences:',
          style: theme.dayHeaderTextStyle,
        ),
        const SizedBox(height: 4),
        for (final date in occurrences)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              _formatDate(date),
              style: theme.timeSlotTextStyle,
            ),
          ),
      ],
    );
  }

  // ─── Helpers ────────────────────────────────────────────

  String _frequencyLabel(TideFrequency freq) {
    switch (freq) {
      case TideFrequency.daily:
        return widget.locale == 'de' ? 'Täglich' : 'Daily';
      case TideFrequency.weekly:
        return widget.locale == 'de' ? 'Wöchentlich' : 'Weekly';
      case TideFrequency.monthly:
        return widget.locale == 'de' ? 'Monatlich' : 'Monthly';
      case TideFrequency.yearly:
        return widget.locale == 'de' ? 'Jährlich' : 'Yearly';
    }
  }

  String _weekdayAbbr(TideWeekday day) {
    if (widget.locale == 'de') {
      const abbrs = {
        TideWeekday.monday: 'Mo',
        TideWeekday.tuesday: 'Di',
        TideWeekday.wednesday: 'Mi',
        TideWeekday.thursday: 'Do',
        TideWeekday.friday: 'Fr',
        TideWeekday.saturday: 'Sa',
        TideWeekday.sunday: 'So',
      };
      return abbrs[day]!;
    }
    const abbrs = {
      TideWeekday.monday: 'Mo',
      TideWeekday.tuesday: 'Tu',
      TideWeekday.wednesday: 'We',
      TideWeekday.thursday: 'Th',
      TideWeekday.friday: 'Fr',
      TideWeekday.saturday: 'Sa',
      TideWeekday.sunday: 'Su',
    };
    return abbrs[day]!;
  }

  String _intervalPrefix() {
    return widget.locale == 'de' ? 'Alle' : 'Every';
  }

  String _intervalSuffix() {
    switch (_frequency) {
      case TideFrequency.daily:
        return widget.locale == 'de' ? 'Tage' : 'days';
      case TideFrequency.weekly:
        return widget.locale == 'de' ? 'Wochen' : 'weeks';
      case TideFrequency.monthly:
        return widget.locale == 'de' ? 'Monate' : 'months';
      case TideFrequency.yearly:
        return widget.locale == 'de' ? 'Jahre' : 'years';
    }
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

// ─── Shared custom controls ───────────────────────────────────────

/// A toggle button used for frequency, weekday, and end-mode selection.
class _TideToggle extends StatefulWidget {
  const _TideToggle({
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final TideThemeData theme;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_TideToggle> createState() => _TideToggleState();
}

class _TideToggleState extends State<_TideToggle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? widget.theme.primaryColor
        : _hovered
            ? widget.theme.selectionColor
            : widget.theme.surfaceColor;
    final fg = widget.selected
        ? const Color(0xFFFFFFFF)
        : widget.theme.headerTextStyle.color ?? const Color(0xFF212121);
    final hPad = widget.compact ? 6.0 : 12.0;
    final vPad = widget.compact ? 4.0 : 6.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            border: Border.all(color: widget.theme.borderColor),
          ),
          child: Text(
            widget.label,
            style: widget.theme.dayHeaderTextStyle.copyWith(color: fg),
          ),
        ),
      ),
    );
  }
}

/// A +/- stepper button.
class _TideStepperButton extends StatefulWidget {
  const _TideStepperButton({
    required this.label,
    required this.theme,
    this.onTap,
  });

  final String label;
  final TideThemeData theme;
  final VoidCallback? onTap;

  @override
  State<_TideStepperButton> createState() => _TideStepperButtonState();
}

class _TideStepperButtonState extends State<_TideStepperButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final bg = _hovered && enabled
        ? widget.theme.selectionColor
        : widget.theme.surfaceColor;
    final opacity = enabled ? 1.0 : 0.3;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
              border: Border.all(color: widget.theme.borderColor),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: widget.theme.headerTextStyle,
            ),
          ),
        ),
      ),
    );
  }
}

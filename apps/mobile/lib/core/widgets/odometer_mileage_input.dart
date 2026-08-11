import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import 'odometer_overlay.dart';

const kOdometerDigitCount = 6;
const kOdometerMaxKm = 999999;

/// Opens a centered dialog with drum-style odometer. No keyboard.
Future<int?> showOdometerMileagePicker(
  BuildContext context, {
  required int initialValue,
  String unit = 'km',
  int maxValue = kOdometerMaxKm,
  String? title,
}) async {
  odometerPickerOpenCount.value++;
  try {
    return await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final width = MediaQuery.sizeOf(context).width;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width < 420 ? width : 400),
            child: _OdometerMileageSheet(
              initialValue: initialValue.clamp(0, maxValue),
              unit: unit,
              maxValue: maxValue,
              title: title ?? context.l10n.odometerPickerTitle,
            ),
          ),
        );
      },
    );
  } finally {
    odometerPickerOpenCount.value = (odometerPickerOpenCount.value - 1)
        .clamp(0, 1 << 20);
  }
}

/// Read-only looking field that opens [showOdometerMileagePicker] on tap.
///
/// Widget tests may still call [WidgetTester.enterText] on [fieldKey] — the
/// controller accepts programmatic edits without opening the keyboard.
class MileageInputField extends StatefulWidget {
  const MileageInputField({
    required this.onChanged,
    this.value,
    this.placeholderValue,
    this.confirmed = true,
    this.unit = 'km',
    this.label,
    this.errorText,
    this.enabled = true,
    this.compact = false,
    this.maxValue = kOdometerMaxKm,
    this.fieldKey,
    super.key,
  });

  final int? value;
  final int? placeholderValue;
  final bool confirmed;
  final ValueChanged<int> onChanged;
  final String unit;
  final String? label;
  final String? errorText;
  final bool enabled;
  final bool compact;
  final int maxValue;
  final Key? fieldKey;

  @override
  State<MileageInputField> createState() => _MileageInputFieldState();
}

class _MileageInputFieldState extends State<MileageInputField> {
  late final TextEditingController _controller;
  var _syncing = false;

  int get _displayValue =>
      widget.value ?? widget.placeholderValue ?? 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _displayText());
    _controller.addListener(_onControllerEdited);
  }

  @override
  void didUpdateWidget(covariant MileageInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _displayText();
    if (_controller.text != next) {
      _syncing = true;
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
      _syncing = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerEdited);
    _controller.dispose();
    super.dispose();
  }

  String _displayText() {
    if (widget.value != null) return widget.value.toString();
    if (widget.placeholderValue != null) {
      return widget.placeholderValue.toString();
    }
    return '';
  }

  void _onControllerEdited() {
    if (_syncing) return;
    final digits = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    final value = int.tryParse(digits);
    if (value == null) return;
    final capped = value.clamp(0, widget.maxValue);
    if (widget.value == capped) return;
    widget.onChanged(capped);
  }

  Future<void> _openPicker() async {
    if (!widget.enabled) return;
    final picked = await showOdometerMileagePicker(
      context,
      initialValue: _displayValue,
      unit: widget.unit,
      maxValue: widget.maxValue,
      title: widget.label,
    );
    if (picked == null || !mounted) return;
    widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = !widget.confirmed && widget.value == null;
    final textColor = muted
        ? colors.onSurfaceVariant.withValues(alpha: 0.45)
        : colors.onSurface;

    return TextField(
      key: widget.fieldKey,
      controller: _controller,
      enabled: widget.enabled,
      readOnly: true,
      showCursor: false,
      enableInteractiveSelection: false,
      keyboardType: TextInputType.none,
      style: (widget.compact
              ? Theme.of(context).textTheme.titleSmall
              : Theme.of(context).textTheme.bodyLarge)
          ?.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
      textAlign: widget.compact ? TextAlign.center : TextAlign.start,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(kOdometerDigitCount),
      ],
      decoration: InputDecoration(
        isDense: widget.compact,
        labelText: widget.label,
        errorText: widget.errorText,
        suffixText: widget.unit,
        prefixIcon: Icon(
          Icons.speed_outlined,
          size: widget.compact ? 16 : 22,
          color: colors.onSurfaceVariant,
        ),
        contentPadding: widget.compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 0)
            : null,
      ),
      onTap: _openPicker,
    );
  }
}

class _OdometerMileageSheet extends StatefulWidget {
  const _OdometerMileageSheet({
    required this.initialValue,
    required this.unit,
    required this.maxValue,
    required this.title,
  });

  final int initialValue;
  final String unit;
  final int maxValue;
  final String title;

  @override
  State<_OdometerMileageSheet> createState() => _OdometerMileageSheetState();
}

class _OdometerMileageSheetState extends State<_OdometerMileageSheet> {
  /// Infinite drums: many loops of 0–9 so the wheel never hits an edge.
  static const _cycle = 10;
  static const _loopCount = 1001;
  static const _midLoop = _loopCount ~/ 2;

  late List<int> _digits;
  late final List<FixedExtentScrollController> _controllers;
  var _ignore = false;

  static int _itemForDigit(int digit) => _midLoop * _cycle + digit.clamp(0, 9);

  static int _digitForItem(int item) {
    final mod = item % _cycle;
    return mod < 0 ? mod + _cycle : mod;
  }

  static List<int> _toDigits(int value, int maxValue) {
    final capped = value.clamp(0, maxValue);
    final raw = capped.toString().padLeft(kOdometerDigitCount, '0');
    return [for (final ch in raw.split('')) int.parse(ch)];
  }

  static int _fromDigits(List<int> digits) {
    var value = 0;
    for (final d in digits) {
      value = value * 10 + d.clamp(0, 9);
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    _digits = _toDigits(widget.initialValue, widget.maxValue);
    _controllers = [
      for (final d in _digits)
        FixedExtentScrollController(initialItem: _itemForDigit(d)),
    ];
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _jumpDigits(List<int> digits) {
    _ignore = true;
    for (var i = 0; i < _controllers.length; i++) {
      final target = _itemForDigit(digits[i]);
      final c = _controllers[i];
      if (c.hasClients && c.selectedItem != target) {
        c.jumpToItem(target);
      }
    }
    _ignore = false;
  }

  void _onDigitChanged(int index, int item) {
    if (_ignore) return;
    final digit = _digitForItem(item);
    if (_digits[index] == digit) return;
    // Light mechanical "tick" on each drum step (no extra permission).
    HapticFeedback.selectionClick();
    setState(() => _digits[index] = digit);
    final value = _fromDigits(_digits);
    if (value > widget.maxValue) {
      final capped = _toDigits(widget.maxValue, widget.maxValue);
      setState(() => _digits = capped);
      _jumpDigits(capped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final value = _fromDigits(_digits).clamp(0, widget.maxValue);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            context.l10n.odometerPickerHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            key: const Key('odometer-picker-drums'),
            height: 168,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.surfaceContainerHighest,
                  colors.surfaceContainer,
                  colors.surfaceContainerHighest,
                ],
              ),
              border: Border.all(color: colors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    children: [
                      for (var i = 0; i < kOdometerDigitCount; i++) ...[
                        if (i > 0)
                          Container(
                            width: 1,
                            color: colors.outlineVariant.withValues(alpha: 0.7),
                          ),
                        Expanded(
                          child: Transform.scale(
                            // Flip wheel so digits read like a mechanical
                            // odometer: 0, then 1 below, then 2… and scrolling
                            // feels top→bottom when counting up.
                            scaleY: -1,
                            child: ListWheelScrollView.useDelegate(
                              controller: _controllers[i],
                              itemExtent: 44,
                              diameterRatio: 1.15,
                              perspective: 0.003,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (item) =>
                                  _onDigitChanged(i, item),
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: _loopCount * _cycle,
                                builder: (context, item) {
                                  final digit = _digitForItem(item);
                                  final selected = digit == _digits[i];
                                  return Transform.scale(
                                    scaleY: -1,
                                    child: Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 120,
                                        ),
                                        style:
                                            Theme.of(context)
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                  fontWeight: selected
                                                      ? FontWeight.w800
                                                      : FontWeight.w500,
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                  color: selected
                                                      ? colors.onSurface
                                                      : colors.onSurfaceVariant
                                                            .withValues(
                                                              alpha: 0.35,
                                                            ),
                                                ) ??
                                            const TextStyle(),
                                        child: Text('$digit'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.55),
                          width: 1.4,
                        ),
                        color: colors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colors.surfaceContainerHighest,
                            colors.surfaceContainerHighest.withValues(
                              alpha: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            colors.surfaceContainerHighest,
                            colors.surfaceContainerHighest.withValues(
                              alpha: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 1,
              child: TextField(
                key: const Key('odometer-picker-test-input'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(kOdometerDigitCount),
                ],
                onChanged: (raw) {
                  final parsed = int.tryParse(raw);
                  if (parsed == null) return;
                  final capped = parsed.clamp(0, widget.maxValue);
                  final next = _toDigits(capped, widget.maxValue);
                  setState(() => _digits = next);
                  _jumpDigits(next);
                },
              ),
            ),
          ),
          Row(
            children: [
              Text(
                context.l10n.odometerPickerSelected,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '$value ${widget.unit}',
                key: const Key('odometer-picker-value'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('odometer-picker-cancel'),
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.cancel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  key: const Key('odometer-picker-confirm'),
                  onPressed: () => Navigator.pop(context, value),
                  child: Text(context.l10n.odometerPickerConfirm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

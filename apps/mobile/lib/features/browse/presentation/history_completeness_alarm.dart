import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';
import '../../../l10n/l10n.dart';
import '../../maintenance/maintenance.dart';
import '../../maintenance/maintenance_controller.dart';
import '../../vehicle/vehicle_controller.dart';

/// Session-local: pulse on first few expansions this app run.
var _historyAlarmPulseCount = 0;

/// Shared: expanded banner takes layout space; collapsed tab overlays content.
final historyAlarmCollapsedListenable = ValueNotifier<bool>(false);

class HistoryCompletenessAlarmBanner extends ConsumerStatefulWidget {
  const HistoryCompletenessAlarmBanner({super.key});

  @override
  ConsumerState<HistoryCompletenessAlarmBanner> createState() =>
      _HistoryCompletenessAlarmBannerState();
}

class _HistoryCompletenessAlarmBannerState
    extends ConsumerState<HistoryCompletenessAlarmBanner>
    with TickerProviderStateMixin {
  late final AnimationController _slide;
  late final AnimationController _pulse;
  String? _ensuredKey;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: historyAlarmCollapsedListenable.value ? 0 : 0,
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    historyAlarmCollapsedListenable.addListener(_onCollapsedChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || historyAlarmCollapsedListenable.value) return;
      _slide.forward();
      _maybePulse();
    });
  }

  void _onCollapsedChanged() {
    if (!mounted) return;
    if (historyAlarmCollapsedListenable.value) {
      setState(() {});
      return;
    }
    setState(() {});
    _slide.forward(from: 0);
    _maybePulse();
  }

  void _maybePulse() {
    if (_historyAlarmPulseCount >= 3) return;
    _historyAlarmPulseCount += 1;
    // One short pulse only — no repeat / delayed stop (those hang pumpAndSettle).
    _pulse
      ..value = 0
      ..forward();
  }

  @override
  void dispose() {
    historyAlarmCollapsedListenable.removeListener(_onCollapsedChanged);
    _slide.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _ensureRoadmap(String vehicleId, String locale) {
    final key = '$vehicleId:$locale';
    if (_ensuredKey == key) return;
    _ensuredKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(maintenanceControllerProvider.notifier)
          .ensureRoadmap(vehicleId, locale: locale);
    });
  }

  Future<void> _collapse() async {
    await _slide.reverse();
    historyAlarmCollapsedListenable.value = true;
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(vehicleSetupControllerProvider).activeVehicle;
    if (vehicle == null) return const SizedBox.shrink();

    final locale = ref.watch(activeLocaleProvider).languageCode;
    _ensureRoadmap(vehicle.id, locale);

    final maintenance = ref.watch(maintenanceControllerProvider);
    if (!maintenance.matches(vehicle.id, locale) ||
        maintenance.plan == null) {
      return const SizedBox.shrink();
    }

    final completeness = historyCompletenessPercent(maintenance.plan!.items);
    if (completeness >= 100) return const SizedBox.shrink();

    if (historyAlarmCollapsedListenable.value) {
      return const SizedBox.shrink();
    }

    final automotive =
        Theme.of(context).extension<AutomotiveColors>() ?? AutomotiveColors.dark;
    final alarm = Color.lerp(automotive.warning, const Color(0xFFE53935), 0.35)!;
    final onAlarm = Colors.white;

    return SizeTransition(
      axis: Axis.vertical,
      alignment: Alignment.topCenter,
      sizeFactor: CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final glow = _pulse.isAnimating ? (0.25 + _pulse.value * 0.45) : 0.35;
          return Container(
            key: const Key('history-completeness-banner'),
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              boxShadow: [
                BoxShadow(
                  color: alarm.withValues(alpha: glow),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Material(
          color: alarm,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
            child: Row(
              children: [
                Icon(Icons.priority_high_rounded, color: onAlarm, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.historyCompletenessAlarmTitle,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: onAlarm,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        context.l10n.historyCompletenessBannerShort(
                          completeness,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: onAlarm.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  key: const Key('history-completeness-cta'),
                  style: FilledButton.styleFrom(
                    backgroundColor: onAlarm,
                    foregroundColor: alarm,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => context.push('/history/wizard'),
                  child: Text(context.l10n.historyCompletenessFill),
                ),
                IconButton(
                  key: const Key('history-completeness-collapse'),
                  tooltip: context.l10n.historyCompletenessCollapse,
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  color: onAlarm,
                  onPressed: _collapse,
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryCompletenessAlarmTab extends ConsumerWidget {
  const HistoryCompletenessAlarmTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<bool>(
      valueListenable: historyAlarmCollapsedListenable,
      builder: (context, collapsed, _) {
        if (!collapsed) return const SizedBox.shrink();

        final vehicle = ref.watch(vehicleSetupControllerProvider).activeVehicle;
        if (vehicle == null) return const SizedBox.shrink();

        final locale = ref.watch(activeLocaleProvider).languageCode;
        final maintenance = ref.watch(maintenanceControllerProvider);
        if (!maintenance.matches(vehicle.id, locale) ||
            maintenance.plan == null) {
          return const SizedBox.shrink();
        }

        final completeness = historyCompletenessPercent(
          maintenance.plan!.items,
        );
        if (completeness >= 100) return const SizedBox.shrink();

        final automotive =
            Theme.of(context).extension<AutomotiveColors>() ??
            AutomotiveColors.dark;
        final alarm =
            Color.lerp(automotive.warning, const Color(0xFFE53935), 0.35)!;
        const onAlarm = Colors.white;

        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: alarm,
              elevation: 4,
              shadowColor: alarm.withValues(alpha: 0.55),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
              child: InkWell(
                key: const Key('history-completeness-tab'),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
                onTap: () => historyAlarmCollapsedListenable.value = false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 3, 6, 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 13,
                        color: onAlarm,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$completeness%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: onAlarm,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          height: 1,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: onAlarm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/automotive_widgets.dart';
import '../../../core/widgets/odometer_mileage_input.dart';
import '../../../l10n/l10n.dart';
import '../../browse/presentation/browse_screens.dart';
import '../../vehicle/vehicle.dart';
import '../../vehicle/vehicle_controller.dart';
import '../maintenance.dart';
import '../maintenance_controller.dart';
import 'state_screen.dart';
import 'work_node_icons.dart';

class FirstPlanScreen extends ConsumerStatefulWidget {
  const FirstPlanScreen({super.key});

  @override
  ConsumerState<FirstPlanScreen> createState() => _FirstPlanScreenState();
}

class _FirstPlanScreenState extends ConsumerState<FirstPlanScreen> {
  String? _requestedKey;

  void _ensure(String vehicleId, String locale, {bool force = false}) {
    final key = '$vehicleId:$locale';
    if (!force && _requestedKey == key) return;
    _requestedKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(maintenanceControllerProvider.notifier)
            .ensurePlan(vehicleId, locale: locale, force: force);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(vehicleSetupControllerProvider).activeVehicle;
    final locale = ref.watch(activeLocaleProvider).languageCode;
    if (vehicle == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/garage/add');
      });
      return const Center(child: CircularProgressIndicator());
    }
    _ensure(vehicle.id, locale);
    final state = ref.watch(maintenanceControllerProvider);
    final stage = state.matches(vehicle.id, locale)
        ? state.planStage
        : MaintenanceLoadStage.loading;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('first-plan-back'),
                tooltip: context.l10n.back,
                onPressed: () => context.go('/roadmap'),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TechnicalLabel(context.l10n.firstPlanStep),
                    Text(
                      context.l10n.firstPlanTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (stage == MaintenanceLoadStage.loading ||
              stage == MaintenanceLoadStage.idle)
            AutomotivePanel(
              emphasized: true,
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.loadingRealPlan(
                      '${vehicle.make} ${vehicle.model}',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (stage == MaintenanceLoadStage.error)
            _ErrorPanel(
              failure: state.failure,
              onRetry: () {
                _requestedKey = null;
                _ensure(vehicle.id, locale, force: true);
              },
            )
          else
            _FirstPlanSuccess(
              plan: state.plan!,
              vehicleName: '${vehicle.make} ${vehicle.model}',
            ),
        ],
      ),
    );
  }
}

class _FirstPlanSuccess extends StatelessWidget {
  const _FirstPlanSuccess({required this.plan, required this.vehicleName});

  final MaintenancePlan plan;
  final String vehicleName;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AutomotivePanel(
        emphasized: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.task_alt, size: 38),
            Text(
              context.l10n.vehicleMaintenancePlan(vehicleName),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(context.l10n.planItemsCount(plan.items.length)),
            if (plan.primarySource case final source?) ...[
              const SizedBox(height: 8),
              Text(source.title),
              Text('${source.publisher} · ${_source(context, source.kind)}'),
            ],
          ],
        ),
      ),
      if (plan.warnings.isNotEmpty) ...[
        const SizedBox(height: 10),
        for (final warning in plan.warnings)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(_warning(context, warning)),
          ),
      ],
      const SizedBox(height: 16),
      FilledButton.icon(
        key: const Key('first-plan-history'),
        onPressed: () => context.go('/history/wizard'),
        icon: const Icon(Icons.history),
        label: Text(context.l10n.refineServiceHistory),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        key: const Key('first-plan-continue'),
        onPressed: () => context.go('/roadmap'),
        child: Text(context.l10n.skipAndOpenPlan),
      ),
    ],
  );
}

class RoadmapScreen extends ConsumerStatefulWidget {
  const RoadmapScreen({super.key});

  @override
  ConsumerState<RoadmapScreen> createState() => _RoadmapScreenState();
}

class LegacyConsumablesScreen extends ConsumerWidget {
  const LegacyConsumablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasVehicle =
        ref.watch(vehicleSetupControllerProvider).activeVehicle != null;
    return hasVehicle
        ? const RoadmapScreen()
        : const ConsumablesPreviewScreen();
  }
}

class _RoadmapScreenState extends ConsumerState<RoadmapScreen> {
  String? _requestedKey;

  void _ensure(String vehicleId, String locale, {bool force = false}) {
    final key = '$vehicleId:$locale';
    if (!force && _requestedKey == key) return;
    _requestedKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(maintenanceControllerProvider.notifier)
            .ensureRoadmap(vehicleId, locale: locale, force: force);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(vehicleSetupControllerProvider).activeVehicle;
    if (vehicle == null) {
      _requestedKey = null;
      return const RoadmapPreviewScreen();
    }
    final locale = ref.watch(activeLocaleProvider).languageCode;
    _ensure(vehicle.id, locale);
    final state = ref.watch(maintenanceControllerProvider);
    final stage = state.matches(vehicle.id, locale)
        ? state.roadmapStage
        : MaintenanceLoadStage.loading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.maintenancePlanTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                key: const Key('plan-legend'),
                tooltip: context.l10n.planLegend,
                onPressed: () => _showLegend(context),
                icon: const Icon(Icons.info_outline),
              ),
            ],
          ),
          if (stage == MaintenanceLoadStage.loading ||
              stage == MaintenanceLoadStage.idle)
            const Expanded(
              child: Center(
                key: Key('roadmap-loading'),
                child: CircularProgressIndicator(),
              ),
            )
          else if (stage == MaintenanceLoadStage.error)
            Expanded(
              child: _ErrorPanel(
                failure: state.failure,
                onRetry: () {
                  _requestedKey = null;
                  _ensure(vehicle.id, locale, force: true);
                },
              ),
            )
          else
            Expanded(
              child: _RealRoadmap(
                timeline: state.timeline!,
                plan: state.plan!,
                vehicle: vehicle,
                forecast: state.mileageForecast,
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> openConsumablesSideSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Vehicle vehicle,
  required List<Consumable> items,
  required Consumable selected,
  MileageForecast? forecast,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: context.l10n.closeConsumablesBarrier,
  barrierColor: Colors.black54,
  pageBuilder: (dialogContext, _, _) => Align(
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      key: const Key('consumables-side-sheet'),
      widthFactor: 0.9,
      heightFactor: 1,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: _ConsumablesSheet(
            items: items
                .where((item) => item.status != MaintenanceStatus.notApplicable)
                .toList(),
            initialId: selected.id,
            onClose: () => Navigator.pop(dialogContext),
            onAdd: (workCode) {
              Navigator.pop(dialogContext);
              context.push(
                '/service/add?workCode=${Uri.encodeQueryComponent(workCode)}',
              );
            },
            onHistory: (workCode) {
              Navigator.pop(dialogContext);
              context.push(
                '/history/wizard?workCode=${Uri.encodeQueryComponent(workCode)}',
              );
            },
            forecast: forecast,
            onWear: (item) {
              Navigator.pop(dialogContext);
              showWearDialog(context, ref, vehicle, item);
            },
          ),
        ),
      ),
    ),
  ),
);

class _RealRoadmap extends ConsumerStatefulWidget {
  const _RealRoadmap({
    required this.timeline,
    required this.plan,
    required this.vehicle,
    this.forecast,
  });

  final VehicleTimeline timeline;
  final MaintenancePlan plan;
  final Vehicle vehicle;
  final MileageForecast? forecast;

  @override
  ConsumerState<_RealRoadmap> createState() => _RealRoadmapState();
}

class _RealRoadmapState extends ConsumerState<_RealRoadmap> {
  final _nowKey = GlobalKey();
  final _scrollController = ScrollController();
  var _didScrollToNow = false;
  var _scrollAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToNow();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToNow() {
    if (_didScrollToNow) return;
    final ctx = _nowKey.currentContext;
    if (ctx == null) {
      if (_scrollAttempts++ > 20) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToNow();
      });
      return;
    }
    _didScrollToNow = true;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.12,
      duration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final future = showableFuturePlanItems(widget.timeline.items);

    return Column(
      key: const Key('real-timeline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MileageQuickBlock(vehicle: widget.vehicle),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: TechnicalLabel(context.l10n.planTimelineLabel),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
            children: [
              _PlanRoadTimeline(
                timeline: widget.timeline,
                vehicle: widget.vehicle,
                future: future,
                forecast: widget.forecast,
                nowKey: _nowKey,
              ),
              const SizedBox(height: 16),
              _PlanAnalyticsQuiet(
                timeline: widget.timeline,
                forecast: widget.forecast,
                nearestCount: future.length,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MileageQuickBlock extends ConsumerStatefulWidget {
  const _MileageQuickBlock({required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<_MileageQuickBlock> createState() => _MileageQuickBlockState();
}

class _MileageQuickBlockState extends ConsumerState<_MileageQuickBlock> {
  late final TextEditingController _controller;
  var _saving = false;
  var _dirty = false;
  String? _error;
  String? _syncedKey;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.vehicle.mileage?.toString() ?? '',
    );
    _syncedKey = '${widget.vehicle.id}:${widget.vehicle.mileage}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncFrom(Vehicle vehicle) {
    final key = '${vehicle.id}:${vehicle.mileage}';
    if (_saving || key == _syncedKey) return;
    _syncedKey = key;
    _controller.text = vehicle.mileage?.toString() ?? '';
    _dirty = false;
  }


  Future<void> _save() async {
    if (_saving) return;
    final vehicle =
        ref.read(vehicleSetupControllerProvider).activeVehicle ?? widget.vehicle;
    final value = int.tryParse(_controller.text.trim());
    final unit = vehicle.mileageUnit ?? 'km';
    if (value == null ||
        value < 0 ||
        (vehicle.mileage != null &&
            mileageInKm(value, unit) <
                mileageInKm(vehicle.mileage!, unit))) {
      setState(() => _error = context.l10n.mileageDecreaseNotAllowed);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(vehicleSetupControllerProvider.notifier)
        .updateMileage(value: value, unit: unit);
    if (!mounted) return;
    if (result != null) {
      _syncedKey = '${vehicle.id}:$value';
      setState(() {
        _saving = false;
        _dirty = false;
      });
      return;
    }
    final failure = ref.read(vehicleSetupControllerProvider).failure;
    setState(() {
      _saving = false;
      _error = failure?.code == 'VERSION_CONFLICT'
          ? context.l10n.versionConflict
          : failure?.safeMessage.isNotEmpty == true
          ? failure!.safeMessage
          : context.l10n.mileageUpdateError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(vehicleSetupControllerProvider).activeVehicle;
    final vehicle =
        (live != null && live.id == widget.vehicle.id) ? live : widget.vehicle;
    _syncFrom(vehicle);

    final colors = Theme.of(context).colorScheme;
    final unit = vehicle.mileageUnit ?? 'km';

    return Material(
      key: const Key('mileage-quick-block'),
      color: colors.surfaceContainerHigh,
      elevation: 1,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.currentMileage,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: MileageInputField(
                        fieldKey: const Key('mileage-update-input'),
                        value: int.tryParse(_controller.text.trim()),
                        unit: unit,
                        compact: true,
                        enabled: !_saving,
                        onChanged: (next) {
                          _controller.text = '$next';
                          setState(() {
                            _error = null;
                            _dirty = next != vehicle.mileage;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton.filled(
                      key: const Key('mileage-update-save'),
                      tooltip: context.l10n.save,
                      onPressed: _saving ? null : _save,
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(40, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: _dirty
                            ? colors.primary
                            : colors.primary.withValues(alpha: 0.22),
                        foregroundColor: _dirty
                            ? colors.onPrimary
                            : colors.onSurfaceVariant.withValues(alpha: 0.55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanAnalyticsQuiet extends StatelessWidget {
  const _PlanAnalyticsQuiet({
    required this.timeline,
    required this.nearestCount,
    this.forecast,
  });

  final VehicleTimeline timeline;
  final MileageForecast? forecast;
  final int nearestCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('plan-analytics-strip'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.planAnalyticsStrip,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeline.currentMileage == null
                ? context.l10n.nowHistoryUnknown
                : context.l10n.nowAtMileage(
                    timeline.currentMileage!,
                    timeline.currentMileageUnit ?? 'km',
                  ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (forecast case final forecastValue?)
            Text(
              context.l10n.forecastAnnualDistance(
                forecastValue.isDefaultAssumption
                    ? context.l10n.preliminaryEstimate
                    : forecastValue.estimateLabel,
                forecastValue.annualDistance,
                forecastValue.annualDistanceUnit,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          Text(
            context.l10n.planNearestCount(nearestCount),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('plan-open-analytics'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                foregroundColor: colors.onSurfaceVariant,
              ),
              onPressed: () => context.push('/analytics'),
              child: Text(context.l10n.openAnalytics),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRoadTimeline extends ConsumerWidget {
  const _PlanRoadTimeline({
    required this.timeline,
    required this.vehicle,
    required this.future,
    required this.nowKey,
    this.forecast,
  });

  final VehicleTimeline timeline;
  final Vehicle vehicle;
  final List<TimelineItem> future;
  final MileageForecast? forecast;
  final GlobalKey nowKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final past = timeline.serviceRecords.take(3).toList(growable: false);

    return AutomotivePanel(
      key: const Key('plan-road'),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (past.isNotEmpty) ...[
            _TimelineSectionLabel(label: context.l10n.planPastLabel),
            const SizedBox(height: 6),
            for (final record in past)
              _RoadEvent(
                accent: colors.tertiary,
                railColor: colors.outlineVariant.withValues(alpha: 0.7),
                isLast: false,
                muted: true,
                dense: true,
                completed: true,
                child: _PastTimelineCard(record: record),
              ),
          ],
          KeyedSubtree(
            key: nowKey,
            child: _NowDivider(timeline: timeline),
          ),
          if (future.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
              child: Text(context.l10n.timelineEmpty),
            )
          else ...[
            _TimelineSectionLabel(label: context.l10n.planFutureLabel),
            const SizedBox(height: 6),
            for (var index = 0; index < future.length; index++)
              _RoadEvent(
                accent: _actionColor(context, future[index].actionLevel),
                railColor: colors.outlineVariant,
                isLast: index == future.length - 1,
                dense: true,
                workCode: future[index].item.workCode,
                onTap: () => _openPlanItem(
                  context,
                  ref,
                  vehicle: vehicle,
                  workCode: future[index].item.workCode,
                  forecast: forecast,
                ),
                child: _TimelineNode(
                  item: future[index],
                  currentMileage: timeline.currentMileage,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

Future<void> _openPlanItem(
  BuildContext context,
  WidgetRef ref, {
  required Vehicle vehicle,
  required String workCode,
  MileageForecast? forecast,
}) async {
  final consumables =
      ref.read(maintenanceControllerProvider).consumables?.items ??
      const <Consumable>[];
  final match = consumables
      .where(
        (item) =>
            item.workCode == workCode ||
            item.id.replaceAll('-', '_') == workCode,
      )
      .firstOrNull;
  if (match != null) {
    await showStateDetailSheet(
      context: context,
      ref: ref,
      vehicle: vehicle,
      item: match,
      forecast: forecast,
    );
    return;
  }
  if (context.mounted) {
    context.push(
      '/service/add?workCode=${Uri.encodeQueryComponent(workCode)}',
    );
  }
}

class _TimelineSectionLabel extends StatelessWidget {
  const _TimelineSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: colors.onSurfaceVariant,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _NowDivider extends StatelessWidget {
  const _NowDivider({required this.timeline});

  final VehicleTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mileageDetail = timeline.currentMileage == null
        ? context.l10n.notSpecified
        : '${timeline.currentMileage} ${timeline.currentMileageUnit ?? 'km'}';
    final position =
        '${_formatDate(DateTime.now())} · $mileageDetail';

    return Padding(
      key: const Key('current-mileage-marker'),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: colors.surface, width: 2),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.45),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 2,
              color: colors.primary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.nowMarker,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                Text(
                  position,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 2,
              color: colors.primary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadEvent extends StatelessWidget {
  const _RoadEvent({
    required this.accent,
    required this.railColor,
    required this.isLast,
    required this.child,
    this.dense = false,
    this.muted = false,
    this.completed = false,
    this.onTap,
    this.workCode,
  });

  final Color accent;
  final Color railColor;
  final bool isLast;
  final Widget child;
  final bool dense;
  final bool muted;
  final bool completed;
  final VoidCallback? onTap;
  final String? workCode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final success =
        Theme.of(context).extension<AutomotiveColors>()?.success ??
        colors.tertiary;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: muted ? colors.surface : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: muted ? 0.55 : 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          dense ? 8 : 10,
          dense ? 6 : 8,
          dense ? 8 : 10,
          dense ? 6 : 8,
        ),
        child: child,
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: completed
                        ? success.withValues(alpha: 0.18)
                        : colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: completed
                          ? success
                          : accent.withValues(alpha: muted ? 0.45 : 0.9),
                      width: 1.6,
                    ),
                  ),
                  child: completed
                      ? Icon(Icons.check_rounded, size: 11, color: success)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: railColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 2 : (dense ? 8 : 12)),
              child: onTap == null
                  ? card
                  : Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: Key('plan-item-tap-${workCode ?? 'x'}'),
                        borderRadius: BorderRadius.circular(10),
                        onTap: onTap,
                        child: card,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionMark extends StatelessWidget {
  const _CompletionMark({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final success =
        Theme.of(context).extension<AutomotiveColors>()?.success ??
        const Color(0xFF65C18C);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: done ? success.withValues(alpha: 0.14) : colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: done ? success : colors.outlineVariant,
          width: 1.4,
        ),
      ),
      child: done
          ? Icon(Icons.check_rounded, size: 15, color: success)
          : null,
    );
  }
}

class _PastTimelineCard extends StatelessWidget {
  const _PastTimelineCard({required this.record});

  final ServiceRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final workCode =
        record.items.isNotEmpty ? record.items.first.workCode : null;
    final title =
        record.title ?? record.items.map((item) => item.title).join(', ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          workNodeIcon(workCode),
          size: 18,
          color: colors.onSurfaceVariant.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                [
                  _formatDate(record.serviceDate),
                  if (record.mileage != null)
                    '${record.mileage} ${record.mileageUnit ?? 'km'}',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const _CompletionMark(done: true),
      ],
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({required this.item, this.currentMileage});

  final TimelineItem item;
  final int? currentMileage;

  @override
  Widget build(BuildContext context) {
    final maintenance = item.item;
    final colors = Theme.of(context).colorScheme;
    final interval = _intervalCriterion(context, maintenance.interval);
    final howSoon = _howSoonLabel(
      context,
      maintenance,
      currentMileage: currentMileage,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          workNodeIcon(maintenance.workCode),
          size: 18,
          color: _actionColor(context, item.actionLevel),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      maintenance.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _Indicator(
                    family: 'action',
                    value: item.actionLevel.name,
                    icon: _actionIcon(item.actionLevel),
                    color: _actionColor(context, item.actionLevel),
                    label: _actionLabel(context, item.actionLevel),
                  ),
                  _Indicator(
                    family: 'basis',
                    value: item.basis.name,
                    icon: _basisIcon(item.basis),
                    color: _basisColor(context, item.basis),
                    label: _basisLabel(context, item.basis),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _conciseDue(context, maintenance),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (interval != null)
                Text(
                  interval,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const _CompletionMark(done: false),
              if (howSoon != null) ...[
                const SizedBox(height: 6),
                Text(
                  howSoon,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _actionColor(context, item.actionLevel),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String? _howSoonLabel(
  BuildContext context,
  MaintenanceItem item, {
  int? currentMileage,
}) {
  final due = item.due;
  final parts = <String>[];
  if (due.date != null) {
    final today = DateTime.now();
    final dueDay = DateTime(due.date!.year, due.date!.month, due.date!.day);
    final nowDay = DateTime(today.year, today.month, today.day);
    final days = dueDay.difference(nowDay).inDays;
    parts.add(
      days >= 0
          ? context.l10n.howSoonDays(days)
          : context.l10n.howSoonOverdueDays(-days),
    );
  }
  if (due.mileage != null && currentMileage != null) {
    final km = due.mileage! - currentMileage;
    parts.add(
      km >= 0
          ? context.l10n.howSoonKm(km)
          : context.l10n.howSoonOverdueKm(-km),
    );
  }
  if (parts.isEmpty) return null;
  // Prefer the more urgent signal when both exist.
  if (parts.length == 2) {
    final daysLeft = due.date == null
        ? null
        : DateTime(
            due.date!.year,
            due.date!.month,
            due.date!.day,
          ).difference(DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          )).inDays;
    final kmLeft = due.mileage! - currentMileage!;
    if (daysLeft != null && daysLeft <= 0) return parts.first;
    if (kmLeft <= 0) return parts.last;
    // Show both, stacked for the narrow column.
    return parts.join('\n');
  }
  return parts.first;
}

String? _intervalCriterion(BuildContext context, MaintenanceInterval interval) {
  final parts = <String>[];
  if (interval.mileageKm != null) {
    parts.add(context.l10n.intervalEveryKm(interval.mileageKm!));
  }
  if (interval.days != null) {
    if (interval.days == 365 || interval.days == 366) {
      parts.add(context.l10n.intervalEveryYear);
    } else {
      parts.add(context.l10n.intervalEveryDays(interval.days!));
    }
  }
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.family,
    required this.value,
    required this.icon,
    required this.label,
    required this.color,
  });

  final String family;
  final String value;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Tooltip(
      message: label,
      child: InkWell(
        key: Key('indicator-$family-$value'),
        onTap: () =>
            _showLegend(context, focusFamily: family, focusValue: value),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    ),
  );
}

class _ConsumablesSheet extends StatefulWidget {
  const _ConsumablesSheet({
    required this.items,
    required this.initialId,
    required this.onClose,
    required this.onAdd,
    required this.onHistory,
    required this.onWear,
    this.forecast,
  });

  final List<Consumable> items;
  final String initialId;
  final VoidCallback onClose;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onHistory;
  final ValueChanged<Consumable> onWear;
  final MileageForecast? forecast;

  @override
  State<_ConsumablesSheet> createState() => _ConsumablesSheetState();
}

class _ConsumablesSheetState extends State<_ConsumablesSheet> {
  late String? expandedId = widget.initialId;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        title: Text(
          context.l10n.consumables,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        trailing: IconButton(
          key: const Key('close-consumables-sheet'),
          tooltip: context.l10n.close,
          onPressed: widget.onClose,
          icon: const Icon(Icons.close),
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final expanded = expandedId == item.id;
            return Semantics(
              key: Key('sheet-consumable-${item.id}'),
              button: true,
              expanded: expanded,
              label: '${item.title}. ${_consumableState(context, item)}',
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DecoratedBox(
                      key: Key(
                        'consumable-border-${expanded ? 'expanded' : 'collapsed'}-${item.id}',
                      ),
                      decoration: BoxDecoration(
                        border: expanded
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Card(
                        key: Key('consumable-main-${item.id}'),
                        margin: EdgeInsets.zero,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          key: Key('consumable-row-${item.id}'),
                          leading: Icon(
                            workNodeIcon(
                              item.workCode.isEmpty ? null : item.workCode,
                              fallbackId: item.id,
                            ),
                          ),
                          title: Text(item.title),
                          subtitle: Text(_consumableState(context, item)),
                          trailing: Icon(
                            expanded ? Icons.expand_less : Icons.expand_more,
                          ),
                          onTap: () => setState(
                            () => expandedId = expanded ? null : item.id,
                          ),
                        ),
                      ),
                    ),
                    if (expanded) ...[
                      const SizedBox(height: 2),
                      DecoratedBox(
                        key: Key('consumable-details-surface-${item.id}'),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                        ),
                        child: _ConsumableDetails(
                          key: Key('consumable-details-${item.id}'),
                          item: item,
                          onAdd: () => widget.onAdd(_workCode(item)),
                          onHistory: () => widget.onHistory(_workCode(item)),
                          onWear: () => widget.onWear(item),
                          forecast: widget.forecast,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _ConsumableDetails extends StatelessWidget {
  const _ConsumableDetails({
    required this.item,
    required this.onAdd,
    required this.onHistory,
    required this.onWear,
    this.forecast,
    super.key,
  });

  final Consumable item;
  final VoidCallback onAdd;
  final VoidCallback onHistory;
  final VoidCallback onWear;
  final MileageForecast? forecast;

  @override
  Widget build(BuildContext context) {
    final history = item.historyState;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          Text(item.title, style: Theme.of(context).textTheme.titleMedium),
          Text(_consumableState(context, item)),
          const SizedBox(height: 8),
          if (item.kind == ConsumableKind.conditionBased) ...[
            if (item.latestObservation case final observation?) ...[
              _WearState(observation: observation, status: item.status),
              Text(
                context.l10n.conditionObservationDateSource(
                  _formatDate(observation.observedAt),
                  observation.source == ConditionObservationSource.workshop
                      ? context.l10n.wearSourceWorkshop
                      : context.l10n.wearSourceSelf,
                ),
              ),
            ] else
              Text(
                item.inspectedAt == null
                    ? context.l10n.inspectionRequiredNoWear
                    : context.l10n.lastInspectionDate(
                        _formatDate(item.inspectedAt!),
                      ),
              ),
            if (item.nextInspection case final due?)
              Text(context.l10n.nextInspectionDue(_due(context, due))),
            if (_supportsWear(item.workCode))
              OutlinedButton.icon(
                key: Key('wear-${item.workCode}'),
                onPressed: onWear,
                icon: const Icon(Icons.speed_outlined),
                label: Text(context.l10n.wearSpecify),
              ),
          ] else ...[
            Text(
              history.performedDate == null
                  ? context.l10n.lastServiceUnknown
                  : context.l10n.lastServiceDate(
                      _formatDate(history.performedDate!),
                    ),
            ),
            if (history.performedMileageKm != null)
              Text(
                context.l10n.lastServiceMileage(
                  history.performedMileageKm!,
                  'km',
                ),
              ),
            const SizedBox(height: 8),
            _Lifecycle(item: item),
            if (forecast?.nextWorkWindow case final window?)
              if (window.from != null &&
                  window.to != null &&
                  window.planItemId == item.id)
                Text(
                  context.l10n.forecastWindow(
                    _formatDate(window.from!),
                    _formatDate(window.to!),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            if (item.timeDue case final due?)
              Text(
                _due(context, due),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (item.mileageDue case final due?)
              Text(
                _due(context, due),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Text(_limiting(context, item.effectiveTrigger)),
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            key: Key('add-service-${item.id}'),
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(context.l10n.addService),
          ),
          TextButton(
            key: Key('consumable-history-${item.id}'),
            onPressed: onHistory,
            child: Text(
              history.answer == null
                  ? context.l10n.specifyHistory
                  : context.l10n.editHistory,
            ),
          ),
        ],
      ),
    );
  }
}

class _WearState extends StatelessWidget {
  const _WearState({required this.observation, required this.status});
  final ConditionObservation observation;
  final MaintenanceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _itemColor(context, status);
    return Semantics(
      label:
          '${context.l10n.wearMeasured(observation.wearPercent)}. '
          '${context.l10n.wearRemaining(observation.remainingPercent)}',
      child: Row(
        key: const Key('condition-wear-state'),
        children: [
          Icon(Icons.speed_outlined, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${context.l10n.wearMeasured(observation.wearPercent)} · '
              '${context.l10n.wearRemaining(observation.remainingPercent)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Lifecycle extends StatelessWidget {
  const _Lifecycle({required this.item});

  final Consumable item;

  @override
  Widget build(BuildContext context) {
    final fraction = effectiveLifecycleFraction(item);
    return Semantics(
      label: fraction == null
          ? context.l10n.historyUnknownCheckNow
          : _consumableState(context, item),
      child: Column(
        key: Key(
          fraction == null
              ? 'lifecycle-unknown-${item.id}'
              : 'lifecycle-known-${item.id}',
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.historyState.performedDate == null
                      ? context.l10n.lastServiceUnknown
                      : _formatDate(item.historyState.performedDate!),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  context.l10n.nowMarker,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(context.l10n.nextDue, textAlign: TextAlign.end),
              ),
            ],
          ),
          const SizedBox(height: 5),
          if (fraction == null)
            Row(
              children: [
                const Expanded(child: Divider()),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.help_outline, size: 18),
                ),
                Expanded(child: Text(context.l10n.historyUnknownCheckNow)),
              ],
            )
          else
            LifecycleProgressBar(fraction: fraction, identifier: item.id),
        ],
      ),
    );
  }
}

class LifecycleProgressBar extends StatelessWidget {
  const LifecycleProgressBar({
    required this.fraction,
    required this.identifier,
    super.key,
  });

  final double fraction;
  final String identifier;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: Key('lifecycle-track-$identifier'),
    height: 24,
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          Positioned(
            left: constraints.maxWidth * fraction - 8.5,
            child: Icon(
              Icons.my_location,
              key: Key('lifecycle-marker-$identifier'),
              size: 17,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.failure, required this.onRetry});

  final Object? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final requestId = failure is MaintenanceFailure
        ? (failure as MaintenanceFailure).requestId
        : null;
    final safeMessage = failure is MaintenanceFailure
        ? (failure as MaintenanceFailure).safeMessage
        : '';
    final preparing =
        failure is MaintenanceFailure &&
        (failure as MaintenanceFailure).isPlanPreparing;
    return Center(
      child: AutomotivePanel(
        emphasized: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36),
            Text(
              preparing
                  ? context.l10n.planPreparingError
                  : safeMessage.isNotEmpty
                  ? safeMessage
                  : context.l10n.planLoadError,
              textAlign: TextAlign.center,
            ),
            if (requestId != null)
              SelectableText(context.l10n.requestIdLabel(requestId)),
            FilledButton.icon(
              key: const Key('maintenance-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showWearDialog(
  BuildContext context,
  WidgetRef ref,
  Vehicle vehicle,
  Consumable item,
) async {
  final wear = TextEditingController();
  final mileage = TextEditingController(
    text: vehicle.mileage?.toString() ?? '',
  );
  final note = TextEditingController();
  var date = DateTime.now();
  var source = ConditionObservationSource.self;
  String? error;
  var saving = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(context.l10n.wearSpecify),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('wear-percent-input'),
                controller: wear,
                enabled: !saving,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: context.l10n.wearPercent,
                  errorText: error,
                ),
              ),
              MileageInputField(
                fieldKey: const Key('wear-mileage-input'),
                value: int.tryParse(mileage.text.trim()),
                unit: vehicle.mileageUnit ?? 'km',
                label: '${context.l10n.currentMileage}, ${vehicle.mileageUnit ?? 'km'}',
                enabled: !saving,
                onChanged: (next) {
                  mileage.text = '$next';
                  setState(() {});
                },
              ),
              ListTile(
                key: const Key('wear-date'),
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.wearDate),
                subtitle: Text(_formatDate(date)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: saving
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => date = picked);
                      },
              ),
              DropdownButtonFormField<ConditionObservationSource>(
                key: const Key('wear-source'),
                initialValue: source,
                decoration: InputDecoration(labelText: context.l10n.wearSource),
                items: [
                  DropdownMenuItem(
                    value: ConditionObservationSource.self,
                    child: Text(context.l10n.wearSourceSelf),
                  ),
                  DropdownMenuItem(
                    value: ConditionObservationSource.workshop,
                    child: Text(context.l10n.wearSourceWorkshop),
                  ),
                ],
                onChanged: saving
                    ? null
                    : (value) => setState(
                        () => source = value ?? ConditionObservationSource.self,
                      ),
              ),
              TextField(
                key: const Key('wear-note'),
                controller: note,
                enabled: !saving,
                maxLength: 4000,
                maxLines: 2,
                decoration: InputDecoration(labelText: context.l10n.wearNote),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext),
            child: Text(context.l10n.close),
          ),
          FilledButton(
            key: const Key('wear-save'),
            onPressed: saving
                ? null
                : () async {
                    final wearValue = int.tryParse(wear.text);
                    final mileageValue = mileage.text.trim().isEmpty
                        ? null
                        : int.tryParse(mileage.text);
                    if (wearValue == null ||
                        wearValue < 0 ||
                        wearValue > 100 ||
                        (mileage.text.trim().isNotEmpty &&
                            mileageValue == null)) {
                      setState(() => error = context.l10n.wearValidation);
                      return;
                    }
                    setState(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      await ref
                          .read(maintenanceControllerProvider.notifier)
                          .createConditionObservation(
                            vehicle.id,
                            locale: Localizations.localeOf(
                              context,
                            ).languageCode,
                            observation: ConditionObservationWrite(
                              workCode: item.workCode,
                              wearPercent: wearValue,
                              observedAt: date,
                              mileage: mileageValue,
                              mileageUnit: vehicle.mileageUnit ?? 'km',
                              source: source,
                              note: note.text,
                            ),
                          );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    } on MaintenanceFailure {
                      if (dialogContext.mounted) {
                        setState(() {
                          saving = false;
                          error = context.l10n.wearSaveError;
                        });
                      }
                    }
                  },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    ),
  );
  wear.dispose();
  mileage.dispose();
  note.dispose();
}

Future<void> _showLegend(
  BuildContext context, {
  String? focusFamily,
  String? focusValue,
}) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(context.l10n.planLegend),
    content: SingleChildScrollView(
      child: Column(
        key: const Key('plan-legend-content'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.legendActionLevel),
          for (final action in TimelineActionLevel.values.where(
            (value) => value != TimelineActionLevel.unrecognized,
          ))
            _LegendRow(
              _actionIcon(action),
              _actionLabel(context, action),
              explanation: _actionExplanation(context, action),
              color: _actionColor(context, action),
              focused: focusFamily == 'action' && focusValue == action.name,
              rowKey: 'legend-action-${action.name}',
            ),
          const Divider(),
          Text(context.l10n.legendBasis),
          for (final basis in PresentationBasis.values.where(
            (value) => value != PresentationBasis.unrecognized,
          ))
            _LegendRow(
              _basisIcon(basis),
              _basisLabel(context, basis),
              explanation: _basisExplanation(context, basis),
              color: _basisColor(context, basis),
              focused: focusFamily == 'basis' && focusValue == basis.name,
              rowKey: 'legend-basis-${basis.name}',
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.close),
      ),
    ],
  ),
);

class _LegendRow extends StatelessWidget {
  const _LegendRow(
    this.icon,
    this.label, {
    required this.explanation,
    required this.color,
    required this.focused,
    required this.rowKey,
  });
  final IconData icon;
  final String label;
  final String explanation;
  final Color color;
  final bool focused;
  final String rowKey;

  @override
  Widget build(BuildContext context) => ListTile(
    key: Key(rowKey),
    dense: true,
    contentPadding: EdgeInsets.zero,
    tileColor: focused ? Theme.of(context).colorScheme.primaryContainer : null,
    leading: Icon(icon, color: color),
    title: Text(label),
    subtitle: Text(explanation),
  );
}

bool _supportsWear(String workCode) => supportsWearMeasurement(workCode);

String _workCode(Consumable item) =>
    item.workCode.isEmpty ? item.id.replaceAll('-', '_') : item.workCode;

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')}.${value.year}';

String _warning(BuildContext context, String warning) => switch (warning) {
  'EDITORIAL_BASELINE_ONLY' => context.l10n.warningEditorialBaseline,
  'HISTORY_REQUIRED' => context.l10n.warningHistoryRequired,
  'MILEAGE_NOT_PROVIDED' => context.l10n.warningMileageMissing,
  _ => context.l10n.warningUnknown,
};

String _source(BuildContext context, MaintenanceSourceKind kind) =>
    switch (kind) {
      MaintenanceSourceKind.editorialBaseline =>
        context.l10n.sourceEditorialBaseline,
      MaintenanceSourceKind.officialOem => context.l10n.sourceOfficialOem,
      MaintenanceSourceKind.regulatory => context.l10n.sourceRegulatory,
      MaintenanceSourceKind.unrecognized => context.l10n.unknownValue,
    };

String _status(BuildContext context, MaintenanceStatus status) =>
    switch (status) {
      MaintenanceStatus.unknown => context.l10n.statusUnknown,
      MaintenanceStatus.current => context.l10n.statusCurrentReal,
      MaintenanceStatus.soon => context.l10n.statusSoonReal,
      MaintenanceStatus.overdue => context.l10n.statusOverdueReal,
      MaintenanceStatus.completed => context.l10n.statusCompleted,
      MaintenanceStatus.notApplicable => context.l10n.statusNotApplicable,
      MaintenanceStatus.unrecognized => context.l10n.unknownValue,
    };

String _consumableState(BuildContext context, Consumable item) {
  if (item.kind == ConsumableKind.conditionBased) {
    return item.inspectedAt == null
        ? context.l10n.inspectionRequired
        : context.l10n.lastInspectionDate(_formatDate(item.inspectedAt!));
  }
  if (item.usedFraction == null) return context.l10n.historyUnknownCheckNow;
  return _status(context, item.status);
}

String _due(BuildContext context, MaintenanceDue due) => [
  if (due.date != null) context.l10n.dueDate(_formatDate(due.date!)),
  if (due.mileage != null)
    context.l10n.dueMileage(due.mileage!, due.unit ?? 'km'),
].join(' · ');

String _conciseDue(BuildContext context, MaintenanceItem item) {
  final due = _due(context, item.due);
  return due.isEmpty
      ? _status(context, item.status)
      : '$due · ${_status(context, item.status)}';
}

String _limiting(BuildContext context, String trigger) => switch (trigger) {
  'time' => context.l10n.limitingTime,
  'mileage' => context.l10n.limitingMileage,
  _ => context.l10n.limitingUnknown,
};

String _actionLabel(BuildContext context, TimelineActionLevel value) =>
    switch (value) {
      TimelineActionLevel.info => context.l10n.actionInfo,
      TimelineActionLevel.recommendation => context.l10n.actionRecommendation,
      TimelineActionLevel.attention => context.l10n.actionAttention,
      TimelineActionLevel.required => context.l10n.actionRequired,
      TimelineActionLevel.critical => context.l10n.actionCritical,
      TimelineActionLevel.unrecognized => context.l10n.unknownValue,
    };

String _actionExplanation(BuildContext context, TimelineActionLevel value) =>
    switch (value) {
      TimelineActionLevel.info => context.l10n.actionInfoExplanation,
      TimelineActionLevel.recommendation =>
        context.l10n.actionRecommendationExplanation,
      TimelineActionLevel.attention => context.l10n.actionAttentionExplanation,
      TimelineActionLevel.required => context.l10n.actionRequiredExplanation,
      TimelineActionLevel.critical => context.l10n.actionCriticalExplanation,
      TimelineActionLevel.unrecognized => context.l10n.unknownValue,
    };

IconData _actionIcon(TimelineActionLevel value) => switch (value) {
  TimelineActionLevel.info => Icons.info_outline,
  TimelineActionLevel.recommendation => Icons.thumb_up_alt_outlined,
  TimelineActionLevel.attention => Icons.schedule_outlined,
  TimelineActionLevel.required => Icons.report_outlined,
  TimelineActionLevel.critical => Icons.priority_high,
  TimelineActionLevel.unrecognized => Icons.help_outline,
};

Color _actionColor(BuildContext context, TimelineActionLevel value) =>
    switch (value) {
      TimelineActionLevel.info => _infoColor(context),
      TimelineActionLevel.recommendation => _successColor(context),
      TimelineActionLevel.attention => _warningColor(context),
      TimelineActionLevel.required => _requiredActionColor(context),
      TimelineActionLevel.critical =>
        Theme.of(context).extension<AutomotiveColors>()?.error ??
            Theme.of(context).colorScheme.error,
      TimelineActionLevel.unrecognized => Theme.of(
        context,
      ).colorScheme.onSurfaceVariant,
    };

String _basisLabel(BuildContext context, PresentationBasis value) =>
    switch (value) {
      PresentationBasis.confirmed => context.l10n.basisConfirmed,
      PresentationBasis.forecast => context.l10n.basisForecast,
      PresentationBasis.missingData => context.l10n.basisMissingData,
      PresentationBasis.unrecognized => context.l10n.unknownValue,
    };

String _basisExplanation(BuildContext context, PresentationBasis value) =>
    switch (value) {
      PresentationBasis.confirmed => context.l10n.basisConfirmedExplanation,
      PresentationBasis.forecast => context.l10n.basisForecastExplanation,
      PresentationBasis.missingData => context.l10n.basisMissingDataExplanation,
      PresentationBasis.unrecognized => context.l10n.unknownValue,
    };

IconData _basisIcon(PresentationBasis value) => switch (value) {
  // Not a checkmark — that reads as "already done" on the timeline.
  PresentationBasis.confirmed => Icons.assignment_outlined,
  PresentationBasis.forecast => Icons.timeline_outlined,
  PresentationBasis.missingData => Icons.help_outline,
  PresentationBasis.unrecognized => Icons.help_outline,
};

Color _basisColor(BuildContext context, PresentationBasis value) =>
    switch (value) {
      PresentationBasis.confirmed => _successColor(context),
      PresentationBasis.forecast => _infoColor(context),
      PresentationBasis.missingData => _warningColor(context),
      PresentationBasis.unrecognized => Theme.of(
        context,
      ).colorScheme.onSurfaceVariant,
    };

Color _itemColor(BuildContext context, MaintenanceStatus status) =>
    switch (status) {
      MaintenanceStatus.overdue => Theme.of(context).colorScheme.error,
      MaintenanceStatus.soon => Theme.of(context).colorScheme.primary,
      _ => Theme.of(context).colorScheme.secondary,
    };

Color _warningColor(BuildContext context) =>
    Theme.of(context).extension<AutomotiveColors>()?.warning ??
    Theme.of(context).colorScheme.primary;

Color _infoColor(BuildContext context) =>
    Theme.of(context).extension<AutomotiveColors>()?.info ??
    Theme.of(context).colorScheme.secondary;

Color _requiredActionColor(BuildContext context) =>
    Theme.of(context).extension<AutomotiveColors>()?.requiredAction ??
    Theme.of(context).colorScheme.primary;

Color _successColor(BuildContext context) =>
    Theme.of(context).extension<AutomotiveColors>()?.success ??
    Theme.of(context).colorScheme.tertiary;

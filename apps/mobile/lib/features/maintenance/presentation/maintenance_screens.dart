import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/automotive_widgets.dart';
import '../../../l10n/l10n.dart';
import '../../browse/presentation/browse_screens.dart';
import '../../vehicle/vehicle.dart';
import '../../vehicle/vehicle_controller.dart';
import '../maintenance.dart';
import '../maintenance_controller.dart';

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
              _showWearDialog(context, ref, vehicle, item);
            },
          ),
        ),
      ),
    ),
  ),
);

class _RealRoadmap extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final future = showableFuturePlanItems(timeline.items);
    final nearest = future.isEmpty ? null : future.first;
    final road = future.skip(1).take(4).toList(growable: false);
    final remaining = future.skip(1 + road.length).toList(growable: false);
    final completeness = historyCompletenessPercent(plan.items);
    final colors = Theme.of(context).colorScheme;

    return ListView(
      key: const Key('real-timeline'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      children: [
        Material(
          key: const Key('history-completeness-banner'),
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/history/wizard'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.historyCompletenessBanner(completeness),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.historyCompletenessCta,
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const Key('open-state-from-plan'),
          onPressed: () => context.go('/state'),
          icon: const Icon(Icons.monitor_heart_outlined, size: 18),
          label: Text(context.l10n.openState),
        ),
        const SizedBox(height: 4),
        _CurrentMarker(timeline: timeline, vehicle: vehicle),
        if (forecast case final value?) _ForecastOrientation(forecast: value),
        if (nearest == null)
          Text(context.l10n.timelineEmpty)
        else ...[
          TechnicalLabel(context.l10n.planNearestWork),
          const SizedBox(height: 4),
          Card(
            key: const Key('plan-nearest-card'),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _TimelineNode(item: nearest, isLast: true, compact: false),
            ),
          ),
          if (road.isNotEmpty) ...[
            const SizedBox(height: 12),
            TechnicalLabel(context.l10n.planRoadLabel),
            const SizedBox(height: 6),
            SizedBox(
              height: 96,
              child: ListView.separated(
                key: const Key('plan-road'),
                scrollDirection: Axis.horizontal,
                itemCount: road.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = road[index];
                  return SizedBox(
                    width: 168,
                    child: AutomotivePanel(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _conciseDue(context, item.item),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (remaining.isNotEmpty) ...[
            const SizedBox(height: 12),
            TechnicalLabel(context.l10n.planRemainingList),
            const SizedBox(height: 4),
            for (var index = 0; index < remaining.length; index++)
              _TimelineNode(
                item: remaining[index],
                isLast: index == remaining.length - 1,
                compact: true,
              ),
          ],
        ],
        const SizedBox(height: 12),
        AutomotivePanel(
          key: const Key('plan-analytics-strip'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TechnicalLabel(context.l10n.planAnalyticsStrip),
              const SizedBox(height: 4),
              Text(
                timeline.currentMileage == null
                    ? context.l10n.nowHistoryUnknown
                    : context.l10n.nowAtMileage(
                        timeline.currentMileage!,
                        timeline.currentMileageUnit ?? 'km',
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
                ),
              Text(context.l10n.planNearestCount(future.length)),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('plan-open-analytics'),
                onPressed: () => context.push('/analytics'),
                child: Text(context.l10n.openAnalytics),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ForecastOrientation extends StatelessWidget {
  const _ForecastOrientation({required this.forecast});
  final MileageForecast forecast;

  @override
  Widget build(BuildContext context) {
    final window = forecast.nextWorkWindow;
    final label = forecast.isDefaultAssumption
        ? context.l10n.preliminaryEstimate
        : forecast.estimateLabel;
    return Semantics(
      label: label,
      child: Padding(
        key: const Key('mileage-forecast-orientation'),
        padding: const EdgeInsets.only(bottom: 12, left: 34),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.forecastAnnualDistance(
                    label,
                    forecast.annualDistance,
                    forecast.annualDistanceUnit,
                  ),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                if (window?.from != null && window?.to != null)
                  Text(
                    context.l10n.forecastWindow(
                      _formatDate(window!.from!),
                      _formatDate(window.to!),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentMarker extends ConsumerWidget {
  const _CurrentMarker({required this.timeline, required this.vehicle});

  final VehicleTimeline timeline;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        SizedBox(
          width: 34,
          child: Icon(Icons.my_location, color: _warningColor(context)),
        ),
        Expanded(
          child: OutlinedButton(
            key: const Key('current-mileage-marker'),
            onPressed: () => _editMileage(context, ref, vehicle),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeline.currentMileage == null
                      ? context.l10n.nowHistoryUnknown
                      : context.l10n.nowAtMileage(
                          timeline.currentMileage!,
                          timeline.currentMileageUnit ?? 'km',
                        ),
                ),
                Text(
                  timeline.currentMileage == null
                      ? context.l10n.setMileage
                      : context.l10n.refineMileage,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.item,
    required this.isLast,
    this.compact = false,
  });

  final TimelineItem item;
  final bool isLast;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final maintenance = item.item;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(maintenance.title, style: Theme.of(context).textTheme.titleSmall),
        Text(
          _conciseDue(context, maintenance),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Wrap(
          spacing: 2,
          children: [
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
        if (!compact)
          TextButton.icon(
            key: Key('performed-${maintenance.workCode}'),
            onPressed: () => context.push(
              '/service/add?workCode=${Uri.encodeQueryComponent(maintenance.workCode)}',
            ),
            icon: const Icon(Icons.task_alt, size: 17),
            label: Text(context.l10n.performed),
          ),
      ],
    );
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            _CategoryNodeIcon(category: item.primaryCategory),
            const SizedBox(width: 8),
            Expanded(child: body),
          ],
        ),
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                _CategoryNodeIcon(category: item.primaryCategory),
                if (!isLast)
                  Expanded(
                    child: VerticalDivider(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryNodeIcon extends StatelessWidget {
  const _CategoryNodeIcon({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.iconCategorySemantics(_category(context, category)),
    child: CircleAvatar(
      key: Key('category-node-$category'),
      radius: 14,
      child: Icon(_categoryIcon(category), size: 16),
    ),
  );
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
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
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
                          leading: Icon(_workIcon(item.id)),
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

Future<void> _editMileage(
  BuildContext context,
  WidgetRef ref,
  Vehicle vehicle,
) async {
  final controller = TextEditingController(
    text: vehicle.mileage?.toString() ?? '',
  );
  String? error;
  var saving = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.currentMileage,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextField(
                  key: const Key('mileage-update-input'),
                  controller: controller,
                  autofocus: true,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    suffixText: vehicle.mileageUnit ?? 'km',
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('mileage-update-save'),
                  onPressed: saving
                      ? null
                      : () async {
                          final value = int.tryParse(controller.text);
                          if (value == null ||
                              value < 0 ||
                              (vehicle.mileage != null &&
                                  mileageInKm(
                                        value,
                                        vehicle.mileageUnit ?? 'km',
                                      ) <
                                      mileageInKm(
                                        vehicle.mileage!,
                                        vehicle.mileageUnit ?? 'km',
                                      ))) {
                            setState(
                              () => error =
                                  context.l10n.mileageDecreaseNotAllowed,
                            );
                            return;
                          }
                          setState(() {
                            saving = true;
                            error = null;
                          });
                          final result = await ref
                              .read(vehicleSetupControllerProvider.notifier)
                              .updateMileage(
                                value: value,
                                unit: vehicle.mileageUnit ?? 'km',
                              );
                          if (!sheetContext.mounted) return;
                          if (result != null) {
                            Navigator.pop(sheetContext);
                            return;
                          }
                          final failure = ref
                              .read(vehicleSetupControllerProvider)
                              .failure;
                          setState(() {
                            saving = false;
                            final message = failure?.code == 'VERSION_CONFLICT'
                                ? context.l10n.versionConflict
                                : failure?.safeMessage.isNotEmpty == true
                                ? failure!.safeMessage
                                : context.l10n.mileageUpdateError;
                            error = failure?.requestId == null
                                ? message
                                : '$message ${context.l10n.requestIdLabel(failure!.requestId!)}';
                          });
                        },
                  child: Text(context.l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 400));
  controller.dispose();
}

Future<void> _showWearDialog(
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
              TextField(
                key: const Key('wear-mileage-input'),
                controller: mileage,
                enabled: !saving,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText:
                      '${context.l10n.currentMileage}, ${vehicle.mileageUnit ?? 'km'}',
                ),
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

String _category(BuildContext context, String value) => switch (value) {
  'inspection' => context.l10n.categoryInspection,
  'parts' => context.l10n.categoryParts,
  'maintenance_repair' => context.l10n.categoryMaintenance,
  _ => context.l10n.unknownValue,
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

IconData _workIcon(String id) {
  if (id.contains('oil')) return Icons.oil_barrel_outlined;
  if (id.contains('tire')) return Icons.tire_repair_outlined;
  if (id.contains('coolant')) return Icons.water_drop_outlined;
  if (id.contains('brake')) return Icons.album_outlined;
  if (id.contains('filter')) return Icons.air_outlined;
  return Icons.build_outlined;
}

IconData _categoryIcon(String category) => switch (category) {
  'inspection' => Icons.manage_search_outlined,
  'parts' => Icons.settings_outlined,
  'maintenance_repair' => Icons.car_repair_outlined,
  _ => Icons.category_outlined,
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
  PresentationBasis.confirmed => Icons.check_circle_outline,
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

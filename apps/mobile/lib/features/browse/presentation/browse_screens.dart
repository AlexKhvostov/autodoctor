import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/dev_tools.dart';
import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/automotive_widgets.dart';
import '../../../core/widgets/preview_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../maintenance/maintenance.dart';
import '../../maintenance/maintenance_controller.dart';
import '../../maintenance/presentation/mileage_trend_chart.dart';
import '../../maintenance/presentation/state_screen.dart';
import '../../maintenance/presentation/work_node_icons.dart';
import '../../vehicle/vehicle.dart';
import '../../vehicle/vehicle_controller.dart';

class RoadmapPreviewScreen extends ConsumerStatefulWidget {
  const RoadmapPreviewScreen({super.key});

  @override
  ConsumerState<RoadmapPreviewScreen> createState() =>
      _RoadmapPreviewScreenState();
}

class _RoadmapPreviewScreenState extends ConsumerState<RoadmapPreviewScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vehicle = ref.watch(vehicleSetupControllerProvider).activeVehicle;
    final timeline = _demoTimeline(context.l10n);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TechnicalLabel(context.l10n.cockpitDemo),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.maintenancePlanTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('preview-plan-legend'),
                tooltip: context.l10n.planLegend,
                onPressed: () => _showPreviewLegend(context),
                icon: const Icon(Icons.info_outline),
              ),
              const ExampleBadge(),
            ],
          ),
          const SizedBox(height: 8),
          if (vehicle == null)
            PreviewGate(
              message: context.l10n.planPreviewGate,
              onAddVehicle: () => context.go('/garage/add'),
            )
          else
            AutomotivePanel(
              emphasized: true,
              child: Text(
                context.l10n.profileCreatedPlanPreparing(
                  vehicle.make,
                  vehicle.model,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Material(
            key: const Key('history-completeness-banner'),
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Text(context.l10n.historyCompletenessBanner(35)),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('open-state-from-plan'),
              onPressed: () => context.go('/state'),
              icon: const Icon(Icons.monitor_heart_outlined, size: 18),
              label: Text(context.l10n.openState),
            ),
          ),
          Expanded(
            child: Semantics(
              container: true,
              label: context.l10n.timelineSemantics,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.outlineVariant)),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 8, 2, 96),
                  itemCount: timeline.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton(
                          key: const Key('plan-open-analytics'),
                          onPressed: () => context.push('/analytics'),
                          child: Text(context.l10n.openAnalytics),
                        ),
                      );
                    }
                    if (index == 4) {
                      return const _CurrentTimelineMarker();
                    }
                    final eventIndex = index > 4 ? index - 2 : index - 1;
                    final event = timeline[eventIndex];
                    return _DetailedTimelineNode(
                      event: event,
                      isLast: eventIndex == timeline.length - 1,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ConsumableKind { interval, condition }

enum _InspectionState { completed, unknown, checkRequired }

class _ConsumableDemo {
  const _ConsumableDemo({
    required this.id,
    required this.title,
    required this.icon,
    required this.kind,
    required this.railState,
    required this.due,
    required this.basis,
    required this.source,
    required this.effectiveTrigger,
    this.intervalFraction,
    this.inspectionState,
    this.lastInspection,
    this.key,
  });

  final String id;
  final String title;
  final IconData icon;
  final _ConsumableKind kind;
  final String railState;
  final String due;
  final String basis;
  final String source;
  final String effectiveTrigger;
  final double? intervalFraction;
  final _InspectionState? inspectionState;
  final String? lastInspection;
  final Key? key;

  IconData? get stateIcon => switch (inspectionState) {
    _InspectionState.completed => Icons.check,
    _InspectionState.unknown => Icons.question_mark,
    _InspectionState.checkRequired => Icons.search,
    null =>
      intervalFraction != null && intervalFraction! >= 0.9
          ? Icons.priority_high
          : null,
  };

  Color color(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (inspectionState == _InspectionState.completed) {
      return const Color(0xFF65C18C);
    }
    if (inspectionState == _InspectionState.checkRequired ||
        (intervalFraction ?? 0) >= 0.9) {
      return colors.error;
    }
    if ((intervalFraction ?? 0) >= 0.72) {
      return colors.primary;
    }
    return colors.secondary;
  }
}

List<_ConsumableDemo> _demoConsumables(AppLocalizations l10n) => [
  _ConsumableDemo(
    id: 'oil',
    key: Key('consumable-rail-oil'),
    title: l10n.oilTitle,
    icon: Icons.oil_barrel_outlined,
    kind: _ConsumableKind.interval,
    railState: l10n.oilState,
    due: l10n.oilDue,
    basis: l10n.intervalEarlierBasis,
    source: l10n.manufacturerSource,
    effectiveTrigger: l10n.triggerMileage,
    intervalFraction: 0.82,
  ),
  _ConsumableDemo(
    id: 'brakes',
    key: Key('consumable-rail-brakes'),
    title: l10n.brakesTitle,
    icon: Icons.album_outlined,
    kind: _ConsumableKind.condition,
    railState: l10n.brakesState,
    due: l10n.brakesDue,
    basis: l10n.conditionBasis,
    source: l10n.inspectionRuleSource,
    effectiveTrigger: l10n.triggerInspection,
    inspectionState: _InspectionState.checkRequired,
    lastInspection: l10n.lastInspectionUnknown,
  ),
  _ConsumableDemo(
    id: 'coolant',
    title: l10n.coolantTitle,
    icon: Icons.water_drop_outlined,
    kind: _ConsumableKind.interval,
    railState: l10n.coolantState,
    due: l10n.coolantDue,
    basis: l10n.intervalEarlierBasis,
    source: l10n.publishedRuleSource,
    effectiveTrigger: l10n.triggerTime,
    intervalFraction: 0.94,
  ),
  _ConsumableDemo(
    id: 'air-filter',
    title: l10n.airFilterTitle,
    icon: Icons.air_outlined,
    kind: _ConsumableKind.interval,
    railState: l10n.normalInterval,
    due: l10n.airFilterDue,
    basis: l10n.verifiedMileageBasis,
    source: l10n.manufacturerSource,
    effectiveTrigger: l10n.triggerMileage,
    intervalFraction: 0.42,
  ),
  _ConsumableDemo(
    id: 'tires',
    title: l10n.tiresTitle,
    icon: Icons.tire_repair_outlined,
    kind: _ConsumableKind.condition,
    railState: l10n.tiresState,
    due: l10n.tiresDue,
    basis: l10n.tiresBasis,
    source: l10n.inspectionRecommendationSource,
    effectiveTrigger: l10n.triggerUnknown,
    inspectionState: _InspectionState.unknown,
    lastInspection: l10n.lastInspectionUnknown,
  ),
];

// ignore: unused_element - kept for demo consumable detail sheets
class _ConsumablesSideSheet extends StatelessWidget {
  const _ConsumablesSideSheet({
    required this.selected,
    required this.onSelected,
    required this.onClose,
  });

  final _ConsumableDemo selected;
  final ValueChanged<_ConsumableDemo> onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: context.l10n.consumablesSheetSemantics,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TechnicalLabel(context.l10n.consumablesProjection),
                      const SizedBox(height: 3),
                      Text(
                        context.l10n.consumables,
                        key: Key('all-consumables'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('close-consumables-sheet'),
                  autofocus: true,
                  tooltip: context.l10n.closeConsumables,
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Divider(color: colors.outlineVariant),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              children: [
                Text(context.l10n.consumablesDisclaimer),
                const SizedBox(height: 10),
                for (final item in _demoConsumables(context.l10n))
                  _ConsumableSheetRow(
                    item: item,
                    selected: item.id == selected.id,
                    onTap: () => onSelected(item),
                  ),
                const SizedBox(height: 14),
                Semantics(
                  liveRegion: true,
                  label: context.l10n.selectedConsumable(selected.title),
                  child: AutomotivePanel(
                    emphasized: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(selected.icon, color: selected.color(context)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selected.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const ExampleBadge(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _DetailLine(
                          icon: selected.kind == _ConsumableKind.interval
                              ? Icons.timelapse
                              : Icons.manage_search,
                          text: selected.kind == _ConsumableKind.interval
                              ? context.l10n.intervalFraction(
                                  (selected.intervalFraction! * 100).round(),
                                )
                              : context.l10n.conditionNoPercent(
                                  selected.railState,
                                ),
                        ),
                        if (selected.lastInspection != null)
                          _DetailLine(
                            icon: Icons.event_busy_outlined,
                            text: selected.lastInspection!,
                          ),
                        _DetailLine(
                          icon: Icons.event_outlined,
                          text: selected.due,
                        ),
                        _DetailLine(
                          icon: Icons.alt_route,
                          text: selected.effectiveTrigger,
                        ),
                        _DetailLine(
                          icon: Icons.rule_outlined,
                          text: selected.basis,
                        ),
                        _DetailLine(
                          icon: Icons.verified_outlined,
                          text: selected.source,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsumableSheetRow extends StatelessWidget {
  const _ConsumableSheetRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _ConsumableDemo item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.consumableRowSemantics(item.title, item.railState),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              ConsumableGauge(
                icon: item.icon,
                color: item.color(context),
                progress: item.intervalFraction,
                stateIcon: item.stateIcon,
                selected: selected,
                semanticLabel: item.railState,
                onTap: onTap,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      item.railState,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: colors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

enum _EventPrimaryCategory {
  maintenanceRepair,
  parts,
  fuel,
  inspection,
  document,
  mileage,
  expense,
  reminder,
}

extension on _EventPrimaryCategory {
  IconData get icon => switch (this) {
    _EventPrimaryCategory.maintenanceRepair => Icons.car_repair_outlined,
    _EventPrimaryCategory.parts => Icons.settings_outlined,
    _EventPrimaryCategory.fuel => Icons.local_gas_station_outlined,
    _EventPrimaryCategory.inspection => Icons.manage_search_outlined,
    _EventPrimaryCategory.document => Icons.description_outlined,
    _EventPrimaryCategory.mileage => Icons.speed_outlined,
    _EventPrimaryCategory.expense => Icons.receipt_long_outlined,
    _EventPrimaryCategory.reminder => Icons.notifications_active_outlined,
  };

  String label(AppLocalizations l10n) => switch (this) {
    _EventPrimaryCategory.maintenanceRepair => l10n.categoryMaintenance,
    _EventPrimaryCategory.parts => l10n.categoryParts,
    _EventPrimaryCategory.fuel => l10n.categoryFuel,
    _EventPrimaryCategory.inspection => l10n.categoryInspection,
    _EventPrimaryCategory.document => l10n.categoryDocument,
    _EventPrimaryCategory.mileage => l10n.categoryMileage,
    _EventPrimaryCategory.expense => l10n.categoryExpense,
    _EventPrimaryCategory.reminder => l10n.categoryReminder,
  };
}

class _RoadmapEvent {
  const _RoadmapEvent({
    required this.timeLabel,
    required this.title,
    required this.category,
    required this.detail,
    required this.future,
    this.mileage,
    this.actionLevel,
    this.basis,
  }) : assert(
         future == (actionLevel != null && basis != null),
         'Future demo events must expose both signal families.',
       );

  final String timeLabel;
  final String title;
  final _EventPrimaryCategory category;
  final String detail;
  final bool future;
  final String? mileage;
  final TimelineActionLevel? actionLevel;
  final PresentationBasis? basis;
}

List<_RoadmapEvent> _demoTimeline(AppLocalizations l10n) => [
  _RoadmapEvent(
    timeLabel: l10n.timelineFuelTime,
    title: l10n.timelineFuelTitle,
    category: _EventPrimaryCategory.fuel,
    detail: l10n.timelineFuelDetail,
    future: false,
    mileage: l10n.demoMileage84120,
  ),
  _RoadmapEvent(
    timeLabel: l10n.timelineServiceTime,
    title: l10n.timelineServiceTitle,
    category: _EventPrimaryCategory.maintenanceRepair,
    detail: l10n.timelineServiceDetail,
    future: false,
    mileage: l10n.demoMileage83900,
  ),
  _RoadmapEvent(
    timeLabel: l10n.timelineExpenseTime,
    title: l10n.timelineExpenseTitle,
    category: _EventPrimaryCategory.expense,
    detail: l10n.timelineExpenseDetail,
    future: false,
  ),
  _RoadmapEvent(
    timeLabel: l10n.timelineMileageTime,
    title: l10n.timelineMileageTitle,
    category: _EventPrimaryCategory.mileage,
    detail: l10n.timelineMileageDetail,
    future: true,
    actionLevel: TimelineActionLevel.info,
    basis: PresentationBasis.forecast,
  ),
  _RoadmapEvent(
    timeLabel: l10n.timelineBrakesTime,
    title: l10n.timelineBrakesTitle,
    category: _EventPrimaryCategory.inspection,
    detail: l10n.timelineBrakesDetail,
    future: true,
    actionLevel: TimelineActionLevel.recommendation,
    basis: PresentationBasis.missingData,
  ),
  _RoadmapEvent(
    timeLabel: l10n.timelineFilterTime,
    title: l10n.timelineFilterTitle,
    category: _EventPrimaryCategory.parts,
    detail: l10n.timelineFilterDetail,
    future: true,
    mileage: l10n.mileageThreshold,
    actionLevel: TimelineActionLevel.attention,
    basis: PresentationBasis.confirmed,
  ),
  _RoadmapEvent(
    timeLabel: l10n.timelineDocumentTime,
    title: l10n.timelineDocumentTitle,
    category: _EventPrimaryCategory.document,
    detail: l10n.timelineDocumentDetail,
    future: true,
    actionLevel: TimelineActionLevel.required,
    basis: PresentationBasis.confirmed,
  ),
  _RoadmapEvent(
    timeLabel: l10n.timelineReminderTime,
    title: l10n.timelineReminderTitle,
    category: _EventPrimaryCategory.reminder,
    detail: l10n.timelineReminderDetail,
    future: true,
    actionLevel: TimelineActionLevel.critical,
    basis: PresentationBasis.forecast,
  ),
];

class _CurrentTimelineMarker extends StatelessWidget {
  const _CurrentTimelineMarker();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: context.l10n.nowSemantics,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Icon(Icons.my_location, color: colors.primary, size: 25),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.l10n.nowExample,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailedTimelineNode extends StatelessWidget {
  const _DetailedTimelineNode({required this.event, required this.isLast});

  final _RoadmapEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Semantics(
      enabled: false,
      label: [
        event.timeLabel,
        if (event.mileage != null) event.mileage!,
        l10n.eventCategorySemantics(event.title, event.category.label(l10n)),
        if (event.actionLevel != null)
          _previewActionLabel(context, event.actionLevel!),
        if (event.basis != null) _previewBasisLabel(context, event.basis!),
        l10n.demoNotVehicleData,
      ].join('. '),
      child: Opacity(
        opacity: 0.78,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 38,
                child: Column(
                  children: [
                    Container(
                      key: Key('preview-component-${event.category.name}'),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surfaceContainerHighest,
                        border: Border.all(color: colors.outline),
                      ),
                      child: Icon(
                        event.category.icon,
                        size: 19,
                        color: colors.secondary,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1,
                          color: colors.outlineVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.timeLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (event.mileage != null)
                        Text(
                          event.mileage!,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        event.category.label(l10n),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colors.secondary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        event.detail,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (event.future) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          key: Key(
                            'preview-event-signals-'
                            '${event.actionLevel!.name}-${event.basis!.name}',
                          ),
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            _PreviewSignal(
                              family: 'action',
                              value: event.actionLevel!.name,
                              icon: _previewActionIcon(event.actionLevel!),
                              label: _previewActionLabel(
                                context,
                                event.actionLevel!,
                              ),
                              color: _previewActionColor(
                                context,
                                event.actionLevel!,
                              ),
                            ),
                            _PreviewSignal(
                              family: 'basis',
                              value: event.basis!.name,
                              icon: _previewBasisIcon(event.basis!),
                              label: _previewBasisLabel(context, event.basis!),
                              color: _previewBasisColor(context, event.basis!),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewSignal extends StatelessWidget {
  const _PreviewSignal({
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
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          key: Key('preview-indicator-$family-$value'),
          onTap: () => _showPreviewLegend(
            context,
            focusFamily: family,
            focusValue: value,
          ),
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
}

Future<void> _showPreviewLegend(
  BuildContext context, {
  String? focusFamily,
  String? focusValue,
}) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(context.l10n.planLegend),
    content: SingleChildScrollView(
      child: Column(
        key: const Key('preview-plan-legend-content'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.legendActionLevel),
          for (final action in TimelineActionLevel.values.where(
            (value) => value != TimelineActionLevel.unrecognized,
          ))
            _PreviewLegendRow(
              icon: _previewActionIcon(action),
              label: _previewActionLabel(context, action),
              explanation: _previewActionExplanation(context, action),
              color: _previewActionColor(context, action),
              focused: focusFamily == 'action' && focusValue == action.name,
              rowKey: 'preview-legend-action-${action.name}',
            ),
          const Divider(),
          Text(context.l10n.legendBasis),
          for (final basis in PresentationBasis.values.where(
            (value) => value != PresentationBasis.unrecognized,
          ))
            _PreviewLegendRow(
              icon: _previewBasisIcon(basis),
              label: _previewBasisLabel(context, basis),
              explanation: _previewBasisExplanation(context, basis),
              color: _previewBasisColor(context, basis),
              focused: focusFamily == 'basis' && focusValue == basis.name,
              rowKey: 'preview-legend-basis-${basis.name}',
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

class _PreviewLegendRow extends StatelessWidget {
  const _PreviewLegendRow({
    required this.icon,
    required this.label,
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

String _previewActionLabel(BuildContext context, TimelineActionLevel value) =>
    switch (value) {
      TimelineActionLevel.info => context.l10n.actionInfo,
      TimelineActionLevel.recommendation => context.l10n.actionRecommendation,
      TimelineActionLevel.attention => context.l10n.actionAttention,
      TimelineActionLevel.required => context.l10n.actionRequired,
      TimelineActionLevel.critical => context.l10n.actionCritical,
      TimelineActionLevel.unrecognized => context.l10n.unknownValue,
    };

String _previewActionExplanation(
  BuildContext context,
  TimelineActionLevel value,
) => switch (value) {
  TimelineActionLevel.info => context.l10n.actionInfoExplanation,
  TimelineActionLevel.recommendation =>
    context.l10n.actionRecommendationExplanation,
  TimelineActionLevel.attention => context.l10n.actionAttentionExplanation,
  TimelineActionLevel.required => context.l10n.actionRequiredExplanation,
  TimelineActionLevel.critical => context.l10n.actionCriticalExplanation,
  TimelineActionLevel.unrecognized => context.l10n.unknownValue,
};

IconData _previewActionIcon(TimelineActionLevel value) => switch (value) {
  TimelineActionLevel.info => Icons.info_outline,
  TimelineActionLevel.recommendation => Icons.thumb_up_alt_outlined,
  TimelineActionLevel.attention => Icons.schedule_outlined,
  TimelineActionLevel.required => Icons.report_outlined,
  TimelineActionLevel.critical => Icons.priority_high,
  TimelineActionLevel.unrecognized => Icons.help_outline,
};

Color _previewActionColor(BuildContext context, TimelineActionLevel value) {
  final automotive =
      Theme.of(context).extension<AutomotiveColors>() ?? AutomotiveColors.dark;
  return switch (value) {
    TimelineActionLevel.info => automotive.info,
    TimelineActionLevel.recommendation => automotive.success,
    TimelineActionLevel.attention => automotive.warning,
    TimelineActionLevel.required => automotive.requiredAction,
    TimelineActionLevel.critical => automotive.error,
    TimelineActionLevel.unrecognized => Theme.of(
      context,
    ).colorScheme.onSurfaceVariant,
  };
}

String _previewBasisLabel(BuildContext context, PresentationBasis value) =>
    switch (value) {
      PresentationBasis.confirmed => context.l10n.basisConfirmed,
      PresentationBasis.forecast => context.l10n.basisForecast,
      PresentationBasis.missingData => context.l10n.basisMissingData,
      PresentationBasis.unrecognized => context.l10n.unknownValue,
    };

String _previewBasisExplanation(
  BuildContext context,
  PresentationBasis value,
) => switch (value) {
  PresentationBasis.confirmed => context.l10n.basisConfirmedExplanation,
  PresentationBasis.forecast => context.l10n.basisForecastExplanation,
  PresentationBasis.missingData => context.l10n.basisMissingDataExplanation,
  PresentationBasis.unrecognized => context.l10n.unknownValue,
};

IconData _previewBasisIcon(PresentationBasis value) => switch (value) {
  PresentationBasis.confirmed => Icons.check_circle_outline,
  PresentationBasis.forecast => Icons.timeline_outlined,
  PresentationBasis.missingData => Icons.help_outline,
  PresentationBasis.unrecognized => Icons.help_outline,
};

Color _previewBasisColor(BuildContext context, PresentationBasis value) {
  final automotive =
      Theme.of(context).extension<AutomotiveColors>() ?? AutomotiveColors.dark;
  return switch (value) {
    PresentationBasis.confirmed => automotive.success,
    PresentationBasis.forecast => automotive.info,
    PresentationBasis.missingData => automotive.warning,
    PresentationBasis.unrecognized => Theme.of(
      context,
    ).colorScheme.onSurfaceVariant,
  };
}

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
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
    final locale = ref.watch(activeLocaleProvider).languageCode;
    if (vehicle != null) {
      _ensure(vehicle.id, locale);
    } else {
      _requestedKey = null;
    }
    final maintenance = ref.watch(maintenanceControllerProvider);
    final colors = Theme.of(context).colorScheme;

    if (vehicle == null) {
      return _PreviewPage(
        title: context.l10n.navJournal,
        gateMessage: context.l10n.journalGate,
        previewChild: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.journalDemoDisclaimer),
            const SizedBox(height: 4),
            PreviewListTile(
              icon: Icons.car_repair_outlined,
              title: context.l10n.journalServiceTitle,
              subtitle: context.l10n.journalServiceSubtitle,
            ),
            PreviewListTile(
              icon: Icons.local_gas_station_outlined,
              title: context.l10n.journalFuelTitle,
              subtitle: context.l10n.journalFuelSubtitle,
            ),
            PreviewListTile(
              icon: Icons.receipt_long_outlined,
              title: context.l10n.journalExpenseTitle,
              subtitle: context.l10n.journalExpenseSubtitle,
            ),
          ],
        ),
        vehicleChild: const SizedBox.shrink(),
      );
    }

    return Column(
      key: const Key('journal-vehicle-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: colors.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.navJournal,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('journal-info'),
                  tooltip: context.l10n.journalIconsLegendTitle,
                  onPressed: () => _showJournalLegend(context),
                  icon: Icon(Icons.info_outline, color: colors.primary),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _JournalVehicleList(
            vehicleId: vehicle.id,
            locale: locale,
            state: maintenance,
            onRetry: () {
              _requestedKey = null;
              _ensure(vehicle.id, locale, force: true);
            },
          ),
        ),
      ],
    );
  }
}

void _showJournalLegend(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  final items = [
    (Icons.oil_barrel, context.l10n.journalLegendOil),
    (Icons.album_outlined, context.l10n.journalLegendBrakes),
    (Icons.manage_search_outlined, context.l10n.journalLegendInspect),
    (Icons.build_outlined, context.l10n.journalLegendOther),
  ];
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.journalIconsLegendTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.journalIconsLegendBody),
          const SizedBox(height: 12),
          for (final (icon, label) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(label)),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.l10n.understood),
        ),
      ],
    ),
  );
}

class _JournalVehicleList extends ConsumerWidget {
  const _JournalVehicleList({
    required this.vehicleId,
    required this.locale,
    required this.state,
    required this.onRetry,
  });

  final String vehicleId;
  final String locale;
  final MaintenanceState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = state.matches(vehicleId, locale);
    final stage = matches ? state.roadmapStage : MaintenanceLoadStage.loading;
    final records = matches ? state.serviceRecords?.items : null;
    final colors = Theme.of(context).colorScheme;

    if (stage == MaintenanceLoadStage.loading ||
        stage == MaintenanceLoadStage.idle) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(context.l10n.journalLoading),
          ],
        ),
      );
    }
    if (stage == MaintenanceLoadStage.error) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: AutomotivePanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.journalLoadError),
              TextButton(
                key: const Key('journal-retry'),
                onPressed: onRetry,
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (records == null || records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: AutomotivePanel(child: Text(context.l10n.serviceTimelineEmpty)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              key: Key('journal-service-${record.id}'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openJournalNode(context, ref, record),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _journalRecordIcon(record),
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.title ??
                                record.items
                                    .map((item) => item.title)
                                    .join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              _journalDate(record.serviceDate),
                              if (record.mileage != null)
                                '${record.mileage} ${record.mileageUnit ?? 'km'}',
                            ].join(' · '),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _openJournalNode(
  BuildContext context,
  WidgetRef ref,
  ServiceRecord record,
) async {
  final vehicle = ref.read(vehicleSetupControllerProvider).activeVehicle;
  if (vehicle == null) return;

  final workCode = record.items.isNotEmpty ? record.items.first.workCode : '';
  final consumables =
      ref.read(maintenanceControllerProvider).consumables?.items ??
      const <Consumable>[];
  final match = consumables
      .where(
        (item) =>
            item.workCode == workCode ||
            item.id.replaceAll('-', '_') == workCode ||
            (workCode.isEmpty &&
                record.title != null &&
                item.title == record.title),
      )
      .firstOrNull;

  if (match != null) {
    await showStateDetailSheet(
      context: context,
      ref: ref,
      vehicle: vehicle,
      item: match,
      forecast: ref.read(maintenanceControllerProvider).mileageForecast,
    );
    return;
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.journalOpenNodeMissing)),
  );
}

IconData _journalRecordIcon(ServiceRecord record) {
  final code = record.items.isNotEmpty ? record.items.first.workCode : null;
  return workNodeIcon(code, fallbackId: record.id);
}

String _journalDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')}.${value.year}';

List<MileageObservation> _mergedMileagePoints({
  required Vehicle vehicle,
  required List<MileageObservation> observations,
  required List<ServiceRecord> records,
}) {
  final byKey = <String, MileageObservation>{};
  void put(MileageObservation item) {
    final day = DateTime(
      item.observedAt.year,
      item.observedAt.month,
      item.observedAt.day,
    );
    final key = '${day.toIso8601String()}|${item.valueKm}';
    byKey.putIfAbsent(key, () => item);
  }

  for (final item in observations) {
    put(item);
  }
  for (final record in records) {
    if (record.mileage == null) continue;
    final unit = record.mileageUnit ?? 'km';
    final value = record.mileage!;
    put(
      MileageObservation(
        id: 'service-${record.id}',
        vehicleId: vehicle.id,
        value: value,
        unit: unit,
        observedAt: record.serviceDate,
        source: 'service_record',
      ),
    );
  }
  if (vehicle.mileage != null) {
    put(
      MileageObservation(
        id: 'vehicle-current',
        vehicleId: vehicle.id,
        value: vehicle.mileage!,
        unit: vehicle.mileageUnit ?? 'km',
        observedAt: DateTime.now(),
        source: 'vehicle',
      ),
    );
  }
  final merged = byKey.values.toList();
  merged.sort((a, b) => a.observedAt.compareTo(b.observedAt));
  return merged;
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String? _requestedKey;

  void _ensure(String vehicleId, String locale) {
    final key = '$vehicleId:$locale';
    if (_requestedKey == key) return;
    _requestedKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(maintenanceControllerProvider.notifier)
            .ensureRoadmap(vehicleId, locale: locale);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(vehicleSetupControllerProvider).activeVehicle;
    final locale = ref.watch(activeLocaleProvider).languageCode;
    if (vehicle != null) {
      _ensure(vehicle.id, locale);
    } else {
      _requestedKey = null;
    }
    final state = ref.watch(maintenanceControllerProvider);
    final activeVehicle = vehicle;
    final matches =
        activeVehicle != null && state.matches(activeVehicle.id, locale);
    final stage = matches ? state.roadmapStage : MaintenanceLoadStage.loading;
    final observations = activeVehicle == null || !matches
        ? const <MileageObservation>[]
        : _mergedMileagePoints(
            vehicle: activeVehicle,
            observations:
                state.mileageObservations?.items ??
                const <MileageObservation>[],
            records:
                state.serviceRecords?.items ?? const <ServiceRecord>[],
          );
    return _PreviewPage(
      title: context.l10n.navAnalytics,
      gateMessage: context.l10n.analyticsGate,
      action: IconButton(
        key: const Key('analytics-exit'),
        tooltip: context.l10n.close,
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/more');
          }
        },
        icon: const Icon(Icons.close),
      ),
      previewChild: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.analyticsEmpty),
          const SizedBox(height: 20),
          _AnalyticsSkeleton(
            icon: Icons.payments_outlined,
            title: context.l10n.confirmedAmounts,
            detail: context.l10n.currentMonthYear,
          ),
          const SizedBox(height: 16),
          _AnalyticsSkeleton(
            icon: Icons.donut_small_outlined,
            title: context.l10n.expenseCategories,
            detail: context.l10n.confirmedDistribution,
          ),
          const SizedBox(height: 16),
          _AnalyticsSkeleton(
            icon: Icons.show_chart,
            title: context.l10n.confirmedMileage,
            detail: context.l10n.odometerDynamics,
          ),
          const SizedBox(height: 16),
          Text(context.l10n.fuelConsumptionFuture),
        ],
      ),
      vehicleChild: vehicle == null
          ? const SizedBox.shrink()
          : Column(
              key: const Key('analytics-vehicle-content'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.analyticsForVehicle(vehicle.make, vehicle.model),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                if (stage == MaintenanceLoadStage.loading ||
                    stage == MaintenanceLoadStage.idle)
                  AutomotivePanel(child: Text(context.l10n.analyticsPreparing))
                else if (stage == MaintenanceLoadStage.error)
                  AutomotivePanel(child: Text(context.l10n.analyticsLoadError))
                else ...[
                  MileageTrendChart(observations: observations),
                  const SizedBox(height: 20),
                  _AnalyticsSkeleton(
                    icon: Icons.payments_outlined,
                    title: context.l10n.confirmedAmounts,
                    detail: context.l10n.currentMonthYear,
                  ),
                  const SizedBox(height: 16),
                  _AnalyticsSkeleton(
                    icon: Icons.donut_small_outlined,
                    title: context.l10n.expenseCategories,
                    detail: context.l10n.confirmedDistribution,
                  ),
                  const SizedBox(height: 16),
                  Text(context.l10n.fuelConsumptionFuture),
                ],
              ],
            ),
    );
  }
}

class ConsumablesPreviewScreen extends ConsumerStatefulWidget {
  const ConsumablesPreviewScreen({super.key});

  @override
  ConsumerState<ConsumablesPreviewScreen> createState() =>
      _ConsumablesPreviewScreenState();
}

class _ConsumablesPreviewScreenState
    extends ConsumerState<ConsumablesPreviewScreen> {
  bool _redirectScheduled = false;

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(vehicleSetupControllerProvider).activeVehicle;
    if (vehicle != null) {
      if (!_redirectScheduled) {
        _redirectScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/roadmap');
        });
      }
      return Center(
        key: const Key('consumables-real-redirect'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.consumablesRedirecting,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: context.l10n.back,
                onPressed: () => context.go('/roadmap'),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  context.l10n.allConsumables,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const ExampleBadge(),
            ],
          ),
          const SizedBox(height: 8),
          PreviewGate(
            message: context.l10n.allConsumablesGate,
            onAddVehicle: () => context.go('/garage/add'),
          ),
          const SizedBox(height: 12),
          _ConsumablePreviewCard(
            icon: Icons.oil_barrel_outlined,
            title: context.l10n.oilFilters,
            detail: context.l10n.oilFiltersDetail,
          ),
          _ConsumablePreviewCard(
            icon: Icons.water_drop_outlined,
            title: context.l10n.technicalFluids,
            detail: context.l10n.technicalFluidsDetail,
          ),
          _ConsumablePreviewCard(
            icon: Icons.album_outlined,
            title: context.l10n.brakesTitle,
            detail: context.l10n.brakesDetail,
          ),
          _ConsumablePreviewCard(
            icon: Icons.tire_repair_outlined,
            title: context.l10n.tiresTitle,
            detail: context.l10n.tiresDetail,
          ),
        ],
      ),
    );
  }
}

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  Future<void> _showLanguagePicker(BuildContext context, WidgetRef ref) async {
    final selected = ref.read(localeControllerProvider).value;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final options = [
          ('system', null, context.l10n.system),
          ('ru', const Locale('ru'), context.l10n.russian),
          ('en', const Locale('en'), context.l10n.english),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.languagePickerTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: selected?.languageCode ?? 'system',
                  onChanged: (value) async {
                    final locale = options
                        .firstWhere((option) => option.$1 == value)
                        .$2;
                    await ref
                        .read(localeControllerProvider.notifier)
                        .setLocale(locale);
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                  child: Column(
                    children: [
                      for (final option in options)
                        RadioListTile<String>(
                          key: Key('language-${option.$1}'),
                          value: option.$1,
                          title: Text(option.$3),
                          secondary:
                              (selected?.languageCode ?? 'system') == option.$1
                              ? Icon(
                                  Icons.check_circle,
                                  semanticLabel: context.l10n.selectedLanguage,
                                )
                              : null,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStub(BuildContext context, String title) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(context.l10n.localPreviewFuture),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.understood),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasVehicle =
        ref.watch(vehicleSetupControllerProvider).activeVehicle != null;
    Widget controls({required bool selectedVehicle}) => Column(
      children: [
        _ControlRow(
          key: const Key('more-analytics'),
          icon: Icons.analytics_outlined,
          title: context.l10n.moreAnalytics,
          detail: context.l10n.moreAnalyticsDetail,
          onTap: () => context.push('/analytics'),
        ),
        _ControlRow(
          key: const Key('language-settings'),
          icon: Icons.settings_outlined,
          title: context.l10n.language,
          detail: context.l10n.unitsThemeLanguage,
          onTap: () => _showLanguagePicker(context, ref),
        ),
        if (showDevMenu)
          _ControlRow(
            key: const Key('more-development'),
            icon: Icons.developer_mode_outlined,
            title: context.l10n.moreDevelopment,
            detail: context.l10n.moreDevelopmentDetail,
            onTap: () => context.push('/dev'),
          ),
        _ControlRow(
          icon: Icons.feedback_outlined,
          title: context.l10n.feedback,
          detail: context.l10n.feedbackDetail,
          onTap: () => _showStub(context, context.l10n.feedback),
        ),
        Semantics(
          enabled: false,
          hint: selectedVehicle
              ? context.l10n.comingSoon
              : context.l10n.addVehicleFirst,
          child: _ControlRow(
            key: const Key('vehicle-reminders'),
            icon: Icons.notifications_active_outlined,
            title: context.l10n.vehicleReminders,
            detail: selectedVehicle
                ? context.l10n.comingSoon
                : context.l10n.addVehicleFirst,
            disabled: true,
          ),
        ),
      ],
    );
    return _PreviewPage(
      title: context.l10n.navMore,
      gateMessage: context.l10n.moreGate,
      previewChild: controls(selectedVehicle: false),
      vehicleChild: hasVehicle
          ? controls(selectedVehicle: true)
          : const SizedBox.shrink(),
    );
  }
}

class _PreviewPage extends ConsumerWidget {
  const _PreviewPage({
    required this.title,
    required this.gateMessage,
    required this.previewChild,
    required this.vehicleChild,
    this.action,
  });

  final String title;
  final String gateMessage;
  final Widget previewChild;
  final Widget vehicleChild;
  final Widget? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasVehicle =
        ref.watch(vehicleSetupControllerProvider).activeVehicle != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!hasVehicle) ...[
            TechnicalLabel(context.l10n.cockpitDemo),
            const SizedBox(height: 5),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (!hasVehicle) const ExampleBadge(),
              if (action != null) ...[const SizedBox(width: 8), action!],
            ],
          ),
          const SizedBox(height: 12),
          if (!hasVehicle) ...[
            PreviewGate(
              message: gateMessage,
              onAddVehicle: () => context.go('/garage/add'),
            ),
            const SizedBox(height: 12),
            previewChild,
          ] else
            vehicleChild,
        ],
      ),
    );
  }
}

class _ConsumablePreviewCard extends StatelessWidget {
  const _ConsumablePreviewCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      enabled: false,
      hint: context.l10n.demoConsumableHint,
      child: Opacity(
        opacity: 0.6,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 50,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TechnicalLabel(context.l10n.demoTechnicalRail),
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(detail),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsSkeleton extends StatelessWidget {
  const _AnalyticsSkeleton({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      enabled: false,
      label: context.l10n.structureWithoutData(title, detail),
      child: Opacity(
        opacity: 0.55,
        child: AutomotivePanel(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(detail),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: List.generate(
                        6,
                        (index) => Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.only(right: index == 5 ? 0 : 4),
                            color: colors.outlineVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.icon,
    required this.title,
    required this.detail,
    this.onTap,
    this.disabled = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Opacity(
      opacity: disabled ? 0.48 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TechnicalLabel(context.l10n.controlChannel),
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(detail),
                  ],
                ),
              ),
              Icon(
                disabled ? Icons.lock_outline : Icons.chevron_right,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

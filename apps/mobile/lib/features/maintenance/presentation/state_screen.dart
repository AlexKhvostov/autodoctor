import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/locale_controller.dart';
import '../../../core/widgets/automotive_widgets.dart';
import '../../../core/widgets/preview_widgets.dart';
import '../../../l10n/l10n.dart';
import '../../vehicle/vehicle_controller.dart';
import '../maintenance.dart';
import '../maintenance_controller.dart';
import 'maintenance_screens.dart';

class StateScreen extends ConsumerStatefulWidget {
  const StateScreen({super.key});

  @override
  ConsumerState<StateScreen> createState() => _StateScreenState();
}

class _StateScreenState extends ConsumerState<StateScreen> {
  String? _requestedKey;

  void _ensure(String vehicleId, String locale) {
    final key = '$vehicleId:$locale';
    if (_requestedKey == key) return;
    _requestedKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(maintenanceControllerProvider.notifier)
          .ensureRoadmap(vehicleId, locale: locale);
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
    final matches = vehicle != null && state.matches(vehicle.id, locale);
    final stage = matches ? state.roadmapStage : MaintenanceLoadStage.idle;
    final tiles = matches && state.consumables != null
        ? sortStateTiles(state.consumables!.items)
        : const <Consumable>[];

    if (vehicle == null) {
      return _StatePreview();
    }

    if (stage == MaintenanceLoadStage.loading ||
        stage == MaintenanceLoadStage.idle) {
      return const Center(
        key: Key('state-loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (stage == MaintenanceLoadStage.error) {
      return Center(
        child: AutomotivePanel(
          emphasized: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.planLoadError),
              FilledButton(
                key: const Key('state-retry'),
                onPressed: () {
                  _requestedKey = null;
                  _ensure(vehicle.id, locale);
                },
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.stateTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tiles.isEmpty
                ? Text(context.l10n.stateEmpty)
                : GridView.builder(
                    key: const Key('state-tiles-grid'),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.92,
                        ),
                    itemCount: tiles.length,
                    itemBuilder: (context, index) {
                      final item = tiles[index];
                      return _StateTile(
                        item: item,
                        onTap: () => openConsumablesSideSheet(
                          context: context,
                          ref: ref,
                          vehicle: vehicle,
                          items: state.consumables!.items,
                          selected: item,
                          forecast: state.mileageForecast,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StateTile extends StatelessWidget {
  const _StateTile({required this.item, required this.onTap});

  final Consumable item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final wear = item.latestObservation;
    final isWear = supportsWearMeasurement(
      item.workCode.isEmpty ? item.id.replaceAll('-', '_') : item.workCode,
    );
    final isInterval = item.kind == ConsumableKind.intervalBased;
    final used = item.usedFraction?.clamp(0.0, 1.0);
    final color = switch (item.status) {
      MaintenanceStatus.overdue => colors.error,
      MaintenanceStatus.soon => colors.primary,
      _ => colors.secondary,
    };

    String status;
    double? ring;
    if (isWear && wear != null) {
      status = context.l10n.stateWearRemaining(
        wear.wearPercent,
        wear.remainingPercent,
      );
      ring = wear.wearPercent / 100;
    } else if (isInterval) {
      if (used == null) {
        status = context.l10n.stateNeedsData;
        ring = null;
      } else {
        status = context.l10n.stateUsedPercent((used * 100).round());
        ring = used;
      }
    } else {
      status =
          item.requiresCheckNow ||
              item.inspectionState == InspectionState.checkRequired
          ? context.l10n.inspectionRequired
          : context.l10n.stateInspectionStatus;
      ring = null;
    }

    return Material(
      key: Key('consumable-${item.id}'),
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('state-tile-${item.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(_stateIcon(item), size: 20, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: SizedBox.square(
                    dimension: 86,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (ring != null)
                          CircularProgressIndicator(
                            value: ring,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            color: color,
                            backgroundColor: colors.outlineVariant,
                          )
                        else
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: color, width: 3),
                            ),
                          ),
                        Icon(_stateIcon(item), size: 28, color: color),
                      ],
                    ),
                  ),
                ),
              ),
              if (ring != null) ...[
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    key: Key('state-bar-${item.id}'),
                    value: ring,
                    minHeight: 5,
                    color: color,
                    backgroundColor: colors.outlineVariant,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                status,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _stateIcon(Consumable item) {
  final id = item.id;
  if (id.contains('oil')) return Icons.oil_barrel_outlined;
  if (id.contains('tire')) return Icons.tire_repair_outlined;
  if (id.contains('coolant')) return Icons.water_drop_outlined;
  if (id.contains('brake')) return Icons.album_outlined;
  if (id.contains('filter')) return Icons.air_outlined;
  return Icons.build_outlined;
}

class _StatePreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final demos = [
      (
        'oil',
        Icons.oil_barrel_outlined,
        context.l10n.oilFilters,
        0.72,
        context.l10n.stateUsedPercent(72),
      ),
      (
        'brakes',
        Icons.album_outlined,
        context.l10n.brakesTitle,
        null,
        context.l10n.inspectionRequired,
      ),
      (
        'tires',
        Icons.tire_repair_outlined,
        context.l10n.tiresTitle,
        0.4,
        context.l10n.stateWearRemaining(40, 60),
      ),
      (
        'coolant',
        Icons.water_drop_outlined,
        context.l10n.technicalFluids,
        null,
        context.l10n.stateNeedsData,
      ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.stateTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const ExampleBadge(),
            ],
          ),
          const SizedBox(height: 8),
          PreviewGate(
            message: context.l10n.stateGate,
            onAddVehicle: () => context.go('/garage/add'),
          ),
          const SizedBox(height: 12),
          GridView.count(
            key: const Key('state-preview-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.92,
            children: [
              for (final demo in demos)
                AutomotivePanel(
                  key: Key('state-preview-${demo.$1}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(demo.$2, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              demo.$3,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Center(
                        child: SizedBox.square(
                          dimension: 72,
                          child: CircularProgressIndicator(
                            value: demo.$4,
                            strokeWidth: 7,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        demo.$5,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

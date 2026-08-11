import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../maintenance/maintenance.dart';
import '../../maintenance/maintenance_controller.dart';
import '../vehicle.dart';
import '../vehicle_controller.dart';
import 'vehicle_passport_sheet.dart';

Future<void> showGarageSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) => const _GarageSheet(),
  );
}

class _GarageSheet extends ConsumerWidget {
  const _GarageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehicleSetupControllerProvider);
    final vehicles = state.vehicles;
    final active = state.activeVehicle;
    final colors = Theme.of(context).colorScheme;
    final forecast = ref.watch(maintenanceControllerProvider).mileageForecast;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: ListView(
            controller: controller,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.garageTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final vehicle in vehicles) ...[
                _VehicleTile(
                  vehicle: vehicle,
                  selected: active?.id == vehicle.id,
                  forecast: active?.id == vehicle.id ? forecast : null,
                  onOpenPassport: () async {
                    final route = await showVehiclePassportSheet(
                      context,
                      vehicle: vehicle,
                    );
                    if (!context.mounted || route == null) return;
                    Navigator.pop(context);
                    if (!context.mounted) return;
                    if (route == '/analytics') {
                      context.push(route);
                    } else {
                      context.go(route);
                    }
                  },
                  onSelect: () {
                    ref
                        .read(vehicleSetupControllerProvider.notifier)
                        .selectVehicle(vehicle.id);
                  },
                ),
                const SizedBox(height: 10),
              ],
              _LockedSlotTile(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.garageSecondCarLocked)),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (vehicles.isEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/garage/add');
                  },
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.addVehicle),
                )
              else
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.lock_outline),
                  label: Text(context.l10n.garageAddBlocked),
                ),
              const SizedBox(height: 8),
              Text(
                context.l10n.garageOneCarHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({
    required this.vehicle,
    required this.selected,
    required this.onOpenPassport,
    required this.onSelect,
    this.forecast,
  });

  final Vehicle vehicle;
  final bool selected;
  final MileageForecast? forecast;
  final VoidCallback onOpenPassport;
  final VoidCallback onSelect;

  IconData get _silhouette {
    final blob =
        '${vehicle.make} ${vehicle.model} ${vehicle.generation ?? ''}'
            .toLowerCase();
    if (blob.contains('cabrio') ||
        blob.contains('кабрио') ||
        blob.contains('eos')) {
      return Icons.directions_car_filled;
    }
    return Icons.directions_car;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final engine = [
      if (vehicle.engineDisplacementCc != null)
        '${(vehicle.engineDisplacementCc! / 1000).toStringAsFixed(1)} L',
      if (vehicle.engineCode != null && vehicle.engineCode!.isNotEmpty)
        vehicle.engineCode!,
      if (vehicle.fuelType.isNotEmpty) vehicle.fuelType,
    ].join(' · ');

    final forecastLine = forecast == null
        ? null
        : context.l10n.forecastAnnualDistance(
            forecast!.isDefaultAssumption
                ? context.l10n.preliminaryEstimate
                : forecast!.estimateLabel,
            forecast!.annualDistance,
            forecast!.annualDistanceUnit,
          );

    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.55)
          : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpenPassport,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_silhouette, size: 32, color: colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicle.make} ${vehicle.model}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            '${vehicle.productionYear}',
                            if (engine.isNotEmpty) engine,
                            if (vehicle.mileage != null)
                              '${vehicle.mileage} ${vehicle.mileageUnit ?? 'km'}',
                          ].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (forecastLine != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            forecastLine,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, color: colors.primary),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: selected
                    ? FilledButton.tonalIcon(
                        onPressed: null,
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(context.l10n.garageSelected),
                      )
                    : FilledButton.icon(
                        onPressed: onSelect,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(context.l10n.garageSelect),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedSlotTile extends StatelessWidget {
  const _LockedSlotTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.outlineVariant,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.lock_outline, color: colors.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.garageSecondCarTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.garageSecondCarLocked,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/automotive_widgets.dart';
import '../../../core/widgets/odometer_overlay.dart';
import '../../../l10n/l10n.dart';
import '../../auth/auth.dart';
import '../../vehicle/presentation/garage_sheet.dart';
import '../../vehicle/vehicle_controller.dart';
import 'history_completeness_alarm.dart';

class GlobalHeaderFrame extends ConsumerStatefulWidget {
  const GlobalHeaderFrame({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<GlobalHeaderFrame> createState() => _GlobalHeaderFrameState();
}

class _GlobalHeaderFrameState extends ConsumerState<GlobalHeaderFrame> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(vehicleSetupControllerProvider.notifier).load(),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final vehicle = ref.watch(
            vehicleSetupControllerProvider.select(
              (state) => state.activeVehicle,
            ),
          );
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    vehicle == null
                        ? context.l10n.notifications
                        : context.l10n.notificationsForVehicle(
                            vehicle.make,
                            vehicle.model,
                          ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vehicle == null
                        ? context.l10n.notificationsEmpty
                        : context.l10n.notificationsNoNew,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text(context.l10n.close),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vehicle = ref.watch(vehicleSetupControllerProvider).activeVehicle;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: colors.surface,
              child: Container(
                height: 62,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colors.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: vehicle == null
                            ? context.l10n.addVehicleSemantics
                            : context.l10n.openVehicleProfile,
                        child: InkWell(
                          key: Key(
                            vehicle == null
                                ? 'header-add-vehicle'
                                : 'header-active-vehicle',
                          ),
                          onTap: vehicle == null
                              ? () => context.go('/garage/add')
                              : () => showGarageSheet(context, ref),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainer,
                              border: Border.all(color: colors.outlineVariant),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.directions_car_filled_outlined,
                                  size: 25,
                                  color: colors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TechnicalLabel(
                                        vehicle == null
                                            ? context.l10n.vehicleStatusNoCar
                                            : context.l10n.vehicleStatusActive,
                                      ),
                                      Text(
                                        vehicle == null
                                            ? context.l10n.garageEmpty
                                            : [
                                                '${vehicle.make} ${vehicle.model}',
                                                if (vehicle.mileage != null)
                                                  '${vehicle.mileage} ${vehicle.mileageUnit ?? 'km'}',
                                              ].join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  vehicle == null
                                      ? Icons.add
                                      : Icons.expand_more,
                                  size: 20,
                                  color: colors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      key: const Key('notifications-bell'),
                      tooltip: context.l10n.notifications,
                      onPressed: () => _showNotifications(context),
                      icon: const Icon(Icons.notifications_none),
                    ),
                    const SizedBox(width: 2),
                    Tooltip(
                      message: context.l10n.guestProfile,
                      child: Semantics(
                        button: true,
                        label: context.l10n.openGuestProfile,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => context.push('/profile'),
                          child: _ProfileAvatar(
                            user: ref.watch(authControllerProvider).asData?.value,
                            guestInitial: context.l10n.guestProfileInitial,
                            backgroundColor: colors.surfaceContainerHighest,
                            foregroundColor: colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const HistoryCompletenessAlarmBanner(),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: widget.child),
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: HistoryCompletenessAlarmTab(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.user,
    required this.guestInitial,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final AuthUser? user;
  final String guestInitial;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 17,
        backgroundColor: backgroundColor,
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    final initial = user == null
        ? guestInitial
        : _initialFromName(user!.name, user!.email);

    return CircleAvatar(
      radius: 17,
      backgroundColor: backgroundColor,
      child: Text(
        initial,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _initialFromName(String name, String email) {
    final source = name.trim().isNotEmpty ? name.trim() : email.trim();
    if (source.isEmpty) {
      return '?';
    }
    return String.fromCharCode(source.runes.first).toUpperCase();
  }
}

class BrowseShell extends StatelessWidget {
  const BrowseShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _openBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(child: navigationShell),
            _ShellNavigation(
              selectedIndex: navigationShell.currentIndex,
              onSelected: _openBranch,
            ),
          ],
        ),
        if (navigationShell.currentIndex == 0 ||
            navigationShell.currentIndex == 3)
          ValueListenableBuilder<int>(
            valueListenable: odometerPickerOpenCount,
            builder: (context, openCount, _) {
              if (openCount > 0) return const SizedBox.shrink();
              return Positioned(
                right: 16,
                bottom: 82,
                child: Semantics(
                  button: true,
                  label: context.l10n.addEventJournalSemantics,
                  child: FloatingActionButton(
                    key: Key(
                      navigationShell.currentIndex == 3
                          ? 'journal-quick-add'
                          : 'roadmap-quick-add',
                    ),
                    tooltip: context.l10n.addEvent,
                    onPressed: () => showQuickAddPreview(context),
                    child: const Icon(Icons.add),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

void showQuickAddPreview(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final vehicle = ref.watch(
          vehicleSetupControllerProvider.select((state) => state.activeVehicle),
        );
        final hasVehicle = vehicle != null;
        final items = [
          (
            Icons.local_gas_station_outlined,
            'fuel',
            context.l10n.quickAddFuel,
            false,
          ),
          (
            Icons.car_repair_outlined,
            'service',
            context.l10n.quickAddService,
            true,
          ),
          (
            Icons.receipt_long_outlined,
            'other-expense',
            context.l10n.quickAddExpense,
            false,
          ),
          (
            Icons.speed_outlined,
            'mileage',
            context.l10n.quickAddMileage,
            false,
          ),
        ];
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.addEvent,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                TechnicalLabel(
                  hasVehicle
                      ? context.l10n.quickAddTechnicalActive
                      : context.l10n.quickAddTechnical,
                ),
                const SizedBox(height: 4),
                Text(
                  hasVehicle
                      ? context.l10n.quickAddActiveHint
                      : context.l10n.quickAddPreview,
                ),
                const SizedBox(height: 8),
                for (final item in items)
                  Semantics(
                    key: Key('quick-add-${item.$2}'),
                    enabled: hasVehicle && item.$4,
                    label: hasVehicle
                        ? item.$4
                              ? item.$3
                              : '${item.$3}. ${context.l10n.comingSoon}'
                        : context.l10n.unavailableWithoutVehicle(item.$3),
                    child: ListTile(
                      key: Key('quick-add-tile-${item.$2}'),
                      enabled: hasVehicle && item.$4,
                      contentPadding: EdgeInsets.zero,
                      shape: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      leading: Icon(item.$1),
                      title: Text(item.$3),
                      subtitle: Text(
                        hasVehicle
                            ? item.$4
                                  ? context.l10n.specifyServiceHistory
                                  : context.l10n.comingSoon
                            : context.l10n.addVehicleFirst,
                      ),
                      trailing: hasVehicle
                          ? item.$4
                                ? const Icon(Icons.chevron_right)
                                : null
                          : const Icon(Icons.lock_outline, size: 18),
                      onTap: hasVehicle && item.$4
                          ? () {
                              Navigator.pop(sheetContext);
                              context.go('/service/add');
                            }
                          : null,
                    ),
                  ),
                if (!hasVehicle) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const Key('quick-add-add-vehicle'),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.go('/garage/add');
                    },
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.addVehicle),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _ShellNavigation extends StatelessWidget {
  const _ShellNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = [
      (Icons.route_outlined, Icons.route, context.l10n.navPlan),
      (
        Icons.monitor_heart_outlined,
        Icons.monitor_heart,
        context.l10n.navState,
      ),
      (
        Icons.auto_awesome_outlined,
        Icons.auto_awesome,
        context.l10n.navAssistant,
      ),
      (Icons.menu_book_outlined, Icons.menu_book, context.l10n.navJournal),
      (Icons.more_horiz, Icons.more_horiz, context.l10n.navMore),
    ];
    return Material(
      color: colors.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final selected = selectedIndex == index;
                if (index == 2) {
                  return Expanded(
                    child: Semantics(
                      button: true,
                      selected: selected,
                      label: context.l10n.aiCentralTab,
                      child: Tooltip(
                        message: context.l10n.aiAssistant,
                        child: InkResponse(
                          onTap: () => onSelected(index),
                          radius: 34,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 50,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: selected
                                        ? colors.primary
                                        : colors.surfaceContainerHighest,
                                    border: Border.all(
                                      color: colors.primary,
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Icon(
                                    selected ? item.$2 : item.$1,
                                    color: selected
                                        ? colors.onPrimary
                                        : colors.onPrimaryContainer,
                                  ),
                                ),
                                Text(
                                  item.$3,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: item.$3,
                    child: InkWell(
                      onTap: () => onSelected(index),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(2, 8, 2, 7),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              selected ? item.$2 : item.$1,
                              color: selected
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.$3,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: selected
                                        ? colors.primary
                                        : colors.onSurfaceVariant,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

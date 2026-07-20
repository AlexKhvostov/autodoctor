import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/browse/presentation/browse_screens.dart';
import '../features/browse/presentation/browse_shell.dart';
import '../features/maintenance/presentation/maintenance_screens.dart';
import '../features/maintenance/presentation/history_wizard_screen.dart';
import '../features/maintenance/presentation/service_record_screen.dart';
import '../features/maintenance/presentation/state_screen.dart';
import '../features/vehicle/presentation/add_vehicle_start_screen.dart';
import '../features/vehicle/presentation/vin_entry_stub_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter();
  ref.onDispose(router.dispose);
  return router;
});

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/roadmap',
    routes: [
      ShellRoute(
        builder: (context, state, child) => GlobalHeaderFrame(child: child),
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return BrowseShell(navigationShell: navigationShell);
            },
            branches: [
              _branch('/roadmap', const RoadmapScreen()),
              _branch('/journal', const JournalScreen()),
              _branch('/assistant', const AssistantScreen()),
              _branch('/state', const StateScreen()),
              _branch('/more', const MoreScreen()),
            ],
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) =>
                const MaterialPage<void>(child: AnalyticsScreen()),
          ),
          GoRoute(
            path: '/garage/consumables',
            pageBuilder: (context, state) =>
                const MaterialPage<void>(child: LegacyConsumablesScreen()),
          ),
          GoRoute(
            path: '/garage/add',
            pageBuilder: (context, state) =>
                const MaterialPage<void>(child: AddVehicleStartScreen()),
          ),
          GoRoute(
            path: '/garage/add/vin',
            pageBuilder: (context, state) =>
                const MaterialPage<void>(child: VinEntryScreen()),
          ),
          GoRoute(
            path: '/garage/add/confirm',
            pageBuilder: (context, state) =>
                const MaterialPage<void>(child: VehicleConfirmScreen()),
          ),
          GoRoute(
            path: '/plan/first',
            pageBuilder: (context, state) =>
                const MaterialPage<void>(child: FirstPlanScreen()),
          ),
          GoRoute(
            path: '/history/wizard',
            pageBuilder: (context, state) => MaterialPage<void>(
              child: HistoryWizardScreen(
                workCode: state.uri.queryParameters['workCode'],
              ),
            ),
          ),
          GoRoute(
            path: '/history/wizard/:workCode',
            pageBuilder: (context, state) => MaterialPage<void>(
              child: HistoryWizardScreen(
                workCode: state.pathParameters['workCode'],
              ),
            ),
          ),
          GoRoute(
            path: '/service/add',
            pageBuilder: (context, state) => MaterialPage<void>(
              child: ServiceRecordScreen(
                workCode: state.uri.queryParameters['workCode'],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

StatefulShellBranch _branch(String path, Widget child) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        pageBuilder: (context, state) => NoTransitionPage<void>(child: child),
      ),
    ],
  );
}

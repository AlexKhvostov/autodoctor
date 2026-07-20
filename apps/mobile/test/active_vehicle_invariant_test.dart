import 'dart:async';

import 'package:autodoctor/app/locale_controller.dart';
import 'package:autodoctor/app/router.dart';
import 'package:autodoctor/features/maintenance/maintenance.dart';
import 'package:autodoctor/features/maintenance/maintenance_controller.dart';
import 'package:autodoctor/features/vehicle/vehicle.dart';
import 'package:autodoctor/features/vehicle/vehicle_controller.dart';
import 'package:autodoctor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('active header notifications never use no-car copy', (
    tester,
  ) async {
    final router = await _pumpActiveApp(tester);

    expect(find.byKey(const Key('header-active-vehicle')), findsOneWidget);
    await tester.tap(find.byKey(const Key('notifications-bell')));
    await tester.pumpAndSettle();

    expect(find.text('Уведомления · Volkswagen Golf'), findsOneWidget);
    expect(find.text('Новых уведомлений нет'), findsOneWidget);
    _expectNoNoCarOrDemo();
    router.dispose();
  });

  testWidgets('active AI and topics show honest unavailable state', (
    tester,
  ) async {
    final router = await _pumpActiveApp(tester);
    router.go('/assistant');
    await tester.pumpAndSettle();

    expect(find.text('Выбранный автомобиль · Volkswagen Golf'), findsOneWidget);
    expect(find.text('AI-ассистент пока не подключён'), findsOneWidget);
    expect(find.text('Будет доступно после подключения AI'), findsNWidgets(2));
    expect(find.textContaining('Что проверить сначала'), findsNothing);
    _expectNoNoCarOrDemo();

    await tester.tap(find.text('Темы'));
    await tester.pumpAndSettle();
    expect(find.text('Темы'), findsWidgets);
    expect(
      find.text('Темы станут доступны после подключения AI-ассистента.'),
      findsOneWidget,
    );
    expect(find.text('Темы · пример'), findsNothing);
    _expectNoNoCarOrDemo();
    router.dispose();
  });

  testWidgets('active journal renders only confirmed service records', (
    tester,
  ) async {
    final router = await _pumpActiveApp(tester);
    router.go('/journal');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('journal-service-service-1')), findsOneWidget);
    expect(find.text('Замена моторного масла'), findsOneWidget);
    expect(find.text('18.07.2026 · 12000 km'), findsOneWidget);
    expect(find.textContaining('Заправка'), findsNothing);
    expect(find.textContaining('это не история'), findsNothing);
    _expectNoNoCarOrDemo();
    expect(find.byKey(const Key('journal-quick-add')), findsOneWidget);
    router.dispose();
  });

  testWidgets('active analytics reminders and consumables stay factual', (
    tester,
  ) async {
    final router = await _pumpActiveApp(tester);
    router.go('/analytics');
    await tester.pumpAndSettle();

    expect(find.text('Аналитика · Volkswagen Golf'), findsOneWidget);
    expect(
      find.text('Подготавливаем аналитику по подтверждённым записям…'),
      findsOneWidget,
    );
    _expectNoNoCarOrDemo();

    router.go('/more');
    await tester.pumpAndSettle();
    final reminders = find.byKey(const Key('vehicle-reminders'));
    expect(
      find.descendant(of: reminders, matching: find.text('Скоро')),
      findsOneWidget,
    );
    _expectNoNoCarOrDemo();

    router.go('/garage/consumables');
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/garage/consumables',
    );
    expect(find.byKey(const Key('real-timeline')), findsOneWidget);
    _expectNoNoCarOrDemo();
    router.dispose();
  });

  testWidgets('loading race never exposes preview under active header', (
    tester,
  ) async {
    final pending = Completer<ServiceRecordList>();
    final router = await _pumpActiveApp(
      tester,
      repository: _MaintenanceRepository(serviceRecords: pending.future),
      settle: false,
    );
    router.go('/journal');
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('header-active-vehicle')), findsOneWidget);
    expect(find.text('Загружаем записи обслуживания…'), findsOneWidget);
    _expectNoNoCarOrDemo();

    pending.complete(const ServiceRecordList(items: []));
    await tester.pumpAndSettle();
    expect(find.text('Записей обслуживания пока нет'), findsOneWidget);
    _expectNoNoCarOrDemo();
    router.dispose();
  });

  testWidgets('active invariant has no overflow at 360x640', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = await _pumpActiveApp(tester);

    for (final path in [
      '/journal',
      '/assistant',
      '/state',
      '/analytics',
      '/more',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: path);
      _expectNoNoCarOrDemo();
    }
    router.dispose();
  });
}

void _expectNoNoCarOrDemo() {
  for (final text in [
    'Сначала добавьте автомобиль',
    'нет выбранного автомобиля',
    'после добавления автомобиля',
    'Пример',
    'Модуль кокпита · деморежим',
  ]) {
    expect(find.textContaining(text), findsNothing, reason: text);
  }
}

Future<GoRouter> _pumpActiveApp(
  WidgetTester tester, {
  MaintenanceRepository? repository,
  bool settle = true,
}) async {
  final router = buildRouter();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeLocaleProvider.overrideWithValue(const Locale('ru')),
        vehicleSetupControllerProvider.overrideWith(_SeedVehicleController.new),
        maintenanceRepositoryProvider.overrideWithValue(
          repository ?? _MaintenanceRepository(),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
  return router;
}

class _SeedVehicleController extends VehicleSetupController {
  @override
  VehicleSetupState build() => const VehicleSetupState(
    vehicles: [_vehicle],
    activeVehicleId: 'vehicle-1',
    stage: VehicleLoadStage.ready,
  );

  @override
  Future<void> load({bool force = false}) async {}
}

class _MaintenanceRepository implements MaintenanceRepository {
  _MaintenanceRepository({Future<ServiceRecordList>? serviceRecords})
    : _serviceRecords = serviceRecords ?? Future.value(_records);

  final Future<ServiceRecordList> _serviceRecords;

  @override
  Future<MileageForecast> getMileageForecast(
    String vehicleId, {
    required String locale,
  }) async => MileageForecast(
    vehicleId: vehicleId,
    annualDistance: 10000,
    annualDistanceUnit: 'km',
    method: 'default_assumption',
    confidence: 'low',
    observationCount: 0,
    estimateLabel: 'Estimate',
  );

  @override
  Future<ConditionObservationList> getConditionObservations(
    String vehicleId, {
    required String locale,
  }) async => const ConditionObservationList(items: []);

  @override
  Future<ConditionObservation> createConditionObservation(
    String vehicleId, {
    required String locale,
    required ConditionObservationWrite observation,
  }) => throw UnimplementedError();

  @override
  Future<ServiceRecord> createServiceRecord(
    String vehicleId, {
    required String locale,
    required ServiceRecordWrite record,
  }) async => _records.items.single;

  @override
  Future<ServiceRecord> updateServiceRecord(
    String vehicleId,
    String recordId, {
    required String locale,
    required ServiceRecordWrite record,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteServiceRecord(
    String vehicleId,
    String recordId, {
    required String locale,
  }) => throw UnimplementedError();

  @override
  Future<ConditionObservation> updateConditionObservation(
    String vehicleId,
    String observationId, {
    required String locale,
    required ConditionObservationWrite observation,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteConditionObservation(
    String vehicleId,
    String observationId, {
    required String locale,
  }) => throw UnimplementedError();

  @override
  Future<ConsumableList> getConsumables(
    String vehicleId, {
    required String locale,
  }) async => const ConsumableList(items: [], warnings: []);

  @override
  Future<MaintenancePlan> getPlan(
    String vehicleId, {
    required String locale,
  }) async => MaintenancePlan(
    id: 'plan-1',
    vehicleId: vehicleId,
    rulesetVersion: 'test',
    items: const [],
    warnings: const [],
  );

  @override
  Future<ServiceRecordList> getServiceRecords(
    String vehicleId, {
    required String locale,
  }) => _serviceRecords;

  @override
  Future<VehicleTimeline> getTimeline(
    String vehicleId, {
    required String locale,
  }) async => VehicleTimeline(
    vehicleId: vehicleId,
    serviceRecords: _records.items,
    items: const [],
  );

  @override
  Future<void> submitHistoryAnswers(
    String vehicleId, {
    required String locale,
    required List<HistoryAnswerWrite> answers,
  }) async {}
}

const _vehicle = Vehicle(
  id: 'vehicle-1',
  make: 'Volkswagen',
  model: 'Golf',
  productionYear: 2020,
  fuelType: 'petrol',
);

final _records = ServiceRecordList(
  items: [
    ServiceRecord(
      id: 'service-1',
      vehicleId: 'vehicle-1',
      serviceDate: DateTime(2026, 7, 18),
      mileage: 12000,
      mileageUnit: 'km',
      title: 'Замена моторного масла',
      items: const [
        ServiceWork(workCode: 'engine_oil', title: 'Моторное масло'),
      ],
    ),
  ],
);

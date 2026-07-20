import 'dart:async';

import 'package:autodoctor/app/locale_controller.dart';
import 'package:autodoctor/features/maintenance/maintenance.dart';
import 'package:autodoctor/features/maintenance/maintenance_controller.dart';
import 'package:autodoctor/features/maintenance/presentation/history_wizard_screen.dart';
import 'package:autodoctor/features/maintenance/presentation/maintenance_screens.dart';
import 'package:autodoctor/features/maintenance/presentation/service_record_screen.dart';
import 'package:autodoctor/features/maintenance/presentation/state_screen.dart';
import 'package:autodoctor/features/browse/presentation/browse_shell.dart';
import 'package:autodoctor/features/vehicle/vehicle.dart';
import 'package:autodoctor/features/vehicle/vehicle_controller.dart';
import 'package:autodoctor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('first plan shows loading then real success', (tester) async {
    final completer = Completer<MaintenancePlan>();
    final repository = FakeMaintenanceRepository(
      planHandler: (_, _) => completer.future,
    );
    await _pumpFirstPlan(tester, repository);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('first-plan-continue')), findsNothing);

    completer.complete(_plan('vehicle-ice', 13));
    await tester.pumpAndSettle();
    expect(find.text('Пунктов обслуживания: 13'), findsOneWidget);
    expect(find.text('AutoDoctor Pilot Baseline v2'), findsOneWidget);
    expect(find.byKey(const Key('first-plan-continue')), findsOneWidget);
  });

  testWidgets('first plan understands PLAN_PREPARING and retries', (
    tester,
  ) async {
    var calls = 0;
    final repository = FakeMaintenanceRepository(
      planHandler: (vehicleId, locale) async {
        calls++;
        if (calls == 1) {
          throw const MaintenanceFailure(
            code: 'PLAN_PREPARING',
            statusCode: 409,
            requestId: 'req-preparing',
          );
        }
        return _plan(vehicleId, 13);
      },
    );
    await _pumpFirstPlan(tester, repository);
    await tester.pumpAndSettle();

    expect(find.textContaining('ещё формируется'), findsOneWidget);
    expect(find.text('ID запроса: req-preparing'), findsOneWidget);
    await tester.tap(find.byKey(const Key('maintenance-retry')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byKey(const Key('first-plan-continue')), findsOneWidget);
  });

  testWidgets('first plan generic error exposes request id and retry', (
    tester,
  ) async {
    final repository = FakeMaintenanceRepository(
      planHandler: (_, _) async => throw const MaintenanceFailure(
        code: 'UNAVAILABLE',
        requestId: 'req-failed',
        safeMessage: 'Безопасное сообщение',
      ),
    );
    await _pumpFirstPlan(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Безопасное сообщение'), findsOneWidget);
    expect(find.text('ID запроса: req-failed'), findsOneWidget);
    expect(find.byKey(const Key('maintenance-retry')), findsOneWidget);
  });

  for (final testCase in const [
    (Locale('ru'), 'История обслуживания не указана'),
    (Locale('en'), 'Service history is missing'),
  ]) {
    testWidgets('${testCase.$1.languageCode} localizes plan warnings', (
      tester,
    ) async {
      await _pumpFirstPlan(
        tester,
        FakeMaintenanceRepository(),
        locale: testCase.$1,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining(testCase.$2), findsOneWidget);
    });
  }

  testWidgets('no-car roadmap keeps grey Example preview', (tester) async {
    await _pumpRoadmap(tester, FakeMaintenanceRepository(), vehicles: const []);
    await tester.pumpAndSettle();
    expect(find.text('Пример'), findsWidgets);
    expect(find.byKey(const Key('real-timeline')), findsNothing);
  });

  testWidgets('real roadmap removes Example semantics', (tester) async {
    await _pumpRoadmap(tester, FakeMaintenanceRepository());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('real-timeline')), findsOneWidget);
    expect(find.text('Пример'), findsNothing);
  });

  testWidgets('default 10000 forecast is clearly an estimate', (tester) async {
    await _pumpRoadmap(tester, FakeMaintenanceRepository());
    await tester.pumpAndSettle();
    expect(find.text('Предварительная оценка: 10000 km/год'), findsOneWidget);
    expect(find.textContaining('Статус: просрочено'), findsNothing);
  });

  test('forecast failure does not block core roadmap', () async {
    final repository = FakeMaintenanceRepository(
      forecastHandler: (_, _) async =>
          throw const MaintenanceFailure(code: 'FORECAST_UNAVAILABLE'),
    );
    final container = ProviderContainer(
      overrides: [maintenanceRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container
        .read(maintenanceControllerProvider.notifier)
        .ensureRoadmap('vehicle-ice', locale: 'ru');
    final state = container.read(maintenanceControllerProvider);
    expect(state.roadmapStage, MaintenanceLoadStage.ready);
    expect(state.plan, isNotNull);
    expect(state.mileageForecast, isNull);
    expect(state.forecastFailure?.code, 'FORECAST_UNAVAILABLE');
  });

  for (final testCase in const [('PETROL', 13), ('DIESEL', 12), ('EV', 7)]) {
    testWidgets('${testCase.$1} shows ${testCase.$2} real plan items', (
      tester,
    ) async {
      final repository = FakeMaintenanceRepository(itemCount: testCase.$2);
      await _pumpFirstPlan(tester, repository);
      await tester.pumpAndSettle();
      expect(find.text('Пунктов обслуживания: ${testCase.$2}'), findsOneWidget);
      expect(find.byKey(const Key('first-plan-continue')), findsOneWidget);
    });
  }

  testWidgets('condition consumable without measurement omits percentage', (
    tester,
  ) async {
    await _pumpState(tester, FakeMaintenanceRepository());
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('consumable-brake-system-inspection')),
    );
    await tester.tap(
      find.byKey(const Key('consumable-brake-system-inspection')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('state-detail-brake-system-inspection')), findsOneWidget);
    expect(find.text('Требуется осмотр'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const Key('state-detail-brake-system-inspection')),
        matching: find.textContaining('%'),
      ),
      findsNothing,
    );
  });

  testWidgets('state detail sheet opens one card at a time', (
    tester,
  ) async {
    await _pumpState(tester, FakeMaintenanceRepository());
    await tester.pumpAndSettle();
    await _revealStateTile(tester, 'consumable-engine-oil');
    await tester.tap(find.byKey(const Key('consumable-engine-oil')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('state-detail-engine-oil')), findsOneWidget);
    await tester.tap(find.byKey(const Key('state-detail-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('state-detail-engine-oil')), findsNothing);

    await _revealStateTile(tester, 'consumable-oil-filter');
    await tester.tap(find.byKey(const Key('consumable-oil-filter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('state-detail-oil-filter')), findsOneWidget);
    expect(find.byKey(const Key('state-detail-engine-oil')), findsNothing);
  });

  testWidgets('new wear-capable record defaults wear to 0 percent', (
    tester,
  ) async {
    await _pumpState(tester, FakeMaintenanceRepository());
    await tester.pumpAndSettle();
    await _revealStateTile(tester, 'consumable-brake-pads');
    await tester.tap(find.byKey(const Key('consumable-brake-pads')));
    await tester.pumpAndSettle();
    await _scrollUntilFound(
      tester,
      find.byKey(const Key('state-update-wear-brake_pads')),
      find.byKey(const Key('state-detail-brake-pads')),
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('state-update-wear-brake_pads')),
          )
          .controller!
          .text,
      '0',
    );
  });

  testWidgets('state tiles show compact horizontal resource bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpState(tester, FakeMaintenanceRepository());
    await tester.pumpAndSettle();
    await _revealStateTile(tester, 'consumable-engine-oil');
    expect(find.byKey(const Key('state-tile-engine-oil')), findsOneWidget);
    expect(find.byKey(const Key('state-bar-engine-oil')), findsOneWidget);
    await tester.tap(find.byKey(const Key('consumable-engine-oil')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('state-detail-engine-oil')), findsOneWidget);
    expect(
      find.byKey(const Key('lifecycle-track-detail-engine-oil')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('known unknown and condition lifecycles stay factual', (
    tester,
  ) async {
    await _pumpState(tester, FakeMaintenanceRepository());
    await tester.pumpAndSettle();
    await _revealStateTile(tester, 'consumable-engine-oil');
    await tester.tap(find.byKey(const Key('consumable-engine-oil')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('lifecycle-track-detail-engine-oil')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('state-detail-close')));
    await tester.pumpAndSettle();

    await _revealStateTile(tester, 'consumable-oil-filter');
    await tester.tap(find.byKey(const Key('consumable-oil-filter')));
    await tester.pumpAndSettle();
    expect(find.text('Нужны данные'), findsWidgets);
    expect(
      find.byKey(const Key('lifecycle-track-detail-oil-filter')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('state-detail-close')));
    await tester.pumpAndSettle();

    await _revealStateTile(tester, 'consumable-brake-system-inspection');
    await tester.tap(
      find.byKey(const Key('consumable-brake-system-inspection')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('state-detail-brake-system-inspection')),
        matching: find.textContaining('%'),
      ),
      findsNothing,
    );
  });

  testWidgets('timeline shows only action and basis indicators', (
    tester,
  ) async {
    await _pumpRoadmap(tester, FakeMaintenanceRepository());
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('indicator-action-recommendation')),
      findsWidgets,
    );
    expect(find.byKey(const Key('indicator-basis-confirmed')), findsWidgets);
    expect(find.byKey(const Key('indicator-status-unknown')), findsNothing);
    expect(
      find.byKey(const Key('indicator-importance-recommended')),
      findsNothing,
    );
    expect(find.byKey(const Key('hide-engine_oil')), findsNothing);
    expect(find.text('Скрыть'), findsNothing);
    expect(find.text('Показать'), findsNothing);
    await tester.tap(find.byKey(const Key('plan-legend')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plan-legend-content')), findsOneWidget);
    expect(find.byKey(const Key('legend-action-info')), findsOneWidget);
    expect(find.byKey(const Key('legend-action-critical')), findsOneWidget);
    expect(find.byKey(const Key('legend-basis-confirmed')), findsOneWidget);
    expect(find.byKey(const Key('legend-basis-missingData')), findsOneWidget);
    expect(find.text('Источник'), findsNothing);
    expect(find.text('История'), findsNothing);
    expect(find.text('Категория'), findsNothing);
  });

  testWidgets('plan home keeps banner nearest card and mileage marker', (
    tester,
  ) async {
    await _pumpRoadmap(tester, FakeMaintenanceRepository());
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('history-completeness-banner')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('plan-road')), findsOneWidget);
    expect(find.byKey(const Key('real-timeline')), findsOneWidget);
    expect(find.byKey(const Key('current-mileage-marker')), findsOneWidget);
    await _scrollUntilFound(
      tester,
      find.byKey(const Key('plan-open-analytics')),
      find.byKey(const Key('real-timeline')),
    );
    expect(find.byKey(const Key('plan-open-analytics')), findsOneWidget);
    expect(find.byKey(const Key('consumables-rail')), findsNothing);
  });

  testWidgets('service form defaults and reloads all roadmap resources', (
    tester,
  ) async {
    final repository = FakeMaintenanceRepository();
    await _pumpState(tester, repository);
    await tester.pumpAndSettle();
    await _revealStateTile(tester, 'consumable-engine-oil');
    await tester.tap(find.byKey(const Key('consumable-engine-oil')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('state-update-mileage')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('state-update-mileage')))
          .controller!
          .text,
      '10000',
    );
    await _scrollUntilFound(
      tester,
      find.byKey(const Key('state-history-list')),
      find.byKey(const Key('state-detail-engine-oil')),
    );
    expect(find.byKey(const Key('state-history-row-0')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('state-update-note')),
      'Замена',
    );
    await tester.tap(find.byKey(const Key('state-update-save-engine_oil')));
    await tester.pumpAndSettle();
    expect(repository.submittedServiceRecords.single.workCode, 'engine_oil');
    expect(repository.submittedServiceRecords.single.mileage, 10000);
    expect(repository.planCalls, greaterThan(1));
    expect(repository.timelineCalls, greaterThan(1));
    expect(repository.consumableCalls, greaterThan(1));
    expect(repository.serviceListCalls, greaterThan(1));
  });

  testWidgets('mileage sheet rejects decrease and is keyboard safe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vehicleRepository = FakeMileageVehicleRepository();
    final maintenanceRepository = FakeMaintenanceRepository();
    await _pumpRoadmap(
      tester,
      maintenanceRepository,
      vehicleRepository: vehicleRepository,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('current-mileage-marker')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('mileage-update-input')),
      '9999',
    );
    await tester.showKeyboard(find.byKey(const Key('mileage-update-input')));
    await tester.tap(find.byKey(const Key('mileage-update-save')));
    await tester.pump();
    expect(
      find.text('Пробег не может быть меньше текущего значения.'),
      findsOneWidget,
    );
    expect(vehicleRepository.updateCalls, 0);
    await tester.enterText(
      find.byKey(const Key('mileage-update-input')),
      '12000',
    );
    await tester.tap(find.byKey(const Key('mileage-update-save')));
    await tester.pumpAndSettle();
    expect(vehicleRepository.updateCalls, 1);
    expect(vehicleRepository.lastValue, 12000);
    expect(vehicleRepository.lastVersion, 3);
    expect(vehicleRepository.lastUnit, 'km');
    expect(maintenanceRepository.timelineCalls, greaterThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('roadmap error retries successfully', (tester) async {
    var timelineCalls = 0;
    final repository = FakeMaintenanceRepository(
      timelineHandler: (vehicleId, locale) async {
        timelineCalls++;
        if (timelineCalls == 1) {
          throw const MaintenanceFailure(requestId: 'req-roadmap');
        }
        return _timeline(vehicleId, 6);
      },
    );
    await _pumpRoadmap(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text('ID запроса: req-roadmap'), findsOneWidget);

    await tester.tap(find.byKey(const Key('maintenance-retry')));
    await tester.pumpAndSettle();
    expect(timelineCalls, 2);
    expect(find.byKey(const Key('real-timeline')), findsOneWidget);
  });

  testWidgets('active vehicle switch clears stale roadmap immediately', (
    tester,
  ) async {
    final secondTimeline = Completer<VehicleTimeline>();
    final repository = FakeMaintenanceRepository(
      timelineHandler: (vehicleId, locale) {
        if (vehicleId == 'vehicle-ev') return secondTimeline.future;
        return Future.value(_timeline(vehicleId, 6, prefix: 'Первый'));
      },
    );
    await _pumpRoadmap(
      tester,
      repository,
      vehicles: const [iceVehicle, evVehicle],
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Первый'), findsWidgets);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(RoadmapScreen)),
    );
    container
        .read(vehicleSetupControllerProvider.notifier)
        .selectVehicle('vehicle-ev');
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('roadmap-loading')), findsOneWidget);
    expect(find.textContaining('Первый'), findsNothing);

    secondTimeline.complete(_timeline('vehicle-ev', 4, prefix: 'Второй'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Второй'), findsWidgets);
    expect(find.textContaining('Первый'), findsNothing);
  });

  test('controller reloads the same vehicle when locale changes', () async {
    final repository = FakeMaintenanceRepository();
    final container = ProviderContainer(
      overrides: [maintenanceRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(maintenanceControllerProvider.notifier);

    await controller.ensureRoadmap('vehicle-ice', locale: 'ru');
    await controller.ensureRoadmap('vehicle-ice', locale: 'en');

    final state = container.read(maintenanceControllerProvider);
    expect(state.locale, 'en');
    expect(state.plan!.items.first.title, 'Engine oil');
    expect(repository.requestedLocales, containsAll(['ru', 'en']));
  });

  testWidgets('360x640 long Russian state detail has no overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpState(tester, FakeMaintenanceRepository(longTitles: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _revealStateTile(tester, 'consumable-engine-oil');
    await tester.tap(find.byKey(const Key('consumable-engine-oil')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('state-detail-engine-oil')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first plan exposes history primary and skip secondary CTAs', (
    tester,
  ) async {
    await _pumpFirstPlan(tester, FakeMaintenanceRepository());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-plan-history')), findsOneWidget);
    expect(find.text('Уточнить историю обслуживания'), findsOneWidget);
    expect(find.byKey(const Key('first-plan-continue')), findsOneWidget);
    expect(find.text('Пропустить и открыть план'), findsOneWidget);
  });

  testWidgets('wizard skips item and preserves progress', (tester) async {
    await _pump(
      tester,
      const HistoryWizardScreen(),
      FakeMaintenanceRepository(itemCount: 2),
      locale: const Locale('ru'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Пункт 1 из 2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-skip-item')));
    await tester.pump();
    expect(find.text('Пункт 2 из 2'), findsOneWidget);
  });

  testWidgets('known answer validates and submits mileage payload', (
    tester,
  ) async {
    final repository = FakeMaintenanceRepository(itemCount: 1);
    await _pump(
      tester,
      const HistoryWizardScreen(),
      repository,
      locale: const Locale('ru'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-fields-first')), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-save')));
    await tester.pump();
    expect(find.text('Укажите дату или корректный пробег.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('history-mileage')), '5000');
    await tester.tap(find.byKey(const Key('history-save')));
    await tester.pumpAndSettle();
    expect(repository.submittedAnswers, hasLength(1));
    expect(
      repository.submittedAnswers.single.toJson(),
      containsPair('performed_mileage_km', 5000),
    );
  });

  testWidgets('single item prefills current answer and submits only it', (
    tester,
  ) async {
    final repository = FakeMaintenanceRepository(
      itemCount: 2,
      planHandler: (vehicleId, locale) async {
        final plan = _plan(vehicleId, 2, locale: locale);
        final first = plan.items.first;
        return MaintenancePlan(
          id: plan.id,
          vehicleId: plan.vehicleId,
          rulesetVersion: plan.rulesetVersion,
          items: [
            MaintenanceItem(
              id: first.id,
              workCode: first.workCode,
              title: first.title,
              status: first.status,
              importance: first.importance,
              basis: first.basis,
              source: first.source,
              due: first.due,
              interval: first.interval,
              historyState: const HistoryState(
                answer: HistoryAnswerValue.doneUnknown,
              ),
            ),
            plan.items.last,
          ],
          warnings: plan.warnings,
        );
      },
    );
    await _pump(
      tester,
      const HistoryWizardScreen(workCode: 'engine_oil'),
      repository,
      locale: const Locale('ru'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-fields-first')), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-answer-not_done')));
    await tester.pumpAndSettle();
    expect(repository.submittedAnswers, hasLength(1));
    expect(repository.submittedAnswers.single.workCode, 'engine_oil');
    expect(
      repository.submittedAnswers.single.answer,
      HistoryAnswerValue.notDone,
    );
  });

  testWidgets('API error retains wizard input and retry succeeds', (
    tester,
  ) async {
    var attempts = 0;
    final repository = FakeMaintenanceRepository(
      itemCount: 1,
      submitHandler: (_, _, _) async {
        attempts++;
        if (attempts == 1) {
          throw const MaintenanceFailure(
            requestId: 'req-history',
            safeMessage: 'Не удалось сохранить',
          );
        }
      },
    );
    await _pump(
      tester,
      const HistoryWizardScreen(),
      repository,
      locale: const Locale('ru'),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('history-mileage')), '4321');
    await tester.tap(find.byKey(const Key('history-save')));
    await tester.pumpAndSettle();

    expect(find.text('ID запроса: req-history'), findsOneWidget);
    expect(find.text('4321'), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-save')));
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });

  for (final localized in const [
    (Locale('ru'), 'Что уже выполнялось?', 'Никогда'),
    (Locale('en'), 'What has already been done?', 'Never'),
  ]) {
    testWidgets('${localized.$1.languageCode} localizes history wizard', (
      tester,
    ) async {
      await _pump(
        tester,
        const HistoryWizardScreen(),
        FakeMaintenanceRepository(itemCount: 1),
        locale: localized.$1,
      );
      await tester.pumpAndSettle();
      expect(find.text(localized.$2), findsOneWidget);
      expect(find.text(localized.$3), findsOneWidget);
      expect(find.byKey(const Key('history-fields-first')), findsOneWidget);
    });
  }

  testWidgets('360x640 wizard remains safe with keyboard', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(
      tester,
      const HistoryWizardScreen(),
      FakeMaintenanceRepository(itemCount: 1, longTitles: true),
      locale: const Locale('ru'),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('history-mileage')));
    await tester.showKeyboard(find.byKey(const Key('history-mileage')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('active vehicle quick add enables service without no-car lie', (
    tester,
  ) async {
    await _pump(
      tester,
      GlobalHeaderFrame(
        child: Builder(
          builder: (context) => Center(
            child: FilledButton(
              key: const Key('open-quick-add'),
              onPressed: () => showQuickAddPreview(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      FakeMaintenanceRepository(),
      locale: const Locale('ru'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('header-active-vehicle')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-quick-add')));
    await tester.pumpAndSettle();
    final service = find.descendant(
      of: find.byKey(const Key('quick-add-service')),
      matching: find.byType(ListTile),
    );
    expect(tester.widget<ListTile>(service).enabled, isTrue);
    expect(find.textContaining('требуется автомобиль'), findsNothing);
    expect(find.text('Сначала добавьте автомобиль'), findsNothing);
    expect(find.text('Скоро'), findsNWidgets(3));
    await tester.tap(service);
    await tester.pumpAndSettle();
    expect(find.byType(ServiceRecordScreen), findsOneWidget);
    expect(find.byKey(const Key('service-work-selector')), findsOneWidget);
  });

  for (final fraction in const [0.0, 0.25, 1.0]) {
    testWidgets('lifecycle marker matches fill endpoint at $fraction', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LifecycleProgressBar(
                fraction: fraction,
                identifier: 'test',
              ),
            ),
          ),
        ),
      );
      final track = tester.getRect(
        find.byKey(const Key('lifecycle-track-test')),
      );
      final marker = tester.getRect(
        find.byKey(const Key('lifecycle-marker-test')),
      );
      expect(
        marker.center.dx,
        moreOrLessEquals(track.left + track.width * fraction, epsilon: 0.01),
      );
    });
  }

  test('effective lifecycle uses confirmed fraction then time fallback', () {
    Consumable item({double? effective, double? time}) => Consumable(
      id: 'oil',
      title: 'Oil',
      kind: ConsumableKind.intervalBased,
      status: MaintenanceStatus.current,
      importance: MaintenanceImportance.recommended,
      basis: '',
      source: source,
      due: const MaintenanceDue(),
      inspectionState: InspectionState.unknown,
      usedFraction: effective,
      timeFraction: time,
    );
    expect(effectiveLifecycleFraction(item(effective: 0.25, time: 0.9)), 0.25);
    expect(effectiveLifecycleFraction(item(time: 0.4)), 0.4);
    expect(effectiveLifecycleFraction(item()), isNull);
  });

  test('timeline action fallback maps every level with precedence', () {
    TimelineActionLevel derive({
      MaintenanceUrgency urgency = MaintenanceUrgency.none,
      MaintenanceStatus status = MaintenanceStatus.current,
      MaintenanceImportance importance = MaintenanceImportance.info,
      bool requiresCheckNow = false,
    }) => deriveTimelineActionLevel(
      urgency: urgency,
      status: status,
      importance: importance,
      requiresCheckNow: requiresCheckNow,
    );

    expect(derive(), TimelineActionLevel.info);
    expect(
      derive(importance: MaintenanceImportance.recommended),
      TimelineActionLevel.recommendation,
    );
    expect(
      derive(urgency: MaintenanceUrgency.medium),
      TimelineActionLevel.attention,
    );
    expect(
      derive(status: MaintenanceStatus.overdue),
      TimelineActionLevel.required,
    );
    expect(
      derive(urgency: MaintenanceUrgency.high),
      TimelineActionLevel.required,
    );
    expect(derive(requiresCheckNow: true), TimelineActionLevel.required);
    expect(
      derive(
        urgency: MaintenanceUrgency.immediate,
        status: MaintenanceStatus.overdue,
      ),
      TimelineActionLevel.critical,
    );
    expect(
      derive(
        urgency: MaintenanceUrgency.medium,
        importance: MaintenanceImportance.criticalAttention,
      ),
      TimelineActionLevel.critical,
    );
  });

  test('timeline parses explicit presentation and basis fallback', () {
    Map<String, Object?> wrapper({
      Map<String, Object?> presentation = const {},
      Map<String, Object?> planItem = const {},
    }) => {
      'type': 'plan_item',
      'presentation': {
        'status': 'unknown',
        'importance': 'recommended',
        ...presentation,
      },
      'plan_item': {
        'id': 'i',
        'work_code': 'oil',
        'title': 'Oil',
        'status': 'unknown',
        'presentation_importance': 'recommended',
        'source': <String, Object?>{},
        'due': <String, Object?>{},
        'interval': <String, Object?>{},
        ...planItem,
      },
    };

    for (final entry in const {
      'info': TimelineActionLevel.info,
      'recommendation': TimelineActionLevel.recommendation,
      'attention': TimelineActionLevel.attention,
      'required': TimelineActionLevel.required,
      'critical': TimelineActionLevel.critical,
    }.entries) {
      expect(
        TimelineItem.fromJson(
          wrapper(presentation: {'action_level': entry.key}),
        ).actionLevel,
        entry.value,
      );
    }
    expect(
      TimelineItem.fromJson(
        wrapper(
          presentation: {'action_level': 'recommendation', 'basis': 'forecast'},
          planItem: {'requires_check_now': true},
        ),
      ).basis,
      PresentationBasis.forecast,
    );
    expect(
      TimelineItem.fromJson(
        wrapper(
          planItem: {
            'history_state': {'answer': 'done_known'},
          },
        ),
      ).basis,
      PresentationBasis.confirmed,
    );
    expect(
      TimelineItem.fromJson(
        wrapper(planItem: {'requires_check_now': true}),
      ).basis,
      PresentationBasis.missingData,
    );
    expect(
      TimelineItem.fromJson(
        wrapper(
          presentation: {
            'latest_observation': {'wear_percent': 20},
          },
        ),
      ).basis,
      PresentationBasis.confirmed,
    );
    expect(
      TimelineItem.fromJson(
        wrapper(presentation: {'action_level': 'future_value', 'basis': 'x'}),
      ).actionLevel,
      TimelineActionLevel.unrecognized,
    );
  });

  testWidgets('both indicators open the same focused compact legend', (
    tester,
  ) async {
    await _pumpRoadmap(tester, FakeMaintenanceRepository());
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('indicator-action-recommendation')).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('legend-action-recommendation')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('legend-action-critical')), findsOneWidget);
    expect(find.byKey(const Key('legend-basis-forecast')), findsOneWidget);
    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('indicator-basis-confirmed')).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('legend-basis-confirmed')), findsOneWidget);
    expect(find.byKey(const Key('legend-action-info')), findsOneWidget);
  });

  test('v3 ordering keeps unresolved first without preference sorting', () {
    TimelineItem node(
      String code, {
      bool unresolved = false,
      MaintenanceCriticality criticality = MaintenanceCriticality.medium,
      MaintenanceStatus status = MaintenanceStatus.current,
    }) {
      final item = MaintenanceItem(
        id: code,
        workCode: code,
        title: code,
        status: status,
        importance: MaintenanceImportance.recommended,
        basis: '',
        source: source,
        due: const MaintenanceDue(),
        interval: const MaintenanceInterval(),
        requiresCheckNow: unresolved,
        criticality: criticality,
      );
      return TimelineItem(
        item: item,
        primaryCategory: 'maintenance_repair',
        status: status,
        importance: item.importance,
      );
    }

    final sorted = sortPlanV3Items([
      node('z-unresolved', unresolved: true),
      node('normal', status: MaintenanceStatus.overdue),
      node('safety', criticality: MaintenanceCriticality.safetyCritical),
      node('a-unresolved', unresolved: true),
    ]);
    expect(sorted.map((item) => item.item.workCode), [
      'a-unresolved',
      'z-unresolved',
      'safety',
      'normal',
    ]);
  });

  test('wear parsing and payload keep measured wear factual', () {
    final observation = ConditionObservation.fromJson({
      'id': 'o1',
      'vehicle_id': 'v1',
      'work_code': 'brake_pads',
      'wear_percent': 76,
      'remaining_percent': 24,
      'observed_at': '2026-07-20',
      'mileage': {'value': 84250, 'unit': 'km'},
      'source': 'workshop',
    });
    expect(observation.remainingPercent, 24);
    expect(
      ConditionObservationWrite(
        workCode: 'brake_pads',
        wearPercent: 76,
        observedAt: DateTime(2026, 7, 20),
        mileage: 84250,
        source: ConditionObservationSource.workshop,
      ).toJson(),
      isNot(contains('remaining_percent')),
    );
  });

  testWidgets('global service form requires exactly one selected work', (
    tester,
  ) async {
    await _pump(
      tester,
      const ServiceRecordScreen(),
      FakeMaintenanceRepository(),
      locale: const Locale('ru'),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('service-save')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('service-work-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Моторное масло').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('service-save')))
          .onPressed,
      isNotNull,
    );
  });

  test('all history answer values map to API enum', () {
    expect(
      HistoryAnswerValue.values
          .where((value) => value != HistoryAnswerValue.unrecognized)
          .map((value) => value.wireValue),
      ['done_known', 'done_unknown', 'not_done', 'unknown', 'not_applicable'],
    );
  });
}

Future<void> _pumpFirstPlan(
  WidgetTester tester,
  MaintenanceRepository repository, {
  Locale locale = const Locale('ru'),
}) => _pump(tester, const FirstPlanScreen(), repository, locale: locale);

Future<void> _pumpRoadmap(
  WidgetTester tester,
  MaintenanceRepository repository, {
  Locale locale = const Locale('ru'),
  List<Vehicle> vehicles = const [iceVehicle],
  VehicleRepository? vehicleRepository,
}) => _pump(
  tester,
  const RoadmapScreen(),
  repository,
  locale: locale,
  vehicles: vehicles,
  vehicleRepository: vehicleRepository,
);

Future<void> _pumpState(
  WidgetTester tester,
  MaintenanceRepository repository, {
  Locale locale = const Locale('ru'),
  List<Vehicle> vehicles = const [iceVehicle],
  VehicleRepository? vehicleRepository,
}) => _pump(
  tester,
  const StateScreen(),
  repository,
  locale: locale,
  vehicles: vehicles,
  vehicleRepository: vehicleRepository,
);

Future<void> _revealStateTile(WidgetTester tester, String key) async {
  await _scrollUntilFound(
    tester,
    find.byKey(Key(key)),
    find.byKey(const Key('state-tiles-grid')),
  );
}

/// Scrolls a lazy list until [target] is built and visible.
Future<void> _scrollUntilFound(
  WidgetTester tester,
  Finder target,
  Finder scrollableAncestor, {
  Offset drag = const Offset(0, -240),
  int maxDrags = 24,
}) async {
  Future<void> dragToward(Offset offset) async {
    for (var i = 0; i < maxDrags && target.evaluate().isEmpty; i++) {
      await tester.drag(scrollableAncestor, offset);
      await tester.pumpAndSettle();
    }
  }

  if (target.evaluate().isEmpty) {
    await dragToward(drag);
  }
  if (target.evaluate().isEmpty) {
    await dragToward(Offset(-drag.dx, -drag.dy));
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  MaintenanceRepository repository, {
  required Locale locale,
  List<Vehicle> vehicles = const [iceVehicle],
  VehicleRepository? vehicleRepository,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: screen),
      ),
      GoRoute(
        path: '/roadmap',
        builder: (_, _) => const Scaffold(body: RoadmapScreen()),
      ),
      GoRoute(
        path: '/state',
        builder: (_, _) => const Scaffold(body: StateScreen()),
      ),
      GoRoute(
        path: '/analytics',
        builder: (_, _) =>
            const Scaffold(body: SizedBox(key: Key('analytics-route-target'))),
      ),
      GoRoute(
        path: '/garage/add',
        builder: (_, _) => const Scaffold(body: SizedBox()),
      ),
      GoRoute(
        path: '/history/wizard',
        builder: (_, _) =>
            const Scaffold(body: SizedBox(key: Key('history-route-target'))),
      ),
      GoRoute(
        path: '/service/add',
        builder: (_, state) => Scaffold(
          body: ServiceRecordScreen(
            workCode: state.uri.queryParameters['workCode'] ?? '',
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeLocaleProvider.overrideWithValue(locale),
        vehicleSetupControllerProvider.overrideWith(
          () => SeedVehicleController(vehicles),
        ),
        maintenanceRepositoryProvider.overrideWithValue(repository),
        if (vehicleRepository != null)
          vehicleRepositoryProvider.overrideWithValue(vehicleRepository),
      ],
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
}

class SeedVehicleController extends VehicleSetupController {
  SeedVehicleController(this.seed);

  final List<Vehicle> seed;

  @override
  VehicleSetupState build() => VehicleSetupState(
    vehicles: seed,
    activeVehicleId: seed.firstOrNull?.id,
    stage: VehicleLoadStage.ready,
  );

  @override
  Future<void> load({bool force = false}) async {}
}

class FakeMaintenanceRepository implements MaintenanceRepository {
  FakeMaintenanceRepository({
    this.itemCount = 13,
    this.longTitles = false,
    this.planHandler,
    this.timelineHandler,
    this.submitHandler,
    this.forecastHandler,
  });

  final int itemCount;
  final bool longTitles;
  final Future<MaintenancePlan> Function(String, String)? planHandler;
  final Future<VehicleTimeline> Function(String, String)? timelineHandler;
  final Future<void> Function(String, String, List<HistoryAnswerWrite>)?
  submitHandler;
  final Future<MileageForecast> Function(String, String)? forecastHandler;
  final List<String> requestedLocales = [];
  final List<HistoryAnswerWrite> submittedAnswers = [];
  final List<ServiceRecordWrite> submittedServiceRecords = [];
  int planCalls = 0;
  int timelineCalls = 0;
  int consumableCalls = 0;
  int serviceListCalls = 0;
  final List<ConditionObservationWrite> submittedObservations = [];

  @override
  Future<MileageForecast> getMileageForecast(
    String vehicleId, {
    required String locale,
  }) =>
      forecastHandler?.call(vehicleId, locale) ??
      Future.value(
        MileageForecast(
          vehicleId: vehicleId,
          annualDistance: 10000,
          annualDistanceUnit: 'km',
          method: 'default_assumption',
          confidence: 'low',
          observationCount: 0,
          estimateLabel: 'Оценка',
        ),
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
  }) async {
    submittedObservations.add(observation);
    return ConditionObservation(
      id: 'observation-1',
      vehicleId: vehicleId,
      workCode: observation.workCode,
      wearPercent: observation.wearPercent,
      remainingPercent: 100 - observation.wearPercent,
      observedAt: observation.observedAt,
      mileage: observation.mileage,
      mileageUnit: observation.mileageUnit,
      source: observation.source,
      note: observation.note,
    );
  }

  @override
  Future<ServiceRecord> createServiceRecord(
    String vehicleId, {
    required String locale,
    required ServiceRecordWrite record,
  }) async {
    submittedServiceRecords.add(record);
    return ServiceRecord(
      id: 'service-${submittedServiceRecords.length}',
      vehicleId: vehicleId,
      serviceDate: record.serviceDate,
      mileage: record.mileage,
      mileageUnit: record.mileageUnit,
      note: record.note,
      items: [ServiceWork(workCode: record.workCode, title: record.workCode)],
    );
  }

  @override
  Future<ServiceRecord> updateServiceRecord(
    String vehicleId,
    String recordId, {
    required String locale,
    required ServiceRecordWrite record,
  }) async {
    final index = int.tryParse(recordId.replaceFirst('service-', '')) ?? 0;
    final target = index > 0 && index <= submittedServiceRecords.length
        ? index - 1
        : 0;
    if (submittedServiceRecords.isNotEmpty) {
      submittedServiceRecords[target] = record;
    } else {
      submittedServiceRecords.add(record);
    }
    return ServiceRecord(
      id: recordId,
      vehicleId: vehicleId,
      serviceDate: record.serviceDate,
      mileage: record.mileage,
      mileageUnit: record.mileageUnit,
      note: record.note,
      items: [ServiceWork(workCode: record.workCode, title: record.workCode)],
    );
  }

  @override
  Future<void> deleteServiceRecord(
    String vehicleId,
    String recordId, {
    required String locale,
  }) async {
    final index = int.tryParse(recordId.replaceFirst('service-', ''));
    if (index != null && index > 0 && index <= submittedServiceRecords.length) {
      submittedServiceRecords.removeAt(index - 1);
    } else if (submittedServiceRecords.isNotEmpty) {
      submittedServiceRecords.removeLast();
    }
  }

  @override
  Future<ConditionObservation> updateConditionObservation(
    String vehicleId,
    String observationId, {
    required String locale,
    required ConditionObservationWrite observation,
  }) async {
    submittedObservations
      ..clear()
      ..add(observation);
    return ConditionObservation(
      id: observationId,
      vehicleId: vehicleId,
      workCode: observation.workCode,
      wearPercent: observation.wearPercent,
      remainingPercent: 100 - observation.wearPercent,
      observedAt: observation.observedAt,
      mileage: observation.mileage,
      mileageUnit: observation.mileageUnit,
      source: observation.source,
      note: observation.note,
    );
  }

  @override
  Future<void> deleteConditionObservation(
    String vehicleId,
    String observationId, {
    required String locale,
  }) async {
    submittedObservations.clear();
  }

  @override
  Future<ServiceRecordList> getServiceRecords(
    String vehicleId, {
    required String locale,
  }) async {
    serviceListCalls++;
    return ServiceRecordList(
      items: [
        for (var index = 0; index < submittedServiceRecords.length; index++)
          ServiceRecord(
            id: 'service-${index + 1}',
            vehicleId: vehicleId,
            serviceDate: submittedServiceRecords[index].serviceDate,
            mileage: submittedServiceRecords[index].mileage,
            mileageUnit: submittedServiceRecords[index].mileageUnit,
            note: submittedServiceRecords[index].note,
            items: [
              ServiceWork(
                workCode: submittedServiceRecords[index].workCode,
                title: submittedServiceRecords[index].workCode,
              ),
            ],
          ),
      ],
    );
  }

  @override
  Future<void> submitHistoryAnswers(
    String vehicleId, {
    required String locale,
    required List<HistoryAnswerWrite> answers,
  }) async {
    requestedLocales.add(locale);
    await submitHandler?.call(vehicleId, locale, answers);
    submittedAnswers
      ..clear()
      ..addAll(answers);
  }

  @override
  Future<MaintenancePlan> getPlan(String vehicleId, {required String locale}) {
    planCalls++;
    requestedLocales.add(locale);
    return planHandler?.call(vehicleId, locale) ??
        Future.value(
          _plan(vehicleId, itemCount, locale: locale, longTitles: longTitles),
        );
  }

  @override
  Future<VehicleTimeline> getTimeline(
    String vehicleId, {
    required String locale,
  }) {
    timelineCalls++;
    requestedLocales.add(locale);
    return timelineHandler?.call(vehicleId, locale) ??
        Future.value(
          _timeline(
            vehicleId,
            itemCount,
            locale: locale,
            longTitles: longTitles,
          ),
        );
  }

  @override
  Future<ConsumableList> getConsumables(
    String vehicleId, {
    required String locale,
  }) async {
    consumableCalls++;
    requestedLocales.add(locale);
    return ConsumableList(
      items: _items(itemCount, locale: locale, longTitles: longTitles).map((
        item,
      ) {
        final condition = item.workCode.contains('inspection');
        return Consumable(
          id: item.workCode.replaceAll('_', '-'),
          title: item.title,
          workCode: item.workCode,
          kind: condition
              ? ConsumableKind.conditionBased
              : ConsumableKind.intervalBased,
          status: item.workCode == 'engine_oil'
              ? MaintenanceStatus.soon
              : condition
              ? MaintenanceStatus.overdue
              : MaintenanceStatus.unknown,
          importance: condition
              ? MaintenanceImportance.required
              : MaintenanceImportance.recommended,
          basis: item.basis,
          source: source,
          due: const MaintenanceDue(),
          inspectionState: condition
              ? InspectionState.checkRequired
              : InspectionState.unknown,
          usedFraction: !condition && item.workCode == 'engine_oil'
              ? 0.5
              : null,
          effectiveTrigger: item.workCode == 'engine_oil' ? 'mileage' : '',
          requiresCheckNow: condition,
          historyState: item.workCode == 'engine_oil'
              ? HistoryState(
                  answer: HistoryAnswerValue.doneKnown,
                  performedDate: DateTime(2025, 7, 20),
                  performedMileageKm: 5000,
                )
              : const HistoryState(),
        );
      }).toList(),
      warnings: const [
        'EDITORIAL_BASELINE_ONLY',
        'HISTORY_REQUIRED',
        'MILEAGE_NOT_PROVIDED',
      ],
    );
  }
}

class FakeMileageVehicleRepository implements VehicleRepository {
  int updateCalls = 0;
  int? lastValue;
  int? lastVersion;
  String? lastUnit;

  @override
  Future<Vehicle> create(VehicleDraft draft, {required String locale}) async =>
      iceVehicle;

  @override
  Future<List<Vehicle>> list({required String locale}) async => [iceVehicle];

  @override
  Future<MileageConfirmation> updateMileage(
    String vehicleId, {
    required int value,
    required String unit,
    required int version,
    required DateTime observedAt,
    required String locale,
  }) async {
    updateCalls++;
    lastValue = value;
    lastVersion = version;
    lastUnit = unit;
    return MileageConfirmation(
      vehicleId: vehicleId,
      vehicleVersion: version + 1,
      value: value,
      unit: unit,
    );
  }
}

MaintenancePlan _plan(
  String vehicleId,
  int count, {
  String locale = 'ru',
  bool longTitles = false,
}) => MaintenancePlan(
  id: 'plan-$vehicleId',
  vehicleId: vehicleId,
  rulesetVersion: 'by-pilot-baseline-2',
  algorithmVersion: 'maintenance-v2',
  configVersion: 'maintenance-history-v1',
  items: _items(count, locale: locale, longTitles: longTitles),
  warnings: const ['EDITORIAL_BASELINE_ONLY', 'HISTORY_REQUIRED'],
);

VehicleTimeline _timeline(
  String vehicleId,
  int count, {
  String locale = 'ru',
  bool longTitles = false,
  String? prefix,
}) => VehicleTimeline(
  vehicleId: vehicleId,
  currentMileage: 10000,
  currentMileageUnit: 'km',
  items: _items(count, locale: locale, longTitles: longTitles, prefix: prefix)
      .map((item) {
        final inspection = item.workCode.contains('inspection');
        final honest = !inspection;
        final enriched = MaintenanceItem(
          id: item.id,
          workCode: item.workCode,
          title: item.title,
          status: honest ? MaintenanceStatus.soon : item.status,
          importance: item.importance,
          basis: item.basis,
          source: item.source,
          due: honest
              ? MaintenanceDue(
                  mileage: 15000,
                  unit: 'km',
                  date: DateTime(2026, 10, 1),
                )
              : item.due,
          interval: item.interval,
          historyState: honest
              ? HistoryState(
                  answer: HistoryAnswerValue.doneKnown,
                  performedDate: DateTime(2025, 7, 20),
                  performedMileageKm: 5000,
                )
              : item.historyState,
          requiresCheckNow: inspection,
        );
        return TimelineItem(
          item: enriched,
          primaryCategory: inspection ? 'inspection' : 'maintenance_repair',
          status: honest ? MaintenanceStatus.soon : MaintenanceStatus.unknown,
          importance: MaintenanceImportance.recommended,
          actionLevel: inspection
              ? TimelineActionLevel.required
              : TimelineActionLevel.recommendation,
          basis: honest
              ? PresentationBasis.confirmed
              : PresentationBasis.missingData,
        );
      })
      .toList(),
);

List<MaintenanceItem> _items(
  int count, {
  String locale = 'ru',
  bool longTitles = false,
  String? prefix,
}) {
  final ru = locale == 'ru';
  final titles = [
    ru ? 'Моторное масло' : 'Engine oil',
    ru ? 'Масляный фильтр' : 'Oil filter',
    ru ? 'Салонный фильтр' : 'Cabin filter',
    ru ? 'Осмотр тормозов' : 'Brake inspection',
    ru ? 'Осмотр шин' : 'Tire inspection',
    ru ? 'Осмотр охлаждающей жидкости' : 'Coolant inspection',
    ru ? 'Воздушный фильтр' : 'Air filter',
    ru ? 'Тормозная жидкость' : 'Brake fluid',
    ru ? 'Охлаждающая жидкость' : 'Coolant',
    ru ? 'Свечи зажигания' : 'Spark plugs',
    ru ? 'Привод ГРМ' : 'Timing drive',
    ru ? 'Масло трансмиссии' : 'Transmission oil',
    ru ? 'Тормозные колодки' : 'Brake pads',
  ];
  final codes = [
    'engine_oil',
    'oil_filter',
    'cabin_filter',
    'brake_system_inspection',
    'tire_condition_inspection',
    'coolant_inspection',
    'air_filter',
    'brake_fluid',
    'coolant',
    'spark_plugs',
    'timing_drive',
    'transmission_oil',
    'brake_pads',
  ];
  return List.generate(count, (index) {
    var title = '${prefix == null ? '' : '$prefix '}${titles[index]}';
    if (longTitles) {
      title =
          '$title — очень длинное название для проверки безопасного переноса '
          'на узком экране';
    }
    return MaintenanceItem(
      id: 'item-$index',
      workCode: codes[index],
      title: title,
      status: MaintenanceStatus.unknown,
      importance: MaintenanceImportance.recommended,
      basis: longTitles
          ? 'Очень длинное локализованное основание: каждые 10 000 километров '
                'или 365 дней, что наступит раньше.'
          : ru
          ? 'Каждые 10 000 км или 365 дней.'
          : 'Every 10,000 km or 365 days.',
      source: source,
      due: const MaintenanceDue(),
      interval: codes[index].contains('inspection')
          ? const MaintenanceInterval()
          : codes[index] == 'air_filter'
          ? const MaintenanceInterval(days: 365)
          : const MaintenanceInterval(mileageKm: 10000, days: 365),
    );
  });
}

const source = MaintenanceSource(
  title: 'AutoDoctor Pilot Baseline v2',
  publisher: 'AutoDoctor Editorial',
  kind: MaintenanceSourceKind.editorialBaseline,
  methodologyNote: 'Editorial methodology',
  officialOem: false,
);

const iceVehicle = Vehicle(
  id: 'vehicle-ice',
  version: 3,
  make: 'Volkswagen',
  model: 'Golf',
  mileage: 10000,
  mileageUnit: 'km',
  productionYear: 2020,
  fuelType: 'petrol',
);

const evVehicle = Vehicle(
  id: 'vehicle-ev',
  make: 'BMW',
  model: 'i3',
  productionYear: 2021,
  fuelType: 'electric',
);

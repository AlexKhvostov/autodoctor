import 'dart:async';

import 'package:autodoctor/app/auto_doctor_app.dart';
import 'package:autodoctor/app/locale_controller.dart';
import 'package:autodoctor/app/router.dart';
import 'package:autodoctor/features/guest_bootstrap/guest_bootstrap.dart';
import 'package:autodoctor/features/guest_bootstrap/guest_bootstrap_controller.dart';
import 'package:autodoctor/features/maintenance/maintenance.dart';
import 'package:autodoctor/features/maintenance/maintenance_controller.dart';
import 'package:autodoctor/features/vehicle/vehicle.dart';
import 'package:autodoctor/features/vehicle/vehicle_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('consents success opens corrected vehicle form', (tester) async {
    final guestRepository = FakeGuestRepository();
    await _pumpApp(tester, guestRepository: guestRepository);
    await _openVehicleFormThroughConsents(tester);

    expect(_path(tester), '/garage/add/vin');
    expect(find.text('Данные автомобиля'), findsOneWidget);
    for (final key in const [
      'vehicle-make-select',
      'vehicle-year-select',
      'vehicle-fuel-select',
      'vehicle-transmission-select',
      'vehicle-mileage-input',
      'vin-input',
      'vehicle-continue',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    expect(guestRepository.saveCalls, 1);
  });

  testWidgets(
    'only make model year fuel and non-electric displacement are required',
    (tester) async {
      final repository = FakeVehicleRepository();
      await _pumpVehicleForm(tester, vehicleRepository: repository);

      expect(_continueButton(tester).onPressed, isNull);
      await _select(tester, 'vehicle-make-select', 'Volkswagen');
      expect(_continueButton(tester).onPressed, isNull);
      await _select(tester, 'vehicle-model-select', 'Golf');
      expect(_continueButton(tester).onPressed, isNull);
      await _select(tester, 'vehicle-year-select', '2020');
      expect(_continueButton(tester).onPressed, isNull);
      await _select(tester, 'vehicle-fuel-select', 'Бензин');
      expect(_continueButton(tester).onPressed, isNull);
      await tester.enterText(
        find.byKey(const Key('vehicle-engine-displacement-input')),
        '1600',
      );
      await tester.pump();
      expect(_continueButton(tester).onPressed, isNotNull);

      await _continueToConfirm(tester);
      expect(_path(tester), '/garage/add/confirm');
      expect(find.text('Не указано'), findsAtLeast(3));

      await _createVehicle(tester);
      expect(repository.createCalls, 1);
      expect(repository.lastDraft?.vin, isEmpty);
      expect(repository.lastDraft?.mileage, isNull);
      expect(repository.lastDraft?.transmissionType, isNull);
    },
  );

  testWidgets('six makes plus Other expose exact dependent models', (
    tester,
  ) async {
    await _pumpVehicleForm(tester);

    expect(_dropdownTextLabels(tester, 'vehicle-make-select'), const [
      'Volkswagen',
      'Peugeot',
      'Mitsubishi',
      'BMW',
      'Mercedes-Benz',
      'Mazda',
      'Другое',
    ]);

    const expectedModels = <String, List<String>>{
      'Volkswagen': [
        'Polo',
        'Golf',
        'Passat',
        'Tiguan',
        'Touareg',
        'Jetta',
        'Transporter',
      ],
      'Peugeot': [
        '206',
        '207',
        '208',
        '307',
        '308',
        '3008',
        '5008',
        '508',
        'Partner',
      ],
      'Mitsubishi': [
        'Colt',
        'Lancer',
        'Galant',
        'ASX',
        'Outlander',
        'Eclipse Cross',
        'Pajero',
        'Pajero Sport',
      ],
      'BMW': [
        '1 Series',
        '3 Series',
        '5 Series',
        '7 Series',
        'X1',
        'X3',
        'X5',
        'X6',
      ],
      'Mercedes-Benz': [
        'A-Class',
        'C-Class',
        'E-Class',
        'S-Class',
        'CLA',
        'GLA',
        'GLC',
        'GLE',
        'Vito',
        'Sprinter',
      ],
      'Mazda': [
        'Mazda2',
        'Mazda3',
        'Mazda6',
        'CX-3',
        'CX-5',
        'CX-7',
        'CX-9',
        'MX-5',
      ],
    };

    for (final entry in expectedModels.entries) {
      await _select(tester, 'vehicle-make-select', entry.key);
      expect(
        _dropdownTextLabels(tester, 'vehicle-model-select'),
        [...entry.value, 'Другая модель'],
        reason: 'Unexpected models for ${entry.key}',
      );
    }
  });

  testWidgets('switching make clears model and disables Continue', (
    tester,
  ) async {
    await _pumpVehicleForm(tester);
    await _fillRequiredProfile(tester);
    expect(_continueButton(tester).onPressed, isNotNull);

    await _select(tester, 'vehicle-make-select', 'Mazda');
    expect(_continueButton(tester).onPressed, isNull);
    expect(
      tester
          .state<FormFieldState<dynamic>>(
            find.byKey(const Key('vehicle-model-select')),
          )
          .value,
      isNull,
    );
  });

  testWidgets(
    'Other make requires manual make and manual model and normalizes',
    (tester) async {
      final repository = FakeVehicleRepository();
      await _pumpVehicleForm(tester, vehicleRepository: repository);

      await _select(tester, 'vehicle-make-select', 'Другое');
      expect(find.byKey(const Key('vehicle-make-other-input')), findsOneWidget);
      expect(find.byKey(const Key('vehicle-model-select')), findsNothing);
      expect(
        find.byKey(const Key('vehicle-model-other-input')),
        findsOneWidget,
      );
      expect(_continueButton(tester).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('vehicle-make-other-input')),
        '  Saab   Automobile  ',
      );
      await tester.enterText(
        find.byKey(const Key('vehicle-model-other-input')),
        '  9-3   Aero  ',
      );
      await _fillYearFuelAndDisplacement(tester);
      await _continueToConfirm(tester);
      await _createVehicle(tester);

      expect(repository.lastDraft?.make, 'Saab Automobile');
      expect(repository.lastDraft?.model, '9-3 Aero');
    },
  );

  testWidgets('Other model under known make shows only manual model input', (
    tester,
  ) async {
    final repository = FakeVehicleRepository();
    await _pumpVehicleForm(tester, vehicleRepository: repository);

    await _select(tester, 'vehicle-make-select', 'Volkswagen');
    await _select(tester, 'vehicle-model-select', 'Другая модель');
    expect(find.byKey(const Key('vehicle-make-other-input')), findsNothing);
    expect(find.byKey(const Key('vehicle-model-other-input')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('vehicle-model-other-input')),
      '  Golf   Variant  ',
    );
    await _fillYearFuelAndDisplacement(tester);
    await _continueToConfirm(tester);
    await _createVehicle(tester);

    expect(repository.lastDraft?.make, 'Volkswagen');
    expect(repository.lastDraft?.model, 'Golf Variant');
  });

  testWidgets('year dropdown is required and spans current year through 1980', (
    tester,
  ) async {
    await _pumpVehicleForm(tester);

    final years = _dropdownTextLabels(
      tester,
      'vehicle-year-select',
    ).map(int.parse).toList();
    expect(years.first, DateTime.now().year);
    expect(years.last, 1980);
    expect(years.length, DateTime.now().year - 1980 + 1);
    for (var index = 1; index < years.length; index++) {
      expect(years[index], years[index - 1] - 1);
    }

    await _select(tester, 'vehicle-make-select', 'BMW');
    await _select(tester, 'vehicle-model-select', 'X3');
    await _select(tester, 'vehicle-fuel-select', 'Электричество');
    expect(_continueButton(tester).onPressed, isNull);
    await _select(
      tester,
      'vehicle-year-select',
      DateTime.now().year.toString(),
    );
    expect(_continueButton(tester).onPressed, isNotNull);
  });

  testWidgets('electric hides displacement while non-electric requires it', (
    tester,
  ) async {
    await _pumpVehicleForm(tester);
    await _select(tester, 'vehicle-make-select', 'BMW');
    await _select(tester, 'vehicle-model-select', 'X3');
    await _select(tester, 'vehicle-year-select', '2020');

    await _select(tester, 'vehicle-fuel-select', 'Электричество');
    expect(
      find.byKey(const Key('vehicle-engine-displacement-input')),
      findsNothing,
    );
    expect(_continueButton(tester).onPressed, isNotNull);

    await _select(tester, 'vehicle-fuel-select', 'Бензин');
    expect(
      find.byKey(const Key('vehicle-engine-displacement-input')),
      findsOneWidget,
    );
    expect(_continueButton(tester).onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('vehicle-engine-displacement-input')),
      '1998',
    );
    await tester.pump();
    expect(_continueButton(tester).onPressed, isNotNull);
  });

  testWidgets('transmission is optional and has only three choices', (
    tester,
  ) async {
    await _pumpVehicleForm(tester);

    expect(_dropdownTextLabels(tester, 'vehicle-transmission-select'), const [
      'Не указано',
      'Механическая',
      'Автоматическая',
    ]);
    expect(find.byKey(const Key('vehicle-gears-input')), findsNothing);
    expect(find.text('Вариатор'), findsNothing);
    expect(find.text('Роботизированная'), findsNothing);
    expect(find.text('Количество передач'), findsNothing);
  });

  testWidgets('VIN and mileage are optional and VIN validates when nonempty', (
    tester,
  ) async {
    await _pumpVehicleForm(tester);

    expect(
      find.text(
        'Без VIN в будущем будут недоступны автоматический сбор данных '
        'и точная идентификация комплектации.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('collect-vin-data')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('vin-input')),
      'wvwzzz1jzxw000001',
    );
    expect(_fieldText(tester, 'vin-input'), 'WVWZZZ1JZXW000001');

    await _fillRequiredProfile(tester);
    expect(_continueButton(tester).onPressed, isNotNull);
    await tester.enterText(
      find.byKey(const Key('vin-input')),
      'WVWZZZ1JZXW00000I',
    );
    await tester.pump();
    expect(_fieldText(tester, 'vin-input'), 'WVWZZZ1JZXW00000');
    expect(_continueButton(tester).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('vin-input')), '');
    await tester.pump();
    expect(_continueButton(tester).onPressed, isNotNull);
  });

  testWidgets('full optional VIN mileage and transmission payload is saved', (
    tester,
  ) async {
    final repository = FakeVehicleRepository(
      createHandler: (_) async => fakeFullVehicle,
    );
    await _pumpVehicleForm(tester, vehicleRepository: repository);
    await _fillRequiredProfile(tester);
    await tester.enterText(
      find.byKey(const Key('vin-input')),
      'wvwzzz1jzxw000001',
    );
    await tester.enterText(
      find.byKey(const Key('vehicle-mileage-input')),
      '50000',
    );
    await _select(tester, 'vehicle-transmission-select', 'Автоматическая');

    await _continueToConfirm(tester);
    expect(find.text('WVW**********0001'), findsOneWidget);
    expect(find.text('50000'), findsOneWidget);
    expect(find.text('Автоматическая'), findsOneWidget);
    await _createVehicle(tester);

    expect(repository.lastDraft?.vin, 'WVWZZZ1JZXW000001');
    expect(repository.lastDraft?.mileage, 50000);
    expect(
      repository.lastDraft?.transmissionType,
      VehicleTransmissionType.automatic,
    );
    expect(repository.lastDraft?.transmissionGears, isNull);
  });

  testWidgets('create to first plan and roadmap works without VIN or mileage', (
    tester,
  ) async {
    final repository = FakeVehicleRepository();
    await _pumpVehicleForm(tester, vehicleRepository: repository);
    await _fillRequiredProfile(tester);
    await _continueToConfirm(tester);
    await _createVehicle(tester);

    expect(_path(tester), '/plan/first');
    expect(find.textContaining('Volkswagen Golf'), findsWidgets);
    expect(find.text('Пунктов обслуживания: 1'), findsOneWidget);
    expect(find.byKey(const Key('first-plan-continue')), findsOneWidget);

    await tester.tap(find.byKey(const Key('first-plan-continue')));
    await tester.pumpAndSettle();
    expect(_path(tester), '/roadmap');
    expect(find.byKey(const Key('header-active-vehicle')), findsOneWidget);
    expect(find.text('Volkswagen Golf'), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
    expect(find.byKey(const Key('real-timeline')), findsOneWidget);
    expect(find.text('Моторное масло'), findsWidgets);
  });

  testWidgets('submit shows loading and API error retries exactly once', (
    tester,
  ) async {
    final completer = Completer<Vehicle>();
    final repository = FakeVehicleRepository(
      createHandler: (_) => completer.future,
    );
    await _pumpVehicleForm(tester, vehicleRepository: repository);
    await _fillRequiredProfile(tester);
    await _continueToConfirm(tester);

    await tester.ensureVisible(find.byKey(const Key('confirm-vehicle')));
    await tester.tap(find.byKey(const Key('confirm-vehicle')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.createCalls, 1);
    completer.completeError(
      const VehicleFailure(
        safeMessage: 'Не удалось сохранить автомобиль.',
        requestId: 'req_vehicle_42',
        statusCode: 422,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Не удалось сохранить автомобиль.'), findsOneWidget);
    expect(find.text('ID запроса: req_vehicle_42'), findsOneWidget);
    expect(repository.createCalls, 1);

    repository.createHandler = (_) async => fakeMinimalVehicle;
    await _createVehicle(tester);
    expect(repository.createCalls, 2);
    expect(_path(tester), '/plan/first');
  });

  testWidgets('back controls and direct route guards do not dead-end', (
    tester,
  ) async {
    await _pumpVehicleForm(tester);
    expect(find.byKey(const Key('vehicle-continue')), findsOneWidget);
    await tester.tap(find.byKey(const Key('vin-back')));
    await tester.pumpAndSettle();
    expect(_path(tester), '/garage/add');
    expect(find.byKey(const Key('consent-continue')), findsOneWidget);

    final router = _router(tester);
    router.go('/garage/add/confirm');
    await tester.pumpAndSettle();
    expect(_path(tester), '/garage/add/vin');
    expect(find.byKey(const Key('vehicle-continue')), findsOneWidget);

    router.go('/plan/first');
    await tester.pumpAndSettle();
    expect(_path(tester), '/garage/add');
    expect(find.byKey(const Key('consent-continue')), findsOneWidget);
  });

  testWidgets('route audit exposes a forward CTA at every flow step', (
    tester,
  ) async {
    final repository = FakeVehicleRepository();
    await _pumpApp(
      tester,
      tokenStore: FakeTokenStore('test-token'),
      vehicleRepository: repository,
    );

    await tester.tap(find.byKey(const Key('header-add-vehicle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('consent-continue')), findsOneWidget);

    await tester.tap(find.byKey(const Key('consent-essential_processing')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('consent-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('vehicle-continue')), findsOneWidget);

    await _fillRequiredProfile(tester);
    await _continueToConfirm(tester);
    expect(find.byKey(const Key('confirm-vehicle')), findsOneWidget);

    await _createVehicle(tester);
    expect(find.byKey(const Key('first-plan-continue')), findsOneWidget);
    await tester.tap(find.byKey(const Key('first-plan-continue')));
    await tester.pumpAndSettle();
    expect(_path(tester), '/roadmap');
    expect(find.byKey(const Key('roadmap-quick-add')), findsOneWidget);
  });

  testWidgets('corrected vehicle flow fits 360x640', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpVehicleForm(tester);
    expect(tester.takeException(), isNull);
    await _fillRequiredProfile(tester);
    await _continueToConfirm(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('confirm-vehicle')), findsOneWidget);
  });

  for (final localeCase in const [
    (
      Locale('ru'),
      ['Данные автомобиля', 'Марка', 'Модель', 'Год выпуска', 'Тип топлива'],
    ),
    (
      Locale('en'),
      ['Vehicle details', 'Make', 'Model', 'Production year', 'Fuel type'],
    ),
  ]) {
    testWidgets(
      '${localeCase.$1.languageCode} localizes corrected required labels',
      (tester) async {
        await _pumpVehicleForm(tester, locale: localeCase.$1);
        expect(find.text(localeCase.$2[0]), findsOneWidget);
        expect(_dropdownLabel(tester, 'vehicle-make-select'), localeCase.$2[1]);
        await _select(tester, 'vehicle-make-select', 'Volkswagen');
        expect(
          _dropdownLabel(tester, 'vehicle-model-select'),
          localeCase.$2[2],
        );
        expect(_dropdownLabel(tester, 'vehicle-year-select'), localeCase.$2[3]);
        expect(_dropdownLabel(tester, 'vehicle-fuel-select'), localeCase.$2[4]);
      },
    );
  }
}

const fakeMinimalVehicle = Vehicle(
  id: 'vehicle-minimal',
  make: 'Volkswagen',
  model: 'Golf',
  productionYear: 2020,
  fuelType: 'petrol',
  engineDisplacementCc: 1600,
);

const fakeFullVehicle = Vehicle(
  id: 'vehicle-full',
  vinMasked: 'WVW**********0001',
  make: 'Volkswagen',
  model: 'Golf',
  mileage: 50000,
  mileageUnit: 'km',
  productionYear: 2020,
  fuelType: 'petrol',
  engineDisplacementCc: 1600,
  transmissionType: 'automatic',
);

Future<void> _pumpApp(
  WidgetTester tester, {
  Locale locale = const Locale('ru'),
  FakeTokenStore? tokenStore,
  FakeGuestRepository? guestRepository,
  FakeVehicleRepository? vehicleRepository,
  MaintenanceRepository? maintenanceRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localeControllerProvider.overrideWith(() => FakeLocale(locale)),
        sessionTokenStoreProvider.overrideWithValue(
          tokenStore ?? FakeTokenStore(),
        ),
        guestBootstrapRepositoryProvider.overrideWithValue(
          guestRepository ?? FakeGuestRepository(),
        ),
        vehicleRepositoryProvider.overrideWithValue(
          vehicleRepository ?? FakeVehicleRepository(),
        ),
        maintenanceRepositoryProvider.overrideWithValue(
          maintenanceRepository ?? FakeMaintenanceRepository(),
        ),
      ],
      child: const AutoDoctorApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpVehicleForm(
  WidgetTester tester, {
  Locale locale = const Locale('ru'),
  FakeVehicleRepository? vehicleRepository,
}) async {
  await _pumpApp(
    tester,
    locale: locale,
    tokenStore: FakeTokenStore('test-token'),
    vehicleRepository: vehicleRepository,
  );
  _router(tester).go('/garage/add/vin');
  await tester.pumpAndSettle();
}

Future<void> _openVehicleFormThroughConsents(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('header-add-vehicle')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('consent-essential_processing')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('consent-continue')));
  await tester.pumpAndSettle();
}

Future<void> _fillRequiredProfile(WidgetTester tester) async {
  await _select(tester, 'vehicle-make-select', 'Volkswagen');
  await _select(tester, 'vehicle-model-select', 'Golf');
  await _fillYearFuelAndDisplacement(tester);
}

Future<void> _fillYearFuelAndDisplacement(WidgetTester tester) async {
  await _select(tester, 'vehicle-year-select', '2020');
  await _select(tester, 'vehicle-fuel-select', 'Бензин');
  await tester.enterText(
    find.byKey(const Key('vehicle-engine-displacement-input')),
    '1600',
  );
  await tester.pump();
}

Future<void> _continueToConfirm(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('vehicle-continue')));
  expect(_continueButton(tester).onPressed, isNotNull);
  await tester.tap(find.byKey(const Key('vehicle-continue')));
  await tester.pumpAndSettle();
  expect(_path(tester), '/garage/add/confirm');
}

Future<void> _createVehicle(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('confirm-vehicle')));
  await tester.tap(find.byKey(const Key('confirm-vehicle')));
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, String key, String label) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

FilledButton _continueButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const Key('vehicle-continue')));

String _fieldText(WidgetTester tester, String key) =>
    tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;

List<String> _dropdownTextLabels(WidgetTester tester, String key) {
  final widget = tester.widget<DropdownButton<dynamic>>(
    find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byWidgetPredicate((widget) => widget is DropdownButton),
    ),
  );
  return widget.items!
      .map((item) => (item.child as Text).data!)
      .toList(growable: false);
}

String? _dropdownLabel(WidgetTester tester, String key) => tester
    .widget<DropdownButtonFormField<dynamic>>(find.byKey(Key(key)))
    .decoration
    .labelText;

GoRouter _router(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(AutoDoctorApp)),
  );
  return container.read(routerProvider);
}

String _path(WidgetTester tester) =>
    _router(tester).routeInformationProvider.value.uri.path;

class FakeLocale extends LocaleController {
  FakeLocale(this.locale);

  final Locale locale;

  @override
  Future<Locale?> build() async => locale;

  @override
  Future<void> setLocale(Locale? locale) async {
    state = AsyncData(locale);
  }
}

class FakeTokenStore implements SessionTokenStore {
  FakeTokenStore([this.token]);

  String? token;

  @override
  Future<void> clear() async => token = null;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;
}

class FakeGuestRepository implements GuestBootstrapRepository {
  int saveCalls = 0;

  @override
  Future<CreatedGuestSession> createAnonymousSession({
    required String locale,
    required String platform,
    required String appVersion,
  }) async => const CreatedGuestSession(
    session: GuestSession(id: 'session-1', status: 'active'),
    token: 'test-token',
  );

  @override
  Future<List<ConsentDocument>> getCurrentConsents() async => const [
    ConsentDocument(
      purpose: 'essential_processing',
      version: '2026-07-17',
      title: 'Обязательная обработка данных',
      text: 'Необходимо для работы приложения.',
      required: true,
    ),
    ConsentDocument(
      purpose: 'analytics',
      version: '2026-07-17',
      title: 'Аналитика',
      text: 'Необязательная аналитика.',
      required: false,
    ),
  ];

  @override
  Future<GuestSession> getCurrentSession() async =>
      const GuestSession(id: 'session-1', status: 'active');

  @override
  Future<void> saveConsents(List<ConsentDecision> decisions) async {
    saveCalls++;
  }
}

class FakeVehicleRepository implements VehicleRepository {
  FakeVehicleRepository({this.createHandler, this.vehicles = const []});

  int createCalls = 0;
  VehicleDraft? lastDraft;
  List<Vehicle> vehicles;
  Future<Vehicle> Function(VehicleDraft draft)? createHandler;

  @override
  Future<Vehicle> create(VehicleDraft draft, {required String locale}) async {
    createCalls++;
    lastDraft = draft;
    return createHandler?.call(draft) ?? fakeMinimalVehicle;
  }

  @override
  Future<List<Vehicle>> list({required String locale}) async => vehicles;

  @override
  Future<MileageConfirmation> updateMileage(
    String vehicleId, {
    required int value,
    required String unit,
    required int version,
    required DateTime observedAt,
    required String locale,
  }) async => MileageConfirmation(
    vehicleId: vehicleId,
    vehicleVersion: version + 1,
    value: value,
    unit: unit,
  );
}

class FakeMaintenanceRepository implements MaintenanceRepository {
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
  }) async => ServiceRecord(
    id: 'service-1',
    vehicleId: vehicleId,
    serviceDate: record.serviceDate,
    mileage: record.mileage,
    mileageUnit: record.mileageUnit,
    items: [ServiceWork(workCode: record.workCode, title: record.workCode)],
  );

  @override
  Future<ServiceRecordList> getServiceRecords(
    String vehicleId, {
    required String locale,
  }) async => const ServiceRecordList(items: []);

  @override
  Future<void> submitHistoryAnswers(
    String vehicleId, {
    required String locale,
    required List<HistoryAnswerWrite> answers,
  }) async {}

  @override
  Future<ConsumableList> getConsumables(
    String vehicleId, {
    required String locale,
  }) async => ConsumableList(
    items: [
      Consumable(
        id: 'engine-oil',
        title: locale == 'en' ? 'Engine oil' : 'Моторное масло',
        kind: ConsumableKind.intervalBased,
        status: MaintenanceStatus.unknown,
        importance: MaintenanceImportance.recommended,
        basis: locale == 'en'
            ? 'Every 10,000 km or 365 days.'
            : 'Каждые 10 000 км или 365 дней.',
        source: fakeSource,
        due: const MaintenanceDue(),
        inspectionState: InspectionState.unknown,
      ),
    ],
    warnings: const ['EDITORIAL_BASELINE_ONLY', 'HISTORY_REQUIRED'],
  );

  @override
  Future<MaintenancePlan> getPlan(
    String vehicleId, {
    required String locale,
  }) async => MaintenancePlan(
    id: 'plan-$vehicleId',
    vehicleId: vehicleId,
    rulesetVersion: 'by-pilot-baseline-1',
    items: [
      MaintenanceItem(
        id: 'item-oil',
        workCode: 'engine_oil',
        title: locale == 'en' ? 'Engine oil' : 'Моторное масло',
        status: MaintenanceStatus.unknown,
        importance: MaintenanceImportance.recommended,
        basis: locale == 'en'
            ? 'Every 10,000 km or 365 days.'
            : 'Каждые 10 000 км или 365 дней.',
        source: fakeSource,
        due: const MaintenanceDue(),
        interval: const MaintenanceInterval(mileageKm: 10000, days: 365),
      ),
    ],
    warnings: const ['EDITORIAL_BASELINE_ONLY', 'HISTORY_REQUIRED'],
  );

  @override
  Future<VehicleTimeline> getTimeline(
    String vehicleId, {
    required String locale,
  }) async {
    final planItem = (await getPlan(vehicleId, locale: locale)).items.first;
    final item = MaintenanceItem(
      id: planItem.id,
      workCode: planItem.workCode,
      title: planItem.title,
      status: MaintenanceStatus.soon,
      importance: planItem.importance,
      basis: planItem.basis,
      source: planItem.source,
      due: MaintenanceDue(
        mileage: 15000,
        unit: 'km',
        date: DateTime(2026, 10, 1),
      ),
      interval: planItem.interval,
      historyState: HistoryState(
        answer: HistoryAnswerValue.doneKnown,
        performedDate: DateTime(2025, 7, 20),
        performedMileageKm: 5000,
      ),
    );
    return VehicleTimeline(
      vehicleId: vehicleId,
      currentMileage: 10000,
      currentMileageUnit: 'km',
      items: [
        TimelineItem(
          item: item,
          primaryCategory: 'maintenance_repair',
          status: MaintenanceStatus.soon,
          importance: MaintenanceImportance.recommended,
          actionLevel: TimelineActionLevel.recommendation,
          basis: PresentationBasis.confirmed,
        ),
      ],
    );
  }
}

const fakeSource = MaintenanceSource(
  title: 'AutoDoctor Pilot Baseline v1',
  publisher: 'AutoDoctor Editorial',
  kind: MaintenanceSourceKind.editorialBaseline,
  methodologyNote: 'Editorial',
  officialOem: false,
);

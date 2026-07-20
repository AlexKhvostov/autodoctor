import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guest_bootstrap/guest_bootstrap_controller.dart';
import 'maintenance.dart';
import 'maintenance_data.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => DioMaintenanceRepository(ref.watch(sessionTokenStoreProvider)),
);

enum MaintenanceLoadStage { idle, loading, ready, error }

class MaintenanceState {
  const MaintenanceState({
    this.vehicleId,
    this.locale,
    this.planStage = MaintenanceLoadStage.idle,
    this.roadmapStage = MaintenanceLoadStage.idle,
    this.plan,
    this.timeline,
    this.consumables,
    this.serviceRecords,
    this.mileageForecast,
    this.conditionObservations,
    this.forecastFailure,
    this.failure,
  });

  final String? vehicleId;
  final String? locale;
  final MaintenanceLoadStage planStage;
  final MaintenanceLoadStage roadmapStage;
  final MaintenancePlan? plan;
  final VehicleTimeline? timeline;
  final ConsumableList? consumables;
  final ServiceRecordList? serviceRecords;
  final MileageForecast? mileageForecast;
  final ConditionObservationList? conditionObservations;
  final MaintenanceFailure? forecastFailure;
  final MaintenanceFailure? failure;

  bool matches(String vehicleId, String locale) =>
      this.vehicleId == vehicleId && this.locale == locale;

  MaintenanceState copyWith({
    String? vehicleId,
    String? locale,
    MaintenanceLoadStage? planStage,
    MaintenanceLoadStage? roadmapStage,
    MaintenancePlan? plan,
    VehicleTimeline? timeline,
    ConsumableList? consumables,
    ServiceRecordList? serviceRecords,
    MileageForecast? mileageForecast,
    ConditionObservationList? conditionObservations,
    MaintenanceFailure? forecastFailure,
    bool clearForecastFailure = false,
    MaintenanceFailure? failure,
    bool clearFailure = false,
  }) => MaintenanceState(
    vehicleId: vehicleId ?? this.vehicleId,
    locale: locale ?? this.locale,
    planStage: planStage ?? this.planStage,
    roadmapStage: roadmapStage ?? this.roadmapStage,
    plan: plan ?? this.plan,
    timeline: timeline ?? this.timeline,
    consumables: consumables ?? this.consumables,
    serviceRecords: serviceRecords ?? this.serviceRecords,
    mileageForecast: mileageForecast ?? this.mileageForecast,
    conditionObservations: conditionObservations ?? this.conditionObservations,
    forecastFailure: clearForecastFailure
        ? null
        : forecastFailure ?? this.forecastFailure,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

final maintenanceControllerProvider =
    NotifierProvider<MaintenanceController, MaintenanceState>(
      MaintenanceController.new,
    );

class MaintenanceController extends Notifier<MaintenanceState> {
  var _generation = 0;

  @override
  MaintenanceState build() => const MaintenanceState();

  MaintenanceRepository get _repository =>
      ref.read(maintenanceRepositoryProvider);

  void clear() {
    _generation++;
    state = const MaintenanceState();
  }

  Future<void> ensurePlan(
    String vehicleId, {
    required String locale,
    bool force = false,
  }) async {
    if (!state.matches(vehicleId, locale)) {
      _generation++;
      state = MaintenanceState(vehicleId: vehicleId, locale: locale);
    }
    if (!force &&
        (state.planStage == MaintenanceLoadStage.loading ||
            state.planStage == MaintenanceLoadStage.ready)) {
      return;
    }
    final generation = ++_generation;
    state = state.copyWith(
      planStage: MaintenanceLoadStage.loading,
      clearFailure: true,
    );
    try {
      final plan = await _repository.getPlan(vehicleId, locale: locale);
      if (generation != _generation || !state.matches(vehicleId, locale)) {
        return;
      }
      state = state.copyWith(
        planStage: MaintenanceLoadStage.ready,
        plan: plan,
        clearFailure: true,
      );
    } on MaintenanceFailure catch (failure) {
      if (generation != _generation) return;
      state = state.copyWith(
        planStage: MaintenanceLoadStage.error,
        failure: failure,
      );
    } on Object {
      if (generation != _generation) return;
      state = state.copyWith(
        planStage: MaintenanceLoadStage.error,
        failure: const MaintenanceFailure(code: 'UNEXPECTED_RESPONSE'),
      );
    }
  }

  Future<void> ensureRoadmap(
    String vehicleId, {
    required String locale,
    bool force = false,
  }) async {
    if (!state.matches(vehicleId, locale)) {
      _generation++;
      state = MaintenanceState(vehicleId: vehicleId, locale: locale);
    }
    if (!force &&
        (state.roadmapStage == MaintenanceLoadStage.loading ||
            state.roadmapStage == MaintenanceLoadStage.ready)) {
      return;
    }
    final generation = ++_generation;
    state = state.copyWith(
      roadmapStage: MaintenanceLoadStage.loading,
      clearFailure: true,
    );
    try {
      final results = await Future.wait<Object?>([
        if (state.plan == null)
          _repository.getPlan(vehicleId, locale: locale)
        else
          Future<MaintenancePlan>.value(state.plan),
        _repository.getTimeline(vehicleId, locale: locale),
        _repository.getConsumables(vehicleId, locale: locale),
        _repository.getServiceRecords(vehicleId, locale: locale),
        _repository.getConditionObservations(vehicleId, locale: locale),
        _optionalForecast(vehicleId, locale),
      ]);
      if (generation != _generation || !state.matches(vehicleId, locale)) {
        return;
      }
      state = state.copyWith(
        planStage: MaintenanceLoadStage.ready,
        roadmapStage: MaintenanceLoadStage.ready,
        plan: results[0] as MaintenancePlan,
        timeline: results[1] as VehicleTimeline,
        consumables: results[2] as ConsumableList,
        serviceRecords: results[3] as ServiceRecordList,
        conditionObservations: results[4] as ConditionObservationList,
        mileageForecast: (results[5] as _ForecastResult).value,
        forecastFailure: (results[5] as _ForecastResult).failure,
        clearForecastFailure: (results[5] as _ForecastResult).failure == null,
        clearFailure: true,
      );
    } on MaintenanceFailure catch (failure) {
      if (generation != _generation) return;
      state = state.copyWith(
        roadmapStage: MaintenanceLoadStage.error,
        failure: failure,
      );
    } on Object {
      if (generation != _generation) return;
      state = state.copyWith(
        roadmapStage: MaintenanceLoadStage.error,
        failure: const MaintenanceFailure(code: 'UNEXPECTED_RESPONSE'),
      );
    }
  }

  Future<_ForecastResult> _optionalForecast(
    String vehicleId,
    String locale,
  ) async {
    try {
      return _ForecastResult(
        value: await _repository.getMileageForecast(vehicleId, locale: locale),
      );
    } on MaintenanceFailure catch (failure) {
      return _ForecastResult(failure: failure);
    } on Object {
      return const _ForecastResult(
        failure: MaintenanceFailure(code: 'UNEXPECTED_RESPONSE'),
      );
    }
  }

  Future<void> submitHistoryAnswers(
    String vehicleId, {
    required String locale,
    required List<HistoryAnswerWrite> answers,
  }) async {
    if (answers.isEmpty || !state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    final generation = ++_generation;
    try {
      await _repository.submitHistoryAnswers(
        vehicleId,
        locale: locale,
        answers: answers,
      );
      if (generation != _generation || !state.matches(vehicleId, locale)) {
        throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
      }
      final results = await Future.wait<Object>([
        _repository.getPlan(vehicleId, locale: locale),
        _repository.getTimeline(vehicleId, locale: locale),
        _repository.getConsumables(vehicleId, locale: locale),
      ]);
      if (generation != _generation || !state.matches(vehicleId, locale)) {
        throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
      }
      state = state.copyWith(
        planStage: MaintenanceLoadStage.ready,
        roadmapStage: MaintenanceLoadStage.ready,
        plan: results[0] as MaintenancePlan,
        timeline: results[1] as VehicleTimeline,
        consumables: results[2] as ConsumableList,
        clearFailure: true,
      );
    } on MaintenanceFailure {
      rethrow;
    } on Object {
      throw const MaintenanceFailure(code: 'UNEXPECTED_RESPONSE');
    }
  }

  Future<ServiceRecord> createServiceRecord(
    String vehicleId, {
    required String locale,
    required ServiceRecordWrite record,
  }) async {
    if (!state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    final generation = ++_generation;
    final created = await _repository.createServiceRecord(
      vehicleId,
      locale: locale,
      record: record,
    );
    if (generation != _generation || !state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    final results = await Future.wait<Object>([
      _repository.getPlan(vehicleId, locale: locale),
      _repository.getTimeline(vehicleId, locale: locale),
      _repository.getConsumables(vehicleId, locale: locale),
      _repository.getServiceRecords(vehicleId, locale: locale),
    ]);
    if (generation != _generation || !state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    state = state.copyWith(
      planStage: MaintenanceLoadStage.ready,
      roadmapStage: MaintenanceLoadStage.ready,
      plan: results[0] as MaintenancePlan,
      timeline: results[1] as VehicleTimeline,
      consumables: results[2] as ConsumableList,
      serviceRecords: results[3] as ServiceRecordList,
      clearFailure: true,
    );
    return created;
  }

  Future<ConditionObservation> createConditionObservation(
    String vehicleId, {
    required String locale,
    required ConditionObservationWrite observation,
  }) async {
    if (!state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    final generation = ++_generation;
    final created = await _repository.createConditionObservation(
      vehicleId,
      locale: locale,
      observation: observation,
    );
    if (generation != _generation || !state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    await _reloadCore(vehicleId, locale, generation);
    return created;
  }

  Future<ServiceRecord> updateServiceRecord(
    String vehicleId,
    String recordId, {
    required String locale,
    required ServiceRecordWrite record,
  }) async {
    if (!state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    final generation = ++_generation;
    final updated = await _repository.updateServiceRecord(
      vehicleId,
      recordId,
      locale: locale,
      record: record,
    );
    if (generation != _generation || !state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    await _reloadCore(vehicleId, locale, generation);
    return updated;
  }

  Future<void> deleteServiceRecord(
    String vehicleId,
    String recordId, {
    required String locale,
  }) async {
    if (!state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    final generation = ++_generation;
    await _repository.deleteServiceRecord(
      vehicleId,
      recordId,
      locale: locale,
    );
    if (generation != _generation || !state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    await _reloadCore(vehicleId, locale, generation);
  }

  Future<ConditionObservation> updateConditionObservation(
    String vehicleId,
    String observationId, {
    required String locale,
    required ConditionObservationWrite observation,
  }) async {
    if (!state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    final generation = ++_generation;
    final updated = await _repository.updateConditionObservation(
      vehicleId,
      observationId,
      locale: locale,
      observation: observation,
    );
    if (generation != _generation || !state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    await _reloadCore(vehicleId, locale, generation);
    return updated;
  }

  Future<void> deleteConditionObservation(
    String vehicleId,
    String observationId, {
    required String locale,
  }) async {
    if (!state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    final generation = ++_generation;
    await _repository.deleteConditionObservation(
      vehicleId,
      observationId,
      locale: locale,
    );
    if (generation != _generation || !state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    await _reloadCore(vehicleId, locale, generation);
  }

  Future<void> _reloadCore(
    String vehicleId,
    String locale,
    int generation,
  ) async {
    final results = await Future.wait<Object>([
      _repository.getPlan(vehicleId, locale: locale),
      _repository.getTimeline(vehicleId, locale: locale),
      _repository.getConsumables(vehicleId, locale: locale),
      _repository.getServiceRecords(vehicleId, locale: locale),
      _repository.getConditionObservations(vehicleId, locale: locale),
    ]);
    if (generation != _generation || !state.matches(vehicleId, locale)) {
      throw const MaintenanceFailure(code: 'STALE_MAINTENANCE_CONTEXT');
    }
    state = state.copyWith(
      planStage: MaintenanceLoadStage.ready,
      roadmapStage: MaintenanceLoadStage.ready,
      plan: results[0] as MaintenancePlan,
      timeline: results[1] as VehicleTimeline,
      consumables: results[2] as ConsumableList,
      serviceRecords: results[3] as ServiceRecordList,
      conditionObservations: results[4] as ConditionObservationList,
      clearFailure: true,
    );
  }
}

class _ForecastResult {
  const _ForecastResult({this.value, this.failure});
  final MileageForecast? value;
  final MaintenanceFailure? failure;
}

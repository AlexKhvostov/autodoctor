import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/locale_controller.dart';
import '../guest_bootstrap/guest_bootstrap_controller.dart';
import '../maintenance/maintenance_controller.dart';
import 'vehicle.dart';
import 'vehicle_data.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => DioVehicleRepository(ref.watch(sessionTokenStoreProvider)),
);

enum VehicleLoadStage { idle, loading, ready, error }

class VehicleSetupState {
  const VehicleSetupState({
    this.draft = const VehicleDraft(),
    this.vehicles = const [],
    this.activeVehicleId,
    this.stage = VehicleLoadStage.idle,
    this.failure,
    this.submitting = false,
  });

  final VehicleDraft draft;
  final List<Vehicle> vehicles;
  final String? activeVehicleId;
  final VehicleLoadStage stage;
  final VehicleFailure? failure;
  final bool submitting;

  Vehicle? get activeVehicle {
    if (vehicles.isEmpty) return null;
    return vehicles
            .where((vehicle) => vehicle.id == activeVehicleId)
            .firstOrNull ??
        vehicles.first;
  }

  VehicleSetupState copyWith({
    VehicleDraft? draft,
    List<Vehicle>? vehicles,
    String? activeVehicleId,
    VehicleLoadStage? stage,
    VehicleFailure? failure,
    bool clearFailure = false,
    bool? submitting,
  }) => VehicleSetupState(
    draft: draft ?? this.draft,
    vehicles: vehicles ?? this.vehicles,
    activeVehicleId: activeVehicleId ?? this.activeVehicleId,
    stage: stage ?? this.stage,
    failure: clearFailure ? null : failure ?? this.failure,
    submitting: submitting ?? this.submitting,
  );
}

final vehicleSetupControllerProvider =
    NotifierProvider<VehicleSetupController, VehicleSetupState>(
      VehicleSetupController.new,
    );

class VehicleSetupController extends Notifier<VehicleSetupState> {
  @override
  VehicleSetupState build() => const VehicleSetupState();

  String get _locale => ref.read(activeLocaleProvider).languageCode;
  VehicleRepository get _repository => ref.read(vehicleRepositoryProvider);

  void updateDraft(VehicleDraft draft) {
    state = state.copyWith(draft: draft, clearFailure: true);
  }

  void clearDraft() {
    state = state.copyWith(draft: const VehicleDraft(), clearFailure: true);
  }

  void selectVehicle(String vehicleId) {
    if (state.vehicles.any((vehicle) => vehicle.id == vehicleId)) {
      state = state.copyWith(activeVehicleId: vehicleId);
    }
  }

  Future<void> load({bool force = false}) async {
    if (state.stage == VehicleLoadStage.loading) return;
    final token = await ref.read(sessionTokenStoreProvider).read();
    if (token == null || token.isEmpty) {
      state = state.copyWith(stage: VehicleLoadStage.ready, vehicles: const []);
      return;
    }
    state = state.copyWith(stage: VehicleLoadStage.loading, clearFailure: true);
    try {
      final vehicles = await _repository.list(locale: _locale);
      state = state.copyWith(
        stage: VehicleLoadStage.ready,
        vehicles: vehicles,
        activeVehicleId:
            vehicles.any((vehicle) => vehicle.id == state.activeVehicleId)
            ? state.activeVehicleId
            : vehicles.firstOrNull?.id,
        clearFailure: true,
      );
    } on VehicleFailure catch (failure) {
      state = state.copyWith(stage: VehicleLoadStage.error, failure: failure);
    }
  }

  Future<Vehicle?> updateMileage({
    required int value,
    required String unit,
  }) async {
    final vehicle = state.activeVehicle;
    if (vehicle == null || state.submitting || value < 0) return null;
    if (vehicle.mileage != null &&
        mileageInKm(value, unit) <
            mileageInKm(vehicle.mileage!, vehicle.mileageUnit ?? 'km')) {
      state = state.copyWith(
        failure: const VehicleFailure(code: 'MILEAGE_DECREASE_NOT_ALLOWED'),
      );
      return null;
    }
    state = state.copyWith(submitting: true, clearFailure: true);
    try {
      final result = await _repository.updateMileage(
        vehicle.id,
        value: value,
        unit: unit,
        version: vehicle.version,
        observedAt: DateTime.now(),
        locale: _locale,
      );
      final updated = vehicle.copyWith(
        version: result.vehicleVersion,
        mileage: result.value,
        mileageUnit: result.unit,
      );
      state = state.copyWith(
        vehicles: [
          for (final item in state.vehicles)
            if (item.id == updated.id) updated else item,
        ],
        submitting: false,
        clearFailure: true,
      );
      await ref
          .read(maintenanceControllerProvider.notifier)
          .ensureRoadmap(updated.id, locale: _locale, force: true);
      return updated;
    } on VehicleFailure catch (failure) {
      state = state.copyWith(submitting: false, failure: failure);
      return null;
    } on Object {
      state = state.copyWith(
        submitting: false,
        failure: const VehicleFailure(code: 'UNEXPECTED_RESPONSE'),
      );
      return null;
    }
  }

  Future<Vehicle?> create() async {
    if (!state.draft.isComplete || state.submitting) return null;
    state = state.copyWith(submitting: true, clearFailure: true);
    try {
      final vehicle = await _repository.create(state.draft, locale: _locale);
      state = state.copyWith(
        vehicles: [vehicle, ...state.vehicles.where((v) => v.id != vehicle.id)],
        activeVehicleId: vehicle.id,
        stage: VehicleLoadStage.ready,
        submitting: false,
        clearFailure: true,
      );
      return vehicle;
    } on VehicleFailure catch (failure) {
      state = state.copyWith(submitting: false, failure: failure);
      return null;
    } on Object {
      state = state.copyWith(
        submitting: false,
        failure: const VehicleFailure(code: 'UNEXPECTED_RESPONSE'),
      );
      return null;
    }
  }
}

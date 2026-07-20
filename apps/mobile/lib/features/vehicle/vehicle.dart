enum VehicleFuelType { petrol, diesel, hybrid, electric, lpg, other }

enum VehicleTransmissionType { manual, automatic, cvt, robotized, other }

enum VehicleDrivetrain { fwd, rwd, awd, fourWd, other }

class VehicleDraft {
  const VehicleDraft({
    this.vin = '',
    this.make = '',
    this.model = '',
    this.generation = '',
    this.mileage,
    this.productionYear,
    this.firstUseDate,
    this.fuelType,
    this.engineDisplacementCc,
    this.engineCode = '',
    this.powerKw,
    this.transmissionType,
    this.transmissionGears,
    this.drivetrain,
    this.market = '',
  });

  final String vin;
  final String make;
  final String model;
  final String generation;
  final int? mileage;
  final int? productionYear;
  final DateTime? firstUseDate;
  final VehicleFuelType? fuelType;
  final int? engineDisplacementCc;
  final String engineCode;
  final double? powerKw;
  final VehicleTransmissionType? transmissionType;
  final int? transmissionGears;
  final VehicleDrivetrain? drivetrain;
  final String market;

  VehicleDraft copyWith({
    String? vin,
    String? make,
    String? model,
    String? generation,
    int? mileage,
    int? productionYear,
    DateTime? firstUseDate,
    VehicleFuelType? fuelType,
    int? engineDisplacementCc,
    String? engineCode,
    double? powerKw,
    VehicleTransmissionType? transmissionType,
    int? transmissionGears,
    VehicleDrivetrain? drivetrain,
    String? market,
  }) => VehicleDraft(
    vin: vin ?? this.vin,
    make: make ?? this.make,
    model: model ?? this.model,
    generation: generation ?? this.generation,
    mileage: mileage ?? this.mileage,
    productionYear: productionYear ?? this.productionYear,
    firstUseDate: firstUseDate ?? this.firstUseDate,
    fuelType: fuelType ?? this.fuelType,
    engineDisplacementCc: engineDisplacementCc ?? this.engineDisplacementCc,
    engineCode: engineCode ?? this.engineCode,
    powerKw: powerKw ?? this.powerKw,
    transmissionType: transmissionType ?? this.transmissionType,
    transmissionGears: transmissionGears ?? this.transmissionGears,
    drivetrain: drivetrain ?? this.drivetrain,
    market: market ?? this.market,
  );

  bool get isComplete =>
      (vin.isEmpty || RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(vin)) &&
      make.trim().isNotEmpty &&
      make.trim().length <= 100 &&
      model.trim().isNotEmpty &&
      model.trim().length <= 100 &&
      (mileage == null || mileage! >= 0) &&
      productionYear != null &&
      productionYear! >= 1980 &&
      productionYear! <= DateTime.now().year &&
      fuelType != null &&
      (transmissionType == null ||
          transmissionType == VehicleTransmissionType.manual ||
          transmissionType == VehicleTransmissionType.automatic) &&
      (!_requiresDisplacement ||
          engineDisplacementCc != null &&
              engineDisplacementCc! >= 1 &&
              engineDisplacementCc! <= 20000);

  bool get _requiresDisplacement =>
      fuelType != null && fuelType != VehicleFuelType.electric;

  Map<String, Object?> toJson() => {
    if (vin.isNotEmpty) 'vin': vin,
    'make': make.trim(),
    'model': model.trim(),
    if (generation.trim().isNotEmpty) 'generation': generation.trim(),
    if (mileage != null) 'mileage': {'value': mileage, 'unit': 'km'},
    'production_year': productionYear,
    if (firstUseDate != null)
      'first_use_date':
          '${firstUseDate!.year.toString().padLeft(4, '0')}-'
          '${firstUseDate!.month.toString().padLeft(2, '0')}-'
          '${firstUseDate!.day.toString().padLeft(2, '0')}',
    'fuel_type': fuelType?.name,
    'engine': {
      'displacement_cc': fuelType == VehicleFuelType.electric
          ? null
          : engineDisplacementCc,
      'engine_code': engineCode.trim().isEmpty ? null : engineCode.trim(),
      'power_kw': powerKw,
    },
    if (transmissionType != null)
      'transmission': {
        'type': transmissionType?.name,
        if (transmissionGears != null) 'gears': transmissionGears,
      },
    if (drivetrain != null)
      'drivetrain': drivetrain == VehicleDrivetrain.fourWd
          ? 'four_wd'
          : drivetrain?.name,
    if (market.trim().isNotEmpty) 'market': market.trim(),
  };
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.productionYear,
    required this.fuelType,
    this.version = 1,
    this.vinMasked,
    this.mileage,
    this.mileageUnit,
    this.transmissionType,
    this.generation,
    this.firstUseDate,
    this.engineDisplacementCc,
    this.engineCode,
    this.powerKw,
    this.transmissionGears,
    this.drivetrain,
    this.market,
  });

  final String id;
  final int version;
  final String? vinMasked;
  final String make;
  final String model;
  final String? generation;
  final int? mileage;
  final String? mileageUnit;
  final int productionYear;
  final DateTime? firstUseDate;
  final String fuelType;
  final int? engineDisplacementCc;
  final String? engineCode;
  final double? powerKw;
  final String? transmissionType;
  final int? transmissionGears;
  final String? drivetrain;
  final String? market;

  Vehicle copyWith({int? version, int? mileage, String? mileageUnit}) =>
      Vehicle(
        id: id,
        version: version ?? this.version,
        vinMasked: vinMasked,
        make: make,
        model: model,
        generation: generation,
        mileage: mileage ?? this.mileage,
        mileageUnit: mileageUnit ?? this.mileageUnit,
        productionYear: productionYear,
        firstUseDate: firstUseDate,
        fuelType: fuelType,
        engineDisplacementCc: engineDisplacementCc,
        engineCode: engineCode,
        powerKw: powerKw,
        transmissionType: transmissionType,
        transmissionGears: transmissionGears,
        drivetrain: drivetrain,
        market: market,
      );

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final mileage = json['mileage'] is Map
        ? Map<String, dynamic>.from(json['mileage'] as Map)
        : null;
    final engine = Map<String, dynamic>.from(json['engine'] as Map);
    final transmission = json['transmission'] is Map
        ? Map<String, dynamic>.from(json['transmission'] as Map)
        : null;
    return Vehicle(
      id: json['id'] as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
      vinMasked: json['vin_masked'] as String?,
      make: json['make'] as String,
      model: json['model'] as String,
      generation: json['generation'] as String?,
      mileage: (mileage?['value'] as num?)?.toInt(),
      mileageUnit: mileage?['unit'] as String?,
      productionYear: (json['production_year'] as num).toInt(),
      firstUseDate: json['first_use_date'] == null
          ? null
          : DateTime.tryParse(json['first_use_date'] as String),
      fuelType: json['fuel_type'] as String,
      engineDisplacementCc: (engine['displacement_cc'] as num?)?.toInt(),
      engineCode: engine['engine_code'] as String?,
      powerKw: (engine['power_kw'] as num?)?.toDouble(),
      transmissionType: transmission?['type'] as String?,
      transmissionGears: (transmission?['gears'] as num?)?.toInt(),
      drivetrain: json['drivetrain'] as String?,
      market: json['market'] as String?,
    );
  }
}

abstract interface class VehicleRepository {
  Future<List<Vehicle>> list({required String locale});
  Future<Vehicle> create(VehicleDraft draft, {required String locale});
  Future<MileageConfirmation> updateMileage(
    String vehicleId, {
    required int value,
    required String unit,
    required int version,
    required DateTime observedAt,
    required String locale,
  });
}

class MileageConfirmation {
  const MileageConfirmation({
    required this.vehicleId,
    required this.vehicleVersion,
    required this.value,
    required this.unit,
  });

  final String vehicleId;
  final int vehicleVersion;
  final int value;
  final String unit;

  factory MileageConfirmation.fromJson(Map<String, dynamic> json) {
    final mileage = json['current_mileage'];
    if (mileage is! Map) throw const FormatException();
    return MileageConfirmation(
      vehicleId: json['vehicle_id'] as String,
      vehicleVersion: (json['vehicle_version'] as num).toInt(),
      value: (mileage['value'] as num).toInt(),
      unit: mileage['unit'] as String,
    );
  }
}

double mileageInKm(num value, String unit) =>
    unit == 'mi' ? value * 1.609344 : value.toDouble();

class VehicleFailure implements Exception {
  const VehicleFailure({
    this.code,
    this.requestId,
    this.statusCode,
    this.safeMessage = '',
  });

  final String? code;
  final String? requestId;
  final int? statusCode;
  final String safeMessage;
}

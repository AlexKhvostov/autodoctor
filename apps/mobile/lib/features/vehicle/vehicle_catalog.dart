import 'package:flutter_riverpod/flutter_riverpod.dart';

class VehicleMakeOption {
  const VehicleMakeOption({
    required this.id,
    required this.apiValue,
    required this.models,
  });

  final String id;
  final String? apiValue;
  final List<String> models;

  bool get isOther => apiValue == null;
}

class VehicleCatalog {
  const VehicleCatalog(this.makes);

  final List<VehicleMakeOption> makes;

  VehicleMakeOption? findMake(String apiValue) {
    for (final make in makes) {
      if (make.apiValue == apiValue) return make;
    }
    return null;
  }

  String normalizeManualValue(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

const vehicleCatalog = VehicleCatalog([
  VehicleMakeOption(
    id: 'volkswagen',
    apiValue: 'Volkswagen',
    models: [
      'Polo',
      'Golf',
      'Passat',
      'Tiguan',
      'Touareg',
      'Jetta',
      'Transporter',
    ],
  ),
  VehicleMakeOption(
    id: 'peugeot',
    apiValue: 'Peugeot',
    models: [
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
  ),
  VehicleMakeOption(
    id: 'mitsubishi',
    apiValue: 'Mitsubishi',
    models: [
      'Colt',
      'Lancer',
      'Galant',
      'ASX',
      'Outlander',
      'Eclipse Cross',
      'Pajero',
      'Pajero Sport',
    ],
  ),
  VehicleMakeOption(
    id: 'bmw',
    apiValue: 'BMW',
    models: [
      '1 Series',
      '3 Series',
      '5 Series',
      '7 Series',
      'X1',
      'X3',
      'X5',
      'X6',
    ],
  ),
  VehicleMakeOption(
    id: 'mercedes-benz',
    apiValue: 'Mercedes-Benz',
    models: [
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
  ),
  VehicleMakeOption(
    id: 'mazda',
    apiValue: 'Mazda',
    models: [
      'Mazda2',
      'Mazda3',
      'Mazda6',
      'CX-3',
      'CX-5',
      'CX-7',
      'CX-9',
      'MX-5',
    ],
  ),
  VehicleMakeOption(id: 'other', apiValue: null, models: []),
]);

final vehicleCatalogProvider = Provider<VehicleCatalog>(
  (ref) => vehicleCatalog,
);

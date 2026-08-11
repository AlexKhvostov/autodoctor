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
    final normalized = apiValue.trim().toLowerCase();
    for (final make in makes) {
      if (make.apiValue?.toLowerCase() == normalized) return make;
    }
    return null;
  }

  List<String> suggestMakes(String query, {int limit = 12}) {
    final q = query.trim().toLowerCase();
    final named = makes.where((m) => !m.isOther).toList(growable: false);
    if (q.isEmpty) {
      return named.take(limit).map((m) => m.apiValue!).toList(growable: false);
    }
    final starts = <String>[];
    final contains = <String>[];
    for (final make in named) {
      final name = make.apiValue!;
      final lower = name.toLowerCase();
      if (lower.startsWith(q)) {
        starts.add(name);
      } else if (lower.contains(q)) {
        contains.add(name);
      }
    }
    return [...starts, ...contains].take(limit).toList(growable: false);
  }

  List<String> suggestModels(String makeName, String query, {int limit = 16}) {
    final make = findMake(makeName);
    final models = make == null || make.isOther
        ? const <String>[]
        : make.models;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return models.take(limit).toList(growable: false);
    final starts = <String>[];
    final contains = <String>[];
    for (final model in models) {
      final lower = model.toLowerCase();
      if (lower.startsWith(q)) {
        starts.add(model);
      } else if (lower.contains(q)) {
        contains.add(model);
      }
    }
    return [...starts, ...contains].take(limit).toList(growable: false);
  }

  String normalizeManualValue(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

const vehicleCatalog = VehicleCatalog([
  VehicleMakeOption(
    id: 'audi',
    apiValue: 'Audi',
    models: ['A3', 'A4', 'A6', 'Q3', 'Q5', 'Q7', 'TT'],
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
    id: 'chevrolet',
    apiValue: 'Chevrolet',
    models: ['Aveo', 'Cruze', 'Lacetti', 'Captiva', 'Orlando', 'Niva'],
  ),
  VehicleMakeOption(
    id: 'citroen',
    apiValue: 'Citroën',
    models: ['C3', 'C4', 'C5', 'Berlingo', 'C4 Picasso'],
  ),
  VehicleMakeOption(
    id: 'ford',
    apiValue: 'Ford',
    models: ['Focus', 'Fiesta', 'Mondeo', 'Kuga', 'Transit', 'Explorer'],
  ),
  VehicleMakeOption(
    id: 'honda',
    apiValue: 'Honda',
    models: ['Civic', 'Accord', 'CR-V', 'HR-V', 'Jazz'],
  ),
  VehicleMakeOption(
    id: 'hyundai',
    apiValue: 'Hyundai',
    models: ['Solaris', 'Elantra', 'Tucson', 'Santa Fe', 'Creta', 'i30'],
  ),
  VehicleMakeOption(
    id: 'kia',
    apiValue: 'Kia',
    models: ['Rio', 'Ceed', 'Sportage', 'Sorento', 'Soul', 'Optima'],
  ),
  VehicleMakeOption(
    id: 'lada',
    apiValue: 'Lada',
    models: ['Granta', 'Vesta', 'XRAY', 'Largus', 'Niva', 'Priora'],
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
    id: 'nissan',
    apiValue: 'Nissan',
    models: ['Qashqai', 'X-Trail', 'Juke', 'Almera', 'Note', 'Pathfinder'],
  ),
  VehicleMakeOption(
    id: 'opel',
    apiValue: 'Opel',
    models: ['Astra', 'Corsa', 'Insignia', 'Mokka', 'Zafira', 'Vectra'],
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
    id: 'renault',
    apiValue: 'Renault',
    models: ['Logan', 'Sandero', 'Duster', 'Megane', 'Fluence', 'Kaptur'],
  ),
  VehicleMakeOption(
    id: 'skoda',
    apiValue: 'Škoda',
    models: ['Octavia', 'Fabia', 'Rapid', 'Superb', 'Kodiaq', 'Karoq'],
  ),
  VehicleMakeOption(
    id: 'toyota',
    apiValue: 'Toyota',
    models: ['Corolla', 'Camry', 'RAV4', 'Land Cruiser', 'Yaris', 'Highlander'],
  ),
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
    id: 'volvo',
    apiValue: 'Volvo',
    models: ['S60', 'S90', 'V60', 'XC40', 'XC60', 'XC90'],
  ),
  VehicleMakeOption(id: 'other', apiValue: null, models: []),
]);

final vehicleCatalogProvider = Provider<VehicleCatalog>(
  (ref) => vehicleCatalog,
);

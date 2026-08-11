import 'package:flutter/material.dart';

/// Visual icons for maintenance work nodes (plan / state / timeline).
IconData workNodeIcon(String? workCode, {String? fallbackId}) {
  final code = (workCode ?? '').trim().toLowerCase().replaceAll('-', '_');
  final id = (fallbackId ?? '').trim().toLowerCase();
  final key = code.isNotEmpty ? code : id.replaceAll('-', '_');

  switch (key) {
    case 'engine_oil':
      return Icons.oil_barrel;
    case 'oil_filter':
      return Icons.filter_alt_outlined;
    case 'air_filter':
      return Icons.air;
    case 'cabin_filter':
      return Icons.air_outlined;
    case 'brake_pads':
      return Icons.disc_full;
    case 'brake_discs':
      return Icons.album_outlined;
    case 'brake_fluid':
      return Icons.opacity;
    case 'brake_system_inspection':
      return Icons.car_crash_outlined;
    case 'coolant_inspection':
      return Icons.thermostat_outlined;
    case 'transmission_oil':
      return Icons.settings_suggest_outlined;
    case 'timing_drive':
      return Icons.timelapse;
    case 'spark_plugs':
      return Icons.bolt;
    case 'tire_condition_inspection':
      return Icons.tire_repair;
  }

  if (key.contains('oil')) return Icons.oil_barrel_outlined;
  if (key.contains('tire') || key.contains('tyre')) {
    return Icons.tire_repair_outlined;
  }
  if (key.contains('coolant')) return Icons.water_drop_outlined;
  if (key.contains('brake')) return Icons.album_outlined;
  if (key.contains('filter')) return Icons.air_outlined;
  if (key.contains('spark') || key.contains('plug')) return Icons.bolt_outlined;
  if (key.contains('timing')) return Icons.timelapse;
  if (key.contains('inspect')) return Icons.manage_search_outlined;
  return Icons.build_outlined;
}

IconData workCategoryIcon(String category) => switch (category) {
  'inspection' => Icons.manage_search_outlined,
  'parts' => Icons.settings_outlined,
  'maintenance_repair' => Icons.car_repair_outlined,
  _ => Icons.category_outlined,
};

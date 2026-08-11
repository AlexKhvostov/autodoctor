import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/automotive_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../vehicle.dart';
import '../vehicle_controller.dart';

Future<String?> showVehiclePassportSheet(
  BuildContext context, {
  required Vehicle vehicle,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => _VehiclePassportSheet(vehicleId: vehicle.id),
  );
}

class _VehiclePassportSheet extends ConsumerStatefulWidget {
  const _VehiclePassportSheet({required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<_VehiclePassportSheet> createState() =>
      _VehiclePassportSheetState();
}

class _VehiclePassportSheetState extends ConsumerState<_VehiclePassportSheet> {
  var _editing = false;
  late VehicleDraft _draft;
  String? _error;

  @override
  void initState() {
    super.initState();
    final vehicle = _vehicle;
    _draft = vehicle?.toDraft() ?? const VehicleDraft();
  }

  Vehicle? get _vehicle => ref
      .read(vehicleSetupControllerProvider)
      .vehicles
      .where((item) => item.id == widget.vehicleId)
      .firstOrNull;

  void _syncDraftFromVehicle() {
    final vehicle = _vehicle;
    if (vehicle == null) return;
    _draft = vehicle.toDraft();
  }

  Future<void> _save() async {
    if (!_draft.isComplete) {
      setState(() => _error = context.l10n.selectValueValidation);
      return;
    }
    setState(() => _error = null);
    final updated = await ref
        .read(vehicleSetupControllerProvider.notifier)
        .updateVehicle(widget.vehicleId, _draft);
    if (!mounted) return;
    if (updated == null) {
      final failure = ref.read(vehicleSetupControllerProvider).failure;
      setState(() {
        _error = failure?.safeMessage.isNotEmpty == true
            ? failure!.safeMessage
            : context.l10n.unexpectedResponse;
      });
      return;
    }
    setState(() {
      _editing = false;
      _draft = updated.toDraft();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleSetupControllerProvider);
    final vehicle =
        state.vehicles.where((item) => item.id == widget.vehicleId).firstOrNull;
    if (vehicle == null) {
      return const SizedBox(height: 120, child: Center(child: Text('—')));
    }

    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TechnicalLabel(l10n.vehiclePassport),
                    Text(
                      '${vehicle.make} ${vehicle.model}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_editing)
                TextButton(
                  onPressed: () => setState(() {
                    _syncDraftFromVehicle();
                    _editing = true;
                    _error = null;
                  }),
                  child: Text(l10n.editVehicle),
                )
              else
                TextButton(
                  onPressed: state.submitting
                      ? null
                      : () => setState(() {
                          _editing = false;
                          _syncDraftFromVehicle();
                          _error = null;
                        }),
                  child: Text(l10n.cancel),
                ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                if (!_editing)
                  _PassportSection(
                    title: l10n.passportSections,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _sectionChip(
                          icon: Icons.route_outlined,
                          label: l10n.navPlan,
                          onTap: () => Navigator.pop(context, '/roadmap'),
                        ),
                        _sectionChip(
                          icon: Icons.monitor_heart_outlined,
                          label: l10n.navState,
                          onTap: () => Navigator.pop(context, '/state'),
                        ),
                        _sectionChip(
                          icon: Icons.menu_book_outlined,
                          label: l10n.navJournal,
                          onTap: () => Navigator.pop(context, '/journal'),
                        ),
                        _sectionChip(
                          icon: Icons.insights_outlined,
                          label: l10n.navAnalytics,
                          onTap: () => Navigator.pop(context, '/analytics'),
                        ),
                        _sectionChip(
                          icon: Icons.auto_awesome_outlined,
                          label: l10n.navAssistant,
                          onTap: () => Navigator.pop(context, '/assistant'),
                        ),
                      ],
                    ),
                  ),
                if (_editing) ...[
                  _PassportSection(
                    title: l10n.passportIdentity,
                    child: Column(
                      children: [
                        _editField(
                          label: l10n.vehicleMake,
                          value: _draft.make,
                          onChanged: (v) =>
                              setState(() => _draft = _draft.copyWith(make: v)),
                        ),
                        _editField(
                          label: l10n.vehicleModel,
                          value: _draft.model,
                          onChanged: (v) =>
                              setState(() => _draft = _draft.copyWith(model: v)),
                        ),
                        _editField(
                          label: l10n.productionYear,
                          value: _draft.productionYear?.toString() ?? '',
                          keyboard: TextInputType.number,
                          onChanged: (v) => setState(
                            () => _draft = _draft.copyWith(
                              productionYear: int.tryParse(v),
                            ),
                          ),
                        ),
                        _editField(
                          label: l10n.generation,
                          value: _draft.generation,
                          onChanged: (v) => setState(
                            () => _draft = _draft.copyWith(generation: v),
                          ),
                        ),
                        _editField(
                          label: l10n.vin,
                          value: _draft.vin,
                          hint: vehicle.vinMasked,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-HJ-NPR-Z0-9]', caseSensitive: false),
                            ),
                            LengthLimitingTextInputFormatter(17),
                            _UpperCaseFormatter(),
                          ],
                          onChanged: (v) =>
                              setState(() => _draft = _draft.copyWith(vin: v)),
                        ),
                      ],
                    ),
                  ),
                  _PassportSection(
                    title: l10n.passportPowertrain,
                    child: Column(
                      children: [
                        _dropdown<VehicleFuelType>(
                          label: l10n.fuelType,
                          value: _draft.fuelType,
                          values: VehicleFuelType.values,
                          labelOf: (v) => _fuelLabel(v, l10n),
                          onChanged: (v) => setState(
                            () => _draft = _draft.copyWith(fuelType: v),
                          ),
                        ),
                        if (_draft.fuelType != VehicleFuelType.electric)
                          _editField(
                            label: l10n.engineDisplacement,
                            value: _draft.engineDisplacementCc?.toString() ?? '',
                            keyboard: TextInputType.number,
                            onChanged: (v) => setState(
                              () => _draft = _draft.copyWith(
                                engineDisplacementCc: int.tryParse(v),
                              ),
                            ),
                          ),
                        _editField(
                          label: l10n.engineCode,
                          value: _draft.engineCode,
                          onChanged: (v) => setState(
                            () => _draft = _draft.copyWith(engineCode: v),
                          ),
                        ),
                        _editField(
                          label: l10n.powerKw,
                          value: _draft.powerKw?.toString() ?? '',
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (v) => setState(
                            () => _draft = _draft.copyWith(
                              powerKw: double.tryParse(v.replaceAll(',', '.')),
                            ),
                          ),
                        ),
                        _dropdown<VehicleTransmissionType>(
                          label: l10n.transmissionType,
                          value: _draft.transmissionType ==
                                      VehicleTransmissionType.manual ||
                                  _draft.transmissionType ==
                                      VehicleTransmissionType.automatic
                              ? _draft.transmissionType
                              : null,
                          values: const [
                            VehicleTransmissionType.manual,
                            VehicleTransmissionType.automatic,
                          ],
                          labelOf: (v) => _transmissionLabel(v, l10n),
                          onChanged: (v) => setState(
                            () => _draft = _draft.copyWith(transmissionType: v),
                          ),
                        ),
                        _editField(
                          label: l10n.transmissionGears,
                          value: _draft.transmissionGears?.toString() ?? '',
                          keyboard: TextInputType.number,
                          onChanged: (v) => setState(
                            () => _draft = _draft.copyWith(
                              transmissionGears: int.tryParse(v),
                            ),
                          ),
                        ),
                        _dropdown<VehicleDrivetrain>(
                          label: l10n.drivetrain,
                          value: _draft.drivetrain,
                          values: VehicleDrivetrain.values,
                          labelOf: (v) => _drivetrainLabel(v, l10n),
                          onChanged: (v) => setState(
                            () => _draft = _draft.copyWith(drivetrain: v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PassportSection(
                    title: l10n.passportUsage,
                    child: Column(
                      children: [
                        _kv(
                          l10n.mileageKm,
                          vehicle.mileage == null
                              ? l10n.notSpecified
                              : '${vehicle.mileage} ${vehicle.mileageUnit ?? 'km'}',
                        ),
                        _editField(
                          label: l10n.market,
                          value: _draft.market,
                          onChanged: (v) => setState(
                            () => _draft = _draft.copyWith(market: v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  _PassportSection(
                    title: l10n.passportIdentity,
                    child: Column(
                      children: [
                        _kv(l10n.vehicleMake, vehicle.make),
                        _kv(l10n.vehicleModel, vehicle.model),
                        _kv(l10n.productionYear, '${vehicle.productionYear}'),
                        _kv(
                          l10n.generation,
                          vehicle.generation?.trim().isNotEmpty == true
                              ? vehicle.generation!
                              : l10n.notSpecified,
                        ),
                        _kv(
                          l10n.vin,
                          vehicle.vinMasked?.trim().isNotEmpty == true
                              ? vehicle.vinMasked!
                              : l10n.notSpecified,
                        ),
                      ],
                    ),
                  ),
                  _PassportSection(
                    title: l10n.passportPowertrain,
                    child: Column(
                      children: [
                        _kv(l10n.fuelType, _fuelString(vehicle.fuelType, l10n)),
                        _kv(
                          l10n.engineDisplacement,
                          vehicle.engineDisplacementCc == null
                              ? l10n.notSpecified
                              : '${vehicle.engineDisplacementCc} cm³',
                        ),
                        _kv(
                          l10n.engineCode,
                          vehicle.engineCode?.trim().isNotEmpty == true
                              ? vehicle.engineCode!
                              : l10n.notSpecified,
                        ),
                        _kv(
                          l10n.powerKw,
                          vehicle.powerKw == null
                              ? l10n.notSpecified
                              : '${vehicle.powerKw}',
                        ),
                        _kv(
                          l10n.transmissionType,
                          _transmissionString(vehicle.transmissionType, l10n),
                        ),
                        _kv(
                          l10n.transmissionGears,
                          vehicle.transmissionGears?.toString() ??
                              l10n.notSpecified,
                        ),
                        _kv(
                          l10n.drivetrain,
                          _drivetrainString(vehicle.drivetrain, l10n),
                        ),
                      ],
                    ),
                  ),
                  _PassportSection(
                    title: l10n.passportUsage,
                    child: Column(
                      children: [
                        _kv(
                          l10n.mileageKm,
                          vehicle.mileage == null
                              ? l10n.notSpecified
                              : '${vehicle.mileage} ${vehicle.mileageUnit ?? 'km'}',
                        ),
                        _kv(
                          l10n.firstUseDate,
                          vehicle.firstUseDate == null
                              ? l10n.notSpecified
                              : _formatDate(vehicle.firstUseDate!),
                        ),
                        _kv(
                          l10n.market,
                          vehicle.market?.trim().isNotEmpty == true
                              ? vehicle.market!
                              : l10n.notSpecified,
                        ),
                      ],
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: colors.error),
                  ),
                ],
              ],
            ),
          ),
          if (_editing) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: state.submitting ? null : _save,
              child: state.submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _kv(String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    String? hint,
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> values,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final item in values)
            DropdownMenuItem(value: item, child: Text(labelOf(item))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _PassportSection extends StatelessWidget {
  const _PassportSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AutomotivePanel(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _fuelLabel(VehicleFuelType value, AppLocalizations l10n) =>
    switch (value) {
      VehicleFuelType.petrol => l10n.fuelPetrol,
      VehicleFuelType.diesel => l10n.fuelDiesel,
      VehicleFuelType.hybrid => l10n.fuelHybrid,
      VehicleFuelType.electric => l10n.fuelElectric,
      VehicleFuelType.lpg => l10n.fuelLpg,
      VehicleFuelType.other => l10n.other,
    };

String _transmissionLabel(
  VehicleTransmissionType value,
  AppLocalizations l10n,
) => switch (value) {
  VehicleTransmissionType.manual => l10n.transmissionManual,
  VehicleTransmissionType.automatic => l10n.transmissionAutomatic,
  VehicleTransmissionType.cvt => l10n.transmissionCvt,
  VehicleTransmissionType.robotized => l10n.transmissionRobotized,
  VehicleTransmissionType.other => l10n.other,
};

String _drivetrainLabel(VehicleDrivetrain value, AppLocalizations l10n) =>
    switch (value) {
      VehicleDrivetrain.fwd => l10n.drivetrainFwd,
      VehicleDrivetrain.rwd => l10n.drivetrainRwd,
      VehicleDrivetrain.awd => l10n.drivetrainAwd,
      VehicleDrivetrain.fourWd => l10n.drivetrainFourWd,
      VehicleDrivetrain.other => l10n.other,
    };

String _fuelString(String value, AppLocalizations l10n) {
  final match = VehicleFuelType.values
      .where((item) => item.name == value)
      .firstOrNull;
  return match == null ? value : _fuelLabel(match, l10n);
}

String _transmissionString(String? value, AppLocalizations l10n) {
  if (value == null || value.isEmpty) return l10n.notSpecified;
  final match = VehicleTransmissionType.values
      .where((item) => item.name == value)
      .firstOrNull;
  return match == null ? value : _transmissionLabel(match, l10n);
}

String _drivetrainString(String? value, AppLocalizations l10n) {
  if (value == null || value.isEmpty) return l10n.notSpecified;
  final normalized = value == 'four_wd' ? 'fourWd' : value;
  final match = VehicleDrivetrain.values
      .where((item) => item.name == normalized || item.name == value)
      .firstOrNull;
  if (value == 'four_wd') return l10n.drivetrainFourWd;
  return match == null ? value : _drivetrainLabel(match, l10n);
}

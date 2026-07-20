import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/automotive_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../guest_bootstrap/guest_bootstrap_controller.dart';
import '../vehicle.dart';
import '../vehicle_catalog.dart';
import '../vehicle_controller.dart';

const _otherModelValue = '__other_model__';

class VinEntryScreen extends ConsumerStatefulWidget {
  const VinEntryScreen({super.key});

  @override
  ConsumerState<VinEntryScreen> createState() => _VinEntryScreenState();
}

class _VinEntryScreenState extends ConsumerState<VinEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  bool _more = false;
  VehicleMakeOption? _make;
  String? _model;
  int? _year;
  VehicleFuelType? _fuel;
  VehicleTransmissionType? _transmission;
  VehicleDrivetrain? _drivetrain;
  DateTime? _firstUseDate;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      final token = await ref.read(sessionTokenStoreProvider).read();
      if ((token == null || token.isEmpty) && mounted) {
        context.go('/garage/add');
      }
    });
    final draft = ref.read(vehicleSetupControllerProvider).draft;
    final catalog = ref.read(vehicleCatalogProvider);
    _make = catalog.findMake(draft.make);
    if (_make == null && draft.make.isNotEmpty) {
      _make = catalog.makes.last;
    }
    if (_make != null && !_make!.isOther) {
      _model = _make!.models.contains(draft.model)
          ? draft.model
          : draft.model.isEmpty
          ? null
          : _otherModelValue;
    }
    _year =
        draft.productionYear != null &&
            draft.productionYear! >= 1980 &&
            draft.productionYear! <= DateTime.now().year
        ? draft.productionYear
        : null;
    _fuel = draft.fuelType;
    _transmission = draft.transmissionType;
    _drivetrain = draft.drivetrain;
    _firstUseDate = draft.firstUseDate;
    _more =
        draft.generation.isNotEmpty ||
        draft.engineCode.isNotEmpty ||
        draft.powerKw != null ||
        draft.drivetrain != null ||
        draft.market.isNotEmpty ||
        draft.firstUseDate != null;
    _fields = {
      'vin': TextEditingController(text: draft.vin),
      'manualMake': TextEditingController(
        text: _make?.isOther == true ? draft.make : '',
      ),
      'manualModel': TextEditingController(
        text: _make?.isOther == true || _model == _otherModelValue
            ? draft.model
            : '',
      ),
      'mileage': TextEditingController(text: draft.mileage?.toString()),
      'displacement': TextEditingController(
        text: draft.engineDisplacementCc?.toString(),
      ),
      'generation': TextEditingController(text: draft.generation),
      'engineCode': TextEditingController(text: draft.engineCode),
      'power': TextEditingController(text: draft.powerKw?.toString()),
      'market': TextEditingController(text: draft.market),
    };
    for (final controller in _fields.values) {
      controller.addListener(_refreshCompletionState);
    }
  }

  void _refreshCompletionState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _needsDisplacement =>
      _fuel != null && _fuel != VehicleFuelType.electric;

  VehicleDraft _draft() {
    final catalog = ref.read(vehicleCatalogProvider);
    final make = _make?.isOther == true
        ? catalog.normalizeManualValue(_fields['manualMake']!.text)
        : _make?.apiValue ?? '';
    final model = _make?.isOther == true || _model == _otherModelValue
        ? catalog.normalizeManualValue(_fields['manualModel']!.text)
        : _model ?? '';
    return VehicleDraft(
      vin: _fields['vin']!.text.toUpperCase(),
      make: make,
      model: model,
      generation: _fields['generation']!.text,
      productionYear: _year,
      mileage: int.tryParse(_fields['mileage']!.text),
      fuelType: _fuel,
      engineDisplacementCc: _fuel == VehicleFuelType.electric
          ? null
          : int.tryParse(_fields['displacement']!.text),
      engineCode: _fields['engineCode']!.text,
      powerKw: double.tryParse(_fields['power']!.text.replaceAll(',', '.')),
      transmissionType: _transmission,
      transmissionGears: null,
      drivetrain: _drivetrain,
      market: _fields['market']!.text,
      firstUseDate: _firstUseDate,
    );
  }

  void _save() =>
      ref.read(vehicleSetupControllerProvider.notifier).updateDraft(_draft());

  void _continue() {
    _save();
    if (_formKey.currentState!.validate() && _draft().isComplete) {
      context.go('/garage/add/confirm');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = ref.watch(vehicleCatalogProvider);
    final years = [
      for (var year = DateTime.now().year; year >= 1980; year--) year,
    ];
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FlowHeader(
              label: l10n.vehicleDetailsStep,
              title: l10n.vehicleDetails,
              backKey: const Key('vin-back'),
              onBack: () {
                _save();
                context.go('/garage/add');
              },
            ),
            const SizedBox(height: 12),
            AutomotivePanel(
              emphasized: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dropdown<VehicleMakeOption>(
                    key: const Key('vehicle-make-select'),
                    label: l10n.vehicleMake,
                    value: _make,
                    values: catalog.makes,
                    title: (value) =>
                        value.isOther ? l10n.other : value.apiValue!,
                    onChanged: (value) {
                      _fields['manualMake']!.clear();
                      _fields['manualModel']!.clear();
                      setState(() {
                        _make = value;
                        _model = null;
                      });
                    },
                  ),
                  if (_make?.isOther == true)
                    _text(
                      'manualMake',
                      l10n.vehicleMakeOther,
                      key: const Key('vehicle-make-other-input'),
                      validator: _required100,
                    ),
                  if (_make != null && !_make!.isOther)
                    _dropdown<String>(
                      key: const Key('vehicle-model-select'),
                      label: l10n.vehicleModel,
                      value: _model,
                      values: [..._make!.models, _otherModelValue],
                      title: (value) =>
                          value == _otherModelValue ? l10n.otherModel : value,
                      onChanged: (value) {
                        _fields['manualModel']!.clear();
                        setState(() {
                          _model = value;
                        });
                      },
                    ),
                  if (_make?.isOther == true || _model == _otherModelValue)
                    _text(
                      'manualModel',
                      l10n.vehicleModelOther,
                      key: const Key('vehicle-model-other-input'),
                      validator: _required100,
                    ),
                  _dropdown<int>(
                    key: const Key('vehicle-year-select'),
                    label: l10n.productionYear,
                    value: _year,
                    values: years,
                    title: (value) => '$value',
                    onChanged: (value) => setState(() => _year = value),
                  ),
                  _dropdown<VehicleFuelType>(
                    key: const Key('vehicle-fuel-select'),
                    label: l10n.fuelType,
                    value: _fuel,
                    values: VehicleFuelType.values,
                    title: (value) => _fuelLabel(value, l10n),
                    onChanged: (value) => setState(() => _fuel = value),
                  ),
                  if (_fuel != VehicleFuelType.electric)
                    _text(
                      'displacement',
                      l10n.engineDisplacement,
                      key: const Key('vehicle-engine-displacement-input'),
                      number: true,
                      validator: (value) {
                        if (!_needsDisplacement && (value ?? '').isEmpty) {
                          return null;
                        }
                        final amount = int.tryParse(value ?? '');
                        return amount != null && amount >= 1 && amount <= 20000
                            ? null
                            : l10n.displacementValidation;
                      },
                    ),
                  _dropdown<VehicleTransmissionType>(
                    key: const Key('vehicle-transmission-select'),
                    label: '${l10n.transmissionType} (${l10n.optional})',
                    value: _transmission,
                    values: const [
                      VehicleTransmissionType.manual,
                      VehicleTransmissionType.automatic,
                    ],
                    title: (value) => _transmissionLabel(value, l10n),
                    onChanged: (value) => setState(() => _transmission = value),
                    required: false,
                  ),
                  _text(
                    'mileage',
                    '${l10n.mileageKm} (${l10n.optional})',
                    key: const Key('vehicle-mileage-input'),
                    number: true,
                    validator: (value) {
                      if ((value ?? '').isEmpty) return null;
                      final mileage = int.tryParse(value!);
                      return mileage != null && mileage >= 0
                          ? null
                          : l10n.nonNegativeValidation;
                    },
                  ),
                  _text(
                    'vin',
                    '${l10n.vin} (${l10n.optional})',
                    key: const Key('vin-input'),
                    maxLength: 17,
                    helperText: l10n.vinOptionalHelper,
                    capitalization: TextCapitalization.characters,
                    formatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-HJ-NPR-Za-hj-npr-z0-9]'),
                      ),
                      _UpperCaseFormatter(),
                    ],
                    validator: (value) {
                      if ((value ?? '').isEmpty) return null;
                      return RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(value!)
                          ? null
                          : l10n.vinValidation;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ExpansionTile(
              key: const Key('vehicle-more-details'),
              initiallyExpanded: _more,
              title: Text('${l10n.moreVehicleDetails} (${l10n.optional})'),
              subtitle: Text(l10n.optionalDetailsAccuracy),
              onExpansionChanged: (value) => _more = value,
              children: [
                _text('generation', l10n.generation, validator: _optional100),
                _text('engineCode', l10n.engineCode, validator: _optional100),
                _text(
                  'power',
                  l10n.powerKw,
                  decimal: true,
                  validator: (value) {
                    if ((value ?? '').isEmpty) return null;
                    final power = double.tryParse(value!.replaceAll(',', '.'));
                    return power != null && power > 0 && power <= 2000
                        ? null
                        : l10n.powerValidation;
                  },
                ),
                _dropdown<VehicleDrivetrain>(
                  label: l10n.drivetrain,
                  value: _drivetrain,
                  values: VehicleDrivetrain.values,
                  title: (value) => _drivetrainLabel(value, l10n),
                  onChanged: (value) => setState(() => _drivetrain = value),
                  required: false,
                ),
                _text('market', l10n.market, validator: _optional100),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.firstUseDate),
                  subtitle: Text(
                    _firstUseDate == null
                        ? l10n.notSpecified
                        : DateFormat.yMMMd(
                            Localizations.localeOf(context).toLanguageTag(),
                          ).format(_firstUseDate!),
                  ),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _firstUseDate ?? DateTime.now(),
                      firstDate: DateTime(1886),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _firstUseDate = date);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('vehicle-continue'),
              onPressed: _draft().isComplete ? _continue : null,
              icon: const Icon(Icons.arrow_forward),
              label: Text(l10n.reviewVehicle),
            ),
          ],
        ),
      ),
    );
  }

  String? _required100(String? value) {
    final text = value?.trim() ?? '';
    return text.isNotEmpty && text.length <= 100
        ? null
        : context.l10n.requiredTextValidation;
  }

  String? _optional100(String? value) =>
      (value?.trim().length ?? 0) <= 100 ? null : context.l10n.max100Validation;

  Widget _text(
    String name,
    String label, {
    Key? key,
    bool number = false,
    bool decimal = false,
    int? maxLength,
    String? helperText,
    TextCapitalization capitalization = TextCapitalization.sentences,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      key: key,
      controller: _fields[name],
      maxLength: maxLength,
      textCapitalization: capitalization,
      keyboardType: number
          ? TextInputType.number
          : decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters:
          formatters ??
          (number ? [FilteringTextInputFormatter.digitsOnly] : null),
      decoration: InputDecoration(labelText: label, helperText: helperText),
      validator: validator,
      onChanged: (_) => _save(),
    ),
  );

  Widget _dropdown<T>({
    Key? key,
    required String label,
    required T? value,
    required List<T> values,
    required String Function(T) title,
    required ValueChanged<T?> onChanged,
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<T>(
      key: key,
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (!required)
          DropdownMenuItem<T>(
            value: null,
            child: Text(
              context.l10n.notSpecified,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        for (final item in values)
          DropdownMenuItem(
            value: item,
            child: Text(
              title(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) {
        onChanged(value);
        _save();
      },
      validator: required
          ? (selected) =>
                selected == null ? context.l10n.selectValueValidation : null
          : null,
    ),
  );
}

class VehicleConfirmScreen extends ConsumerWidget {
  const VehicleConfirmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehicleSetupControllerProvider);
    final draft = state.draft;
    if (!draft.isComplete) {
      Future<void>.microtask(() {
        if (context.mounted) context.go('/garage/add/vin');
      });
      return const SizedBox.shrink();
    }
    final rows = <(String, String)>[
      (context.l10n.vehicleMake, draft.make),
      (context.l10n.vehicleModel, draft.model),
      (context.l10n.productionYear, '${draft.productionYear}'),
      (context.l10n.fuelType, _fuelLabel(draft.fuelType!, context.l10n)),
      if (draft.engineDisplacementCc != null)
        (context.l10n.engineDisplacement, '${draft.engineDisplacementCc}'),
      (
        context.l10n.transmissionType,
        draft.transmissionType == null
            ? context.l10n.notSpecified
            : _transmissionLabel(draft.transmissionType!, context.l10n),
      ),
      (
        context.l10n.mileageKm,
        draft.mileage == null ? context.l10n.notSpecified : '${draft.mileage}',
      ),
      (
        context.l10n.vin,
        draft.vin.isEmpty
            ? context.l10n.notSpecified
            : '${draft.vin.substring(0, 3)}**********${draft.vin.substring(13)}',
      ),
    ];
    final additionalRows = <(String, String)>[
      (
        context.l10n.generation,
        draft.generation.isEmpty ? context.l10n.notSpecified : draft.generation,
      ),
      (
        context.l10n.engineCode,
        draft.engineCode.isEmpty ? context.l10n.notSpecified : draft.engineCode,
      ),
      (
        context.l10n.powerKw,
        draft.powerKw == null ? context.l10n.notSpecified : '${draft.powerKw}',
      ),
      (
        context.l10n.drivetrain,
        draft.drivetrain == null
            ? context.l10n.notSpecified
            : _drivetrainLabel(draft.drivetrain!, context.l10n),
      ),
      (
        context.l10n.market,
        draft.market.isEmpty ? context.l10n.notSpecified : draft.market,
      ),
      (
        context.l10n.firstUseDate,
        draft.firstUseDate == null
            ? context.l10n.notSpecified
            : DateFormat.yMMMd(
                Localizations.localeOf(context).toLanguageTag(),
              ).format(draft.firstUseDate!),
      ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FlowHeader(
            label: context.l10n.confirmVehicleStep,
            title: context.l10n.confirmVehicleTitle,
            onBack: () => context.go('/garage/add/vin'),
          ),
          const SizedBox(height: 12),
          AutomotivePanel(
            emphasized: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ConfirmSection(
                  title: context.l10n.vehicleIdentitySection,
                  rows: rows,
                ),
                _ConfirmSection(
                  title: context.l10n.vehicleAdditionalSection,
                  rows: additionalRows,
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(context.l10n.dataSource),
                  subtitle: Text(context.l10n.dataSourceUser),
                ),
              ],
            ),
          ),
          if (state.failure != null) ...[
            const SizedBox(height: 10),
            AutomotivePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    state.failure!.safeMessage.isNotEmpty
                        ? state.failure!.safeMessage
                        : context.l10n.vehicleCreateError,
                  ),
                  if (state.failure!.requestId != null)
                    SelectableText(
                      context.l10n.requestIdLabel(state.failure!.requestId!),
                    ),
                  if (state.failure!.statusCode == 409 ||
                      state.failure!.statusCode == 422)
                    Text(context.l10n.vehicleConflictHelp),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: state.submitting
                ? null
                : () => context.go('/garage/add/vin'),
            icon: const Icon(Icons.edit_outlined),
            label: Text(context.l10n.editVehicle),
          ),
          FilledButton.icon(
            key: const Key('confirm-vehicle'),
            onPressed: state.submitting
                ? null
                : () async {
                    final vehicle = await ref
                        .read(vehicleSetupControllerProvider.notifier)
                        .create();
                    if (vehicle != null && context.mounted) {
                      context.go('/plan/first');
                    }
                  },
            icon: state.submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(
              state.failure == null
                  ? context.l10n.createVehicle
                  : context.l10n.retry,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmSection extends StatelessWidget {
  const _ConfirmSection({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TechnicalLabel(title),
      for (final row in rows)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(row.$1),
          subtitle: Text(row.$2),
        ),
      const Divider(),
    ],
  );
}

class LegacyFirstPlanScreen extends ConsumerWidget {
  const LegacyFirstPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehicleSetupControllerProvider);
    final vehicle = state.activeVehicle;
    if (vehicle == null) {
      if (state.stage == VehicleLoadStage.idle) {
        Future<void>.microtask(
          () => ref.read(vehicleSetupControllerProvider.notifier).load(),
        );
      }
      if (state.stage == VehicleLoadStage.ready ||
          state.stage == VehicleLoadStage.error) {
        Future<void>.microtask(() {
          if (context.mounted) context.go('/garage/add');
        });
      }
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FlowHeader(
            label: context.l10n.firstPlanStep,
            title: context.l10n.firstPlanTitle,
            onBack: () => context.go('/garage/add/confirm'),
          ),
          const SizedBox(height: 20),
          AutomotivePanel(
            emphasized: true,
            child: Column(
              children: [
                const Icon(Icons.hourglass_top, size: 44),
                const SizedBox(height: 12),
                Text(
                  context.l10n.firstPlanPreparing(vehicle.make, vehicle.model),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.firstPlanHonestStatus,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('first-plan-continue'),
            onPressed: () => context.go('/roadmap'),
            icon: const Icon(Icons.route_outlined),
            label: Text(context.l10n.openPlan),
          ),
        ],
      ),
    );
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.label,
    required this.title,
    required this.onBack,
    this.backKey,
  });

  final String label;
  final String title;
  final VoidCallback onBack;
  final Key? backKey;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        key: backKey,
        tooltip: context.l10n.back,
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TechnicalLabel(label),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    ],
  );
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

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

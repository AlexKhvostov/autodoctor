import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/locale_controller.dart';
import '../../../l10n/l10n.dart';
import '../../vehicle/vehicle_controller.dart';
import '../maintenance.dart';
import '../maintenance_controller.dart';

class ServiceRecordScreen extends ConsumerStatefulWidget {
  const ServiceRecordScreen({this.workCode, super.key});

  final String? workCode;

  @override
  ConsumerState<ServiceRecordScreen> createState() =>
      _ServiceRecordScreenState();
}

class _ServiceRecordScreenState extends ConsumerState<ServiceRecordScreen> {
  late DateTime _date = DateTime.now();
  late final TextEditingController _mileage;
  final _note = TextEditingController();
  MaintenanceFailure? _failure;
  bool _saving = false;
  String? _workCode;
  String? _requestedPlanKey;

  @override
  void initState() {
    super.initState();
    final vehicle = ref.read(vehicleSetupControllerProvider).activeVehicle;
    _mileage = TextEditingController(text: vehicle?.mileage?.toString() ?? '');
    _workCode = widget.workCode?.trim().isEmpty == true
        ? null
        : widget.workCode;
  }

  @override
  void dispose() {
    _mileage.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final vehicle = ref.read(vehicleSetupControllerProvider).activeVehicle;
    if (vehicle == null || _saving || _workCode == null) return;
    final mileage = _mileage.text.trim().isEmpty
        ? null
        : int.tryParse(_mileage.text.trim());
    if (_mileage.text.trim().isNotEmpty && mileage == null) {
      setState(
        () => _failure = const MaintenanceFailure(code: 'VALIDATION_FAILED'),
      );
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      await ref
          .read(maintenanceControllerProvider.notifier)
          .createServiceRecord(
            vehicle.id,
            locale: ref.read(activeLocaleProvider).languageCode,
            record: ServiceRecordWrite(
              serviceDate: _date,
              workCode: _workCode!,
              mileage: mileage,
              mileageUnit: vehicle.mileageUnit ?? 'km',
              note: _note.text,
            ),
          );
      await ref.read(vehicleSetupControllerProvider.notifier).load(force: true);
      if (mounted) context.pop(true);
    } on MaintenanceFailure catch (failure) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failure = failure;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(vehicleSetupControllerProvider).activeVehicle;
    final locale = ref.watch(activeLocaleProvider).languageCode;
    final maintenanceState = ref.watch(maintenanceControllerProvider);
    if (vehicle != null) {
      final key = '${vehicle.id}:$locale';
      if (_requestedPlanKey != key &&
          (!maintenanceState.matches(vehicle.id, locale) ||
              maintenanceState.plan == null)) {
        _requestedPlanKey = key;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(maintenanceControllerProvider.notifier)
                .ensurePlan(vehicle.id, locale: locale);
          }
        });
      }
    }
    final plan = maintenanceState.matches(vehicle?.id ?? '', locale)
        ? maintenanceState.plan
        : null;
    final applicable =
        plan?.items
            .where(
              (item) =>
                  item.status != MaintenanceStatus.notApplicable &&
                  item.status != MaintenanceStatus.completed,
            )
            .toList() ??
        const <MaintenanceItem>[];
    final title =
        plan?.items
            .where((item) => item.workCode == _workCode)
            .firstOrNull
            ?.title ??
        (_workCode?.replaceAll('_', ' ') ?? context.l10n.selectServiceWork);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.addServiceRecord)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(context.l10n.serviceRecordFactHint),
            if (widget.workCode == null ||
                widget.workCode?.trim().isEmpty == true) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('service-work-selector'),
                initialValue: _workCode,
                decoration: InputDecoration(
                  labelText: context.l10n.selectServiceWork,
                  helperText: context.l10n.selectServiceWorkHint,
                ),
                items: [
                  for (final item in applicable)
                    DropdownMenuItem(
                      value: item.workCode,
                      child: Text(item.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _workCode = value),
              ),
            ],
            const SizedBox(height: 16),
            ListTile(
              key: const Key('service-date'),
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.serviceDate),
              subtitle: Text(_formatDate(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _saving ? null : _pickDate,
            ),
            TextFormField(
              key: const Key('service-mileage'),
              controller: _mileage,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText:
                    '${context.l10n.serviceMileage}, ${vehicle?.mileageUnit ?? 'km'}',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('service-note'),
              controller: _note,
              enabled: !_saving,
              maxLength: 4000,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: context.l10n.serviceNote),
            ),
            if (_failure != null) ...[
              Text(
                _failure!.safeMessage.isNotEmpty
                    ? _failure!.safeMessage
                    : context.l10n.serviceSaveError,
                key: const Key('service-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              if (_failure!.requestId != null)
                SelectableText(
                  context.l10n.requestIdLabel(_failure!.requestId!),
                ),
              const SizedBox(height: 8),
            ],
            FilledButton.icon(
              key: const Key('service-save'),
              onPressed: _saving || _workCode == null ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _failure == null ? context.l10n.save : context.l10n.retry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')}.${value.year}';

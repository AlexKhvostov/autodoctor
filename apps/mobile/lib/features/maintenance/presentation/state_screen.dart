import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/automotive_widgets.dart';
import '../../../core/widgets/preview_widgets.dart';
import '../../../l10n/l10n.dart';
import '../../vehicle/vehicle.dart';
import '../../vehicle/vehicle_controller.dart';
import '../maintenance.dart';
import '../maintenance_controller.dart';

class StateScreen extends ConsumerStatefulWidget {
  const StateScreen({super.key});

  @override
  ConsumerState<StateScreen> createState() => _StateScreenState();
}

class _StateScreenState extends ConsumerState<StateScreen> {
  String? _requestedKey;

  void _ensure(String vehicleId, String locale) {
    final key = '$vehicleId:$locale';
    if (_requestedKey == key) return;
    _requestedKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(maintenanceControllerProvider.notifier)
          .ensureRoadmap(vehicleId, locale: locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(vehicleSetupControllerProvider).activeVehicle;
    final locale = ref.watch(activeLocaleProvider).languageCode;
    if (vehicle != null) {
      _ensure(vehicle.id, locale);
    } else {
      _requestedKey = null;
    }
    final state = ref.watch(maintenanceControllerProvider);
    final matches = vehicle != null && state.matches(vehicle.id, locale);
    final stage = matches ? state.roadmapStage : MaintenanceLoadStage.idle;
    final tiles = matches && state.consumables != null
        ? sortStateTiles(state.consumables!.items)
        : const <Consumable>[];

    if (vehicle == null) {
      return const _StatePreview();
    }

    if (stage == MaintenanceLoadStage.loading ||
        stage == MaintenanceLoadStage.idle) {
      return const Center(
        key: Key('state-loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (stage == MaintenanceLoadStage.error) {
      return Center(
        child: AutomotivePanel(
          emphasized: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.planLoadError),
              FilledButton(
                key: const Key('state-retry'),
                onPressed: () {
                  _requestedKey = null;
                  _ensure(vehicle.id, locale);
                },
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.stateTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.stateSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: tiles.isEmpty
                ? Text(context.l10n.stateEmpty)
                : GridView.builder(
                    key: const Key('state-tiles-grid'),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.55,
                        ),
                    itemCount: tiles.length,
                    itemBuilder: (context, index) {
                      final item = tiles[index];
                      return _StateTile(
                        item: item,
                        onTap: () => showStateDetailSheet(
                          context: context,
                          ref: ref,
                          vehicle: vehicle,
                          item: item,
                          forecast: state.mileageForecast,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StateMetric {
  const _StateMetric({
    required this.status,
    required this.color,
    this.progress,
    this.caption,
  });

  final String status;
  final Color color;
  final double? progress;
  final String? caption;
}

_StateMetric _metricFor(BuildContext context, Consumable item) {
  final colors = Theme.of(context).colorScheme;
  final automotive =
      Theme.of(context).extension<AutomotiveColors>() ?? AutomotiveColors.dark;
  final wear = item.latestObservation;
  final workCode = item.workCode.isEmpty
      ? item.id.replaceAll('-', '_')
      : item.workCode;
  final isWear = supportsWearMeasurement(workCode);
  final isInterval = item.kind == ConsumableKind.intervalBased;
  final used = item.usedFraction?.clamp(0.0, 1.0);

  if (isWear && wear != null) {
    final color = wear.wearPercent >= 80
        ? colors.error
        : wear.wearPercent >= 60
        ? automotive.warning
        : automotive.success;
    return _StateMetric(
      status: context.l10n.stateWearRemaining(
        wear.wearPercent,
        wear.remainingPercent,
      ),
      color: color,
      progress: wear.wearPercent / 100,
      caption: context.l10n.stateWearCaption,
    );
  }
  if (isInterval) {
    if (used == null) {
      return _StateMetric(
        status: context.l10n.stateNeedsData,
        color: colors.onSurfaceVariant,
      );
    }
    final color = used >= 1
        ? colors.error
        : used >= 0.8
        ? automotive.warning
        : automotive.success;
    return _StateMetric(
      status: context.l10n.stateUsedPercent((used * 100).round()),
      color: color,
      progress: used,
      caption: item.effectiveTrigger == 'time'
          ? context.l10n.stateTriggerTime
          : item.effectiveTrigger == 'mileage'
          ? context.l10n.stateTriggerMileage
          : null,
    );
  }
  final needsCheck =
      item.requiresCheckNow ||
      item.inspectionState == InspectionState.checkRequired;
  return _StateMetric(
    status: needsCheck
        ? context.l10n.inspectionRequired
        : context.l10n.stateInspectionStatus,
    color: needsCheck ? automotive.warning : automotive.success,
  );
}

class _StateTile extends StatelessWidget {
  const _StateTile({required this.item, required this.onTap});

  final Consumable item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final metric = _metricFor(context, item);
    final lastService = item.historyState.performedDate;
    final scaleLabel =
        metric.caption ??
        (metric.progress == null
            ? null
            : context.l10n.stateScaleCaption);

    return Material(
      key: Key('consumable-${item.id}'),
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('state-tile-${item.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: metric.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _stateIcon(item),
                        size: 15,
                        color: metric.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                    ),
                    if (metric.progress != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${(metric.progress! * 100).round()}%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: metric.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    key: Key('state-bar-${item.id}'),
                    value: metric.progress ?? 0,
                    minHeight: 7,
                    color: metric.progress == null
                        ? colors.outlineVariant
                        : metric.color,
                    backgroundColor: colors.outlineVariant.withValues(
                      alpha: 0.55,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  scaleLabel ?? metric.status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: metric.progress == null
                        ? metric.color
                        : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lastService == null
                      ? context.l10n.stateLastServiceUnknownShort
                      : context.l10n.stateLastServiceShort(
                          _formatDate(lastService),
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showStateDetailSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Vehicle vehicle,
  required Consumable item,
  MileageForecast? forecast,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final inset = MediaQuery.viewInsetsOf(dialogContext);
      return Dialog(
        key: const Key('state-detail-dialog'),
        insetPadding: EdgeInsets.fromLTRB(16, 24, 16, 24 + inset.bottom),
        backgroundColor: Theme.of(dialogContext).colorScheme.surfaceContainer,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 440,
            maxHeight: size.height * 0.86,
          ),
          child: _StateDetailCard(
            vehicle: vehicle,
            item: item,
            forecast: forecast,
            onClose: () => Navigator.pop(dialogContext),
          ),
        ),
      );
    },
  );
}

class _StateDetailCard extends ConsumerStatefulWidget {
  const _StateDetailCard({
    required this.vehicle,
    required this.item,
    required this.onClose,
    this.forecast,
  });

  final Vehicle vehicle;
  final Consumable item;
  final MileageForecast? forecast;
  final VoidCallback onClose;

  @override
  ConsumerState<_StateDetailCard> createState() => _StateDetailCardState();
}

class _StateDetailCardState extends ConsumerState<_StateDetailCard> {
  late DateTime _date;
  late final TextEditingController _mileage;
  late final TextEditingController _wear;
  late final TextEditingController _note;
  late final TextEditingController _laborCost;
  late final TextEditingController _partsCost;
  final _scrollController = ScrollController();
  final _formSectionKey = GlobalKey();
  var _saving = false;
  String? _error;
  String? _editingRecordId;
  String? _editingObservationId;
  DateTime? _editingOriginalDate;

  Consumable get item => widget.item;
  Vehicle get vehicle => widget.vehicle;
  String get workCode => _workCode(item);
  bool get _isEditing => _editingRecordId != null;

  @override
  void initState() {
    super.initState();
    final canWear = supportsWearMeasurement(workCode);
    _mileage = TextEditingController();
    // New service for wear parts always starts at 0% (e.g. new tires/pads).
    _wear = TextEditingController(text: canWear ? '0' : '');
    _note = TextEditingController();
    _laborCost = TextEditingController();
    _partsCost = TextEditingController();
    _resetFormForCreate();
    _fillCreateDefaults();
  }

  void _resetFormForCreate() {
    _editingRecordId = null;
    _editingObservationId = null;
    _editingOriginalDate = null;
    _date = DateTime.now();
  }

  void _fillCreateDefaults() {
    _mileage.text = vehicle.mileage?.toString() ?? '';
    // Never prefill previous wear when adding a new record.
    _wear.text = supportsWearMeasurement(workCode) ? '0' : '';
    _note.clear();
    _laborCost.clear();
    _partsCost.clear();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mileage.dispose();
    _wear.dispose();
    _note.dispose();
    _laborCost.dispose();
    _partsCost.dispose();
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

  double? _parseMoney(String raw) {
    final normalized = raw.trim().replaceAll(',', '.').replaceAll(' ', '');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String? _composedNote() {
    final parts = <String>[
      if (_partsCost.text.trim().isNotEmpty)
        '${context.l10n.statePartsCost}: ${_partsCost.text.trim()}',
      if (_laborCost.text.trim().isNotEmpty)
        '${context.l10n.stateLaborCost}: ${_laborCost.text.trim()}',
      if (_note.text.trim().isNotEmpty) _note.text.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _startEdit(_ServiceHistoryRow row) {
    setState(() {
      _editingRecordId = row.recordId;
      _editingObservationId = row.observationId;
      _editingOriginalDate = row.date;
      _date = row.date;
      _mileage.text = row.mileage?.toString() ?? '';
      _wear.text =
          row.wearPercent?.toString() ??
          (supportsWearMeasurement(workCode) ? '0' : '');
      _note.text = row.note ?? '';
      _laborCost.clear();
      _partsCost.clear();
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final formContext = _formSectionKey.currentContext;
      if (formContext != null) {
        Scrollable.ensureVisible(
          formContext,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0,
        );
        return;
      }
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _cancelEdit() {
    setState(() {
      _resetFormForCreate();
      _fillCreateDefaults();
      _error = null;
    });
  }

  Future<void> _confirmDelete(_ServiceHistoryRow row) async {
    if (row.recordId == null || _saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(context.l10n.stateDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.close),
          ),
          FilledButton(
            key: const Key('state-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.stateDeleteRecord),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final locale = ref.read(activeLocaleProvider).languageCode;
    try {
      final notifier = ref.read(maintenanceControllerProvider.notifier);
      await notifier.deleteServiceRecord(
        vehicle.id,
        row.recordId!,
        locale: locale,
      );
      if (row.observationId != null) {
        await notifier.deleteConditionObservation(
          vehicle.id,
          row.observationId!,
          locale: locale,
        );
      }
      await ref.read(vehicleSetupControllerProvider.notifier).load(force: true);
      if (!mounted) return;
      if (_editingRecordId == row.recordId) {
        _cancelEdit();
      }
      setState(() => _saving = false);
    } on MaintenanceFailure {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = context.l10n.stateUpdateError;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = context.l10n.stateUpdateError;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final locale = ref.read(activeLocaleProvider).languageCode;
    final mileageText = _mileage.text.trim();
    final mileage = mileageText.isEmpty ? null : int.tryParse(mileageText);
    if (mileageText.isNotEmpty && mileage == null) {
      setState(() => _error = context.l10n.stateUpdateError);
      return;
    }
    if (_laborCost.text.trim().isNotEmpty &&
        _parseMoney(_laborCost.text) == null) {
      setState(() => _error = context.l10n.stateUpdateError);
      return;
    }
    if (_partsCost.text.trim().isNotEmpty &&
        _parseMoney(_partsCost.text) == null) {
      setState(() => _error = context.l10n.stateUpdateError);
      return;
    }
    final canWear = supportsWearMeasurement(workCode);
    int? wearValue;
    if (canWear) {
      final raw = _wear.text.trim();
      // New record: empty field means 0%. Edit: keep explicit value or 0.
      wearValue = raw.isEmpty ? 0 : int.tryParse(raw);
      if (wearValue == null || wearValue < 0 || wearValue > 100) {
        setState(() => _error = context.l10n.stateUpdateError);
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final notifier = ref.read(maintenanceControllerProvider.notifier);
      final record = ServiceRecordWrite(
        serviceDate: _date,
        workCode: workCode,
        mileage: mileage,
        mileageUnit: vehicle.mileageUnit ?? 'km',
        note: _composedNote(),
      );
      if (_isEditing) {
        await notifier.updateServiceRecord(
          vehicle.id,
          _editingRecordId!,
          locale: locale,
          record: record,
        );
      } else {
        await notifier.createServiceRecord(
          vehicle.id,
          locale: locale,
          record: record,
        );
      }
      if (canWear && wearValue != null) {
        final observation = ConditionObservationWrite(
          workCode: workCode,
          wearPercent: wearValue,
          observedAt: _date,
          mileage: mileage,
          mileageUnit: vehicle.mileageUnit ?? 'km',
          source: ConditionObservationSource.self,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
        if (_editingObservationId != null) {
          await notifier.updateConditionObservation(
            vehicle.id,
            _editingObservationId!,
            locale: locale,
            observation: observation,
          );
        } else {
          // Always write wear for new/updated service on wear-capable parts.
          await notifier.createConditionObservation(
            vehicle.id,
            locale: locale,
            observation: observation,
          );
        }
      }
      await ref.read(vehicleSetupControllerProvider.notifier).load(force: true);
      if (mounted) widget.onClose();
    } on MaintenanceFailure {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = context.l10n.stateUpdateError;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = context.l10n.stateUpdateError;
        });
      }
    }
  }

  List<_ServiceHistoryRow> _historyRows(MaintenanceState state) {
    final observations =
        state.conditionObservations?.items
            .where((observation) => observation.workCode == workCode)
            .toList() ??
        const <ConditionObservation>[];
    final records =
        state.serviceRecords?.items
            .where(
              (record) =>
                  record.items.any((work) => work.workCode == workCode),
            )
            .toList() ??
        const <ServiceRecord>[];
    records.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

    final rows = <_ServiceHistoryRow>[
      for (final record in records.take(5))
        _ServiceHistoryRow(
          recordId: record.id.isEmpty ? null : record.id,
          observationId: observations
              .where((observation) => _sameDay(observation.observedAt, record.serviceDate))
              .map((observation) => observation.id)
              .firstOrNull,
          date: record.serviceDate,
          mileage: record.mileage,
          mileageUnit: record.mileageUnit ?? 'km',
          note: record.note,
          wearPercent: observations
              .where((observation) => _sameDay(observation.observedAt, record.serviceDate))
              .map((observation) => observation.wearPercent)
              .firstOrNull,
        ),
    ];

    final historyDate = item.historyState.performedDate;
    if (historyDate != null &&
        !rows.any((row) => _sameDay(row.date, historyDate))) {
      rows.add(
        _ServiceHistoryRow(
          date: historyDate,
          mileage: item.historyState.performedMileageKm,
          mileageUnit: 'km',
          wearPercent: item.latestObservation?.wearPercent,
          observationId: item.latestObservation?.id,
        ),
      );
      rows.sort((a, b) => b.date.compareTo(a.date));
    }
    return rows.take(5).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final metric = _metricFor(context, item);
    final barValue =
        metric.progress ?? effectiveLifecycleFraction(item);
    final canWear = supportsWearMeasurement(workCode);
    final maintenance = ref.watch(maintenanceControllerProvider);
    final history = _historyRows(maintenance);
    final scaleLabel =
        metric.caption ??
        (barValue == null ? null : context.l10n.stateScaleCaption);

    final maxBodyHeight = MediaQuery.sizeOf(context).height * 0.62;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxBodyHeight),
          child: ListView(
            key: Key('state-detail-${item.id}'),
            controller: _scrollController,
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            children: [
              Row(
                children: [
                  Icon(_stateIcon(item), color: metric.color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('state-detail-close'),
                    tooltip: context.l10n.close,
                    visualDensity: VisualDensity.compact,
                    onPressed: _saving ? null : widget.onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              AutomotivePanel(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                emphasized: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            metric.status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: metric.color,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Text(
                          barValue == null
                              ? '—'
                              : '${(barValue * 100).round()}%',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: metric.color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        key: Key(
                          barValue == null
                              ? 'state-bar-detail-${item.id}'
                              : 'lifecycle-track-detail-${item.id}',
                        ),
                        value: barValue ?? 0,
                        minHeight: 8,
                        color: barValue == null
                            ? colors.outlineVariant
                            : metric.color,
                        backgroundColor: colors.outlineVariant.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                    if (scaleLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        scaleLabel,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AutomotivePanel(
                key: _formSectionKey,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TechnicalLabel(
                      _isEditing
                          ? context.l10n.stateEditingBanner(
                              _formatDate(_editingOriginalDate ?? _date),
                            )
                          : context.l10n.stateUpdateSection,
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          key: const Key('state-cancel-edit'),
                          onPressed: _saving ? null : _cancelEdit,
                          child: Text(context.l10n.stateCancelEdit),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Material(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        key: const Key('state-update-date'),
                        borderRadius: BorderRadius.circular(10),
                        onTap: _saving ? null : _pickDate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.stateUpdateDate,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                    ),
                                    Text(_formatDate(_date)),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('state-update-mileage'),
                            controller: _mileage,
                            enabled: !_saving,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              isDense: true,
                              labelText:
                                  '${context.l10n.stateUpdateMileage}, ${vehicle.mileageUnit ?? 'km'}',
                            ),
                          ),
                        ),
                        if (canWear) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              key: Key('state-update-wear-$workCode'),
                              controller: _wear,
                              enabled: !_saving,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: context.l10n.stateWearField,
                                helperText: context.l10n.stateWearHint,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('state-update-parts-cost'),
                            controller: _partsCost,
                            enabled: !_saving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: context.l10n.statePartsCost,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            key: const Key('state-update-labor-cost'),
                            controller: _laborCost,
                            enabled: !_saving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: context.l10n.stateLaborCost,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('state-update-note'),
                      controller: _note,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: context.l10n.stateNoteField,
                        hintText: context.l10n.stateNoteHint,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _error!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colors.error),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AutomotivePanel(
                key: const Key('state-history-list'),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TechnicalLabel(context.l10n.stateServiceHistory),
                    const SizedBox(height: 4),
                    if (history.isEmpty)
                      Text(
                        context.l10n.stateServiceHistoryEmpty,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      )
                    else
                      for (var index = 0; index < history.length; index++)
                        Padding(
                          key: Key('state-history-row-$index'),
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 84,
                                child: Text(
                                  _formatDate(history[index].date),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  [
                                    if (history[index].mileage != null)
                                      '${history[index].mileage} ${history[index].mileageUnit}',
                                    if (history[index].wearPercent != null)
                                      '${history[index].wearPercent}%',
                                    if (history[index].note
                                            ?.trim()
                                            .isNotEmpty ==
                                        true)
                                      history[index].note!.trim(),
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                              ),
                              if (history[index].recordId != null) ...[
                                IconButton(
                                  key: Key('state-history-edit-$index'),
                                  tooltip: context.l10n.stateEditRecord,
                                  visualDensity: VisualDensity.compact,
                                  iconSize: 18,
                                  onPressed: _saving
                                      ? null
                                      : () => _startEdit(history[index]),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  key: Key('state-history-delete-$index'),
                                  tooltip: context.l10n.stateDeleteRecord,
                                  visualDensity: VisualDensity.compact,
                                  iconSize: 18,
                                  onPressed: _saving
                                      ? null
                                      : () => _confirmDelete(history[index]),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: colors.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: Key('state-update-save-$workCode'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isEditing
                          ? context.l10n.stateUpdateSaveEdit
                          : context.l10n.stateUpdateSave,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceHistoryRow {
  const _ServiceHistoryRow({
    required this.date,
    this.recordId,
    this.observationId,
    this.mileage,
    this.mileageUnit = 'km',
    this.note,
    this.wearPercent,
  });

  final String? recordId;
  final String? observationId;
  final DateTime date;
  final int? mileage;
  final String mileageUnit;
  final String? note;
  final int? wearPercent;
}

IconData _stateIcon(Consumable item) {
  final id = item.id;
  if (id.contains('oil')) return Icons.oil_barrel_outlined;
  if (id.contains('tire')) return Icons.tire_repair_outlined;
  if (id.contains('coolant')) return Icons.water_drop_outlined;
  if (id.contains('brake')) return Icons.album_outlined;
  if (id.contains('filter')) return Icons.air_outlined;
  return Icons.build_outlined;
}

String _workCode(Consumable item) =>
    item.workCode.isEmpty ? item.id.replaceAll('-', '_') : item.workCode;

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')}.${value.year}';

class _StatePreview extends StatelessWidget {
  const _StatePreview();

  @override
  Widget build(BuildContext context) {
    final demos = [
      (
        'oil',
        Icons.oil_barrel_outlined,
        context.l10n.oilFilters,
        0.72,
        context.l10n.stateTriggerMileage,
      ),
      (
        'brakes',
        Icons.album_outlined,
        context.l10n.brakesTitle,
        null,
        context.l10n.inspectionRequired,
      ),
      (
        'tires',
        Icons.tire_repair_outlined,
        context.l10n.tiresTitle,
        0.4,
        context.l10n.stateWearCaption,
      ),
      (
        'coolant',
        Icons.water_drop_outlined,
        context.l10n.technicalFluids,
        null,
        context.l10n.stateNeedsData,
      ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.stateTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const ExampleBadge(),
            ],
          ),
          const SizedBox(height: 8),
          PreviewGate(
            message: context.l10n.stateGate,
            onAddVehicle: () => context.go('/garage/add'),
          ),
          const SizedBox(height: 12),
          GridView.count(
            key: const Key('state-preview-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              for (final demo in demos)
                AutomotivePanel(
                  key: Key('state-preview-${demo.$1}'),
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(demo.$2, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              demo.$3,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (demo.$4 != null)
                            Text(
                              '${(demo.$4! * 100).round()}%',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: demo.$4 ?? 0,
                          minHeight: 7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        demo.$5,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.stateLastServiceUnknownShort,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

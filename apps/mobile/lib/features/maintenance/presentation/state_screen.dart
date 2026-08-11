import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/automotive_widgets.dart';
import '../../../core/widgets/odometer_mileage_input.dart';
import '../../../core/widgets/preview_widgets.dart';
import '../../../l10n/l10n.dart';
import '../../vehicle/vehicle.dart';
import '../../vehicle/vehicle_controller.dart';
import '../maintenance.dart';
import '../maintenance_controller.dart';
import 'work_node_icons.dart';

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

    final colors = Theme.of(context).colorScheme;

    return CustomScrollView(
      // Keep this key on the scrollable RenderBox (tests drag it).
      key: const Key('state-tiles-grid'),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _StateSectionHeaderDelegate(
            title: context.l10n.stateTitle,
            subtitle: context.l10n.stateSubtitle,
            background: colors.surface,
            subtitleColor: colors.onSurfaceVariant,
          ),
        ),
        if (tiles.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Text(context.l10n.stateEmpty),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 100,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
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
                childCount: tiles.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _StateSectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StateSectionHeaderDelegate({
    required this.title,
    required this.subtitle,
    required this.background,
    required this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final Color background;
  final Color subtitleColor;

  static const double _height = 72;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      elevation: overlapsContent || shrinkOffset > 0 ? 1.5 : 0,
      shadowColor: Colors.black38,
      color: background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subtitleColor,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StateSectionHeaderDelegate oldDelegate) {
    return title != oldDelegate.title ||
        subtitle != oldDelegate.subtitle ||
        background != oldDelegate.background ||
        subtitleColor != oldDelegate.subtitleColor;
  }
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
  final missingData =
      item.basis == 'missing_data' ||
      item.status == MaintenanceStatus.unknown ||
      (isInterval && used == null) ||
      (item.kind == ConsumableKind.conditionBased &&
          item.inspectionState == InspectionState.unknown &&
          !item.requiresCheckNow);

  if (missingData) {
    return _StateMetric(
      status: context.l10n.stateNeedsData,
      color: colors.error,
      progress: null,
      caption: context.l10n.stateNeedsDataUrgent,
      missingData: true,
    );
  }

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
        color: colors.error,
        missingData: true,
        caption: context.l10n.stateNeedsDataUrgent,
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

class _StateMetric {
  const _StateMetric({
    required this.status,
    required this.color,
    this.progress,
    this.caption,
    this.missingData = false,
  });

  final String status;
  final Color color;
  final double? progress;
  final String? caption;
  final bool missingData;
}

class _StateTile extends StatelessWidget {
  const _StateTile({required this.item, required this.onTap});

  final Consumable item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final metric = _metricFor(context, item);
    final scaleLabel =
        metric.caption ??
        (metric.progress == null ? null : context.l10n.stateScaleCaption);
    final frameBadge = metric.missingData
        ? context.l10n.stateNeedsDataBadge
        : (metric.progress != null && metric.progress! >= 0.8
              ? '${(metric.progress! * 100).round()}%'
              : null);
    final frameColor = metric.missingData
        ? colors.error
        : (metric.progress != null && metric.progress! >= 1
              ? colors.error
              : (metric.progress != null && metric.progress! >= 0.8
                    ? metric.color
                    : colors.outlineVariant));
    final frameWidth =
        metric.missingData || (metric.progress != null && metric.progress! >= 0.8)
        ? 1.6
        : 1.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          key: Key('consumable-${item.id}'),
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: Key('state-tile-${item.id}'),
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: frameColor, width: frameWidth),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: metric.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            workNodeIcon(
                              item.workCode.isEmpty ? null : item.workCode,
                              fallbackId: item.id,
                            ),
                            size: 13,
                            color: metric.color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                  fontSize: 12.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              key: Key('state-bar-${item.id}'),
                              value: metric.missingData
                                  ? 1
                                  : (metric.progress ?? 0),
                              minHeight: 5,
                              color: metric.color,
                              backgroundColor: colors.outlineVariant.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ),
                        if (metric.progress != null && !metric.missingData) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${(metric.progress! * 100).round()}%',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: metric.color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scaleLabel ?? metric.status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: metric.missingData || metric.progress == null
                            ? metric.color
                            : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      _nextDueShort(context, item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (frameBadge != null && metric.missingData)
          Positioned(
            top: -5,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: frameColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.surface, width: 1.5),
              ),
              child: Text(
                frameBadge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
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
  // Use showDialog (not showGeneralDialog + BackdropFilter): blur/custom
  // routes are unreliable on some physical Android devices in release builds.
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0xCCE8EEF4),
    builder: (dialogContext) {
      final mq = MediaQuery.of(dialogContext);
      final keyboard = mq.viewInsets.bottom;
      // Dialog already adds viewInsets to its padding — do NOT add keyboard
      // again in insetPadding (that was shrinking the card to ~half).
      final verticalGap = keyboard > 0 ? 8.0 : 20.0;
      final freeHeight = mq.size.height - keyboard - verticalGap * 2;
      final dialogHeight = keyboard > 0
          ? freeHeight.clamp(freeHeight * 0.92, freeHeight)
          : (mq.size.height * 0.86).clamp(320.0, freeHeight);
      return Dialog(
        key: const Key('state-detail-dialog'),
        insetPadding: EdgeInsets.fromLTRB(12, verticalGap, 12, verticalGap),
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        elevation: 16,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 440,
          height: dialogHeight,
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
      _date = row.date ?? DateTime.now();
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

    if (mileage != null) {
      final unit = vehicle.mileageUnit ?? 'km';
      final mileageKm = unit == 'mi' ? (mileage * 1.609344).round() : mileage;
      final known = <(DateTime, int)>[
        for (final row in _historyRows(ref.read(maintenanceControllerProvider)))
          if (row.date != null && row.mileage != null)
            (
              row.date!,
              row.mileageUnit == 'mi'
                  ? (row.mileage! * 1.609344).round()
                  : row.mileage!,
            ),
        for (final obs
            in ref.read(maintenanceControllerProvider).mileageObservations?.items ??
                const <MileageObservation>[])
          (obs.observedAt, obs.valueKm),
      ];
      for (final point in known) {
        if (_editingOriginalDate != null &&
            _sameDay(point.$1, _editingOriginalDate!)) {
          continue;
        }
        final pointDay = DateTime(point.$1.year, point.$1.month, point.$1.day);
        final entryDay = DateTime(_date.year, _date.month, _date.day);
        if (entryDay.isAfter(pointDay) && mileageKm < point.$2) {
          setState(() => _error = context.l10n.mileageTimelineInconsistentLater);
          return;
        }
        if (entryDay.isBefore(pointDay) && mileageKm > point.$2) {
          setState(
            () => _error = context.l10n.mileageTimelineInconsistentEarlier,
          );
          return;
        }
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
    final code = workCode;
    bool matchesWork(String? value) {
      if (value == null || value.isEmpty) return false;
      final normalized = value.replaceAll('-', '_');
      return normalized == code || normalized == code.replaceAll('-', '_');
    }

    final observations =
        state.conditionObservations?.items
            .where((observation) => matchesWork(observation.workCode))
            .toList() ??
        const <ConditionObservation>[];

    final fromApi =
        state.serviceRecords?.items
            .where(
              (record) =>
                  record.items.any((work) => matchesWork(work.workCode)),
            )
            .toList() ??
        const <ServiceRecord>[];
    final fromTimeline =
        state.timeline?.serviceRecords
            .where(
              (record) =>
                  record.items.any((work) => matchesWork(work.workCode)),
            )
            .toList() ??
        const <ServiceRecord>[];

    final recordsById = <String, ServiceRecord>{};
    for (final record in [...fromApi, ...fromTimeline]) {
      final key = record.id.isNotEmpty
          ? record.id
          : '${record.serviceDate.toIso8601String()}|${record.mileage ?? ''}';
      recordsById.putIfAbsent(key, () => record);
    }
    final records = recordsById.values.toList()
      ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

    final rows = <_ServiceHistoryRow>[
      for (final record in records.take(5))
        _ServiceHistoryRow(
          recordId: record.id.isEmpty ? null : record.id,
          observationId: observations
              .where(
                (observation) =>
                    _sameDay(observation.observedAt, record.serviceDate),
              )
              .map((observation) => observation.id)
              .firstOrNull,
          date: record.serviceDate,
          mileage: record.mileage,
          mileageUnit: record.mileageUnit ?? 'km',
          note: record.note,
          wearPercent: observations
              .where(
                (observation) =>
                    _sameDay(observation.observedAt, record.serviceDate),
              )
              .map((observation) => observation.wearPercent)
              .firstOrNull,
        ),
    ];

    final liveConsumable = state.consumables?.items
        .where((entry) => matchesWork(_workCode(entry)))
        .firstOrNull;
    final livePlan = state.plan?.items
        .where((entry) => matchesWork(entry.workCode))
        .firstOrNull;
    final historyState =
        liveConsumable?.historyState ??
        livePlan?.historyState ??
        item.historyState;

    final historyDate = historyState.performedDate;
    final historyMileage = historyState.performedMileageKm;
    final alreadyPresent = historyDate != null
        ? rows.any((row) => row.date != null && _sameDay(row.date!, historyDate))
        : historyMileage != null &&
            rows.any((row) => row.mileage == historyMileage);
    if (!alreadyPresent &&
        (historyDate != null || historyMileage != null) &&
        (historyState.answer == HistoryAnswerValue.doneKnown ||
            historyDate != null ||
            historyMileage != null)) {
      rows.add(
        _ServiceHistoryRow(
          date: historyDate,
          mileage: historyMileage,
          mileageUnit: 'km',
          wearPercent: liveConsumable?.latestObservation?.wearPercent ??
              item.latestObservation?.wearPercent,
          observationId: liveConsumable?.latestObservation?.id ??
              item.latestObservation?.id,
        ),
      );
      rows.sort((a, b) {
        final aDate = a.date;
        final bDate = b.date;
        if (aDate != null && bDate != null) return bDate.compareTo(aDate);
        if (aDate != null) return -1;
        if (bDate != null) return 1;
        return (b.mileage ?? 0).compareTo(a.mileage ?? 0);
      });
    }
    return rows.take(5).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final automotive =
        Theme.of(context).extension<AutomotiveColors>() ?? AutomotiveColors.dark;
    final metric = _metricFor(context, item);
    final barValue = metric.progress ?? effectiveLifecycleFraction(item);
    final canWear = supportsWearMeasurement(workCode);
    final maintenance = ref.watch(maintenanceControllerProvider);
    final history = _historyRows(maintenance);
    final scaleLabel =
        metric.caption ??
        (barValue == null ? null : context.l10n.stateScaleCaption);

    final fieldDecoration = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.45),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: colors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: colors.primary,
        fontWeight: FontWeight.w700,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.primary, width: 1.4),
      ),
    );

    final planItem = maintenance.plan?.items
        .where((entry) => entry.workCode == workCode)
        .firstOrNull;
    final intervalLabel = planItem == null
        ? null
        : _intervalLabel(context, planItem.interval);
    final nextLabel = _nextDueShort(context, item);

    // Left accent via border — avoid IntrinsicHeight (breaks with ListView).
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: metric.color, width: 3),
        ),
      ),
      child: Column(
        children: [
                Material(
                  color: colors.primaryContainer.withValues(alpha: 0.55),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: metric.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            workNodeIcon(
                              item.workCode.isEmpty ? null : item.workCode,
                              fallbackId: item.id,
                            ),
                            color: metric.color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                              ),
                              if (intervalLabel != null || nextLabel.isNotEmpty)
                                Text(
                                  [
                                    ?intervalLabel,
                                    if (nextLabel.isNotEmpty) nextLabel,
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          key: const Key('state-detail-close'),
                          tooltip: context.l10n.close,
                          visualDensity: VisualDensity.compact,
                          onPressed: _saving ? null : widget.onClose,
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: colors.outlineVariant),
                Expanded(
                  child: ListView(
                    key: Key('state-detail-${item.id}'),
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    children: [
                      // Compact current-state strip (informational only).
                      Container(
                        key: const Key('state-current-compact'),
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  context.l10n.stateCurrentFacts,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                _InfoIconButton(
                                  message: context.l10n.stateCurrentFactsInfo,
                                ),
                                const Spacer(),
                                Text(
                                  barValue == null
                                      ? '—'
                                      : '${(barValue * 100).round()}%',
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: metric.color,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                metric.status,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: metric.color,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                key: Key(
                                  barValue == null
                                      ? 'state-bar-detail-${item.id}'
                                      : 'lifecycle-track-detail-${item.id}',
                                ),
                                value: barValue ?? 0,
                                minHeight: 5,
                                color: barValue == null
                                    ? colors.outlineVariant
                                    : metric.color,
                                backgroundColor: colors.outlineVariant
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            if (scaleLabel != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      scaleLabel,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  _InfoIconButton(
                                    message: item.effectiveTrigger == 'time'
                                        ? context.l10n.stateTriggerTimeHint
                                        : item.effectiveTrigger == 'mileage'
                                        ? context.l10n.stateTriggerMileageHint
                                        : (supportsWearMeasurement(workCode)
                                              ? context.l10n.stateWearCaptionHint
                                              : context
                                                    .l10n
                                                    .stateCurrentFactsInfo),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DetailSection(
                        key: _formSectionKey,
                        title: _isEditing
                            ? context.l10n.stateEditingBanner(
                                _formatDate(_editingOriginalDate ?? _date),
                              )
                            : context.l10n.stateUpdateSection,
                        accent: automotive.info,
                        infoMessage: context.l10n.stateUpdateSectionInfo,
                        trailing: _isEditing
                            ? TextButton(
                                key: const Key('state-cancel-edit'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: _saving ? null : _cancelEdit,
                                child: Text(context.l10n.stateCancelEdit),
                              )
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    key: const Key('state-update-date'),
                                    onTap: _saving ? null : _pickDate,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InputDecorator(
                                      decoration: fieldDecoration.copyWith(
                                        labelText: context.l10n.stateUpdateDate,
                                        prefixIcon: Icon(
                                          Icons.calendar_month_outlined,
                                          size: 16,
                                          color: colors.onSurfaceVariant,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 0,
                                        ),
                                      ),
                                      child: Text(
                                        _formatDate(_date),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: MileageInputField(
                                    fieldKey: const Key('state-update-mileage'),
                                    value: int.tryParse(_mileage.text.trim()),
                                    unit: vehicle.mileageUnit ?? 'km',
                                    compact: true,
                                    enabled: !_saving,
                                    label:
                                        '${context.l10n.stateUpdateMileage}, ${vehicle.mileageUnit ?? 'km'}',
                                    onChanged: (next) {
                                      _mileage.text = '$next';
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (canWear) ...[
                              const SizedBox(height: 10),
                              TextField(
                                key: Key('state-update-wear-$workCode'),
                                controller: _wear,
                                enabled: !_saving,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: fieldDecoration.copyWith(
                                  labelText: context.l10n.stateWearField,
                                  helperText: context.l10n.stateWearHint,
                                  helperMaxLines: 2,
                                  helperStyle: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              context.l10n.stateCostSection,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    key: const Key('state-update-parts-cost'),
                                    controller: _partsCost,
                                    enabled: !_saving,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: fieldDecoration.copyWith(
                                      labelText: context.l10n.statePartsCost,
                                    ),
                                    onTap: () => _ensureFormVisible(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    key: const Key('state-update-labor-cost'),
                                    controller: _laborCost,
                                    enabled: !_saving,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: fieldDecoration.copyWith(
                                      labelText: context.l10n.stateLaborCost,
                                    ),
                                    onTap: () => _ensureFormVisible(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              key: const Key('state-update-note'),
                              controller: _note,
                              enabled: !_saving,
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: 2,
                              decoration: fieldDecoration.copyWith(
                                labelText: context.l10n.stateNoteField,
                                hintText: context.l10n.stateNoteHint,
                              ),
                              onTap: () => _ensureFormVisible(),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: colors.error),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DetailSection(
                        key: const Key('state-history-list'),
                        title: context.l10n.stateServiceHistory,
                        accent: colors.tertiary,
                        infoMessage: context.l10n.stateServiceHistoryInfo,
                        child: history.isEmpty
                            ? Text(
                                context.l10n.stateServiceHistoryEmpty,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              )
                            : Column(
                                children: [
                                  for (
                                    var index = 0;
                                    index < history.length;
                                    index++
                                  )
                                    Container(
                                      key: Key('state-history-row-$index'),
                                      margin: EdgeInsets.only(
                                        bottom: index == history.length - 1
                                            ? 0
                                            : 8,
                                      ),
                                      padding: const EdgeInsets.fromLTRB(
                                        10,
                                        8,
                                        4,
                                        8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.surfaceContainerHighest
                                            .withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: colors.outlineVariant,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  history[index].date != null
                                                      ? _formatDate(
                                                          history[index].date!,
                                                        )
                                                      : context
                                                            .l10n
                                                            .historyMileageOnly,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  [
                                                    if (history[index]
                                                            .mileage !=
                                                        null)
                                                      '${history[index].mileage} ${history[index].mileageUnit}',
                                                    if (history[index]
                                                            .wearPercent !=
                                                        null)
                                                      '${history[index].wearPercent}%',
                                                    if (history[index]
                                                            .note
                                                            ?.trim()
                                                            .isNotEmpty ==
                                                        true)
                                                      history[index].note!
                                                          .trim(),
                                                  ].join(' · '),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: colors
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (history[index].recordId !=
                                              null) ...[
                                            IconButton(
                                              key: Key(
                                                'state-history-edit-$index',
                                              ),
                                              tooltip: context
                                                  .l10n
                                                  .stateEditRecord,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              iconSize: 18,
                                              onPressed: _saving
                                                  ? null
                                                  : () => _startEdit(
                                                        history[index],
                                                      ),
                                              icon: Icon(
                                                Icons.edit_outlined,
                                                color: colors.primary,
                                              ),
                                            ),
                                            IconButton(
                                              key: Key(
                                                'state-history-delete-$index',
                                              ),
                                              tooltip: context
                                                  .l10n
                                                  .stateDeleteRecord,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              iconSize: 18,
                                              onPressed: _saving
                                                  ? null
                                                  : () => _confirmDelete(
                                                        history[index],
                                                      ),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    border: Border(
                      top: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('state-update-cancel'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: _saving ? null : widget.onClose,
                          child: Text(context.l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          key: Key('state-update-save-$workCode'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: metric.color,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isEditing
                                      ? context.l10n.stateUpdateSaveEdit
                                      : context.l10n.stateUpdateSave,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _ensureFormVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _formSectionKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: 0.05,
      );
    });
  }
}





class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.accent,
    required this.child,
    this.trailing,
    this.infoMessage,
    super.key,
  });

  final String title;
  final Color accent;
  final Widget child;
  final Widget? trailing;
  final String? infoMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (infoMessage != null)
                  _InfoIconButton(message: infoMessage!),
                ?trailing,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoIconButton extends StatelessWidget {
  const _InfoIconButton({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: message,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.l10n.understood),
              ),
            ],
          ),
        );
      },
      icon: Icon(Icons.info_outline, size: 18, color: colors.primary),
    );
  }
}

class _ServiceHistoryRow {
  const _ServiceHistoryRow({
    this.date,
    this.recordId,
    this.observationId,
    this.mileage,
    this.mileageUnit = 'km',
    this.note,
    this.wearPercent,
  });

  final String? recordId;
  final String? observationId;
  final DateTime? date;
  final int? mileage;
  final String mileageUnit;
  final String? note;
  final int? wearPercent;
}

String _workCode(Consumable item) =>
    item.workCode.isEmpty ? item.id.replaceAll('-', '_') : item.workCode;

String _nextDueShort(BuildContext context, Consumable item) {
  final due = item.due;
  if (due.date != null) {
    return context.l10n.stateNextDueShort(_formatDate(due.date!));
  }
  if (due.mileage != null) {
    return context.l10n.stateNextDueShort(
      '${due.mileage} ${due.unit ?? 'km'}',
    );
  }
  final next = item.nextInspection;
  if (next?.date != null) {
    return context.l10n.stateNextDueShort(_formatDate(next!.date!));
  }
  if (next?.mileage != null) {
    return context.l10n.stateNextDueShort(
      '${next!.mileage} ${next.unit ?? 'km'}',
    );
  }
  return context.l10n.stateNextDueUnknown;
}

String? _intervalLabel(BuildContext context, MaintenanceInterval interval) {
  final parts = <String>[];
  if (interval.mileageKm != null) {
    parts.add(context.l10n.intervalEveryKm(interval.mileageKm!));
  }
  if (interval.days != null) {
    if (interval.days == 365 || interval.days == 366) {
      parts.add(context.l10n.intervalEveryYear);
    } else {
      parts.add(context.l10n.intervalEveryDays(interval.days!));
    }
  }
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

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

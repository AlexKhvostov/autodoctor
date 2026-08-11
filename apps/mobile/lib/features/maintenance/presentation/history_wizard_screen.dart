import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/locale_controller.dart';
import '../../../core/widgets/automotive_widgets.dart';
import '../../../core/widgets/odometer_mileage_input.dart';
import '../../../l10n/l10n.dart';
import '../../vehicle/vehicle_controller.dart';
import '../maintenance.dart';
import '../maintenance_controller.dart';

class HistoryWizardScreen extends ConsumerStatefulWidget {
  const HistoryWizardScreen({this.workCode, super.key});

  final String? workCode;

  @override
  ConsumerState<HistoryWizardScreen> createState() =>
      _HistoryWizardScreenState();
}

class _HistoryWizardScreenState extends ConsumerState<HistoryWizardScreen> {
  final _drafts = <String, _HistoryDraft>{};
  final _scroll = ScrollController();
  String? _contextKey;
  String? _initializedKey;
  int _index = 0;
  bool _submitting = false;
  bool _showIntroCard = true;
  MaintenanceFailure? _failure;

  void _ensure(String vehicleId, String locale) {
    final key = '$vehicleId:$locale';
    if (_contextKey == key) return;
    _contextKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(maintenanceControllerProvider.notifier)
          .ensurePlan(vehicleId, locale: locale);
    });
  }

  List<MaintenanceItem> _items(MaintenancePlan plan) {
    final applicable = plan.items
        .where((item) => item.status != MaintenanceStatus.notApplicable)
        .toList(growable: false);
    if (widget.workCode == null) return applicable;
    return applicable
        .where((item) => item.workCode == widget.workCode)
        .toList(growable: false);
  }

  void _initialize(
    String vehicleId,
    String locale,
    List<MaintenanceItem> items,
    int? currentMileage,
  ) {
    final key = '$vehicleId:$locale:${widget.workCode ?? '*'}';
    if (_initializedKey == key) return;
    _initializedKey = key;
    _drafts.clear();
    final today = DateTime.now();
    for (final item in items) {
      final history = item.historyState;
      final wearCapable = supportsWearMeasurement(item.workCode);
      if (history.answer != null &&
          history.answer != HistoryAnswerValue.unrecognized) {
        _drafts[item.workCode] = _HistoryDraft(
          answer: history.answer,
          date: history.performedDate,
          mileage: history.performedMileageKm?.toString() ?? '',
          checkDate: today,
          checkMileage: currentMileage?.toString() ?? '',
          wearMode: wearCapable,
        );
      } else {
        _drafts[item.workCode] = _HistoryDraft(
          checkDate: today,
          checkMileage: currentMileage?.toString() ?? '',
          wearMode: wearCapable,
        );
      }
    }
    _index = 0;
  }

  void _openIntro() {
    setState(() => _showIntroCard = true);
  }

  bool _validateKnown(MaintenanceItem item, int? currentMileage) {
    final draft = _drafts[item.workCode];
    if (draft?.answer != HistoryAnswerValue.doneKnown) return true;
    final mileage = int.tryParse(draft!.mileage);
    final validMileage =
        draft.mileage.isEmpty ||
        (mileage != null &&
            mileage >= 0 &&
            (currentMileage == null || mileage <= currentMileage));
    if ((draft.date == null && draft.mileage.isEmpty) || !validMileage) {
      setState(() => _drafts[item.workCode] = draft.copyWith(showError: true));
      return false;
    }
    if (draft.wearMode && draft.wearEnabled) {
      final wear = int.tryParse(draft.wearPercent);
      if (wear == null || wear < 0 || wear > 100) {
        setState(
          () => _drafts[item.workCode] = draft.copyWith(showError: true),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _submit(
    String vehicleId,
    String locale,
    List<MaintenanceItem> items,
    int? currentMileage,
  ) async {
    for (final item in items) {
      if (!_validateKnown(item, currentMileage)) {
        setState(() => _index = items.indexOf(item));
        return;
      }
    }
    final answers = items
        .where((item) => _drafts[item.workCode]?.answer != null)
        .map((item) {
          final draft = _drafts[item.workCode]!;
          return HistoryAnswerWrite(
            workCode: item.workCode,
            answer: draft.answer!,
            performedDate: draft.answer == HistoryAnswerValue.doneKnown
                ? draft.date
                : null,
            performedMileageKm: draft.answer == HistoryAnswerValue.doneKnown
                ? int.tryParse(draft.mileage)
                : null,
          );
        })
        .toList(growable: false);
    if (answers.isEmpty) {
      context.go('/roadmap');
      return;
    }
    setState(() {
      _submitting = true;
      _failure = null;
    });
    try {
      final notifier = ref.read(maintenanceControllerProvider.notifier);
      await notifier.submitHistoryAnswers(
        vehicleId,
        locale: locale,
        answers: answers,
      );
      for (final item in items) {
        final draft = _drafts[item.workCode];
        if (draft == null ||
            !draft.wearMode ||
            !draft.wearEnabled ||
            draft.answer != HistoryAnswerValue.doneKnown) {
          continue;
        }
        final wear = int.tryParse(draft.wearPercent);
        if (wear == null) continue;
        await notifier.createConditionObservation(
          vehicleId,
          locale: locale,
          observation: ConditionObservationWrite(
            workCode: item.workCode,
            wearPercent: wear,
            observedAt: draft.checkDate ?? DateTime.now(),
            mileage: int.tryParse(draft.checkMileage),
            source: ConditionObservationSource.self,
            note: draft.note.trim().isEmpty ? null : draft.note.trim(),
          ),
        );
      }
      if (mounted) context.go('/roadmap');
    } on MaintenanceFailure catch (failure) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _failure = failure;
        });
      }
    }
  }

  void _setAnswer(
    MaintenanceItem item,
    _HistoryDraft draft,
    HistoryAnswerValue answer,
  ) {
    setState(() {
      _failure = null;
      _drafts[item.workCode] = draft.copyWith(
        answer: answer,
        deferred: false,
        clearKnown: answer != HistoryAnswerValue.doneKnown,
        showError: false,
      );
    });
  }

  Future<void> _goNext({
    required MaintenanceItem item,
    required String vehicleId,
    required String locale,
    required List<MaintenanceItem> items,
    required int? currentMileage,
  }) async {
    final draft = _drafts[item.workCode] ?? const _HistoryDraft();
    if (draft.deferred) {
      // skip without answer
    } else if (draft.answer == null) {
      setState(
        () => _drafts[item.workCode] = draft.copyWith(showError: true),
      );
      return;
    } else if (draft.answer == HistoryAnswerValue.doneKnown) {
      if (!_validateKnown(item, currentMileage)) return;
    }

    if (_index == items.length - 1) {
      await _submit(vehicleId, locale, items, currentMileage);
    } else {
      setState(() => _index++);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(0);
        }
      });
    }
  }

  void _goPrevious() {
    if (_index > 0) {
      setState(() => _index--);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(0);
      });
    } else {
      context.pop();
    }
  }

  void _selectDeferred(MaintenanceItem item, _HistoryDraft draft) {
    setState(() {
      _failure = null;
      _drafts[item.workCode] = draft.copyWith(
        deferred: true,
        clearAnswer: true,
        clearKnown: true,
        showError: false,
      );
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(vehicleSetupControllerProvider).activeVehicle;
    final locale = ref.watch(activeLocaleProvider).languageCode;
    if (vehicle == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/garage/add');
      });
      return const Center(child: CircularProgressIndicator());
    }
    _ensure(vehicle.id, locale);
    final state = ref.watch(maintenanceControllerProvider);
    if (!state.matches(vehicle.id, locale) ||
        state.planStage != MaintenanceLoadStage.ready ||
        state.plan == null) {
      if (state.matches(vehicle.id, locale) &&
          state.planStage == MaintenanceLoadStage.error) {
        return _WizardLoadError(
          failure: state.failure,
          onRetry: () {
            _contextKey = null;
            _ensure(vehicle.id, locale);
          },
        );
      }
      return const Center(
        key: Key('history-wizard-loading'),
        child: CircularProgressIndicator(),
      );
    }
    final items = _items(state.plan!);
    final currentMileageKm = vehicle.mileage == null
        ? null
        : vehicle.mileageUnit == 'mi'
        ? (vehicle.mileage! * 1.609344).round()
        : vehicle.mileage;
    _initialize(vehicle.id, locale, items, currentMileageKm);
    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/roadmap');
      });
      return const SizedBox.shrink();
    }
    _index = _index.clamp(0, items.length - 1);
    final item = items[_index];
    final draft = _drafts[item.workCode] ?? const _HistoryDraft();
    final single = widget.workCode != null;
    final showIntro = _showIntroCard && !single;
    final wearCapable = supportsWearMeasurement(item.workCode);
    final colors = Theme.of(context).colorScheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final isLast = _index == items.length - 1;

    if (showIntro) {
      return Scaffold(
        backgroundColor: colors.scrim.withValues(alpha: 0.55),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Material(
                  key: const Key('history-intro-dialog'),
                  color: colors.surfaceContainerHigh,
                  elevation: 8,
                  shadowColor: Colors.black54,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.fact_check_outlined,
                          size: 36,
                          color: colors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.historyWizardTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.historyWizardFriendlyHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.historyWizardIntroDetail,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                height: 1.4,
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          key: const Key('history-intro-got-it'),
                          onPressed: () =>
                              setState(() => _showIntroCard = false),
                          child: Text(context.l10n.historyIntroGotIt),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  key: const Key('history-progress'),
                  minHeight: 3,
                  value: (_index + 1) / items.length,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Material(
                key: const Key('history-question-block'),
                color: colors.primaryContainer.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${single ? context.l10n.historySingleLabel : context.l10n.historyWizardLabel}'
                              ' · ${context.l10n.historyProgress(_index + 1, items.length)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ),
                          if (!single)
                            IconButton(
                              key: const Key('history-intro-info'),
                              visualDensity: VisualDensity.compact,
                              tooltip: context.l10n.historyWizardTitle,
                              onPressed: _submitting ? null : _openIntro,
                              icon: const Icon(Icons.info_outline, size: 18),
                            ),
                        ],
                      ),
                      Text(
                        item.title.endsWith('.') ? item.title : '${item.title}.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.historyLastServicePrompt,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                key: const Key('history-fields-first'),
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + keyboard * 0.1),
                children: [
                  _AnswerTile(
                    key: const Key('history-answer-done_known'),
                    selected: draft.answer == HistoryAnswerValue.doneKnown,
                    icon: Icons.event_available_outlined,
                    title: context.l10n.historyDoneKnownShort,
                    onTap: _submitting
                        ? null
                        : () => _setAnswer(
                              item,
                              draft,
                              HistoryAnswerValue.doneKnown,
                            ),
                  ),
                  _AnswerTile(
                    key: const Key('history-answer-unknown'),
                    selected:
                        draft.answer == HistoryAnswerValue.doneUnknown ||
                        draft.answer == HistoryAnswerValue.unknown,
                    icon: Icons.help_outline,
                    title: context.l10n.historyUnknownShort,
                    onTap: _submitting
                        ? null
                        : () => _setAnswer(
                              item,
                              draft,
                              HistoryAnswerValue.unknown,
                            ),
                  ),
                  _AnswerTile(
                    key: const Key('history-answer-not_done'),
                    selected: draft.answer == HistoryAnswerValue.notDone,
                    icon: Icons.block,
                    title: context.l10n.historyNever,
                    onTap: _submitting
                        ? null
                        : () => _setAnswer(
                              item,
                              draft,
                              HistoryAnswerValue.notDone,
                            ),
                  ),
                  _AnswerTile(
                    key: const Key('history-answer-not_applicable'),
                    selected: draft.answer == HistoryAnswerValue.notApplicable,
                    icon: Icons.remove_circle_outline,
                    title: context.l10n.historyNotApplicable,
                    onTap: _submitting
                        ? null
                        : () => _setAnswer(
                              item,
                              draft,
                              HistoryAnswerValue.notApplicable,
                            ),
                  ),
                  if (!single)
                    _AnswerTile(
                      key: const Key('history-skip-item'),
                      selected: draft.deferred,
                      icon: Icons.schedule_outlined,
                      title: context.l10n.historyAnswerLater,
                      muted: !draft.deferred,
                      onTap: _submitting
                          ? null
                          : () => _selectDeferred(item, draft),
                    ),
                  if (draft.showError &&
                      draft.answer == null &&
                      !draft.deferred) ...[
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.historyChooseAnswer,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.error),
                    ),
                  ],
                  if (draft.answer == HistoryAnswerValue.doneKnown) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _MetaDisplayField(
                            key: const Key('history-date'),
                            icon: Icons.calendar_month_outlined,
                            label: wearCapable
                                ? context.l10n.historyCheckDate
                                : context.l10n.historyReplacementDate,
                            value: draft.date == null
                                ? '—'
                                : _date(draft.date!),
                            enabled: !_submitting,
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    draft.date ?? draft.checkDate ?? now,
                                firstDate: DateTime(1950),
                                lastDate: now,
                              );
                              if (picked != null && mounted) {
                                setState(
                                  () => _drafts[item.workCode] =
                                      draft.copyWith(
                                    date: picked,
                                    checkDate: picked,
                                    showError: false,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MileageInputField(
                            key: ValueKey('mileage-odo-${item.workCode}'),
                            fieldKey: const Key('history-mileage'),
                            value: draft.mileage.isNotEmpty
                                ? int.tryParse(draft.mileage)
                                : null,
                            placeholderValue: int.tryParse(draft.checkMileage),
                            confirmed: draft.mileage.isNotEmpty,
                            enabled: !_submitting,
                            unit: 'km',
                            compact: true,
                            label: context.l10n.historyMileage,
                            errorText: draft.showError
                                ? _knownError(
                                    context,
                                    draft,
                                    currentMileageKm,
                                  )
                                : null,
                            onChanged: (value) => setState(
                              () => _drafts[item.workCode] = draft.copyWith(
                                mileage: value.toString(),
                                showError: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (wearCapable) ...[
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHigh.withValues(
                            alpha: 0.65,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SwitchListTile(
                                key: const Key('history-wear-toggle'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                title: Text(
                                  context.l10n.historyWearToggle,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                value: draft.wearEnabled,
                                onChanged: _submitting
                                    ? null
                                    : (value) => setState(
                                          () => _drafts[item.workCode] =
                                              draft.copyWith(
                                            wearEnabled: value,
                                          ),
                                        ),
                              ),
                              if (draft.wearEnabled) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        key: const Key('history-wear-percent'),
                                        value:
                                            (double.tryParse(
                                                      draft.wearPercent,
                                                    ) ??
                                                    50)
                                                .clamp(0, 100),
                                        min: 0,
                                        max: 100,
                                        divisions: 20,
                                        label:
                                            '${(double.tryParse(draft.wearPercent) ?? 50).round()}%',
                                        onChanged: _submitting
                                            ? null
                                            : (value) => setState(
                                                  () => _drafts[item.workCode] =
                                                      draft.copyWith(
                                                    wearPercent: value
                                                        .round()
                                                        .toString(),
                                                    showError: false,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    Text(
                                      '${(double.tryParse(draft.wearPercent) ?? 50).round()}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                                Text(
                                  context.l10n.wearRemaining(
                                    (100 -
                                            (int.tryParse(draft.wearPercent) ??
                                                50))
                                        .clamp(0, 100),
                                  ),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                  if (_failure != null) ...[
                    const SizedBox(height: 10),
                    AutomotivePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _failure!.safeMessage.isNotEmpty
                                ? _failure!.safeMessage
                                : context.l10n.historySaveError,
                          ),
                          if (_failure!.requestId != null)
                            SelectableText(
                              context.l10n.requestIdLabel(_failure!.requestId!),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Material(
              elevation: 6,
              color: colors.surfaceContainer,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + keyboard),
                child: Row(
                  children: [
                    SizedBox(
                      width: 104,
                      child: OutlinedButton(
                        key: const Key('history-nav-prev'),
                        onPressed: _submitting ? null : _goPrevious,
                        child: Text(context.l10n.back),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        context.l10n.appTitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 104,
                      child: FilledButton(
                        key: Key(isLast ? 'history-save' : 'history-next'),
                        onPressed: _submitting
                            ? null
                            : () => _goNext(
                                  item: item,
                                  vehicleId: vehicle.id,
                                  locale: locale,
                                  items: items,
                                  currentMileage: currentMileageKm,
                                ),
                        child: _submitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isLast
                                    ? context.l10n.save
                                    : context.l10n.next,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaDisplayField extends StatelessWidget {
  const _MetaDisplayField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          prefixIcon: Icon(icon, size: 16, color: colors.onSurfaceVariant),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}


class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
    this.muted = false,
    super.key,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: 0.55)
            : colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: muted
                      ? colors.onSurfaceVariant
                      : selected
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: muted ? colors.onSurfaceVariant : null,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: colors.primary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryDraft {
  const _HistoryDraft({
    this.answer,
    this.deferred = false,
    this.date,
    this.mileage = '',
    this.note = '',
    this.showError = false,
    this.wearMode = false,
    this.wearEnabled = false,
    this.wearPercent = '',
    this.checkDate,
    this.checkMileage = '',
  });

  final HistoryAnswerValue? answer;
  final bool deferred;
  final DateTime? date;
  final String mileage;
  final String note;
  final bool showError;
  final bool wearMode;
  final bool wearEnabled;
  final String wearPercent;
  final DateTime? checkDate;
  final String checkMileage;

  _HistoryDraft copyWith({
    HistoryAnswerValue? answer,
    bool? deferred,
    DateTime? date,
    String? mileage,
    String? note,
    bool? showError,
    bool clearKnown = false,
    bool clearAnswer = false,
    bool? wearMode,
    bool? wearEnabled,
    String? wearPercent,
    DateTime? checkDate,
    String? checkMileage,
  }) => _HistoryDraft(
    answer: clearAnswer ? null : answer ?? this.answer,
    deferred: deferred ?? (clearAnswer ? false : this.deferred),
    date: clearKnown ? null : date ?? this.date,
    mileage: clearKnown ? '' : mileage ?? this.mileage,
    note: note ?? this.note,
    showError: showError ?? this.showError,
    wearMode: wearMode ?? this.wearMode,
    wearEnabled: wearEnabled ?? this.wearEnabled,
    wearPercent: wearPercent ?? this.wearPercent,
    checkDate: checkDate ?? this.checkDate,
    checkMileage: checkMileage ?? this.checkMileage,
  );
}

class _WizardLoadError extends StatelessWidget {
  const _WizardLoadError({required this.failure, required this.onRetry});

  final MaintenanceFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: AutomotivePanel(
        emphasized: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.planLoadError),
            if (failure?.requestId != null)
              Text(context.l10n.requestIdLabel(failure!.requestId!)),
            FilledButton(
              key: const Key('history-load-retry'),
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    ),
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')}.${value.year}';

String _knownError(
  BuildContext context,
  _HistoryDraft draft,
  int? currentMileage,
) {
  if (draft.date == null && draft.mileage.isEmpty) {
    return context.l10n.historyKnownRequired;
  }
  final mileage = int.tryParse(draft.mileage);
  if (draft.mileage.isNotEmpty &&
      (mileage == null ||
          mileage < 0 ||
          currentMileage != null && mileage > currentMileage)) {
    return currentMileage == null
        ? context.l10n.nonNegativeValidation
        : context.l10n.historyMileageMax(currentMileage);
  }
  return context.l10n.historyKnownRequired;
}

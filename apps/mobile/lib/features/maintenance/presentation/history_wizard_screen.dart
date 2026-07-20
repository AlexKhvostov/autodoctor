import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/locale_controller.dart';
import '../../../core/widgets/automotive_widgets.dart';
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
  String? _contextKey;
  String? _initializedKey;
  int _index = 0;
  bool _submitting = false;
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
        clearKnown: answer != HistoryAnswerValue.doneKnown,
        showError: false,
      );
    });
  }

  Future<void> _saveCurrent(
    MaintenanceItem item,
    String vehicleId,
    String locale,
    List<MaintenanceItem> items,
    int? currentMileage,
  ) async {
    final draft = _drafts[item.workCode] ?? const _HistoryDraft();
    final next = draft.copyWith(
      answer: HistoryAnswerValue.doneKnown,
      date: draft.date ?? (draft.wearMode ? draft.checkDate : draft.date),
      mileage: draft.mileage.isEmpty && draft.wearMode
          ? draft.checkMileage
          : draft.mileage,
      showError: false,
    );
    _drafts[item.workCode] = next;
    if (!_validateKnown(item, currentMileage)) return;
    if (_index == items.length - 1) {
      await _submit(vehicleId, locale, items, currentMileage);
    } else {
      setState(() => _index++);
    }
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
    final wearCapable = supportsWearMeasurement(item.workCode);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
            child: Row(
              children: [
                IconButton(
                  key: const Key('history-back'),
                  onPressed: _submitting
                      ? null
                      : () {
                          if (_index > 0) {
                            setState(() => _index--);
                          } else {
                            context.pop();
                          }
                        },
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TechnicalLabel(
                        single
                            ? context.l10n.historySingleLabel
                            : context.l10n.historyWizardLabel,
                      ),
                      Text(
                        context.l10n.historyWizardTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                if (!single)
                  TextButton(
                    key: const Key('history-skip-all'),
                    onPressed: _submitting
                        ? null
                        : () => context.go('/roadmap'),
                    child: Text(context.l10n.skipAll),
                  ),
              ],
            ),
          ),
          LinearProgressIndicator(
            key: const Key('history-progress'),
            value: (_index + 1) / items.length,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                12,
                12,
                12,
                16 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.historyProgress(_index + 1, items.length),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  AutomotivePanel(
                    key: const Key('history-fields-first'),
                    emphasized: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(item.basis),
                        const SizedBox(height: 12),
                        if (wearCapable) ...[
                          SwitchListTile(
                            key: const Key('history-wear-toggle'),
                            contentPadding: EdgeInsets.zero,
                            title: Text(context.l10n.historyWearToggle),
                            value: draft.wearEnabled,
                            onChanged: _submitting
                                ? null
                                : (value) => setState(
                                    () => _drafts[item.workCode] = draft
                                        .copyWith(wearEnabled: value),
                                  ),
                          ),
                          if (draft.wearEnabled) ...[
                            TextFormField(
                              key: const Key('history-wear-percent'),
                              initialValue: draft.wearPercent,
                              enabled: !_submitting,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: context.l10n.wearPercent,
                                errorText: draft.showError
                                    ? context.l10n.wearValidation
                                    : null,
                              ),
                              onChanged: (value) =>
                                  _drafts[item.workCode] = draft.copyWith(
                                    wearPercent: value,
                                    showError: false,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              draft.wearPercent.isEmpty
                                  ? context.l10n.historyRemainingPercent
                                  : context.l10n.wearRemaining(
                                      (100 -
                                              (int.tryParse(
                                                    draft.wearPercent,
                                                  ) ??
                                                  0))
                                          .clamp(0, 100),
                                    ),
                            ),
                          ],
                          OutlinedButton.icon(
                            key: const Key('history-date'),
                            onPressed: _submitting
                                ? null
                                : () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: draft.checkDate ?? now,
                                      firstDate: DateTime(1950),
                                      lastDate: now,
                                    );
                                    if (picked != null && mounted) {
                                      setState(
                                        () => _drafts[item.workCode] = draft
                                            .copyWith(
                                              checkDate: picked,
                                              date: picked,
                                              showError: false,
                                            ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              draft.checkDate == null
                                  ? context.l10n.historyCheckDate
                                  : '${context.l10n.historyCheckDate}: ${_date(draft.checkDate!)}',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('history-mileage'),
                            initialValue: draft.checkMileage,
                            enabled: !_submitting,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: context.l10n.currentMileage,
                              errorText: draft.showError && !draft.wearEnabled
                                  ? _knownError(
                                      context,
                                      draft,
                                      currentMileageKm,
                                    )
                                  : null,
                            ),
                            onChanged: (value) =>
                                _drafts[item.workCode] = draft.copyWith(
                                  checkMileage: value,
                                  mileage: value,
                                  showError: false,
                                ),
                          ),
                          ExpansionTile(
                            key: const Key('history-additional'),
                            title: Text(context.l10n.historyAdditional),
                            children: [
                              OutlinedButton.icon(
                                onPressed: _submitting
                                    ? null
                                    : () async {
                                        final now = DateTime.now();
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: draft.date ?? now,
                                          firstDate: DateTime(1950),
                                          lastDate: now,
                                        );
                                        if (picked != null && mounted) {
                                          setState(
                                            () => _drafts[item.workCode] = draft
                                                .copyWith(date: picked),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.event_outlined),
                                label: Text(
                                  draft.date == null
                                      ? context.l10n.historyInstallDate
                                      : '${context.l10n.historyInstallDate}: ${_date(draft.date!)}',
                                ),
                              ),
                              TextFormField(
                                initialValue: draft.mileage,
                                enabled: !_submitting,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: context.l10n.historyInstallMileage,
                                ),
                                onChanged: (value) => _drafts[item.workCode] =
                                    draft.copyWith(mileage: value),
                              ),
                            ],
                          ),
                        ] else ...[
                          OutlinedButton.icon(
                            key: const Key('history-date'),
                            onPressed: _submitting
                                ? null
                                : () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: draft.date ?? now,
                                      firstDate: DateTime(1950),
                                      lastDate: now,
                                    );
                                    if (picked != null && mounted) {
                                      setState(
                                        () => _drafts[item.workCode] = draft
                                            .copyWith(
                                              date: picked,
                                              showError: false,
                                            ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              draft.date == null
                                  ? context.l10n.historyReplacementDate
                                  : '${context.l10n.historyReplacementDate}: ${_date(draft.date!)}',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('history-mileage'),
                            initialValue: draft.mileage,
                            enabled: !_submitting,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: context.l10n.historyReplacementMileage,
                              errorText: draft.showError
                                  ? _knownError(
                                      context,
                                      draft,
                                      currentMileageKm,
                                    )
                                  : null,
                            ),
                            onChanged: (value) => _drafts[item.workCode] = draft
                                .copyWith(mileage: value, showError: false),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('history-note'),
                            initialValue: draft.note,
                            enabled: !_submitting,
                            decoration: InputDecoration(
                              labelText: context.l10n.historyNoteOptional,
                            ),
                            onChanged: (value) => _drafts[item.workCode] = draft
                                .copyWith(note: value),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.historyKnownHint,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  key: Key(
                    _index == items.length - 1
                        ? 'history-save'
                        : 'history-next',
                  ),
                  onPressed: _submitting
                      ? null
                      : () => _saveCurrent(
                          item,
                          vehicle.id,
                          locale,
                          items,
                          currentMileageKm,
                        ),
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _index == items.length - 1
                              ? context.l10n.save
                              : context.l10n.historySaveAndNext,
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('history-answer-unknown'),
                        onPressed: _submitting
                            ? null
                            : () {
                                _setAnswer(
                                  item,
                                  draft,
                                  HistoryAnswerValue.unknown,
                                );
                                if (_index == items.length - 1) {
                                  _submit(
                                    vehicle.id,
                                    locale,
                                    items,
                                    currentMileageKm,
                                  );
                                } else {
                                  setState(() => _index++);
                                }
                              },
                        child: Text(context.l10n.historyUnknown),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('history-answer-not_applicable'),
                        onPressed: _submitting
                            ? null
                            : () {
                                _setAnswer(
                                  item,
                                  draft,
                                  HistoryAnswerValue.notApplicable,
                                );
                                if (_index == items.length - 1) {
                                  _submit(
                                    vehicle.id,
                                    locale,
                                    items,
                                    currentMileageKm,
                                  );
                                } else {
                                  setState(() => _index++);
                                }
                              },
                        child: Text(context.l10n.historyNotApplicable),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        key: const Key('history-answer-not_done'),
                        onPressed: _submitting
                            ? null
                            : () {
                                _setAnswer(
                                  item,
                                  draft,
                                  HistoryAnswerValue.notDone,
                                );
                                if (_index == items.length - 1) {
                                  _submit(
                                    vehicle.id,
                                    locale,
                                    items,
                                    currentMileageKm,
                                  );
                                } else {
                                  setState(() => _index++);
                                }
                              },
                        child: Text(context.l10n.historyNever),
                      ),
                    ),
                    if (!single)
                      Expanded(
                        child: TextButton(
                          key: const Key('history-skip-item'),
                          onPressed: _submitting
                              ? null
                              : () {
                                  if (_index == items.length - 1) {
                                    context.go('/roadmap');
                                  } else {
                                    setState(() => _index++);
                                  }
                                },
                          child: Text(context.l10n.historyFinishLater),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryDraft {
  const _HistoryDraft({
    this.answer,
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
    DateTime? date,
    String? mileage,
    String? note,
    bool? showError,
    bool clearKnown = false,
    bool? wearMode,
    bool? wearEnabled,
    String? wearPercent,
    DateTime? checkDate,
    String? checkMileage,
  }) => _HistoryDraft(
    answer: answer ?? this.answer,
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

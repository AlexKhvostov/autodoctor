import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/locale_controller.dart';
import '../../../l10n/l10n.dart';
import '../../assistant/assistant_controller.dart';
import '../../vehicle/vehicle_controller.dart';
import '../guest_skill_api.dart';

class OwnerSkillQuizScreen extends ConsumerStatefulWidget {
  const OwnerSkillQuizScreen({super.key});

  @override
  ConsumerState<OwnerSkillQuizScreen> createState() =>
      _OwnerSkillQuizScreenState();
}

class _OwnerSkillQuizScreenState extends ConsumerState<OwnerSkillQuizScreen> {
  int _step = 0;
  String? _knowledgeBand;
  String? _handsOn;
  String? _detailPreference;
  bool _submitting = false;
  String? _error;

  static const _totalSteps = 3;

  Future<void> _finish() async {
    if (_knowledgeBand == null || _handsOn == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final locale = ref.read(activeLocaleProvider).languageCode;
    final vehicle = ref.read(vehicleSetupControllerProvider).activeVehicle;
    try {
      await ref.read(guestSkillApiClientProvider).submitQuiz(
            locale: locale,
            knowledgeBand: _knowledgeBand!,
            handsOn: _handsOn!,
            detailPreference: _detailPreference,
          );

      if (!mounted) return;
      final assistant = ref.read(assistantControllerProvider.notifier);
      final label = vehicle == null
          ? 'авто'
          : '${vehicle.make} ${vehicle.model}'.trim();
      final thread = await assistant.createWelcomeThread(
        title: context.l10n.assistantWelcomeTitle,
        welcomeMessage: context.l10n.assistantWelcomeMessage(label),
      );
      if (mounted) {
        context.go('/ai/chat/${thread.id}');
      }
    } on GuestSkillApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _submitting = false;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _submitting = false;
        });
      }
    }
  }

  void _selectKnowledge(String value) {
    setState(() {
      _knowledgeBand = value;
      _step = 1;
    });
  }

  void _selectHandsOn(String value) {
    setState(() {
      _handsOn = value;
      _step = 2;
    });
  }

  void _selectDetail(String value) {
    setState(() => _detailPreference = value);
    unawaited(_finish());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.back,
                    onPressed: _submitting
                        ? null
                        : () {
                            if (_step == 0) {
                              context.go('/garage/add/confirm');
                              return;
                            }
                            setState(() => _step -= 1);
                          },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      l10n.ownerSkillQuizTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${_step + 1}/$_totalSteps',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_step + 1) / _totalSteps,
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 28),
              Text(
                switch (_step) {
                  0 => l10n.ownerSkillQ1,
                  1 => l10n.ownerSkillQ2,
                  _ => l10n.ownerSkillQ3,
                },
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.ownerSkillQuizHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  children: [
                    if (_step == 0) ...[
                      _OptionButton(
                        label: l10n.ownerSkillQ1Novice,
                        selected: _knowledgeBand == 'novice',
                        onPressed: _submitting
                            ? null
                            : () => _selectKnowledge('novice'),
                      ),
                      _OptionButton(
                        label: l10n.ownerSkillQ1Basic,
                        selected: _knowledgeBand == 'basic',
                        onPressed: _submitting
                            ? null
                            : () => _selectKnowledge('basic'),
                      ),
                      _OptionButton(
                        label: l10n.ownerSkillQ1Confident,
                        selected: _knowledgeBand == 'confident',
                        onPressed: _submitting
                            ? null
                            : () => _selectKnowledge('confident'),
                      ),
                    ] else if (_step == 1) ...[
                      _OptionButton(
                        label: l10n.ownerSkillQ2Never,
                        selected: _handsOn == 'never',
                        onPressed:
                            _submitting ? null : () => _selectHandsOn('never'),
                      ),
                      _OptionButton(
                        label: l10n.ownerSkillQ2Sometimes,
                        selected: _handsOn == 'sometimes',
                        onPressed: _submitting
                            ? null
                            : () => _selectHandsOn('sometimes'),
                      ),
                      _OptionButton(
                        label: l10n.ownerSkillQ2Yes,
                        selected: _handsOn == 'yes',
                        onPressed:
                            _submitting ? null : () => _selectHandsOn('yes'),
                      ),
                    ] else ...[
                      _OptionButton(
                        label: l10n.ownerSkillQ3Simple,
                        selected: _detailPreference == 'simple',
                        onPressed:
                            _submitting ? null : () => _selectDetail('simple'),
                      ),
                      _OptionButton(
                        label: l10n.ownerSkillQ3Detailed,
                        selected: _detailPreference == 'detailed',
                        onPressed: _submitting
                            ? null
                            : () => _selectDetail('detailed'),
                      ),
                    ],
                    if (_submitting) ...[
                      const SizedBox(height: 24),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _finish,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            side: BorderSide(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            backgroundColor: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : null,
          ),
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(height: 1.3),
          ),
        ),
      ),
    );
  }
}

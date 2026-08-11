import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/locale_controller.dart';
import '../../../l10n/l10n.dart';
import '../../vehicle/vehicle_controller.dart';
import '../agent_profile_api.dart';

class AgentProfileScreen extends ConsumerStatefulWidget {
  const AgentProfileScreen({super.key});

  @override
  ConsumerState<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends ConsumerState<AgentProfileScreen> {
  AgentProfile? _profile;
  AgentPreferences? _draft;
  String _knowledgeBand = 'basic';
  String _handsOn = 'sometimes';
  final _instructionsCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _usageSectionKey = GlobalKey();
  bool _loading = true;
  bool _saving = false;
  bool _refueling = false;
  String? _error;
  String? _banner;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  @override
  void dispose() {
    _instructionsCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _scrollToUsage() async {
    final ctx = _usageSectionKey.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  Future<void> _showBuyTokensSheet(List<RefuelPackage> packages) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.agentRefuelTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.agentRefuelHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                for (final pack in packages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FilledButton.tonal(
                      key: Key('agent-refuel-pack-${pack.ml}'),
                      onPressed: _refueling
                          ? null
                          : () async {
                              Navigator.of(ctx).pop();
                              await _refuel(pack.ml);
                            },
                      child: Text(
                        '${l10n.agentRefuelPackage(pack.label)} — ${l10n.agentPaymentSoon}',
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTokensGuide(AgentFuel fuel) async {
    final l10n = context.l10n;
    final one = fuel.typicalSpendMl;
    final goUsage = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.agentTokensGuideTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.agentTokensGuideIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 14),
                _TokenGuideRow(
                  icon: Icons.chat_bubble_outline,
                  text: l10n.agentTokensGuideOneReply(one),
                ),
                _TokenGuideRow(
                  icon: Icons.short_text_rounded,
                  text: l10n.agentTokensGuideShort(one * 3),
                ),
                _TokenGuideRow(
                  icon: Icons.forum_outlined,
                  text: l10n.agentTokensGuideMedium(one * 9),
                ),
                _TokenGuideRow(
                  icon: Icons.all_inclusive_rounded,
                  text: l10n.agentTokensGuideLong(one * 22),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l10n.agentTokensGuideSeeUsage),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (goUsage == true && mounted) {
      await _scrollToUsage();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final locale = ref.read(activeLocaleProvider).languageCode;
    final vehicleId = ref
        .read(vehicleSetupControllerProvider)
        .activeVehicle
        ?.id;
    try {
      final profile = await ref
          .read(agentProfileApiClientProvider)
          .fetch(locale: locale, vehicleId: vehicleId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _draft = profile.preferences;
        _knowledgeBand = profile.skill.knowledgeBandValue;
        final hands = profile.skill.handsOnValue;
        _handsOn = hands == 'yes' ? 'often' : hands;
        _instructionsCtrl.text = profile.preferences.customInstructions ?? '';
        _loading = false;
      });
    } on AgentProfileApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || _saving) return;
    setState(() {
      _saving = true;
      _banner = null;
    });
    final locale = ref.read(activeLocaleProvider).languageCode;
    final next = draft.copyWith(
      customInstructions: _instructionsCtrl.text.trim().isEmpty
          ? null
          : _instructionsCtrl.text.trim(),
      clearInstructions: _instructionsCtrl.text.trim().isEmpty,
    );
    try {
      final api = ref.read(agentProfileApiClientProvider);
      final saved = await api.updatePreferences(
        locale: locale,
        preferences: next,
      );
      final skill = await api.updateSkill(
        locale: locale,
        knowledgeBand: _knowledgeBand,
        handsOn: _handsOn,
      );
      if (!mounted) return;
      setState(() {
        _draft = saved;
        _knowledgeBand = skill.knowledgeBandValue;
        _handsOn = skill.handsOnValue;
        _saving = false;
        _banner = context.l10n.agentProfileSaved;
      });
    } on AgentProfileApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    }
  }

  Future<void> _forgetNote({
    required String noteId,
    required bool vehicleNote,
  }) async {
    final locale = ref.read(activeLocaleProvider).languageCode;
    final vehicleId = ref
        .read(vehicleSetupControllerProvider)
        .activeVehicle
        ?.id;
    try {
      final api = ref.read(agentProfileApiClientProvider);
      if (vehicleNote) {
        if (vehicleId == null || vehicleId.isEmpty) return;
        await api.deleteVehicleNote(
          locale: locale,
          vehicleId: vehicleId,
          noteId: noteId,
        );
      } else {
        await api.deleteUserNote(locale: locale, noteId: noteId);
      }
      if (!mounted) return;
      setState(() => _banner = context.l10n.agentNoteForgetDone);
      await _load();
    } on AgentProfileApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    }
  }

  Future<void> _refuel(int packageMl) async {
    if (_refueling) return;
    setState(() {
      _refueling = true;
      _banner = null;
    });
    final locale = ref.read(activeLocaleProvider).languageCode;
    try {
      await ref
          .read(agentProfileApiClientProvider)
          .refuelStub(locale: locale, packageMl: packageMl);
      if (!mounted) return;
      setState(() {
        _refueling = false;
        _banner = context.l10n.agentRefuelStubDone;
      });
      await _load();
    } on AgentProfileApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _refueling = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final draft = _draft;
    final profile = _profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.agentProfileTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/assistant');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: (_saving || draft == null) ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && profile == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _load, child: Text(l10n.retry)),
                  ],
                ),
              ),
            )
          : ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (_banner != null) ...[
                  Text(
                    _banner!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _HeaderCard(
                  fuel: profile!.fuel,
                  onTokensTap: () => _showTokensGuide(profile.fuel),
                  onAddTokens: () =>
                      _showBuyTokensSheet(profile.refuelPackages),
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: l10n.agentOwnerSkillTitle,
                  subtitle: l10n.agentOwnerSkillHint,
                  child: Column(
                    children: [
                      _OptionPicker(
                        key: const Key('agent-skill-band'),
                        label: l10n.agentOwnerSkillBand,
                        value: _knowledgeBand,
                        options: [
                          ('never_tools', l10n.agentOwnerSkillBandNeverTools),
                          ('scared', l10n.agentOwnerSkillBandScared),
                          ('novice', l10n.agentOwnerSkillBandNovice),
                          ('basic', l10n.agentOwnerSkillBandBasic),
                          ('curious', l10n.agentOwnerSkillBandCurious),
                          ('confident', l10n.agentOwnerSkillBandConfident),
                          ('advanced', l10n.agentOwnerSkillBandAdvanced),
                          ('pro', l10n.agentOwnerSkillBandPro),
                        ],
                        onChanged: (value) =>
                            setState(() => _knowledgeBand = value),
                      ),
                      const SizedBox(height: 12),
                      _OptionPicker(
                        key: const Key('agent-skill-hands'),
                        label: l10n.agentOwnerSkillHandsOn,
                        value: _handsOn,
                        options: [
                          ('never', l10n.agentOwnerSkillHandsNever),
                          ('outside', l10n.agentOwnerSkillHandsOutside),
                          ('sometimes', l10n.agentOwnerSkillHandsSometimes),
                          ('often', l10n.agentOwnerSkillHandsOften),
                          ('always', l10n.agentOwnerSkillHandsAlways),
                        ],
                        onChanged: (value) => setState(() => _handsOn = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: _usageSectionKey,
                  child: _ProfileSection(
                    title: l10n.agentUsageTitle,
                    child: _UsageOverview(
                      today: profile.usageToday,
                      week: profile.usageWeek,
                      all: profile.usageAll,
                      daily: profile.usageDaily,
                      currency: profile.fuel.currency,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (draft != null)
                  _ProfileSection(
                    title: l10n.agentHowItAnswers,
                    subtitle: l10n.agentHowItAnswersHint,
                    accentNote: l10n.agentPrefsLiveHint,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SliderRow(
                          label: l10n.agentSliderSimplicity,
                          low: l10n.agentSliderSimplicityLow,
                          high: l10n.agentSliderSimplicityHigh,
                          value: draft.simplicity,
                          onChanged: (v) => setState(
                            () =>
                                _draft = draft.copyWith(simplicity: v.round()),
                          ),
                        ),
                        _SliderRow(
                          label: l10n.agentSliderVerbosity,
                          low: l10n.agentSliderVerbosityLow,
                          high: l10n.agentSliderVerbosityHigh,
                          value: draft.verbosity,
                          onChanged: (v) => setState(
                            () =>
                                _draft = draft.copyWith(verbosity: v.round()),
                          ),
                        ),
                        _SliderRow(
                          label: l10n.agentSliderDirectness,
                          low: l10n.agentSliderDirectnessLow,
                          high: l10n.agentSliderDirectnessHigh,
                          value: draft.directness,
                          onChanged: (v) => setState(
                            () =>
                                _draft = draft.copyWith(directness: v.round()),
                          ),
                        ),
                        _SliderRow(
                          label: l10n.agentSliderInitiative,
                          low: l10n.agentSliderInitiativeLow,
                          high: l10n.agentSliderInitiativeHigh,
                          value: draft.initiative,
                          onChanged: (v) => setState(
                            () =>
                                _draft = draft.copyWith(initiative: v.round()),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.agentCustomInstructions,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _instructionsCtrl,
                          maxLength: 800,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: l10n.agentCustomInstructionsHint,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                _ProfileSection(
                  title: l10n.agentNotesTitle,
                  subtitle: l10n.agentNotesHint,
                  child: Column(
                    children: [
                      _NotesBlock(
                        title: l10n.agentNotesUser,
                        notes: profile.userNotes,
                        empty: l10n.agentNotesEmpty,
                        onForget: (noteId) => _forgetNote(
                          noteId: noteId,
                          vehicleNote: false,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _NotesBlock(
                        title: l10n.agentNotesVehicle,
                        notes: profile.vehicleNotes,
                        empty: l10n.agentNotesEmpty,
                        onForget: (noteId) => _forgetNote(
                          noteId: noteId,
                          vehicleNote: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileSection(
                  title: l10n.agentRefuelTitle,
                  subtitle: l10n.agentRefuelHint,
                  emphasize: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('agent-refuel-open'),
                      onPressed: _refueling
                          ? null
                          : () => _showBuyTokensSheet(profile.refuelPackages),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.agentTokensAdd),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.fuel,
    required this.onTokensTap,
    required this.onAddTokens,
  });

  final AgentFuel fuel;
  final VoidCallback onTokensTap;
  final VoidCallback onAddTokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final accent = switch (fuel.status) {
      AgentEnergyStatus.empty => colors.error,
      AgentEnergyStatus.low => const Color(0xFFE07A3A),
      AgentEnergyStatus.ok => colors.primary,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/branding/agent_companion_widget.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.smart_toy_rounded, size: 56),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AutoDoctor',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.agentIntroSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          key: const Key('agent-tokens-balance'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.20),
                colors.surfaceContainerHighest,
              ],
            ),
            border: Border.all(
              color: accent.withValues(alpha: 0.55),
              width: 1.4,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.generating_tokens_outlined,
                      color: accent,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.agentTokensBalanceLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatEnergy(fuel.balanceMl),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: accent,
                              height: 1.05,
                              letterSpacing: -0.5,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.agentApproxReplies(fuel.approxRepliesLeft),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      key: const Key('agent-tokens-add'),
                      onPressed: onAddTokens,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.agentTokensAdd),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onTokensTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: accent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.agentTokensTapHint,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (fuel.isLow || fuel.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            fuel.isEmpty
                ? l10n.agentFuelEmptyBanner
                : l10n.agentEnergyLowBanner,
            style: theme.textTheme.bodySmall?.copyWith(
              color: fuel.isEmpty ? colors.error : const Color(0xFFC45C1A),
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  String _formatEnergy(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buf.write('\u202f');
      }
    }
    return buf.toString();
  }
}

class _TokenGuideRow extends StatelessWidget {
  const _TokenGuideRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.accentNote,
    this.emphasize = false,
  });

  final String title;
  final String? subtitle;
  final String? accentNote;
  final Widget child;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: emphasize
            ? colors.primaryContainer.withValues(alpha: 0.28)
            : colors.surfaceContainerHighest.withValues(alpha: 0.72),
        border: Border.all(
          color: emphasize
              ? colors.primary.withValues(alpha: 0.45)
              : colors.outline.withValues(alpha: 0.35),
          width: emphasize ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
          if (accentNote != null) ...[
            const SizedBox(height: 4),
            Text(
              accentNote!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _OptionPicker extends StatelessWidget {
  const _OptionPicker({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  String get _selectedLabel {
    for (final option in options) {
      if (option.$1 == value) return option.$2;
    }
    return options.isEmpty ? value : options.first.$2;
  }

  Future<void> _openSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  label,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option.$1 == value;
                      return Material(
                        color: isSelected
                            ? colors.primaryContainer.withValues(alpha: 0.55)
                            : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(ctx).pop(option.$1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option.$2,
                                    style: Theme.of(ctx).textTheme.bodyMedium
                                        ?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: colors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: colors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openSheet(context),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.55),
                  width: 1.3,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedLabel.isEmpty
                            ? l10n.agentSelectOption
                            : _selectedLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UsageOverview extends StatelessWidget {
  const _UsageOverview({
    required this.today,
    required this.week,
    required this.all,
    required this.daily,
    required this.currency,
  });

  final AgentUsageBucket today;
  final AgentUsageBucket week;
  final AgentUsageBucket all;
  final List<AgentDailyUsage> daily;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final days = daily.isNotEmpty
        ? daily
        : [
            for (var i = 6; i >= 0; i--)
              AgentDailyUsage(
                date: DateTime.now()
                    .subtract(Duration(days: i))
                    .toIso8601String()
                    .substring(0, 10),
                spentMl: 0,
                refueledMl: 0,
              ),
          ];
    final maxBar = days.fold<int>(
      1,
      (m, d) => [
        m,
        d.spentMl,
        d.refueledMl,
      ].reduce((a, b) => a > b ? a : b),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _UsageStatChip(
                label: l10n.agentUsageToday,
                value: l10n.agentUsageCompactSpent('${today.fuelMl}'),
                color: colors.error,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _UsageStatChip(
                label: l10n.agentUsageWeek,
                value: l10n.agentUsageCompactSpent('${week.fuelMl}'),
                color: colors.tertiary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _UsageStatChip(
                label: l10n.agentUsageAll,
                value: l10n.agentUsageCompactSpent('${all.fuelMl}'),
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.agentUsageCost(
            all.estimatedCost.toStringAsFixed(3),
            currency,
          ),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.agentUsageWeekChart,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _DayBars(
                      day: day,
                      maxValue: maxBar,
                      spentColor: colors.error.withValues(alpha: 0.85),
                      refuelColor: colors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _LegendDot(color: colors.error.withValues(alpha: 0.85)),
            const SizedBox(width: 4),
            Text(
              l10n.agentUsageLegendSpent,
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(width: 12),
            _LegendDot(color: colors.primary),
            const SizedBox(width: 4),
            Text(
              l10n.agentUsageLegendRefuel,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _UsageStatChip extends StatelessWidget {
  const _UsageStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBars extends StatelessWidget {
  const _DayBars({
    required this.day,
    required this.maxValue,
    required this.spentColor,
    required this.refuelColor,
  });

  final AgentDailyUsage day;
  final int maxValue;
  final Color spentColor;
  final Color refuelColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekday = () {
      final parsed = DateTime.tryParse(day.date);
      if (parsed == null) return '·';
      return DateFormat.E(Localizations.localeOf(context).toString())
          .format(parsed);
    }();
    final spentH = (78 * day.spentMl / maxValue).clamp(3.0, 78.0);
    final refuelH = (78 * day.refueledMl / maxValue).clamp(
      day.refueledMl > 0 ? 3.0 : 0.0,
      78.0,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: day.spentMl > 0 ? spentH : 2,
                    decoration: BoxDecoration(
                      color: day.spentMl > 0
                          ? spentColor
                          : theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.35,
                            ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: day.refueledMl > 0 ? refuelH : 2,
                    decoration: BoxDecoration(
                      color: day.refueledMl > 0
                          ? refuelColor
                          : theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.35,
                            ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          weekday,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.low,
    required this.high,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String low;
  final String high;
  final int value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
            Text('$value/10'),
          ],
        ),
        Slider(value: value.toDouble(), min: 0, max: 10, divisions: 10, onChanged: onChanged),
        Row(
          children: [
            Expanded(
              child: Text(
                low,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              high,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _NotesBlock extends StatelessWidget {
  const _NotesBlock({
    required this.title,
    required this.notes,
    required this.empty,
    required this.onForget,
  });

  final String title;
  final List<AgentNote> notes;
  final String empty;
  final Future<void> Function(String noteId) onForget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        if (notes.isEmpty)
          Text(
            empty,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...notes.take(12).map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '• ${note.body}',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => onForget(note.id),
                    child: Text(
                      l10n.agentNoteForget,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

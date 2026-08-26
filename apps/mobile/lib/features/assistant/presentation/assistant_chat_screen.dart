import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../maintenance/maintenance.dart';
import '../../maintenance/maintenance_controller.dart';
import '../../vehicle/vehicle_controller.dart';
import '../assistant.dart';
import '../assistant_controller.dart';
import 'assistant_threads_screen.dart';

class AssistantChatScreen extends ConsumerStatefulWidget {
  const AssistantChatScreen({
    required this.threadId,
    this.initialPrompt,
    super.key,
  });

  final String threadId;
  final String? initialPrompt;

  @override
  ConsumerState<AssistantChatScreen> createState() =>
      _AssistantChatScreenState();
}

class _AssistantChatScreenState extends ConsumerState<AssistantChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};
  var _seedSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final locale = Localizations.localeOf(context).languageCode;
      final vehicleId =
          ref.read(vehicleSetupControllerProvider).activeVehicle?.id;
      if (vehicleId != null) {
        unawaited(
          ref
              .read(maintenanceControllerProvider.notifier)
              .ensurePlan(vehicleId, locale: locale),
        );
      }
      await ref
          .read(assistantControllerProvider.notifier)
          .openThread(widget.threadId, locale: locale);
      if (!mounted) return;
      await _maybeSendSeed();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String messageId) =>
      _messageKeys.putIfAbsent(messageId, GlobalKey.new);

  Future<void> _maybeSendSeed() async {
    final prompt = widget.initialPrompt?.trim();
    if (_seedSent || prompt == null || prompt.isEmpty) return;
    final existing = ref
        .read(assistantControllerProvider)
        .threadById(widget.threadId);
    if (existing == null) return;
    if (existing.messages.isNotEmpty) {
      _seedSent = true;
      return;
    }
    _seedSent = true;
    await _sendText(prompt);
  }

  Future<void> _send() async {
    final text = _input.text;
    _input.clear();
    await _sendText(text);
  }

  Future<void> _sendText(String text) async {
    final vehicle = ref.read(vehicleSetupControllerProvider).activeVehicle;
    final locale = Localizations.localeOf(context).languageCode;
    final beforeCount =
        ref
            .read(assistantControllerProvider)
            .threadById(widget.threadId)
            ?.messages
            .length ??
        0;
    await ref
        .read(assistantControllerProvider.notifier)
        .sendMessage(
          threadId: widget.threadId,
          text: text,
          locale: locale,
          vehicle: vehicle,
        );
    if (!mounted) return;
    ref.invalidate(agentEnergyProvider);
    final state = ref.read(assistantControllerProvider);
    if (state.isFuelEmpty) {
      await _showFuelEmptyDialog();
      return;
    }
    final thread = state.threadById(widget.threadId);
    if (thread == null) return;
    ChatMessage? assistant;
    for (var i = thread.messages.length - 1; i >= beforeCount; i--) {
      if (thread.messages[i].role == ChatRole.assistant) {
        assistant = thread.messages[i];
        break;
      }
    }
    if (assistant == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;
    await _scrollToMessageStart(assistant.id);
  }

  Future<void> _scrollToMessageStart(String messageId) async {
    final key = _messageKeys[messageId];
    final ctx = key?.currentContext;
    if (ctx == null) {
      if (_scroll.hasClients) {
        await _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
      return;
    }
    await Scrollable.ensureVisible(
      ctx,
      alignment: 0.08,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _showChatGuide() async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.assistantChatGuideTitle),
        content: Text(
          l10n.assistantChatGuideBody,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.odometerPickerConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _showFuelEmptyDialog() async {
    final l10n = context.l10n;
    final goRefuel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.generating_tokens_outlined),
        title: Text(l10n.agentFuelEmptyTitle),
        content: Text(l10n.agentFuelEmptyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.agentFuelEmptyLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.agentFuelEmptyRefuel),
          ),
        ],
      ),
    );
    if (!mounted) return;
    ref.read(assistantControllerProvider.notifier).clearError();
    if (goRefuel == true) {
      await context.push('/ai/agent');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantControllerProvider);
    final thread = state.threadById(widget.threadId);
    final vehicle = ref.watch(vehicleSetupControllerProvider).activeVehicle;
    final energy = ref.watch(agentEnergyProvider).asData?.value;
    final colors = Theme.of(context).colorScheme;
    final showLowEnergy = energy != null && energy.isLow && !state.isFuelEmpty;

    if (thread == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.aiAssistant),
          leading: IconButton(
            onPressed: () => context.go('/assistant'),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(child: Text(context.l10n.assistantThreadMissing)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          thread.title.isEmpty ? context.l10n.aiAssistant : thread.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          onPressed: () => context.go('/assistant'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton.icon(
            key: const Key('assistant-chat-guide'),
            onPressed: _showChatGuide,
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: Text(context.l10n.assistantChatGuideAction),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.isFuelEmpty)
              Material(
                color: colors.errorContainer.withValues(alpha: 0.55),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.agentFuelEmptyBanner,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onErrorContainer),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/ai/agent'),
                        child: Text(context.l10n.agentFuelEmptyRefuel),
                      ),
                    ],
                  ),
                ),
              ),
            if (state.error != null &&
                state.error!.isNotEmpty &&
                !state.isFuelEmpty)
              Material(
                color: colors.errorContainer.withValues(alpha: 0.7),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.error!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onErrorContainer),
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.close,
                        onPressed: () => ref
                            .read(assistantControllerProvider.notifier)
                            .clearError(),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            if (showLowEnergy)
              Material(
                color: const Color(0xFFFFF1E6),
                child: InkWell(
                  onTap: () async {
                    await context.push('/ai/agent');
                    ref.invalidate(agentEnergyProvider);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.generating_tokens_outlined,
                          color: Color(0xFFC45C1A),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.agentEnergyLowTitle,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: const Color(0xFFC45C1A),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Text(
                                context.l10n.agentEnergyLowBanner,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF8A4B1A),
                                      height: 1.25,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          context.l10n.agentEnergyLowAction,
                          style: const TextStyle(
                            color: Color(0xFFC45C1A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                key: const Key('assistant-chat-messages'),
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                itemCount:
                    thread.messages.length +
                    (state.sending ? 1 : 0) +
                    (_showChatQuickStarts(thread, state.sending) ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_showChatQuickStarts(thread, state.sending) &&
                      index == 0) {
                    return _ChatQuickStarts(
                      onPick: (prompt) => _sendText(prompt),
                    );
                  }
                  final messageIndex = _showChatQuickStarts(
                        thread,
                        state.sending,
                      )
                      ? index - 1
                      : index;
                  if (state.sending &&
                      messageIndex == thread.messages.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Image.asset(
                              'assets/branding/agent_companion_widget.png',
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHigh,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                                bottomRight: Radius.circular(18),
                                bottomLeft: Radius.circular(6),
                              ),
                            ),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final message = thread.messages[messageIndex];
                  final outgoing = message.role == ChatRole.user;
                  final bubble = ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                    ),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                      decoration: BoxDecoration(
                        color: outgoing
                            ? Theme.of(context).colorScheme.primaryContainer
                            : colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(outgoing ? 18 : 6),
                          bottomRight: Radius.circular(outgoing ? 6 : 18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        message.content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: outgoing ? Colors.white : colors.onSurface,
                          height: 1.35,
                        ),
                      ),
                    ),
                  );
                  if (outgoing) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: bubble,
                      ),
                    );
                  }
                  final spent = message.tokensSpent;
                  return Padding(
                    key: _keyFor(message.id),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: Image.asset(
                                'assets/branding/agent_companion_widget.png',
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 8),
                            bubble,
                          ],
                        ),
                        if (spent != null && spent > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 40, top: 3),
                            child: Text(
                              context.l10n.assistantTokensSpent(spent),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('assistant-chat-input'),
                            controller: _input,
                            enabled: vehicle != null,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: vehicle == null
                                  ? context.l10n.assistantNeedsVehicle
                                  : context.l10n.message,
                            ),
                          ),
                        ),
                        IconButton.filled(
                          key: const Key('assistant-chat-send'),
                          onPressed: state.sending || vehicle == null
                              ? null
                              : _send,
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _showChatQuickStarts(ChatThread thread, bool sending) {
    if (sending) return false;
    return !thread.messages.any((m) => m.role == ChatRole.user);
  }
}

class _ChatQuickStarts extends ConsumerWidget {
  const _ChatQuickStarts({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final plan = ref.watch(maintenanceControllerProvider).plan;
    final percent = plan == null
        ? null
        : historyCompletenessPercent(plan.items);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              percent == null
                  ? l10n.assistantChatEmptyHistoryUnknown
                  : l10n.assistantChatEmptyHistory(percent),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              key: const Key('assistant-fill-history'),
              onPressed: () => context.push('/history/wizard'),
              icon: const Icon(Icons.checklist_outlined, size: 18),
              label: Text(l10n.assistantChatEmptyHistoryCta),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.assistantChatEmptyIntro,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.assistantChatEmptyTopicsLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            _ChatTopicLine(
              key: const Key('chat-quick-service'),
              label: l10n.assistantQuickStartService,
              onTap: () => onPick(l10n.assistantQuickStartServicePrompt),
            ),
            _ChatTopicLine(
              key: const Key('chat-quick-symptom'),
              label: l10n.assistantQuickStartSymptom,
              onTap: () => onPick(l10n.assistantQuickStartSymptomPrompt),
            ),
            _ChatTopicLine(
              key: const Key('chat-quick-workshop'),
              label: l10n.assistantQuickStartWorkshop,
              onTap: () => onPick(l10n.assistantQuickStartWorkshopPrompt),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.assistantChatEmptyOwnHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTopicLine extends StatelessWidget {
  const _ChatTopicLine({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '•  ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: colors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: colors.primary.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}












import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/locale_controller.dart';
import '../../../l10n/l10n.dart';
import '../../agent_profile/agent_profile_api.dart';
import '../../agent_profile/presentation/agent_intro_card.dart';
import '../../vehicle/vehicle_controller.dart';
import '../assistant.dart';
import '../assistant_controller.dart';

final agentEnergyProvider = FutureProvider.autoDispose<AgentFuel>((ref) async {
  final locale = ref.read(activeLocaleProvider).languageCode;
  final vehicleId = ref.watch(vehicleSetupControllerProvider).activeVehicle?.id;
  try {
    final profile = await ref
        .read(agentProfileApiClientProvider)
        .fetch(locale: locale, vehicleId: vehicleId);
    return profile.fuel;
  } on Object {
    return AgentFuel.fallbackOk;
  }
});

class AssistantScreen extends ConsumerWidget {
  const AssistantScreen({super.key});

  Future<void> _createChat(
    BuildContext context,
    WidgetRef ref, {
    String? initialPrompt,
  }) async {
    final router = GoRouter.of(context);
    final title = context.l10n.assistantNewChat;
    final thread = await ref
        .read(assistantControllerProvider.notifier)
        .createThread(title: title);
    router.go('/ai/chat/${thread.id}', extra: initialPrompt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assistantControllerProvider);
    final energyAsync = ref.watch(agentEnergyProvider);
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final emptyActive =
        !state.loading && state.visibleThreads.isEmpty && state.listTab == 0;
    final brightness = Theme.of(context).brightness;
    final topGlow = brightness == Brightness.dark
        ? colors.primaryContainer.withValues(alpha: 0.45)
        : colors.primary.withValues(alpha: 0.18);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              topGlow,
              colors.surface,
              colors.surface,
            ],
            stops: const [0, 0.32, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AgentIntroCard(
                  energy: energyAsync.asData?.value ?? AgentFuel.fallbackOk,
                  loading: energyAsync.isLoading,
                  onOpenProfile: () async {
                    await context.push('/ai/agent');
                    ref.invalidate(agentEnergyProvider);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.agentIntroChatsLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!emptyActive)
                      SegmentedButton<int>(
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        segments: [
                          ButtonSegment(
                            value: 0,
                            label: Text(context.l10n.assistantTopicsActive),
                          ),
                          ButtonSegment(
                            value: 1,
                            label: Text(context.l10n.assistantTopicsArchive),
                          ),
                        ],
                        selected: {state.listTab},
                        onSelectionChanged: (value) {
                          ref
                              .read(assistantControllerProvider.notifier)
                              .setListTab(value.first);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator())
                      : state.visibleThreads.isEmpty
                      ? state.listTab == 0
                            ? _TopicsQuickStarts(
                                onPick: (prompt) => _createChat(
                                  context,
                                  ref,
                                  initialPrompt: prompt,
                                ),
                              )
                            : Center(
                                key: const Key('assistant-topics-empty'),
                                child: Text(
                                  context.l10n.assistantArchiveEmpty,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                              )
                      : ListView.separated(
                          key: const Key('assistant-topics-list'),
                          padding: const EdgeInsets.only(bottom: 4),
                          itemCount: state.visibleThreads.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final thread = state.visibleThreads[index];
                            return _TopicTile(
                              thread: thread,
                              locale: locale,
                            );
                          },
                        ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('assistant-new-chat'),
                    onPressed: () => _createChat(context, ref),
                    icon: const Icon(Icons.add_comment_outlined, size: 20),
                    label: Text(
                      context.l10n.assistantNewChat,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      elevation: 2,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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

class _TopicsQuickStarts extends StatelessWidget {
  const _TopicsQuickStarts({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return KeyedSubtree(
      key: const Key('assistant-topics-empty'),
      child: ListView(
        padding: const EdgeInsets.only(top: 4),
        children: [
          Text(
            l10n.assistantChatEmptyIntro,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.assistantChatEmptyTopicsLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          _QuickStartTile(
            key: const Key('assistant-quick-service'),
            label: l10n.assistantQuickStartService,
            onTap: () => onPick(l10n.assistantQuickStartServicePrompt),
          ),
          const SizedBox(height: 8),
          _QuickStartTile(
            key: const Key('assistant-quick-symptom'),
            label: l10n.assistantQuickStartSymptom,
            onTap: () => onPick(l10n.assistantQuickStartSymptomPrompt),
          ),
          const SizedBox(height: 8),
          _QuickStartTile(
            key: const Key('assistant-quick-workshop'),
            label: l10n.assistantQuickStartWorkshop,
            onTap: () => onPick(l10n.assistantQuickStartWorkshopPrompt),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.assistantChatEmptyOwnHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStartTile extends StatelessWidget {
  const _QuickStartTile({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outline.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicTile extends ConsumerStatefulWidget {
  const _TopicTile({required this.thread, required this.locale});

  final ChatThread thread;
  final String locale;

  @override
  ConsumerState<_TopicTile> createState() => _TopicTileState();
}

class _TopicTileState extends ConsumerState<_TopicTile> {
  var _editing = false;
  var _saving = false;
  late final TextEditingController _title;
  late final FocusNode _focus;

  ChatThread get thread => widget.thread;
  String get locale => widget.locale;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: thread.title);
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _TopicTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.thread.title != thread.title) {
      _title.text = thread.title;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _editing = true;
      _title.text = thread.title;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      _title.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _title.text.length,
      );
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _title.text = thread.title;
    });
  }

  Future<void> _saveEdit() async {
    if (_saving) return;
    final next = _title.text.trim();
    if (next.isEmpty || next == thread.title.trim()) {
      _cancelEdit();
      return;
    }
    setState(() => _saving = true);
    final notifier = ref.read(assistantControllerProvider.notifier);
    try {
      await notifier.renameThread(thread.id, next, locale: locale);
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  String _previewText(ChatThread thread) {
    if (thread.messages.isEmpty) return '';
    final last = thread.messages.last;
    final raw = last.content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (raw.isEmpty) return '';
    return raw.length <= 72 ? raw : '${raw.substring(0, 72).trimRight()}…';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final controller = ref.read(assistantControllerProvider.notifier);
    final titleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.1,
    );
    final preview = _previewText(thread);
    final when = DateFormat.MMMd(
      Localizations.localeOf(context).toString(),
    ).format(thread.updatedAt.toLocal());

    return Material(
      color: colors.surfaceContainerHighest,
      elevation: 0,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: Key('assistant-topic-${thread.id}'),
        borderRadius: BorderRadius.circular(8),
        onTap: _editing
            ? null
            : () async {
                await controller.openThread(thread.id, locale: locale);
                if (context.mounted) {
                  context.push('/ai/chat/${thread.id}');
                }
              },
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 5, 2, 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: colors.surfaceContainerHighest,
            border: Border.all(
              color: _editing
                  ? colors.primary
                  : colors.outline.withValues(alpha: 0.45),
              width: _editing ? 1.2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _editing
                    ? TextField(
                        key: Key('assistant-topic-title-field-${thread.id}'),
                        controller: _title,
                        focusNode: _focus,
                        enabled: !_saving,
                        maxLength: 80,
                        maxLines: 1,
                        style: titleStyle,
                        cursorColor: colors.primary,
                        decoration: InputDecoration(
                          isDense: true,
                          counterText: '',
                          border: InputBorder.none,
                          hintText: context.l10n.assistantRenameHint,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _saveEdit(),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  thread.title.isEmpty
                                      ? context.l10n.assistantNewChat
                                      : thread.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle,
                                ),
                              ),
                              if (thread.isResolved) ...[
                                const SizedBox(width: 6),
                                Text(
                                  context.l10n.assistantTopicResolved,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Text(
                                when,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 10,
                                      height: 1,
                                    ),
                              ),
                            ],
                          ),
                          if (preview.isNotEmpty)
                            Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    height: 1.2,
                                    fontSize: 11,
                                  ),
                            ),
                        ],
                      ),
              ),
              if (_editing) ...[
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    key: Key('assistant-topic-rename-cancel-${thread.id}'),
                    tooltip: context.l10n.cancel,
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    onPressed: _saving ? null : _cancelEdit,
                    icon: const Icon(Icons.close),
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    key: Key('assistant-topic-rename-save-${thread.id}'),
                    tooltip: context.l10n.save,
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    onPressed: _saving ? null : _saveEdit,
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                  ),
                ),
              ] else
                SizedBox(
                  width: 28,
                  height: 28,
                  child: PopupMenuButton<String>(
                  key: Key('assistant-topic-menu-${thread.id}'),
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  onSelected: (value) async {
                    switch (value) {
                      case 'rename':
                        _startEdit();
                      case 'resolve':
                        await controller.setThreadStatus(
                          thread.id,
                          ChatThreadStatus.resolved,
                          locale: locale,
                        );
                      case 'active':
                        await controller.setThreadStatus(
                          thread.id,
                          ChatThreadStatus.active,
                          locale: locale,
                        );
                      case 'archive':
                        await controller.setThreadStatus(
                          thread.id,
                          ChatThreadStatus.archived,
                          locale: locale,
                        );
                      case 'restore':
                        await controller.setThreadStatus(
                          thread.id,
                          ChatThreadStatus.active,
                          locale: locale,
                        );
                      case 'delete':
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                              ctx.l10n.assistantDeleteTopicConfirmTitle,
                            ),
                            content: Text(
                              ctx.l10n.assistantDeleteTopicConfirmBody,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: Text(ctx.l10n.cancel),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: Text(
                                  ctx.l10n.assistantDeleteTopicConfirmAction,
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await controller.deleteThread(
                            thread.id,
                            locale: locale,
                          );
                        }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Text(context.l10n.assistantRenameTopic),
                    ),
                    if (!thread.isArchived && !thread.isResolved)
                      PopupMenuItem(
                        value: 'resolve',
                        child: Text(context.l10n.assistantMarkResolved),
                      ),
                    if (thread.isResolved)
                      PopupMenuItem(
                        value: 'active',
                        child: Text(context.l10n.assistantMarkActive),
                      ),
                    if (!thread.isArchived)
                      PopupMenuItem(
                        value: 'archive',
                        child: Text(context.l10n.assistantArchiveTopic),
                      )
                    else ...[
                      PopupMenuItem(
                        value: 'restore',
                        child: Text(context.l10n.assistantRestoreTopic),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          context.l10n.assistantDeleteTopic,
                          style: TextStyle(color: colors.error),
                        ),
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

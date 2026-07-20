import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/automotive_widgets.dart';
import '../../../l10n/l10n.dart';
import '../../vehicle/vehicle_controller.dart';
import '../assistant_config.dart';
import '../assistant_controller.dart';

class AssistantScreen extends ConsumerWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(vehicleSetupControllerProvider).activeVehicle;
    final state = ref.watch(assistantControllerProvider);
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.aiAssistant,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (!AssistantLlmConfig.isConfigured)
                Icon(
                  Icons.key_off_outlined,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
          if (vehicle != null) ...[
            const SizedBox(height: 4),
            Text(
              context.l10n.selectedVehicleContext(vehicle.make, vehicle.model),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('assistant-new-chat'),
            onPressed: () async {
              final router = GoRouter.of(context);
              final title = context.l10n.assistantNewChat;
              final thread = await ref
                  .read(assistantControllerProvider.notifier)
                  .createThread(title: title);
              router.go('/ai/chat/${thread.id}');
            },
            icon: const Icon(Icons.add_comment_outlined),
            label: Text(context.l10n.assistantNewChat),
          ),
          const SizedBox(height: 12),
          TechnicalLabel(context.l10n.assistantTopicsTitle),
          const SizedBox(height: 6),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.threads.isEmpty
                ? AutomotivePanel(
                    key: const Key('assistant-topics-empty'),
                    child: Text(context.l10n.assistantTopicsEmpty),
                  )
                : ListView.separated(
                    key: const Key('assistant-topics-list'),
                    itemCount: state.threads.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final thread = state.threads[index];
                      final preview = thread.messages.isEmpty
                          ? context.l10n.assistantEmptyThread
                          : thread.messages.last.content;
                      return Material(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          key: Key('assistant-topic-${thread.id}'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colors.outlineVariant),
                          ),
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(
                            thread.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            key: Key('assistant-topic-delete-${thread.id}'),
                            tooltip: context.l10n.assistantDeleteTopic,
                            onPressed: () => ref
                                .read(assistantControllerProvider.notifier)
                                .deleteThread(thread.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                          onTap: () => context.push('/ai/chat/${thread.id}'),
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

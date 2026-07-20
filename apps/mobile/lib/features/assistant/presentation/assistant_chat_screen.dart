import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/automotive_widgets.dart';
import '../../../l10n/l10n.dart';
import '../../vehicle/vehicle_controller.dart';
import '../assistant.dart';
import '../assistant_config.dart';
import '../assistant_controller.dart';

class AssistantChatScreen extends ConsumerStatefulWidget {
  const AssistantChatScreen({required this.threadId, super.key});

  final String threadId;

  @override
  ConsumerState<AssistantChatScreen> createState() =>
      _AssistantChatScreenState();
}

class _AssistantChatScreenState extends ConsumerState<AssistantChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    _input.clear();
    final vehicle = ref.read(vehicleSetupControllerProvider).activeVehicle;
    await ref
        .read(assistantControllerProvider.notifier)
        .sendMessage(
          threadId: widget.threadId,
          text: text,
          vehicle: vehicle,
        );
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_scroll.hasClients) {
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantControllerProvider);
    final thread = state.threadById(widget.threadId);
    final colors = Theme.of(context).colorScheme;

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
        title: Text(thread.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          key: const Key('assistant-chat-back'),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/assistant');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          if (!AssistantLlmConfig.isConfigured)
            Material(
              color: colors.errorContainer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Text(
                  context.l10n.assistantKeyMissing,
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
            ),
          if (state.error != null)
            Material(
              color: colors.errorContainer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Text(
                  state.error!,
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              key: const Key('assistant-chat-messages'),
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: thread.messages.length + (state.sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (state.sending && index == thread.messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final message = thread.messages[index];
                final outgoing = message.role == ChatRole.user;
                return Align(
                  alignment: outgoing
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.84,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: outgoing
                            ? colors.primaryContainer
                            : colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(message.content),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: AutomotivePanel(
                padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('assistant-chat-input'),
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: context.l10n.message,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('assistant-chat-send'),
                      onPressed: state.sending ? null : _send,
                      icon: const Icon(Icons.send_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

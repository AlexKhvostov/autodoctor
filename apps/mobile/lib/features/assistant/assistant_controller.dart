import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../vehicle/vehicle.dart';
import 'assistant.dart';
import 'assistant_llm.dart';
import 'assistant_store.dart';

class AssistantState {
  const AssistantState({
    this.threads = const [],
    this.loading = true,
    this.sending = false,
    this.error,
  });

  final List<ChatThread> threads;
  final bool loading;
  final bool sending;
  final String? error;

  AssistantState copyWith({
    List<ChatThread>? threads,
    bool? loading,
    bool? sending,
    String? error,
    bool clearError = false,
  }) => AssistantState(
    threads: threads ?? this.threads,
    loading: loading ?? this.loading,
    sending: sending ?? this.sending,
    error: clearError ? null : error ?? this.error,
  );

  ChatThread? threadById(String id) =>
      threads.where((thread) => thread.id == id).firstOrNull;
}

class AssistantController extends Notifier<AssistantState> {
  final _uuid = const Uuid();
  late final AssistantThreadStore _store;
  late final AssistantLlmClient _llm;

  @override
  AssistantState build() {
    _store = ref.watch(assistantThreadStoreProvider);
    _llm = AssistantLlmClient();
    Future.microtask(load);
    return const AssistantState();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    final threads = List<ChatThread>.from(await _store.load());
    threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = state.copyWith(threads: threads, loading: false);
  }

  Future<ChatThread> createThread({String? title}) async {
    final thread = ChatThread(
      id: _uuid.v4(),
      title: title?.trim().isNotEmpty == true ? title!.trim() : 'Новый чат',
      updatedAt: DateTime.now(),
      messages: const [],
    );
    final next = [thread, ...state.threads];
    state = state.copyWith(threads: next, clearError: true);
    await _store.save(next);
    return thread;
  }

  Future<void> deleteThread(String threadId) async {
    final next = state.threads
        .where((thread) => thread.id != threadId)
        .toList(growable: false);
    state = state.copyWith(threads: next, clearError: true);
    await _store.save(next);
  }

  Future<void> sendMessage({
    required String threadId,
    required String text,
    Vehicle? vehicle,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;
    final thread = state.threadById(threadId);
    if (thread == null) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );
    var updated = thread.copyWith(
      title: thread.messages.isEmpty
          ? _titleFrom(trimmed)
          : thread.title,
      updatedAt: DateTime.now(),
      messages: [...thread.messages, userMessage],
    );
    _replaceThread(updated);
    state = state.copyWith(sending: true, clearError: true);
    await _store.save(state.threads);

    try {
      final reply = await _llm.complete(
        history: updated.messages,
        vehicleContext: vehicle == null
            ? null
            : [
                '${vehicle.make} ${vehicle.model}',
                'год: ${vehicle.productionYear}',
                if (vehicle.mileage != null)
                  'пробег: ${vehicle.mileage} ${vehicle.mileageUnit ?? 'km'}',
              ].join(', '),
      );
      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        role: ChatRole.assistant,
        content: reply,
        createdAt: DateTime.now(),
      );
      updated = updated.copyWith(
        updatedAt: DateTime.now(),
        messages: [...updated.messages, assistantMessage],
      );
      _replaceThread(updated);
      state = state.copyWith(sending: false, clearError: true);
      await _store.save(state.threads);
    } on AssistantLlmException catch (error) {
      state = state.copyWith(sending: false, error: error.message);
    } on Object catch (error) {
      state = state.copyWith(sending: false, error: error.toString());
    }
  }

  void _replaceThread(ChatThread thread) {
    final next = [
      thread,
      ...state.threads.where((item) => item.id != thread.id),
    ];
    next.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = state.copyWith(threads: next);
  }

  String _titleFrom(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 42) return compact;
    return '${compact.substring(0, 42).trimRight()}…';
  }
}

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(
      AssistantController.new,
    );

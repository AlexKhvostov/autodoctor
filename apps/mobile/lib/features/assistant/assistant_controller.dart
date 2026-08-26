import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../vehicle/vehicle.dart';
import '../vehicle/vehicle_controller.dart';
import 'assistant.dart';
import 'assistant_api.dart';
import 'assistant_store.dart';

class AssistantState {
  const AssistantState({
    this.threads = const [],
    this.archivedThreads = const [],
    this.listTab = 0,
    this.loading = true,
    this.sending = false,
    this.error,
    this.errorCode,
  });

  final List<ChatThread> threads;
  final List<ChatThread> archivedThreads;
  final int listTab; // 0 active, 1 archive
  final bool loading;
  final bool sending;
  final String? error;
  final String? errorCode;

  bool get isFuelEmpty => errorCode == 'AGENT_FUEL_EMPTY';

  AssistantState copyWith({
    List<ChatThread>? threads,
    List<ChatThread>? archivedThreads,
    int? listTab,
    bool? loading,
    bool? sending,
    String? error,
    String? errorCode,
    bool clearError = false,
  }) => AssistantState(
    threads: threads ?? this.threads,
    archivedThreads: archivedThreads ?? this.archivedThreads,
    listTab: listTab ?? this.listTab,
    loading: loading ?? this.loading,
    sending: sending ?? this.sending,
    error: clearError ? null : error ?? this.error,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
  );

  List<ChatThread> get visibleThreads =>
      listTab == 0 ? threads : archivedThreads;

  ChatThread? threadById(String id) =>
      [...threads, ...archivedThreads]
          .where((thread) => thread.id == id)
          .firstOrNull;
}

class AssistantController extends Notifier<AssistantState> {
  final _uuid = const Uuid();
  late final AssistantThreadStore _store;

  @override
  AssistantState build() {
    _store = ref.watch(assistantThreadStoreProvider);
    ref.listen(vehicleSetupControllerProvider, (previous, next) {
      if (previous?.activeVehicle?.id != next.activeVehicle?.id) {
        load();
      }
    });
    Future.microtask(load);
    return const AssistantState();
  }

  void setListTab(int tab) {
    state = state.copyWith(listTab: tab);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final api = ref.read(assistantApiClientProvider);
      const locale = 'ru';
      final active = await api.listThreads(
        locale: locale,
        status: 'active',
      );
      final archived = await api.listThreads(
        locale: locale,
        status: 'archived',
      );
      state = state.copyWith(
        threads: active,
        archivedThreads: archived,
        loading: false,
        clearError: true,
      );
      await _store.save([...active, ...archived]);
    } on AssistantApiException catch (error) {
      final local = await _store.load();
      state = state.copyWith(
        threads: local.where((t) => !t.isArchived).toList(growable: false),
        archivedThreads: local
            .where((t) => t.isArchived)
            .toList(growable: false),
        loading: false,
        error: error.message,
      );
    } on Object catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<ChatThread> createThread({
    String? title,
    List<ChatMessage> messages = const [],
    ChatTitleSource titleSource = ChatTitleSource.auto,
  }) async {
    final resolved =
        title?.trim().isNotEmpty == true ? title!.trim() : 'Новый чат';
    final thread = ChatThread(
      id: _uuid.v4(),
      title: resolved,
      updatedAt: DateTime.now(),
      messages: messages,
      titleSource: titleSource,
    );
    final next = [thread, ...state.threads];
    state = state.copyWith(threads: next, listTab: 0, clearError: true);
    await _store.save([...next, ...state.archivedThreads]);
    return thread;
  }

  Future<ChatThread> createWelcomeThread({
    required String title,
    required String welcomeMessage,
  }) {
    return createThread(
      title: title,
      titleSource: ChatTitleSource.user,
      messages: [
        ChatMessage(
          id: _uuid.v4(),
          role: ChatRole.assistant,
          content: welcomeMessage,
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> openThread(String threadId, {required String locale}) async {
    final existing = state.threadById(threadId);
    if (existing == null) return;
    if (existing.messages.isNotEmpty) return;
    try {
      final full = await ref
          .read(assistantApiClientProvider)
          .getThread(
            threadId: threadId,
            locale: locale,
          );
      _replaceThread(full);
      await _persistAll();
    } on Object {
      // Keep local stub if remote fetch fails.
    }
  }

  Future<void> renameThread(
    String threadId,
    String title, {
    required String locale,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final local = state.threadById(threadId);
    if (local == null) return;

    try {
      final updated = await ref
          .read(assistantApiClientProvider)
          .updateThread(
            threadId: threadId,
            locale: locale,
            title: trimmed,
          );
      _replaceThread(
        updated.copyWith(messages: local.messages),
      );
      await _persistAll();
    } on AssistantApiException catch (error) {
      state = state.copyWith(error: error.message);
    }
  }

  Future<void> setThreadStatus(
    String threadId,
    ChatThreadStatus status, {
    required String locale,
  }) async {
    final local = state.threadById(threadId);
    if (local == null) return;

    try {
      final updated = await ref
          .read(assistantApiClientProvider)
          .updateThread(
            threadId: threadId,
            locale: locale,
            status: status,
          );
      _applyStatusMove(updated.copyWith(messages: local.messages));
      await _persistAll();
    } on AssistantApiException catch (error) {
      state = state.copyWith(error: error.message);
    }
  }

  Future<void> deleteThread(String threadId, {required String locale}) async {
    final local = state.threadById(threadId);
    if (local == null) return;

    try {
      await ref
          .read(assistantApiClientProvider)
          .deleteThread(
            threadId: threadId,
            locale: locale,
          );
      _removeThread(threadId);
      await _persistAll();
    } on AssistantApiException catch (error) {
      state = state.copyWith(error: error.message);
    }
  }

  void _removeThread(String threadId) {
    state = state.copyWith(
      threads: state.threads.where((t) => t.id != threadId).toList(),
      archivedThreads: state.archivedThreads
          .where((t) => t.id != threadId)
          .toList(),
    );
  }

  Future<void> sendMessage({
    required String threadId,
    required String text,
    required String locale,
    Vehicle? vehicle,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;
    final thread = state.threadById(threadId);
    if (thread == null) return;

    final isFirstMessage = thread.messages.isEmpty;
    final allowAutoTitle = _allowsAutoTitle(thread);
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );
    var updated = thread.copyWith(
      title: allowAutoTitle && (isFirstMessage || _isPlaceholderTitle(thread.title))
          ? _titleFrom(trimmed)
          : thread.title,
      titleSource: allowAutoTitle ? ChatTitleSource.auto : thread.titleSource,
      updatedAt: DateTime.now(),
      messages: [...thread.messages, userMessage],
    );
    _replaceThread(updated);
    state = state.copyWith(sending: true, clearError: true);
    await _persistAll();

    try {
      final prior = updated.messages
          .where((message) => message.id != userMessage.id)
          .toList(growable: false);
      final result = await ref
          .read(assistantApiClientProvider)
          .sendMessage(
            vehicleId: vehicle?.id,
            message: trimmed,
            locale: locale,
            threadId: threadId,
            suggestTitle: allowAutoTitle &&
                (isFirstMessage || _isPlaceholderTitle(thread.title)),
            history: prior,
          );
      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        role: ChatRole.assistant,
        content: result.reply,
        createdAt: DateTime.now(),
        tokensSpent: result.tokensSpent,
      );
      final nextTitle = !allowAutoTitle
          ? updated.title
          : ((result.title != null && result.title!.trim().isNotEmpty)
                ? result.title!.trim()
                : updated.title);
      updated = updated.copyWith(
        title: nextTitle,
        titleSource: allowAutoTitle ? ChatTitleSource.auto : thread.titleSource,
        updatedAt: DateTime.now(),
        messages: [...updated.messages, assistantMessage],
        messagesCount: updated.messages.length + 1,
      );
      _replaceThread(updated);
      state = state.copyWith(sending: false, clearError: true);
      await _persistAll();
    } on AssistantApiException catch (error) {
      state = state.copyWith(
        sending: false,
        error: error.message,
        errorCode: error.code,
      );
    } on Object catch (error) {
      state = state.copyWith(
        sending: false,
        error: error.toString(),
        errorCode: 'UNKNOWN',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _applyStatusMove(ChatThread thread) {
    final without = [...state.threads, ...state.archivedThreads]
        .where((item) => item.id != thread.id)
        .toList(growable: false);
    final active = without.where((t) => !t.isArchived).toList(growable: true);
    final archived = without.where((t) => t.isArchived).toList(growable: true);
    if (thread.isArchived) {
      archived.insert(0, thread);
    } else {
      active.insert(0, thread);
    }
    active.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    archived.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = state.copyWith(threads: active, archivedThreads: archived);
  }

  void _replaceThread(ChatThread thread) {
    if (thread.isArchived) {
      final next = [
        thread,
        ...state.archivedThreads.where((item) => item.id != thread.id),
      ];
      next.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = state.copyWith(archivedThreads: next);
      return;
    }
    final next = [
      thread,
      ...state.threads.where((item) => item.id != thread.id),
    ];
    next.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = state.copyWith(threads: next);
  }

  Future<void> _persistAll() async {
    await _store.save([...state.threads, ...state.archivedThreads]);
  }

  String _titleFrom(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 42) return compact;
    return '${compact.substring(0, 42).trimRight()}…';
  }

  bool _isPlaceholderTitle(String title) {
    final normalized = title.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'новый чат' ||
        normalized == 'new chat';
  }

  /// User-locked titles stay; placeholders (even wrongly marked user) can rename.
  bool _allowsAutoTitle(ChatThread thread) =>
      thread.titleSource != ChatTitleSource.user ||
      _isPlaceholderTitle(thread.title);
}

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(
      AssistantController.new,
    );

enum ChatRole { user, assistant, system }

enum ChatThreadStatus { active, resolved, archived }

enum ChatTitleSource { auto, user }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.tokensSpent,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final int? tokensSpent;

  Map<String, Object?> toJson() => {
    'id': id,
    'role': role.name,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'tokens_spent': tokensSpent,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String? ?? '',
    role: ChatRole.values.firstWhere(
      (value) => value.name == json['role'],
      orElse: () => ChatRole.assistant,
    ),
    content: json['content'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    tokensSpent: (json['tokens_spent'] as num?)?.toInt(),
  );
}

class ChatThread {
  const ChatThread({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
    this.status = ChatThreadStatus.active,
    this.titleSource = ChatTitleSource.auto,
    this.messagesCount = 0,
    this.resolvedAt,
    this.archivedAt,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final ChatThreadStatus status;
  final ChatTitleSource titleSource;
  final int messagesCount;
  final DateTime? resolvedAt;
  final DateTime? archivedAt;

  bool get isResolved => status == ChatThreadStatus.resolved;
  bool get isArchived => status == ChatThreadStatus.archived;

  ChatThread copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    ChatThreadStatus? status,
    ChatTitleSource? titleSource,
    int? messagesCount,
    DateTime? resolvedAt,
    DateTime? archivedAt,
    bool clearResolvedAt = false,
    bool clearArchivedAt = false,
  }) => ChatThread(
    id: id,
    title: title ?? this.title,
    updatedAt: updatedAt ?? this.updatedAt,
    messages: messages ?? this.messages,
    status: status ?? this.status,
    titleSource: titleSource ?? this.titleSource,
    messagesCount: messagesCount ?? this.messagesCount,
    resolvedAt: clearResolvedAt ? null : resolvedAt ?? this.resolvedAt,
    archivedAt: clearArchivedAt ? null : archivedAt ?? this.archivedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'updated_at': updatedAt.toIso8601String(),
    'messages': messages.map((message) => message.toJson()).toList(),
    'status': status.name,
    'title_source': titleSource.name,
    'messages_count': messagesCount,
    'resolved_at': resolvedAt?.toIso8601String(),
    'archived_at': archivedAt?.toIso8601String(),
  };

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['status'] as String? ?? 'active';
    final titleSourceRaw = json['title_source'] as String? ?? 'auto';
    final messages = ((json['messages'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final count = json['messages_count'];
    return ChatThread(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(
            json['last_message_at'] as String? ??
                json['updated_at'] as String? ??
                '',
          ) ??
          DateTime.now(),
      messages: messages,
      status: ChatThreadStatus.values.firstWhere(
        (value) => value.name == statusRaw,
        orElse: () => ChatThreadStatus.active,
      ),
      titleSource: ChatTitleSource.values.firstWhere(
        (value) => value.name == titleSourceRaw,
        orElse: () => ChatTitleSource.auto,
      ),
      messagesCount: count is int ? count : messages.length,
      resolvedAt: DateTime.tryParse(json['resolved_at'] as String? ?? ''),
      archivedAt: DateTime.tryParse(json['archived_at'] as String? ?? ''),
    );
  }
}

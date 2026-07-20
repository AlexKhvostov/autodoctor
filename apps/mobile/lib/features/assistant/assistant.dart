enum ChatRole { user, assistant, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'role': role.name,
    'content': content,
    'created_at': createdAt.toIso8601String(),
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
  );
}

class ChatThread {
  const ChatThread({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  ChatThread copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) => ChatThread(
    id: id,
    title: title ?? this.title,
    updatedAt: updatedAt ?? this.updatedAt,
    messages: messages ?? this.messages,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'updated_at': updatedAt.toIso8601String(),
    'messages': messages.map((message) => message.toJson()).toList(),
  };

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    updatedAt:
        DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    messages: ((json['messages'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false),
  );
}

/// Fallback if `prompts/ai-chat-system.md` is not loaded as an asset.
const kDefaultAssistantSystemPrompt = '''
Ты — AI-ассистент приложения AutoDoctor: помощник автовладельца по обслуживанию, износу узлов, плану работ и пониманию срочности.

Роль: отвечай коротко и по делу; опирайся на факты о машине, если они переданы; если данных мало — скажи, чего не хватает.

Границы: не заменяешь диагностику на СТО; не выдумывай жёсткие регламенты OEM; не советуй опасные действия.

Стиль: язык пользователя; краткий вывод → что проверить → срочность → что сделать в AutoDoctor.
''';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'assistant.dart';
import 'assistant_config.dart';

class AssistantLlmException implements Exception {
  const AssistantLlmException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AssistantLlmClient {
  AssistantLlmClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  String? _cachedSystemPrompt;

  Future<String> systemPrompt() async {
    if (_cachedSystemPrompt != null) return _cachedSystemPrompt!;
    try {
      final fromAsset = await rootBundle.loadString(
        'assets/prompts/ai-chat-system.md',
      );
      final body = _extractPromptBody(fromAsset);
      _cachedSystemPrompt = body.isEmpty
          ? kDefaultAssistantSystemPrompt
          : body;
    } on Object {
      _cachedSystemPrompt = kDefaultAssistantSystemPrompt;
    }
    return _cachedSystemPrompt!;
  }

  Future<String> complete({
    required List<ChatMessage> history,
    String? vehicleContext,
  }) async {
    if (!AssistantLlmConfig.isConfigured) {
      throw const AssistantLlmException(
        'DEEPSEEK_API_KEY is not configured. Pass --dart-define=DEEPSEEK_API_KEY=...',
      );
    }

    final system = StringBuffer(await systemPrompt());
    if (vehicleContext != null && vehicleContext.trim().isNotEmpty) {
      system
        ..writeln()
        ..writeln('## Контекст автомобиля')
        ..writeln(vehicleContext.trim());
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': system.toString()},
      for (final message in history)
        if (message.role != ChatRole.system)
          {
            'role': message.role == ChatRole.user ? 'user' : 'assistant',
            'content': message.content,
          },
    ];

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${AssistantLlmConfig.baseUrl}/v1/chat/completions',
        data: {
          'model': AssistantLlmConfig.model,
          'messages': messages,
          'temperature': 0.4,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AssistantLlmConfig.apiKey}',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final choices = response.data?['choices'];
      if (choices is! List || choices.isEmpty) {
        throw const AssistantLlmException('Empty LLM response');
      }
      final message = (choices.first as Map)['message'];
      final content = message is Map ? message['content'] : null;
      if (content is! String || content.trim().isEmpty) {
        throw const AssistantLlmException('LLM returned no text');
      }
      return content.trim();
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      final detail = data is Map && data['error'] is Map
          ? data['error']['message']?.toString()
          : data?.toString();
      throw AssistantLlmException(
        [
          'LLM request failed',
          if (status != null) 'HTTP $status',
          if (detail != null && detail.isNotEmpty) detail,
        ].join(': '),
      );
    }
  }

  String _extractPromptBody(String markdown) {
    final marker = '---';
    final first = markdown.indexOf(marker);
    if (first < 0) return markdown.trim();
    final second = markdown.indexOf(marker, first + marker.length);
    if (second < 0) return markdown.trim();
    return markdown.substring(second + marker.length).trim();
  }
}

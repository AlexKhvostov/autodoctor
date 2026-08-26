import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/api_endpoint.dart';
import '../guest_bootstrap/guest_bootstrap.dart';
import '../guest_bootstrap/guest_bootstrap_controller.dart';
import 'assistant.dart';

class AssistantApiException implements Exception {
  const AssistantApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AssistantReply {
  const AssistantReply({
    required this.reply,
    this.title,
    this.threadId,
    this.tokensSpent,
  });

  final String reply;
  final String? title;
  final String? threadId;
  final int? tokensSpent;
}

class AssistantApiClient {
  AssistantApiClient(
    this._tokenStore, {
    Dio? dio,
    String? baseUrl,
  }) : _dio =
           dio ??
           createApiDio(
             baseUrl: baseUrl ?? compiledApiBaseUrl(),
             connectTimeout: const Duration(seconds: 15),
             receiveTimeout: const Duration(seconds: 90),
           );

  final SessionTokenStore _tokenStore;
  final Dio _dio;

  Future<Map<String, String>> _authHeaders(String locale) async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const AssistantApiException(
        'Session token missing',
        code: 'SESSION_TOKEN_REQUIRED',
      );
    }
    return {
      'X-Session-Token': token,
      'Accept-Language': locale,
    };
  }

  Future<List<ChatThread>> listThreads({
    String? vehicleId,
    required String locale,
    String status = 'active',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/assistant/threads',
        queryParameters: {'status': status},
        options: Options(headers: await _authHeaders(locale)),
      );
      final items = response.data?['items'];
      if (items is! List) return const [];
      return items
          .whereType<Map>()
          .map((item) => ChatThread.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Future<ChatThread> getThread({
    String? vehicleId,
    required String threadId,
    required String locale,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/assistant/threads/$threadId',
        options: Options(headers: await _authHeaders(locale)),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AssistantApiException(
          'Empty thread response',
          code: 'UNEXPECTED_RESPONSE',
        );
      }
      return ChatThread.fromJson(data);
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Future<ChatThread> updateThread({
    String? vehicleId,
    required String threadId,
    required String locale,
    String? title,
    ChatThreadStatus? status,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/assistant/threads/$threadId',
        data: {
          if (title != null) 'title': title,
          if (status != null) 'status': status.name,
        },
        options: Options(headers: await _authHeaders(locale)),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AssistantApiException(
          'Empty thread response',
          code: 'UNEXPECTED_RESPONSE',
        );
      }
      return ChatThread.fromJson(data);
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Future<void> deleteThread({
    String? vehicleId,
    required String threadId,
    required String locale,
  }) async {
    try {
      await _dio.delete<void>(
        '/assistant/threads/$threadId',
        options: Options(headers: await _authHeaders(locale)),
      );
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Future<AssistantReply> sendMessage({
    String? vehicleId,
    required String message,
    required String locale,
    String? threadId,
    bool suggestTitle = false,
    List<ChatMessage> history = const [],
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/assistant/messages',
        data: {
          'message': message,
          'thread_id': ?threadId,
          if (vehicleId != null && vehicleId.isNotEmpty) 'vehicle_id': vehicleId,
          'suggest_title': suggestTitle,
          'history': [
            for (final item in history)
              if (item.role == ChatRole.user || item.role == ChatRole.assistant)
                {
                  'role': item.role == ChatRole.user ? 'user' : 'assistant',
                  'content': item.content,
                },
          ],
        },
        options: Options(headers: await _authHeaders(locale)),
      );
      final reply = response.data?['reply'];
      if (reply is! String || reply.trim().isEmpty) {
        throw const AssistantApiException(
          'Empty assistant reply',
          code: 'UNEXPECTED_RESPONSE',
        );
      }
      final titleRaw = response.data?['title'];
      final title = titleRaw is String && titleRaw.trim().isNotEmpty
          ? titleRaw.trim()
          : null;
      final threadRaw = response.data?['thread_id'];
      final serverThreadId = threadRaw is String && threadRaw.isNotEmpty
          ? threadRaw
          : null;
      final spentRaw = response.data?['tokens_spent'];
      final tokensSpent = spentRaw is num ? spentRaw.toInt() : null;
      return AssistantReply(
        reply: reply.trim(),
        title: title,
        threadId: serverThreadId,
        tokensSpent: tokensSpent,
      );
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  AssistantApiException _mapDio(DioException error) {
    final data = error.response?.data;
    String? code;
    String? message;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      code = err['code']?.toString();
      message = err['message']?.toString();
    }
    return AssistantApiException(
      message?.isNotEmpty == true
          ? message!
          : 'Assistant request failed (${error.response?.statusCode ?? 'network'})',
      code: code,
    );
  }
}

final assistantApiClientProvider = Provider<AssistantApiClient>((ref) {
  return AssistantApiClient(
    ref.watch(sessionTokenStoreProvider),
    baseUrl: ref.watch(apiBaseUrlProvider),
  );
});

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'guest_bootstrap.dart';

const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl {
  if (_configuredApiBaseUrl.isNotEmpty) {
    return _configuredApiBaseUrl;
  }
  if (!kIsWeb && Platform.isAndroid) {
    return 'http://10.0.2.2:8000/api/v1';
  }
  return 'http://localhost:8000/api/v1';
}

class SecureSessionTokenStore implements SessionTokenStore {
  SecureSessionTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'anonymous_session_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  @override
  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _tokenKey);
}

class DioGuestBootstrapRepository implements GuestBootstrapRepository {
  DioGuestBootstrapRepository(
    this._tokenStore, {
    required String locale,
    Dio? dio,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid(),
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: apiBaseUrl,
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 15),
               headers: {
                 'Accept': 'application/json',
                 'Accept-Language': locale,
               },
             ),
           );

  final SessionTokenStore _tokenStore;
  final Uuid _uuid;
  final Dio _dio;

  @override
  Future<CreatedGuestSession> createAnonymousSession({
    required String locale,
    required String platform,
    required String appVersion,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sessions/anonymous',
        data: {
          'locale': locale,
          'platform': platform,
          'app_version': appVersion,
        },
        options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
      );
      final body = _body(response);
      return CreatedGuestSession(
        session: _session(_map(body['session'])),
        token: body['session_token'] as String,
      );
    } on DioException catch (error) {
      throw _failure(error);
    } on FormatException {
      throw const GuestBootstrapFailure(
        safeMessage: '',
        kind: GuestBootstrapFailureKind.unexpectedResponse,
      );
    } on TypeError {
      throw const GuestBootstrapFailure(
        safeMessage: '',
        kind: GuestBootstrapFailureKind.unexpectedResponse,
      );
    }
  }

  @override
  Future<GuestSession> getCurrentSession() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/sessions/current',
        options: await _authenticatedOptions(),
      );
      return _session(_body(response));
    } on DioException catch (error) {
      throw _failure(error);
    } on FormatException {
      throw const GuestBootstrapFailure(
        safeMessage: '',
        kind: GuestBootstrapFailureKind.unexpectedResponse,
      );
    } on TypeError {
      throw const GuestBootstrapFailure(
        safeMessage: '',
        kind: GuestBootstrapFailureKind.unexpectedResponse,
      );
    }
  }

  @override
  Future<List<ConsentDocument>> getCurrentConsents() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/consents/current',
      );
      final items = _body(response)['items'];
      if (items is! List) {
        throw const FormatException();
      }
      return items
          .map((item) => ConsentDocument.fromJson(_map(item)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _failure(error);
    } on FormatException {
      throw const GuestBootstrapFailure(
        safeMessage: '',
        kind: GuestBootstrapFailureKind.unexpectedResponse,
      );
    } on TypeError {
      throw const GuestBootstrapFailure(
        safeMessage: '',
        kind: GuestBootstrapFailureKind.unexpectedResponse,
      );
    }
  }

  @override
  Future<void> saveConsents(List<ConsentDecision> decisions) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/consents',
        data: {'decisions': decisions.map((item) => item.toJson()).toList()},
        options: await _authenticatedOptions(mutation: true),
      );
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  Future<Options> _authenticatedOptions({bool mutation = false}) async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const GuestBootstrapFailure(
        code: 'SESSION_TOKEN_REQUIRED',
        statusCode: 401,
        safeMessage: '',
        kind: GuestBootstrapFailureKind.unavailable,
      );
    }
    return Options(
      headers: {
        'X-Session-Token': token,
        if (mutation) 'Idempotency-Key': _uuid.v4(),
      },
    );
  }

  static Map<String, dynamic> _body(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      throw const FormatException();
    }
    return data;
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map) {
      throw const FormatException();
    }
    return Map<String, dynamic>.from(value);
  }

  static GuestSession _session(Map<String, dynamic> json) {
    return GuestSession(
      id: json['id'] as String,
      status: json['status'] as String,
    );
  }

  static GuestBootstrapFailure _failure(DioException exception) {
    final response = exception.response;
    String? code;
    String? requestId;
    final data = response?.data;
    if (data is Map) {
      final error = data['error'];
      if (error is Map) {
        code = error['code'] as String?;
        requestId = error['request_id'] as String?;
      }
    }
    requestId ??= response?.headers.value('x-request-id');
    final serverMessage = data is Map && data['error'] is Map
        ? (data['error'] as Map)['message'] as String?
        : null;
    return GuestBootstrapFailure(
      code: code,
      requestId: requestId,
      statusCode: response?.statusCode,
      safeMessage: serverMessage ?? '',
      kind: serverMessage != null
          ? null
          : response == null
          ? GuestBootstrapFailureKind.network
          : GuestBootstrapFailureKind.unavailable,
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../guest_bootstrap/guest_bootstrap.dart';
import '../guest_bootstrap/guest_bootstrap_controller.dart';
import '../vehicle/vehicle_controller.dart';
import '../../app/api_endpoint.dart';

const _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  final int id;
  final String name;
  final String email;
  final String? photoUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final avatar = json['avatar_url'] ?? json['photo_url'];
    return AuthUser(
      id: id,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      photoUrl: avatar is String && avatar.trim().isNotEmpty ? avatar.trim() : null,
    );
  }

  AuthUser copyWith({
    int? id,
    String? name,
    String? email,
    String? photoUrl,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    required this.guestProfileId,
  });

  final String token;
  final AuthUser user;
  final String guestProfileId;
}

abstract interface class AuthTokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  @override
  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _tokenKey);
}

class AuthApiClient {
  AuthApiClient(
    this._tokenStore,
    this._profileStore, {
    Dio? dio,
    String? baseUrl,
  }) : _dio =
           dio ??
           createApiDio(
             baseUrl: baseUrl ?? compiledApiBaseUrl(),
             receiveTimeout: const Duration(seconds: 20),
           );

  final AuthTokenStore _tokenStore;
  final GuestProfileIdStore _profileStore;
  final Dio _dio;

  Future<AuthSession> loginWithGoogleIdToken(String idToken) async {
    final profileId = await _profileStore.read();
    try {
      return await _loginOnce(idToken, profileId);
    } on DioException catch (error) {
      // Stale local guest profile id after DB reset → retry without it.
      if (error.response?.statusCode == 422 &&
          profileId != null &&
          profileId.isNotEmpty) {
        return _loginOnce(idToken, null);
      }
      throw AuthFailure(_describeDio(error));
    }
  }

  Future<AuthSession> _loginOnce(String idToken, String? profileId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/google',
      data: {
        'id_token': idToken,
        if (profileId != null && profileId.isNotEmpty)
          'guest_profile_id': profileId,
      },
    );
    final body = response.data;
    if (body == null) {
      throw const AuthFailure('Пустой ответ сервера при входе');
    }
    final token = body['token'] as String?;
    final userRaw = body['user'];
    final guestProfileId = body['guest_profile_id'] as String?;
    if (token == null ||
        token.isEmpty ||
        userRaw is! Map ||
        guestProfileId == null ||
        guestProfileId.isEmpty) {
      throw const AuthFailure('Неожиданный ответ сервера при входе');
    }
    await _tokenStore.write(token);
    await _profileStore.write(guestProfileId);
    return AuthSession(
      token: token,
      user: AuthUser.fromJson(Map<String, dynamic>.from(userRaw)),
      guestProfileId: guestProfileId,
    );
  }

  Future<AuthUser?> currentUser() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      return null;
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final body = response.data;
      if (body == null) {
        return null;
      }
      return AuthUser.fromJson(body);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _tokenStore.clear();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final token = await _tokenStore.read();
    if (token != null && token.isNotEmpty) {
      try {
        await _dio.post<Map<String, dynamic>>(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } on DioException {
        // ignore
      }
    }
    await _tokenStore.clear();
  }

  static String _describeDio(DioException error) => describeDioPublic(error);

  /// Public for UI mapping of unexpected Dio errors.
  static String describeDioPublic(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    String? serverMessage;
    String? serverCode;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      serverMessage = err['message']?.toString();
      serverCode = err['code']?.toString();
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Сервер недоступен (${error.requestOptions.baseUrl}). '
          'Запущен ли API? В Cursor: php artisan serve --host=127.0.0.1 --port=8000';
    }
    if (status == 503) {
      return serverMessage ??
          'Вход через Google не настроен на сервере (.env).';
    }
    if (status == 401) {
      if (serverCode == 'GOOGLE_TOKEN_INVALID' ||
          (serverMessage != null && serverMessage.isNotEmpty)) {
        return serverMessage ??
            'Google отклонил токен. Проверьте Client ID в .env и dart-define.';
      }
      return 'Ошибка авторизации (401). Попробуйте войти ещё раз.';
    }
    if (status != null) {
      return serverMessage ?? 'Ошибка сервера при входе (код $status).';
    }
    return 'Ошибка сети при входе: ${error.message ?? error.type.name}';
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthController extends Notifier<AsyncValue<AuthUser?>> {
  AuthApiClient get _api => ref.read(authApiClientProvider);
  bool _googleReady = false;

  @override
  AsyncValue<AuthUser?> build() {
    // Start as guest so stale DioException is not shown on open.
    Future.microtask(_restore);
    return const AsyncValue.data(null);
  }

  Future<void> _restore() async {
    try {
      final user = await _api.currentUser();
      if (user != null) {
        state = AsyncValue.data(user);
      }
    } catch (_) {
      // Stay guest.
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      if (_googleServerClientId.isEmpty) {
        throw const AuthFailure(
          'В сборке нет GOOGLE_SERVER_CLIENT_ID. '
          'Запускайте flutter run с --dart-define=GOOGLE_SERVER_CLIENT_ID=...',
        );
      }

      final google = GoogleSignIn.instance;
      if (!_googleReady) {
        await google.initialize(serverClientId: _googleServerClientId);
        _googleReady = true;
      }

      final account = await google.authenticate(
        scopeHint: const ['email', 'profile', 'openid'],
      );
      final idToken = account.authentication.idToken;
      debugPrint(
        'Google sign-in: email=${account.email}, '
        'idTokenLen=${idToken?.length ?? 0}',
      );
      if (idToken == null || idToken.isEmpty) {
        throw const AuthFailure(
          'Google не вернул id_token. Проверьте, что в --dart-define '
          'указан именно Web Client ID (не Android).',
        );
      }

      final session = await _api.loginWithGoogleIdToken(idToken);
      final photoUrl = account.photoUrl;
      final user = (photoUrl != null && photoUrl.isNotEmpty)
          ? session.user.copyWith(photoUrl: photoUrl)
          : session.user;
      state = AsyncValue.data(user);
      // Account now owns guest vehicles — refresh garage for this session.
      await ref.read(vehicleSetupControllerProvider.notifier).load(force: true);
    } catch (error, stack) {
      debugPrint('Google sign-in failed: $error');
      debugPrintStack(stackTrace: stack);
      final message = switch (error) {
        AuthFailure(:final message) => message,
        DioException() => AuthApiClient.describeDioPublic(error),
        _ => error.toString(),
      };
      state = AsyncValue.error(AuthFailure(message), stack);
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _api.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> forgetLocal() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    state = const AsyncValue.data(null);
  }
}

final authTokenStoreProvider = Provider<AuthTokenStore>(
  (ref) => SecureAuthTokenStore(),
);

final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(
    ref.watch(authTokenStoreProvider),
    ref.watch(guestProfileIdStoreProvider),
    baseUrl: ref.watch(apiBaseUrlProvider),
  );
});

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<AuthUser?>>(AuthController.new);

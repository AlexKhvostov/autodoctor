import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const kApiDevBaseUrl = 'https://api-dev.autodoctor.by/api/v1';
const kApiProdBaseUrl = 'https://api.autodoctor.by/api/v1';
const kRemoteConfigApiBaseUrlKey = 'api_base_url';

const _kindStorageKey = 'api_endpoint_kind';
const _tunnelStorageKey = 'api_endpoint_tunnel_url';

enum ApiEndpointKind { firebase, tunnel, dev, prod }

class ApiEndpointSettings {
  const ApiEndpointSettings({
    required this.kind,
    required this.tunnelUrl,
    this.remoteConfigUrl = '',
  });

  final ApiEndpointKind kind;
  final String tunnelUrl;
  final String remoteConfigUrl;

  String get resolvedUrl {
    switch (kind) {
      case ApiEndpointKind.dev:
        return kApiDevBaseUrl;
      case ApiEndpointKind.prod:
        return kApiProdBaseUrl;
      case ApiEndpointKind.firebase:
        if (looksLikeHttpUrl(remoteConfigUrl)) {
          return normalizeApiBaseUrl(remoteConfigUrl);
        }
        return kApiDevBaseUrl;
      case ApiEndpointKind.tunnel:
        final raw = tunnelUrl.trim().isEmpty
            ? compiledApiBaseUrl()
            : tunnelUrl;
        return normalizeApiBaseUrl(raw);
    }
  }
}

String compiledApiBaseUrl() {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) {
    return normalizeApiBaseUrl(configured);
  }
  if (!kIsWeb && Platform.isAndroid) {
    return 'http://10.0.2.2:8000/api/v1';
  }
  return 'http://localhost:8000/api/v1';
}

String normalizeApiBaseUrl(String raw) {
  var url = raw.trim();
  if (url.isEmpty) {
    return compiledApiBaseUrl();
  }
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  if (!url.contains('/api/')) {
    url = '$url/api/v1';
  }
  return url;
}

ApiEndpointKind inferApiEndpointKind(String url) {
  final normalized = url.toLowerCase();
  if (normalized.contains('api-dev.autodoctor.by')) {
    return ApiEndpointKind.dev;
  }
  if (normalized.contains('api.autodoctor.by')) {
    return ApiEndpointKind.prod;
  }
  return ApiEndpointKind.tunnel;
}

ApiEndpointSettings settingsFromCompiledDefault() {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isEmpty) {
    return const ApiEndpointSettings(kind: ApiEndpointKind.firebase, tunnelUrl: '');
  }
  final compiled = compiledApiBaseUrl();
  final kind = inferApiEndpointKind(compiled);
  return ApiEndpointSettings(
    kind: kind,
    tunnelUrl: kind == ApiEndpointKind.tunnel ? compiled : '',
  );
}

bool looksLikeHttpUrl(String raw) {
  final url = raw.trim().toLowerCase();
  return url.startsWith('https://') || url.startsWith('http://');
}

Dio createApiDio({
  required String baseUrl,
  Duration connectTimeout = const Duration(seconds: 10),
  Duration receiveTimeout = const Duration(seconds: 15),
  Map<String, dynamic>? headers,
}) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {'Accept': 'application/json', ...?headers},
    ),
  );
}

final apiEndpointControllerProvider =
    NotifierProvider<ApiEndpointController, ApiEndpointSettings>(
      ApiEndpointController.new,
    );

final apiBaseUrlProvider = Provider<String>((ref) {
  return ref.watch(apiEndpointControllerProvider).resolvedUrl;
});

class ApiEndpointController extends Notifier<ApiEndpointSettings> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  ApiEndpointSettings build() => settingsFromCompiledDefault();

  Future<void> hydrate() async {
    try {
      final kindRaw = await _storage.read(key: _kindStorageKey);
      final tunnelUrl = await _storage.read(key: _tunnelStorageKey) ?? '';
      final kind = ApiEndpointKind.values
          .where((item) => item.name == kindRaw)
          .firstOrNull;
      if (kind == null) {
        state = settingsFromCompiledDefault();
        return;
      }
      state = ApiEndpointSettings(
        kind: kind,
        tunnelUrl: tunnelUrl,
        remoteConfigUrl: state.remoteConfigUrl,
      );
    } on Object {
      // Keep compiled default.
    }
  }

  Future<void> applyRemoteConfig() async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }
    try {
      if (Firebase.apps.isEmpty) {
        return;
      }
      final remote = FirebaseRemoteConfig.instance;
      await remote.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(minutes: 5),
        ),
      );
      await remote.setDefaults({
        kRemoteConfigApiBaseUrlKey: kApiDevBaseUrl,
      });
      await remote.fetchAndActivate();
      final url = remote.getString(kRemoteConfigApiBaseUrlKey);
      state = ApiEndpointSettings(
        kind: state.kind,
        tunnelUrl: state.tunnelUrl,
        remoteConfigUrl: looksLikeHttpUrl(url) ? normalizeApiBaseUrl(url) : '',
      );
    } on Object catch (error) {
      debugPrint('Remote Config skipped: $error');
    }
  }

  /// Saves the endpoint. Returns false if URL did not change.
  Future<bool> select({
    required ApiEndpointKind kind,
    required String tunnelUrl,
  }) async {
    if (kind == ApiEndpointKind.tunnel && !looksLikeHttpUrl(tunnelUrl)) {
      throw ArgumentError('Tunnel URL must start with http:// or https://');
    }
    final next = ApiEndpointSettings(
      kind: kind,
      tunnelUrl: kind == ApiEndpointKind.tunnel
          ? normalizeApiBaseUrl(tunnelUrl)
          : tunnelUrl.trim(),
      remoteConfigUrl: state.remoteConfigUrl,
    );
    final previous = state;
    final changed = previous.resolvedUrl != next.resolvedUrl;
    await _storage.write(key: _kindStorageKey, value: next.kind.name);
    await _storage.write(key: _tunnelStorageKey, value: next.tunnelUrl);
    state = next;
    return changed;
  }
}

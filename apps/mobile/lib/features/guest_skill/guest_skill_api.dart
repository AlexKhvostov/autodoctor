import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/api_endpoint.dart';
import '../guest_bootstrap/guest_bootstrap.dart';
import '../guest_bootstrap/guest_bootstrap_controller.dart';

class GuestSkillApiException implements Exception {
  const GuestSkillApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class GuestSkillProfile {
  const GuestSkillProfile({
    required this.overallScore,
    required this.band,
    required this.assessed,
    this.selfReportedBand,
    this.handsOn,
    this.samplesCount = 0,
  });

  final int overallScore;
  final String band;
  final String? selfReportedBand;
  final bool? handsOn;
  final int samplesCount;
  final bool assessed;

  factory GuestSkillProfile.fromJson(Map<String, dynamic> json) {
    return GuestSkillProfile(
      overallScore: (json['overall_score'] as num?)?.toInt() ?? 50,
      band: (json['band'] as String?) ?? 'basic',
      selfReportedBand: json['self_reported_band'] as String?,
      handsOn: json['hands_on'] as bool?,
      samplesCount: (json['samples_count'] as num?)?.toInt() ?? 0,
      assessed: json['assessed'] == true,
    );
  }
}

class GuestSkillApiClient {
  GuestSkillApiClient(
    this._tokenStore, {
    Dio? dio,
    String? baseUrl,
  }) : _dio = dio ?? createApiDio(baseUrl: baseUrl ?? compiledApiBaseUrl());

  final SessionTokenStore _tokenStore;
  final Dio _dio;

  Future<Map<String, String>> _authHeaders(String locale) async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const GuestSkillApiException(
        'Session token missing',
        code: 'SESSION_TOKEN_REQUIRED',
      );
    }
    return {
      'X-Session-Token': token,
      'Accept-Language': locale,
    };
  }

  Future<GuestSkillProfile> fetch({required String locale}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/guest/skill-profile',
        options: Options(headers: await _authHeaders(locale)),
      );
      final raw = response.data?['skill_profile'];
      if (raw is! Map) {
        throw const GuestSkillApiException('Invalid skill profile response');
      }
      return GuestSkillProfile.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Future<GuestSkillProfile> submitQuiz({
    required String locale,
    required String knowledgeBand,
    required String handsOn,
    String? detailPreference,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/guest/skill-profile',
        data: {
          'knowledge_band': knowledgeBand,
          'hands_on': handsOn,
          'detail_preference': ?detailPreference,
        },
        options: Options(headers: await _authHeaders(locale)),
      );
      final raw = response.data?['skill_profile'];
      if (raw is! Map) {
        throw const GuestSkillApiException('Invalid skill profile response');
      }
      return GuestSkillProfile.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  GuestSkillApiException _mapDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = Map<String, dynamic>.from(data['error'] as Map);
      return GuestSkillApiException(
        (err['message'] as String?) ?? error.message ?? 'Request failed',
        code: err['code'] as String?,
      );
    }
    return GuestSkillApiException(error.message ?? 'Request failed');
  }
}

final guestSkillApiClientProvider = Provider<GuestSkillApiClient>((ref) {
  return GuestSkillApiClient(
    ref.watch(sessionTokenStoreProvider),
    baseUrl: ref.watch(apiBaseUrlProvider),
  );
});

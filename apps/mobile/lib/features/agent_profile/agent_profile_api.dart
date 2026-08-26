import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/api_endpoint.dart';
import '../guest_bootstrap/guest_bootstrap.dart';
import '../guest_bootstrap/guest_bootstrap_controller.dart';

class AgentProfileApiException implements Exception {
  const AgentProfileApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AgentNote {
  const AgentNote({
    required this.id,
    required this.body,
    this.source,
    this.createdAt,
  });

  final String id;
  final String body;
  final String? source;
  final String? createdAt;

  factory AgentNote.fromJson(Map<String, dynamic> json) => AgentNote(
    id: (json['id'] as String?) ?? '',
    body: (json['body'] as String?) ?? '',
    source: json['source'] as String?,
    createdAt: json['created_at'] as String?,
  );
}

class AgentPreferences {
  const AgentPreferences({
    required this.simplicity,
    required this.verbosity,
    required this.directness,
    required this.initiative,
    this.customInstructions,
  });

  final int simplicity;
  final int verbosity;
  final int directness;
  final int initiative;
  final String? customInstructions;

  factory AgentPreferences.fromJson(Map<String, dynamic> json) =>
      AgentPreferences(
        simplicity: (json['simplicity'] as num?)?.toInt() ?? 3,
        verbosity: (json['verbosity'] as num?)?.toInt() ?? 3,
        directness: (json['directness'] as num?)?.toInt() ?? 5,
        initiative: (json['initiative'] as num?)?.toInt() ?? 4,
        customInstructions: json['custom_instructions'] as String?,
      );

  AgentPreferences copyWith({
    int? simplicity,
    int? verbosity,
    int? directness,
    int? initiative,
    String? customInstructions,
    bool clearInstructions = false,
  }) => AgentPreferences(
    simplicity: simplicity ?? this.simplicity,
    verbosity: verbosity ?? this.verbosity,
    directness: directness ?? this.directness,
    initiative: initiative ?? this.initiative,
    customInstructions: clearInstructions
        ? null
        : customInstructions ?? this.customInstructions,
  );
}

class OwnerSkillSnapshot {
  const OwnerSkillSnapshot({
    required this.overallScore,
    required this.band,
    required this.assessed,
    this.selfReportedBand,
    this.handsOn,
    this.handsOnLevel,
  });

  final int overallScore;
  final String band;
  final String? selfReportedBand;
  final bool? handsOn;
  final String? handsOnLevel;
  final bool assessed;

  String get knowledgeBandValue {
    const known = {
      'never_tools',
      'scared',
      'novice',
      'basic',
      'curious',
      'confident',
      'advanced',
      'pro',
    };
    final raw = selfReportedBand ?? band;
    if (known.contains(raw)) return raw;
    return switch (raw) {
      'novice' => 'novice',
      'confident' => 'confident',
      _ => 'basic',
    };
  }

  String get handsOnValue {
    final level = handsOnLevel;
    if (level != null && level.isNotEmpty) {
      if (level == 'yes') return 'often';
      return level;
    }
    if (handsOn == false) return 'never';
    if (handsOn == true) return 'often';
    return 'sometimes';
  }

  factory OwnerSkillSnapshot.fromJson(Map<String, dynamic> json) =>
      OwnerSkillSnapshot(
        overallScore: (json['overall_score'] as num?)?.toInt() ?? 50,
        band: (json['band'] as String?) ?? 'basic',
        selfReportedBand: json['self_reported_band'] as String?,
        handsOn: json['hands_on'] as bool?,
        handsOnLevel: json['hands_on_level'] as String?,
        assessed: json['assessed'] == true,
      );
}

enum AgentEnergyStatus { ok, low, empty }

class AgentFuel {
  const AgentFuel({
    required this.balanceMl,
    required this.capacityMl,
    required this.percent,
    required this.lifetimeConsumedMl,
    required this.approxRepliesLeft,
    required this.typicalSpendMl,
    required this.status,
    required this.lowBalanceMl,
    required this.currency,
    required this.lifetimeEstimatedCost,
    required this.lifetimePromptTokens,
    required this.lifetimeCompletionTokens,
  });

  final int balanceMl;
  final int capacityMl;
  final int percent;
  final int lifetimeConsumedMl;
  final int approxRepliesLeft;
  final int typicalSpendMl;
  final AgentEnergyStatus status;
  final int lowBalanceMl;
  final String currency;
  final double lifetimeEstimatedCost;
  final int lifetimePromptTokens;
  final int lifetimeCompletionTokens;

  bool get isLow => status == AgentEnergyStatus.low;
  bool get isEmpty => status == AgentEnergyStatus.empty;

  factory AgentFuel.fromJson(Map<String, dynamic> json) {
    final statusRaw = (json['status'] as String?) ?? 'ok';
    final status = switch (statusRaw) {
      'empty' => AgentEnergyStatus.empty,
      'low' => AgentEnergyStatus.low,
      _ => AgentEnergyStatus.ok,
    };
    return AgentFuel(
      balanceMl: (json['balance_ml'] as num?)?.toInt() ?? 0,
      capacityMl: (json['capacity_ml'] as num?)?.toInt() ?? 1,
      percent: (json['percent'] as num?)?.toInt() ?? 0,
      lifetimeConsumedMl: (json['lifetime_consumed_ml'] as num?)?.toInt() ?? 0,
      approxRepliesLeft: (json['approx_replies_left'] as num?)?.toInt() ?? 0,
      typicalSpendMl: (json['typical_spend_ml'] as num?)?.toInt() ?? 80,
      status: status,
      lowBalanceMl: (json['low_balance_ml'] as num?)?.toInt() ?? 400,
      currency: (json['currency'] as String?) ?? 'BYN',
      lifetimeEstimatedCost:
          (json['lifetime_estimated_cost'] as num?)?.toDouble() ?? 0,
      lifetimePromptTokens:
          (json['lifetime_prompt_tokens'] as num?)?.toInt() ?? 0,
      lifetimeCompletionTokens:
          (json['lifetime_completion_tokens'] as num?)?.toInt() ?? 0,
    );
  }

  static const empty = AgentFuel(
    balanceMl: 0,
    capacityMl: 1,
    percent: 0,
    lifetimeConsumedMl: 0,
    approxRepliesLeft: 0,
    typicalSpendMl: 80,
    status: AgentEnergyStatus.empty,
    lowBalanceMl: 400,
    currency: 'BYN',
    lifetimeEstimatedCost: 0,
    lifetimePromptTokens: 0,
    lifetimeCompletionTokens: 0,
  );

  static const fallbackOk = AgentFuel(
    balanceMl: 5000,
    capacityMl: 5000,
    percent: 100,
    lifetimeConsumedMl: 0,
    approxRepliesLeft: 60,
    typicalSpendMl: 80,
    status: AgentEnergyStatus.ok,
    lowBalanceMl: 400,
    currency: 'BYN',
    lifetimeEstimatedCost: 0,
    lifetimePromptTokens: 0,
    lifetimeCompletionTokens: 0,
  );
}

class AgentUsageBucket {
  const AgentUsageBucket({
    required this.fuelMl,
    required this.promptTokens,
    required this.completionTokens,
    required this.estimatedCost,
    required this.events,
    required this.tokensAreEstimates,
  });

  final int fuelMl;
  final int promptTokens;
  final int completionTokens;
  final double estimatedCost;
  final int events;
  final bool tokensAreEstimates;

  factory AgentUsageBucket.fromJson(Map<String, dynamic> json) =>
      AgentUsageBucket(
        fuelMl: (json['fuel_ml'] as num?)?.toInt() ?? 0,
        promptTokens: (json['prompt_tokens'] as num?)?.toInt() ?? 0,
        completionTokens: (json['completion_tokens'] as num?)?.toInt() ?? 0,
        estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0,
        events: (json['events'] as num?)?.toInt() ?? 0,
        tokensAreEstimates: json['tokens_are_estimates'] == true,
      );

  static const empty = AgentUsageBucket(
    fuelMl: 0,
    promptTokens: 0,
    completionTokens: 0,
    estimatedCost: 0,
    events: 0,
    tokensAreEstimates: false,
  );
}

class AgentDailyUsage {
  const AgentDailyUsage({
    required this.date,
    required this.spentMl,
    required this.refueledMl,
  });

  final String date;
  final int spentMl;
  final int refueledMl;

  factory AgentDailyUsage.fromJson(Map<String, dynamic> json) =>
      AgentDailyUsage(
        date: (json['date'] as String?) ?? '',
        spentMl: (json['spent_ml'] as num?)?.toInt() ?? 0,
        refueledMl: (json['refueled_ml'] as num?)?.toInt() ?? 0,
      );
}

class RefuelPackage {
  const RefuelPackage({
    required this.ml,
    required this.label,
    required this.paymentAvailable,
  });

  final int ml;
  final String label;
  final bool paymentAvailable;

  factory RefuelPackage.fromJson(Map<String, dynamic> json) => RefuelPackage(
    ml: (json['ml'] as num?)?.toInt() ?? 0,
    label: (json['label'] as String?) ?? '',
    paymentAvailable: json['payment_available'] == true,
  );
}

class AgentProfile {
  const AgentProfile({
    required this.preferences,
    required this.skill,
    required this.fuel,
    required this.usageToday,
    required this.usageWeek,
    required this.usageAll,
    required this.usageDaily,
    required this.refuelPackages,
    required this.userNotes,
    required this.vehicleNotes,
  });

  final AgentPreferences preferences;
  final OwnerSkillSnapshot skill;
  final AgentFuel fuel;
  final AgentUsageBucket usageToday;
  final AgentUsageBucket usageWeek;
  final AgentUsageBucket usageAll;
  final List<AgentDailyUsage> usageDaily;
  final List<RefuelPackage> refuelPackages;
  final List<AgentNote> userNotes;
  final List<AgentNote> vehicleNotes;

  factory AgentProfile.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'] is Map
        ? Map<String, dynamic>.from(json['usage'] as Map)
        : <String, dynamic>{};
    final notes = json['notes'] is Map
        ? Map<String, dynamic>.from(json['notes'] as Map)
        : <String, dynamic>{};

    List<AgentNote> parseNotes(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => AgentNote.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    }

    return AgentProfile(
      preferences: AgentPreferences.fromJson(
        json['preferences'] is Map
            ? Map<String, dynamic>.from(json['preferences'] as Map)
            : const {},
      ),
      skill: OwnerSkillSnapshot.fromJson(
        json['skill'] is Map
            ? Map<String, dynamic>.from(json['skill'] as Map)
            : const {},
      ),
      fuel: AgentFuel.fromJson(
        json['fuel'] is Map
            ? Map<String, dynamic>.from(json['fuel'] as Map)
            : const {},
      ),
      usageToday: AgentUsageBucket.fromJson(
        usage['today'] is Map
            ? Map<String, dynamic>.from(usage['today'] as Map)
            : const {},
      ),
      usageWeek: AgentUsageBucket.fromJson(
        usage['last_7_days'] is Map
            ? Map<String, dynamic>.from(usage['last_7_days'] as Map)
            : const {},
      ),
      usageAll: AgentUsageBucket.fromJson(
        usage['all_time'] is Map
            ? Map<String, dynamic>.from(usage['all_time'] as Map)
            : const {},
      ),
      usageDaily: (usage['daily'] is List)
          ? (usage['daily'] as List)
                .whereType<Map>()
                .map(
                  (e) => AgentDailyUsage.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(growable: false)
          : const [],
      refuelPackages: (json['refuel_packages'] is List)
          ? (json['refuel_packages'] as List)
                .whereType<Map>()
                .map(
                  (e) => RefuelPackage.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(growable: false)
          : const [],
      userNotes: parseNotes(notes['user']),
      vehicleNotes: parseNotes(notes['vehicle']),
    );
  }
}

class AgentProfileApiClient {
  AgentProfileApiClient(
    this._tokenStore, {
    Dio? dio,
    String? baseUrl,
  }) : _dio =
           dio ??
           createApiDio(
             baseUrl: baseUrl ?? compiledApiBaseUrl(),
             receiveTimeout: const Duration(seconds: 20),
           );

  final SessionTokenStore _tokenStore;
  final Dio _dio;

  Future<Map<String, String>> _authHeaders(String locale) async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const AgentProfileApiException(
        'Session token missing',
        code: 'SESSION_TOKEN_REQUIRED',
      );
    }
    return {
      'X-Session-Token': token,
      'Accept-Language': locale,
    };
  }

  Future<AgentProfile> fetch({
    required String locale,
    String? vehicleId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/guest/agent-profile',
        queryParameters: {
          if (vehicleId != null && vehicleId.isNotEmpty)
            'vehicle_id': vehicleId,
        },
        options: Options(headers: await _authHeaders(locale)),
      );
      final raw = response.data?['agent_profile'];
      if (raw is! Map) {
        throw const AgentProfileApiException('Invalid agent profile response');
      }
      return AgentProfile.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Future<AgentPreferences> updatePreferences({
    required String locale,
    required AgentPreferences preferences,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/guest/agent-profile/preferences',
        data: {
          'simplicity': preferences.simplicity,
          'verbosity': preferences.verbosity,
          'directness': preferences.directness,
          'initiative': preferences.initiative,
          'custom_instructions': preferences.customInstructions,
        },
        options: Options(headers: await _authHeaders(locale)),
      );
      final raw = response.data?['preferences'];
      if (raw is! Map) {
        throw const AgentProfileApiException('Invalid preferences response');
      }
      return AgentPreferences.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Future<OwnerSkillSnapshot> updateSkill({
    required String locale,
    required String knowledgeBand,
    required String handsOn,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/guest/agent-profile/skill',
        data: {
          'knowledge_band': knowledgeBand,
          'hands_on': handsOn,
        },
        options: Options(headers: await _authHeaders(locale)),
      );
      final raw = response.data?['skill'];
      if (raw is! Map) {
        throw const AgentProfileApiException('Invalid skill response');
      }
      return OwnerSkillSnapshot.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Future<AgentFuel> refuelStub({
    required String locale,
    required int packageMl,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/guest/agent-profile/refuel-stub',
        data: {'package_ml': packageMl},
        options: Options(headers: await _authHeaders(locale)),
      );
      final raw = response.data?['fuel'];
      if (raw is! Map) {
        throw const AgentProfileApiException('Invalid refuel response');
      }
      return AgentFuel.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Future<void> deleteUserNote({
    required String locale,
    required String noteId,
  }) async {
    try {
      await _dio.delete<void>(
        '/guest/ai-notes/$noteId',
        options: Options(headers: await _authHeaders(locale)),
      );
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Future<void> deleteVehicleNote({
    required String locale,
    required String vehicleId,
    required String noteId,
  }) async {
    try {
      await _dio.delete<void>(
        '/vehicles/$vehicleId/ai-notes/$noteId',
        options: Options(headers: await _authHeaders(locale)),
      );
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  AgentProfileApiException _mapDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = Map<String, dynamic>.from(data['error'] as Map);
      return AgentProfileApiException(
        (err['message'] as String?) ?? error.message ?? 'Request failed',
        code: err['code'] as String?,
      );
    }
    return AgentProfileApiException(error.message ?? 'Request failed');
  }
}

final agentProfileApiClientProvider = Provider<AgentProfileApiClient>((ref) {
  return AgentProfileApiClient(
    ref.watch(sessionTokenStoreProvider),
    baseUrl: ref.watch(apiBaseUrlProvider),
  );
});

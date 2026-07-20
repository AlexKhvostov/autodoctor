import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../guest_bootstrap/guest_bootstrap.dart';
import '../guest_bootstrap/guest_bootstrap_data.dart';
import 'maintenance.dart';

class DioMaintenanceRepository implements MaintenanceRepository {
  DioMaintenanceRepository(this._tokenStore, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Accept': 'application/json'},
            ),
          );

  final SessionTokenStore _tokenStore;
  final Dio _dio;
  static const _uuid = Uuid();

  @override
  Future<MaintenancePlan> getPlan(String vehicleId, {required String locale}) =>
      _get(
        '/vehicles/$vehicleId/maintenance-plan',
        locale,
        MaintenancePlan.fromJson,
      );

  @override
  Future<VehicleTimeline> getTimeline(
    String vehicleId, {
    required String locale,
  }) => _get('/vehicles/$vehicleId/timeline', locale, VehicleTimeline.fromJson);

  @override
  Future<ConsumableList> getConsumables(
    String vehicleId, {
    required String locale,
  }) =>
      _get('/vehicles/$vehicleId/consumables', locale, ConsumableList.fromJson);

  @override
  Future<ServiceRecordList> getServiceRecords(
    String vehicleId, {
    required String locale,
  }) =>
      _get('/vehicles/$vehicleId/history', locale, ServiceRecordList.fromJson);

  @override
  Future<MileageForecast> getMileageForecast(
    String vehicleId, {
    required String locale,
  }) => _get(
    '/vehicles/$vehicleId/mileage-forecast',
    locale,
    MileageForecast.fromJson,
  );

  @override
  Future<ConditionObservationList> getConditionObservations(
    String vehicleId, {
    required String locale,
  }) => _get(
    '/vehicles/$vehicleId/condition-observations',
    locale,
    ConditionObservationList.fromJson,
  );

  @override
  Future<ConditionObservation> createConditionObservation(
    String vehicleId, {
    required String locale,
    required ConditionObservationWrite observation,
  }) => _write(
    'POST',
    '/vehicles/$vehicleId/condition-observations',
    locale,
    observation.toJson(),
    (json) => ConditionObservation.fromJson(json['observation']),
  );

  @override
  Future<ServiceRecord> createServiceRecord(
    String vehicleId, {
    required String locale,
    required ServiceRecordWrite record,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/vehicles/$vehicleId/history',
        data: record.toJson(),
        options: await _options(
          locale,
          extraHeaders: {'Idempotency-Key': _uuid.v4()},
        ),
      );
      final data = response.data;
      if (data == null || data['service_record'] == null) {
        throw const FormatException();
      }
      return ServiceRecord.fromJson(data['service_record']);
    } on DioException catch (error) {
      throw _failure(error);
    } on FormatException {
      throw const MaintenanceFailure(code: 'UNEXPECTED_RESPONSE');
    } on TypeError {
      throw const MaintenanceFailure(code: 'UNEXPECTED_RESPONSE');
    }
  }

  @override
  Future<void> submitHistoryAnswers(
    String vehicleId, {
    required String locale,
    required List<HistoryAnswerWrite> answers,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/vehicles/$vehicleId/history-answers',
        data: {'answers': answers.map((answer) => answer.toJson()).toList()},
        options: await _options(
          locale,
          extraHeaders: {'Idempotency-Key': _uuid.v4()},
        ),
      );
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  Future<T> _get<T>(
    String path,
    String locale,
    T Function(Map<String, dynamic>) decode,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        options: await _options(locale),
      );
      final data = response.data;
      if (data == null) throw const FormatException();
      return decode(data);
    } on DioException catch (error) {
      throw _failure(error);
    } on FormatException {
      throw const MaintenanceFailure(code: 'UNEXPECTED_RESPONSE');
    } on TypeError {
      throw const MaintenanceFailure(code: 'UNEXPECTED_RESPONSE');
    }
  }

  Future<T> _write<T>(
    String method,
    String path,
    String locale,
    Map<String, Object?> body,
    T Function(Map<String, dynamic>) decode,
  ) async {
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: body,
        options: (await _options(
          locale,
          extraHeaders: {'Idempotency-Key': _uuid.v4()},
        )).copyWith(method: method),
      );
      final data = response.data;
      if (data == null) throw const FormatException();
      return decode(data);
    } on DioException catch (error) {
      throw _failure(error);
    } on FormatException {
      throw const MaintenanceFailure(code: 'UNEXPECTED_RESPONSE');
    } on TypeError {
      throw const MaintenanceFailure(code: 'UNEXPECTED_RESPONSE');
    }
  }

  Future<Options> _options(
    String locale, {
    Map<String, Object?> extraHeaders = const {},
  }) async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const MaintenanceFailure(
        code: 'SESSION_TOKEN_REQUIRED',
        statusCode: 401,
      );
    }
    return Options(
      headers: {
        'X-Session-Token': token,
        'Accept-Language': locale,
        ...extraHeaders,
      },
    );
  }

  static MaintenanceFailure _failure(DioException exception) {
    final response = exception.response;
    final data = response?.data;
    String? code;
    String? message;
    String? requestId;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      code = error['code'] is String ? error['code'] as String : null;
      message = error['message'] is String ? error['message'] as String : null;
      requestId = error['request_id'] is String
          ? error['request_id'] as String
          : null;
    }
    return MaintenanceFailure(
      code: code,
      requestId: requestId ?? response?.headers.value('x-request-id'),
      statusCode: response?.statusCode,
      safeMessage: message ?? '',
    );
  }
}

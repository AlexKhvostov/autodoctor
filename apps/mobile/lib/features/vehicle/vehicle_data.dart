import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../guest_bootstrap/guest_bootstrap.dart';
import '../guest_bootstrap/guest_bootstrap_data.dart';
import 'vehicle.dart';

class DioVehicleRepository implements VehicleRepository {
  DioVehicleRepository(this._tokenStore, {Dio? dio, Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      _dio =
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
  final Uuid _uuid;

  @override
  Future<List<Vehicle>> list({required String locale}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/vehicles',
        options: await _options(locale),
      );
      final items = response.data?['items'];
      if (items is! List) throw const FormatException();
      return items
          .map((item) => Vehicle.fromJson(_map(item)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _failure(error);
    } on FormatException {
      throw const VehicleFailure(code: 'UNEXPECTED_RESPONSE');
    } on TypeError {
      throw const VehicleFailure(code: 'UNEXPECTED_RESPONSE');
    }
  }

  @override
  Future<Vehicle> create(VehicleDraft draft, {required String locale}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/vehicles',
        data: draft.toJson(),
        options: await _options(locale, mutation: true),
      );
      return Vehicle.fromJson(_map(response.data));
    } on DioException catch (error) {
      throw _failure(error);
    } on FormatException {
      throw const VehicleFailure(code: 'UNEXPECTED_RESPONSE');
    } on TypeError {
      throw const VehicleFailure(code: 'UNEXPECTED_RESPONSE');
    }
  }

  @override
  Future<MileageConfirmation> updateMileage(
    String vehicleId, {
    required int value,
    required String unit,
    required int version,
    required DateTime observedAt,
    required String locale,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/vehicles/$vehicleId/mileage',
        data: {
          'mileage': {'value': value, 'unit': unit},
          'observed_at': observedAt.toUtc().toIso8601String(),
          'version': version,
        },
        options: await _options(locale, mutation: true),
      );
      return MileageConfirmation.fromJson(_map(response.data));
    } on DioException catch (error) {
      throw _failure(error);
    } on FormatException {
      throw const VehicleFailure(code: 'UNEXPECTED_RESPONSE');
    } on TypeError {
      throw const VehicleFailure(code: 'UNEXPECTED_RESPONSE');
    }
  }

  Future<Options> _options(String locale, {bool mutation = false}) async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const VehicleFailure(
        code: 'SESSION_TOKEN_REQUIRED',
        statusCode: 401,
      );
    }
    return Options(
      headers: {
        'X-Session-Token': token,
        'Accept-Language': locale,
        if (mutation) 'Idempotency-Key': _uuid.v4(),
      },
    );
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map) throw const FormatException();
    return Map<String, dynamic>.from(value);
  }

  static VehicleFailure _failure(DioException exception) {
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
    return VehicleFailure(
      code: code,
      requestId: requestId ?? response?.headers.value('x-request-id'),
      statusCode: response?.statusCode,
      safeMessage: message ?? '',
    );
  }
}

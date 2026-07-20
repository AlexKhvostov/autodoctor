import 'package:autodoctor/features/guest_bootstrap/guest_bootstrap.dart';
import 'package:autodoctor/features/maintenance/maintenance.dart';
import 'package:autodoctor/features/maintenance/maintenance_data.dart';
import 'package:autodoctor/features/vehicle/vehicle.dart';
import 'package:autodoctor/features/vehicle/vehicle_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vehicle parses version and mileage PUT matches OpenAPI', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    RequestOptions? captured;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'vehicle_id': 'vehicle-1',
                'vehicle_version': 8,
                'current_mileage': {'value': 12000, 'unit': 'km'},
                'observation': {},
                'maintenance_plan_id': 'plan-1',
              },
            ),
          );
        },
      ),
    );
    final repository = DioVehicleRepository(_TokenStore(), dio: dio);
    final result = await repository.updateMileage(
      'vehicle-1',
      value: 12000,
      unit: 'km',
      version: 7,
      observedAt: DateTime.utc(2026, 7, 20, 9, 30),
      locale: 'ru',
    );

    expect(captured!.method, 'PUT');
    expect(captured!.path, '/vehicles/vehicle-1/mileage');
    expect(captured!.data, {
      'mileage': {'value': 12000, 'unit': 'km'},
      'observed_at': '2026-07-20T09:30:00.000Z',
      'version': 7,
    });
    expect(captured!.headers['X-Session-Token'], 'token-1');
    expect(captured!.headers['Accept-Language'], 'ru');
    expect(
      captured!.headers['Idempotency-Key'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(result.vehicleVersion, 8);

    final vehicle = Vehicle.fromJson({
      'id': 'vehicle-1',
      'version': 7,
      'make': 'Other',
      'model': 'Car',
      'production_year': 2020,
      'fuel_type': 'petrol',
      'engine': <String, dynamic>{},
      'transmission': null,
      'mileage': {'value': 10000, 'unit': 'km'},
    });
    expect(vehicle.version, 7);
  });

  test('service POST uses factual append contract and UUID', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    RequestOptions? captured;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 201,
              data: {
                'service_record': {
                  'id': 'service-1',
                  'vehicle_id': 'vehicle-1',
                  'service_date': '2026-07-20',
                  'mileage': {'value': 10000, 'unit': 'km'},
                  'evidence_source': 'self',
                  'note': 'Changed at home',
                  'items': [
                    {'work_code': 'engine_oil', 'title': 'Engine oil'},
                  ],
                  'created_at': '2026-07-20T09:30:00Z',
                },
                'mileage_observation': null,
                'maintenance_plan_id': 'plan-1',
              },
            ),
          );
        },
      ),
    );
    final repository = DioMaintenanceRepository(_TokenStore(), dio: dio);
    final result = await repository.createServiceRecord(
      'vehicle-1',
      locale: 'en',
      record: ServiceRecordWrite(
        serviceDate: DateTime(2026, 7, 20),
        workCode: 'engine_oil',
        mileage: 10000,
        note: ' Changed at home ',
      ),
    );

    expect(captured!.method, 'POST');
    expect(captured!.path, '/vehicles/vehicle-1/history');
    expect(captured!.data, {
      'service_date': '2026-07-20',
      'work_codes': ['engine_oil'],
      'mileage': {'value': 10000, 'unit': 'km'},
      'evidence_source': 'self',
      'note': 'Changed at home',
    });
    expect(captured!.headers['Accept-Language'], 'en');
    expect(captured!.headers['Idempotency-Key'], isNotEmpty);
    expect(result.items.single.workCode, 'engine_oil');
  });

  test('mileage conversion compares km and mi correctly', () {
    expect(mileageInKm(100, 'mi'), closeTo(160.9344, 0.0001));
    expect(mileageInKm(100, 'km'), 100);
    expect(mileageInKm(6214, 'mi'), closeTo(10000.463616, 0.0001));
  });

  test(
    'timeline contract parses action and basis without preferences call',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      final requestedPaths = <String>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'vehicle_id': 'vehicle-1',
                  'last_confirmed_observation': {
                    'mileage': {'value': 12000, 'unit': 'km'},
                  },
                  'items': [
                    {
                      'type': 'plan_item',
                      'presentation': {
                        'primary_category': 'maintenance_repair',
                        'status': 'overdue',
                        'importance': 'required',
                        'action_level': 'critical',
                        'basis': 'confirmed',
                      },
                      'plan_item': {
                        'id': 'item-1',
                        'work_code': 'engine_oil',
                        'title': 'Engine oil',
                        'status': 'overdue',
                        'presentation_importance': 'required',
                        'source': <String, dynamic>{},
                        'due': <String, dynamic>{},
                        'interval': <String, dynamic>{},
                      },
                    },
                  ],
                },
              ),
            );
          },
        ),
      );
      final repository = DioMaintenanceRepository(_TokenStore(), dio: dio);
      final timeline = await repository.getTimeline('vehicle-1', locale: 'en');

      expect(requestedPaths, ['/vehicles/vehicle-1/timeline']);
      expect(
        requestedPaths.where(
          (path) => path.contains('plan-item-ui-preferences'),
        ),
        isEmpty,
      );
      expect(timeline.items.single.actionLevel, TimelineActionLevel.critical);
      expect(timeline.items.single.basis, PresentationBasis.confirmed);
    },
  );
}

class _TokenStore implements SessionTokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> read() async => 'token-1';

  @override
  Future<void> write(String token) async {}
}

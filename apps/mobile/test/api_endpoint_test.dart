import 'package:autodoctor/app/api_endpoint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeApiBaseUrl appends /api/v1', () {
    expect(
      normalizeApiBaseUrl('https://pest.trycloudflare.com'),
      'https://pest.trycloudflare.com/api/v1',
    );
    expect(
      normalizeApiBaseUrl('https://api-dev.autodoctor.by/api/v1/'),
      'https://api-dev.autodoctor.by/api/v1',
    );
  });

  test('inferApiEndpointKind maps official hosts', () {
    expect(
      inferApiEndpointKind('https://api-dev.autodoctor.by/api/v1'),
      ApiEndpointKind.dev,
    );
    expect(
      inferApiEndpointKind('https://api.autodoctor.by/api/v1'),
      ApiEndpointKind.prod,
    );
    expect(
      inferApiEndpointKind('https://abc.trycloudflare.com/api/v1'),
      ApiEndpointKind.tunnel,
    );
  });

  test('firebase kind falls back to api-dev', () {
    const settings = ApiEndpointSettings(
      kind: ApiEndpointKind.firebase,
      tunnelUrl: '',
    );
    expect(settings.resolvedUrl, kApiDevBaseUrl);
  });

  test('looksLikeHttpUrl', () {
    expect(looksLikeHttpUrl('https://x.trycloudflare.com'), isTrue);
    expect(looksLikeHttpUrl('not-a-url'), isFalse);
  });
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/api_endpoint.dart';
import '../../../app/api_endpoint_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../guest_bootstrap/guest_bootstrap_controller.dart';

class DevelopmentScreen extends ConsumerStatefulWidget {
  const DevelopmentScreen({super.key});

  @override
  ConsumerState<DevelopmentScreen> createState() => _DevelopmentScreenState();
}

class _DevelopmentScreenState extends ConsumerState<DevelopmentScreen> {
  String _statusText = '';
  var _loadingHealth = false;
  var _probing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadHealth();
    });
  }

  String _apiServerLabel(BuildContext context, ApiEndpointKind kind) {
    final l10n = context.l10n;
    return switch (kind) {
      ApiEndpointKind.firebase => l10n.apiServerFirebase,
      ApiEndpointKind.tunnel => l10n.apiServerTunnel,
      ApiEndpointKind.dev => l10n.apiServerDev,
      ApiEndpointKind.prod => l10n.apiServerProd,
    };
  }

  Dio _dio() => createApiDio(
    baseUrl: ref.read(apiBaseUrlProvider),
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 70),
  );

  Future<Map<String, String>> _headers() async {
    final locale = Localizations.localeOf(context).languageCode;
    final token = await ref.read(sessionTokenStoreProvider).read();
    return {
      'Accept-Language': locale,
      if (token != null && token.isNotEmpty) 'X-Session-Token': token,
    };
  }

  String _formatHealth(Map<String, dynamic> json) {
    final checks = json['checks'];
    final db = checks is Map ? checks['database'] : null;
    final ai = checks is Map ? checks['ai'] : null;
    final dbOk = db is Map && db['ok'] == true;
    final ready = ai is Map && ai['ready'] == true;
    final buf = StringBuffer()
      ..writeln('API: ${json['status']} · ${json['service']} ${json['version']}')
      ..writeln('База: ${dbOk ? 'ok' : db}');
    if (ai is Map) {
      buf
        ..writeln('AI: ${ready ? 'готов' : 'не готов'}')
        ..writeln('Код: ${ai['code']}')
        ..writeln('${ai['message']}')
        ..writeln(
          'Конфиг: row=${ai['has_config_row']} active=${ai['is_active']} enabled=${ai['enabled']}',
        )
        ..writeln(
          'Промпт: ${ai['prompt_code'] ?? '—'} approved=${ai['prompt_approved']}',
        )
        ..writeln(
          'Провайдер: ${ai['primary_provider']} / ${ai['primary_model']} ключ=${ai['primary_key_configured']}',
        )
        ..writeln(
          'Fallback: ${ai['fallback_provider'] ?? '—'} ключ=${ai['fallback_key_configured']}',
        );
    }
    return buf.toString().trim();
  }

  Future<void> _loadHealth() async {
    setState(() {
      _loadingHealth = true;
      _statusText = context.l10n.apiStatusLoading;
    });
    try {
      final response = await _dio().get<Map<String, dynamic>>(
        '/health',
        options: Options(headers: await _headers()),
      );
      final data = response.data ?? const <String, dynamic>{};
      if (!mounted) return;
      setState(() => _statusText = _formatHealth(data));
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _statusText = _dioError(error));
    } finally {
      if (mounted) setState(() => _loadingHealth = false);
    }
  }

  Future<void> _probeAi() async {
    setState(() {
      _probing = true;
      _statusText = context.l10n.apiStatusProbing;
    });
    try {
      final response = await _dio().post<Map<String, dynamic>>(
        '/diagnostics/ai',
        options: Options(headers: await _headers()),
      );
      final data = response.data ?? const <String, dynamic>{};
      if (!mounted) return;
      final probe = data['probe'];
      final probeLine = probe is Map
          ? 'Тест: ${probe['ok'] == true ? 'ok' : 'ошибка'} · ${probe['code']} · ${probe['latency_ms']} ms\n${probe['message']}\nОтвет: ${probe['reply'] ?? '—'}'
          : data.toString();
      setState(() => _statusText = '${_formatHealth(data)}\n\n$probeLine');
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      if (data is Map) {
        final probe = data['probe'];
        final checks = data['checks'];
        if (probe is Map) {
          setState(() {
            _statusText =
                '${checks is Map ? _formatHealth({'status': data['status'], 'service': '', 'version': '', 'checks': checks}) : ''}\n\nТест: ошибка · ${probe['code']}\n${probe['message']}';
          });
          return;
        }
      }
      setState(() => _statusText = _dioError(error));
    } finally {
      if (mounted) setState(() => _probing = false);
    }
  }

  String _dioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return '${err['code'] ?? error.response?.statusCode}: ${err['message'] ?? error.message}';
    }
    return 'Сеть/API: ${error.response?.statusCode ?? error.type.name}\n${error.message ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiEndpointControllerProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.developmentTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            context.l10n.developmentIntro,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ListTile(
            key: const Key('api-server-settings'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_outlined),
            title: Text(context.l10n.apiServer),
            subtitle: Text(
              '${_apiServerLabel(context, api.kind)} · ${api.resolvedUrl}',
            ),
            onTap: () => showApiEndpointSheet(context, ref),
          ),
          const Divider(height: 1),
          ListTile(
            key: const Key('more-ui-kit'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.widgets_outlined),
            title: Text(context.l10n.uiKitTitle),
            subtitle: Text(context.l10n.uiKitMoreDetail),
            onTap: () => context.push('/dev/ui-kit'),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.apiStatusTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.apiStatusHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              _statusText.isEmpty ? context.l10n.apiStatusLoading : _statusText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('api-status-refresh'),
                  onPressed: _loadingHealth ? null : _loadHealth,
                  child: _loadingHealth
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.apiStatusRefresh),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: const Key('api-status-probe-ai'),
                  onPressed: _probing ? null : _probeAi,
                  child: _probing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.apiStatusProbeAi),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

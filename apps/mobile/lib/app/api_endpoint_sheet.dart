import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth.dart';
import '../features/guest_bootstrap/guest_bootstrap_controller.dart';
import '../features/vehicle/vehicle_controller.dart';
import '../l10n/l10n.dart';
import 'api_endpoint.dart';
import 'locale_controller.dart';

Future<void> showApiEndpointSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => const _ApiEndpointSheet(),
  );
}

class _ApiEndpointSheet extends ConsumerStatefulWidget {
  const _ApiEndpointSheet();

  @override
  ConsumerState<_ApiEndpointSheet> createState() => _ApiEndpointSheetState();
}

class _ApiEndpointSheetState extends ConsumerState<_ApiEndpointSheet> {
  ApiEndpointKind? _kind;
  late final TextEditingController _tunnelCtrl;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(apiEndpointControllerProvider);
    _kind = current.kind;
    _tunnelCtrl = TextEditingController(
      text: current.tunnelUrl.isNotEmpty
          ? current.tunnelUrl
          : (current.kind == ApiEndpointKind.tunnel
                ? current.resolvedUrl
                : ''),
    );
  }

  @override
  void dispose() {
    _tunnelCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final l10n = context.l10n;
    final kind = _kind ?? ApiEndpointKind.dev;
    final tunnel = _tunnelCtrl.text.trim();
    if (kind == ApiEndpointKind.tunnel && !looksLikeHttpUrl(tunnel)) {
      setState(() => _error = l10n.apiServerTunnelInvalid);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.apiServerPickerTitle),
        content: Text(l10n.apiServerSwitchWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.apiServerApply),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final changed = await ref
          .read(apiEndpointControllerProvider.notifier)
          .select(kind: kind, tunnelUrl: tunnel);
      if (kind == ApiEndpointKind.firebase) {
        await ref
            .read(apiEndpointControllerProvider.notifier)
            .applyRemoteConfig();
      }
      final appliedUrl = ref.read(apiBaseUrlProvider);
      if (changed) {
        await ref.read(sessionTokenStoreProvider).clear();
        await ref.read(guestProfileIdStoreProvider).clear();
        await ref.read(authTokenStoreProvider).clear();
        await ref.read(authControllerProvider.notifier).forgetLocal();
        ref.read(vehicleSetupControllerProvider.notifier).resetLocal();
        final locale = ref.read(activeLocaleProvider).languageCode;
        final platform = !kIsWeb && Platform.isIOS ? 'ios' : 'android';
        await ref
            .read(guestBootstrapControllerProvider.notifier)
            .reconnectAfterApiChange(locale: locale, platform: platform);
        await ref
            .read(vehicleSetupControllerProvider.notifier)
            .load(force: true);
      }
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      final switched = l10n.apiServerSwitched(appliedUrl);
      Navigator.pop(context);
      messenger?.showSnackBar(SnackBar(content: Text(switched)));
    } on Object catch (error) {
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final kind = _kind ?? ApiEndpointKind.dev;
    final currentUrl = switch (kind) {
      ApiEndpointKind.dev => kApiDevBaseUrl,
      ApiEndpointKind.prod => kApiProdBaseUrl,
      ApiEndpointKind.firebase => looksLikeHttpUrl(
            ref.read(apiEndpointControllerProvider).remoteConfigUrl,
          )
          ? ref.read(apiEndpointControllerProvider).resolvedUrl
          : kApiDevBaseUrl,
      ApiEndpointKind.tunnel => looksLikeHttpUrl(_tunnelCtrl.text)
          ? normalizeApiBaseUrl(_tunnelCtrl.text)
          : l10n.apiServerTunnelHint,
    };

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.apiServerPickerTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.apiServerHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<ApiEndpointKind>(
                groupValue: kind,
                onChanged: (value) {
                  if (_busy || value == null) return;
                  setState(() {
                    _kind = value;
                    _error = null;
                    if (value == ApiEndpointKind.tunnel &&
                        _tunnelCtrl.text.trim().isEmpty) {
                      _tunnelCtrl.text = ref
                          .read(apiEndpointControllerProvider)
                          .resolvedUrl;
                    }
                  });
                },
                child: Column(
                  children: [
                    RadioListTile<ApiEndpointKind>(
                      key: const Key('api-endpoint-firebase'),
                      value: ApiEndpointKind.firebase,
                      title: Text(l10n.apiServerFirebase),
                      subtitle: Text(l10n.apiServerFirebaseDetail),
                    ),
                    RadioListTile<ApiEndpointKind>(
                      key: const Key('api-endpoint-dev'),
                      value: ApiEndpointKind.dev,
                      title: Text(l10n.apiServerDev),
                      subtitle: const Text(kApiDevBaseUrl),
                    ),
                    RadioListTile<ApiEndpointKind>(
                      key: const Key('api-endpoint-prod'),
                      value: ApiEndpointKind.prod,
                      title: Text(l10n.apiServerProd),
                      subtitle: const Text(kApiProdBaseUrl),
                    ),
                    RadioListTile<ApiEndpointKind>(
                      key: const Key('api-endpoint-tunnel'),
                      value: ApiEndpointKind.tunnel,
                      title: Text(l10n.apiServerTunnel),
                      subtitle: Text(l10n.apiServerTunnelDetail),
                    ),
                  ],
                ),
              ),
              if (kind == ApiEndpointKind.tunnel) ...[
                TextField(
                  key: const Key('api-endpoint-tunnel-url'),
                  controller: _tunnelCtrl,
                  enabled: !_busy,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: InputDecoration(
                    labelText: l10n.apiServerTunnelField,
                    hintText: l10n.apiServerTunnelHint,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                currentUrl,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('api-endpoint-apply'),
                onPressed: _busy ? null : _apply,
                child: Text(l10n.apiServerApply),
              ),
              TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

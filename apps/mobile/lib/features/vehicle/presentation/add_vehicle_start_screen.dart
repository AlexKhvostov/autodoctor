import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/automotive_widgets.dart';
import '../../../l10n/l10n.dart';
import '../../guest_bootstrap/guest_bootstrap.dart';
import '../../guest_bootstrap/guest_bootstrap_controller.dart';

class AddVehicleStartScreen extends ConsumerStatefulWidget {
  const AddVehicleStartScreen({super.key});

  @override
  ConsumerState<AddVehicleStartScreen> createState() =>
      _AddVehicleStartScreenState();
}

class _AddVehicleStartScreenState extends ConsumerState<AddVehicleStartScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    final localeTag = locale.languageCode;
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';
    Future<void>.microtask(
      () => ref
          .read(guestBootstrapControllerProvider.notifier)
          .start(locale: localeTag, platform: platform),
    );
  }

  void _cancel() {
    ref.read(guestBootstrapControllerProvider.notifier).reset();
    context.go('/roadmap');
  }

  Future<void> _continue() async {
    await ref.read(guestBootstrapControllerProvider.notifier).submit();
    if (!mounted) {
      return;
    }
    final state = ref.read(guestBootstrapControllerProvider);
    if (state.stage == GuestBootstrapStage.ready && state.failure == null) {
      context.go('/garage/add/vin');
    }
  }

  Future<void> _retry() async {
    final wasSubmitFailure = ref
        .read(guestBootstrapControllerProvider)
        .submitFailure;
    await ref.read(guestBootstrapControllerProvider.notifier).retry();
    if (!mounted || !wasSubmitFailure) {
      return;
    }
    final state = ref.read(guestBootstrapControllerProvider);
    if (state.stage == GuestBootstrapStage.ready && state.failure == null) {
      context.go('/garage/add/vin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guestBootstrapControllerProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: context.l10n.back,
                onPressed: _cancel,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TechnicalLabel(context.l10n.garageSetupStep1),
                    Text(
                      context.l10n.addVehicle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _FlowBody(
            state: state,
            onContinue: _continue,
            onRetry: _retry,
          ),
        ),
      ],
    );
  }
}

class _FlowBody extends ConsumerWidget {
  const _FlowBody({
    required this.state,
    required this.onContinue,
    required this.onRetry,
  });

  final GuestBootstrapState state;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.stage == GuestBootstrapStage.idle ||
        state.stage == GuestBootstrapStage.loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AutomotivePanel(
            emphasized: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TechnicalLabel(context.l10n.secureInitializing),
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(context.l10n.preparingSecureSetup),
              ],
            ),
          ),
        ),
      );
    }

    if (state.stage == GuestBootstrapStage.error) {
      return _ErrorView(failure: state.failure, onRetry: onRetry);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TechnicalLabel(context.l10n.consentProtocol),
          const SizedBox(height: 5),
          Text(
            context.l10n.consents,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(context.l10n.consentsIntro),
          const SizedBox(height: 12),
          for (final document in state.documents)
            _ConsentCard(document: document, selected: state.selected),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const Key('consent-continue'),
            onPressed:
                state.canContinue &&
                    state.stage != GuestBootstrapStage.submitting
                ? onContinue
                : null,
            icon: state.stage == GuestBootstrapStage.submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward),
            label: Text(context.l10n.continueAction),
          ),
        ],
      ),
    );
  }
}

class _ConsentCard extends ConsumerWidget {
  const _ConsentCard({required this.document, required this.selected});

  final ConsentDocument document;
  final Map<String, bool> selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AutomotivePanel(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                key: Key('consent-${document.purpose}'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(document.title),
                subtitle: Text(
                  document.required
                      ? context.l10n.required
                      : context.l10n.optional,
                ),
                value: selected[document.purpose] ?? false,
                onChanged: (value) => ref
                    .read(guestBootstrapControllerProvider.notifier)
                    .setDecision(document.purpose, value ?? false),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(document.text),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: TechnicalLabel(
                context.l10n.versionLabel(document.version),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.failure, required this.onRetry});

  final GuestBootstrapFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AutomotivePanel(
          emphasized: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TechnicalLabel(
                context.l10n.connectionFault,
                icon: Icons.cloud_off_outlined,
              ),
              const SizedBox(height: 12),
              Text(
                _failureMessage(context, failure),
                textAlign: TextAlign.center,
              ),
              if (failure?.requestId case final requestId?) ...[
                const SizedBox(height: 8),
                SelectableText(
                  context.l10n.requestIdLabel(requestId),
                  key: const Key('error-request-id'),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('consent-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _failureMessage(BuildContext context, GuestBootstrapFailure? failure) {
    return switch (failure?.kind) {
      GuestBootstrapFailureKind.network => context.l10n.networkError,
      GuestBootstrapFailureKind.unexpectedResponse =>
        context.l10n.unexpectedResponse,
      GuestBootstrapFailureKind.unavailable =>
        context.l10n.bootstrapUnavailable,
      null when failure != null && failure.safeMessage.isNotEmpty =>
        failure.safeMessage,
      _ => context.l10n.bootstrapUnavailable,
    };
  }
}

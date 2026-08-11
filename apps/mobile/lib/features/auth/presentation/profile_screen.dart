import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/locale_controller.dart';
import '../../../l10n/l10n.dart';
import '../../assistant/assistant_controller.dart';
import '../../maintenance/maintenance_controller.dart';
import '../../vehicle/vehicle_controller.dart';
import '../auth.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final vehicles = ref.watch(vehicleSetupControllerProvider).vehicles;
    final assistant = ref.watch(assistantControllerProvider);
    final maintenance = ref.watch(maintenanceControllerProvider);
    final active = ref.watch(vehicleSetupControllerProvider).activeVehicle;
    final locale = ref.watch(activeLocaleProvider).languageCode;

    final chats =
        assistant.threads.length + assistant.archivedThreads.length;
    final actions = active != null && maintenance.matches(active.id, locale)
        ? (maintenance.serviceRecords?.items.length ?? 0)
        : 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _SignInBody(
          hint: l10n.profileGuestHint,
          errorText: '$error',
          signInLabel: l10n.signInWithGoogle,
          signedInMessage: l10n.profileSignedIn,
          onSignIn: () =>
              ref.read(authControllerProvider.notifier).signInWithGoogle(),
          stats: _ProfileStats(
            vehicles: vehicles.length,
            actions: actions,
            chats: chats,
          ),
        ),
        data: (user) {
          if (user == null) {
            return _SignInBody(
              hint: l10n.profileGuestHint,
              errorText: null,
              signInLabel: l10n.signInWithGoogle,
              signedInMessage: l10n.profileSignedIn,
              onSignIn: () =>
                  ref.read(authControllerProvider.notifier).signInWithGoogle(),
              stats: _ProfileStats(
                vehicles: vehicles.length,
                actions: actions,
                chats: chats,
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  backgroundImage:
                      user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null || user.photoUrl!.isEmpty
                      ? Text(
                          user.name.trim().isNotEmpty
                              ? String.fromCharCode(
                                  user.name.trim().runes.first,
                                ).toUpperCase()
                              : '?',
                          style: Theme.of(context).textTheme.headlineMedium,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(user.email, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              _ProfileStats(
                vehicles: vehicles.length,
                actions: actions,
                chats: chats,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.profileSignedOut)),
                    );
                  }
                },
                child: Text(l10n.signOut),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({
    required this.vehicles,
    required this.actions,
    required this.chats,
  });

  final int vehicles;
  final int actions;
  final int chats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.profileStatsTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  icon: Icons.directions_car_outlined,
                  label: l10n.profileStatsVehicles,
                  value: '$vehicles',
                ),
              ),
              Expanded(
                child: _StatCell(
                  icon: Icons.build_circle_outlined,
                  label: l10n.profileStatsActions,
                  value: '$actions',
                ),
              ),
              Expanded(
                child: _StatCell(
                  icon: Icons.chat_bubble_outline,
                  label: l10n.profileStatsChats,
                  value: '$chats',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: colors.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SignInBody extends StatelessWidget {
  const _SignInBody({
    required this.hint,
    required this.errorText,
    required this.signInLabel,
    required this.signedInMessage,
    required this.onSignIn,
    required this.stats,
  });

  final String hint;
  final String? errorText;
  final String signInLabel;
  final String signedInMessage;
  final Future<void> Function() onSignIn;
  final Widget stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(hint, style: Theme.of(context).textTheme.bodyLarge),
        if (errorText != null && errorText!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            errorText!,
            style: TextStyle(color: colors.error),
          ),
        ],
        const SizedBox(height: 20),
        stats,
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () async {
            await onSignIn();
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(signedInMessage)));
            }
          },
          icon: const Icon(Icons.login),
          label: Text(signInLabel),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../agent_profile_api.dart';

/// Compact companion chip for the assistant header: mascot + full energy digits.
class AgentFuelChip extends StatelessWidget {
  const AgentFuelChip({
    super.key,
    required this.energy,
    required this.onTap,
    this.loading = false,
  });

  final AgentFuel energy;
  final VoidCallback onTap;
  final bool loading;

  Color _accent(ColorScheme colors) {
    return switch (energy.status) {
      AgentEnergyStatus.empty => colors.error,
      AgentEnergyStatus.low => const Color(0xFFE07A3A),
      AgentEnergyStatus.ok => colors.primary,
    };
  }

  String _formatBalance(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buf.write('\u202f');
      }
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final accent = _accent(colors);
    final lowOrEmpty = energy.status != AgentEnergyStatus.ok;
    final balance = _formatBalance(energy.balanceMl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('agent-fuel-chip'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: lowOrEmpty ? 0.24 : 0.14),
                colors.surfaceContainerHighest.withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(
              color: lowOrEmpty
                  ? accent.withValues(alpha: 0.6)
                  : colors.outlineVariant.withValues(alpha: 0.5),
              width: lowOrEmpty ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: loading
              ? const SizedBox(
                  width: 96,
                  height: 52,
                  child: Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/branding/agent_companion_widget.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                color: colors.primary.withValues(alpha: 0.12),
                                child: Icon(
                                  Icons.smart_toy_rounded,
                                  size: 24,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ),
                          if (lowOrEmpty)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.surface,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.generating_tokens_outlined,
                                size: 16,
                                color: accent,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                balance,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                  height: 1.05,
                                  letterSpacing: -0.2,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '≈${energy.approxRepliesLeft}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

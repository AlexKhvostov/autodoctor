import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../l10n/l10n.dart';
import '../agent_profile_api.dart';

const _kIntroCollapsedKey = 'agent_intro_description_collapsed';

/// Compact agent intro for the chats list header (not shown inside an open chat).
class AgentIntroCard extends StatefulWidget {
  const AgentIntroCard({
    super.key,
    required this.energy,
    required this.onOpenProfile,
    this.loading = false,
  });

  final AgentFuel energy;
  final VoidCallback onOpenProfile;
  final bool loading;

  @override
  State<AgentIntroCard> createState() => _AgentIntroCardState();
}

class _AgentIntroCardState extends State<AgentIntroCard> {
  static const _storage = FlutterSecureStorage();
  var _collapsed = false;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadCollapsed();
  }

  Future<void> _loadCollapsed() async {
    final raw = await _storage.read(key: _kIntroCollapsedKey);
    if (!mounted) return;
    setState(() {
      _collapsed = raw == '1';
      _loaded = true;
    });
  }

  Future<void> _setCollapsed(bool value) async {
    setState(() => _collapsed = value);
    await _storage.write(key: _kIntroCollapsedKey, value: value ? '1' : '0');
  }

  Color _accent(ColorScheme colors) {
    return switch (widget.energy.status) {
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final accent = _accent(colors);
    final energy = widget.energy;
    final loading = widget.loading;
    final lowOrEmpty = energy.status != AgentEnergyStatus.ok;
    final collapsed = _loaded && _collapsed;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: lowOrEmpty ? 0.18 : 0.10),
              colors.surfaceContainerHighest.withValues(alpha: 0.96),
            ],
          ),
          border: Border.all(
            color: lowOrEmpty
                ? accent.withValues(alpha: 0.55)
                : colors.outlineVariant.withValues(alpha: 0.5),
            width: lowOrEmpty ? 1.3 : 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, collapsed ? 8 : 10, 8, collapsed ? 8 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      key: const Key('agent-intro-card'),
                      onTap: widget.onOpenProfile,
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  'assets/branding/agent_companion_widget.png',
                                  width: collapsed ? 40 : 48,
                                  height: collapsed ? 40 : 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: collapsed ? 40 : 48,
                                    height: collapsed ? 40 : 48,
                                    color: colors.primary.withValues(alpha: 0.12),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.smart_toy_rounded,
                                      size: collapsed ? 22 : 26,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              if (lowOrEmpty)
                                Positioned(
                                  right: -1,
                                  top: -1,
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.aiAssistant,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    letterSpacing: -0.2,
                                    fontSize: collapsed ? 16 : null,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  l10n.agentIntroSubtitle,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (loading)
                                  SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: accent,
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.generating_tokens_outlined,
                                        size: 14,
                                        color: accent,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        _formatBalance(energy.balanceMl),
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: accent,
                                              height: 1.05,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          l10n.agentIntroRepliesLeft(
                                            energy.approxRepliesLeft,
                                          ),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (!loading) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.agentTypicalReplyCost(
                                      energy.typicalSpendMl,
                                    ),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.onSurfaceVariant,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    key: const Key('agent-intro-toggle'),
                    tooltip: collapsed
                        ? l10n.agentIntroExpand
                        : l10n.agentIntroCollapse,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => _setCollapsed(!_collapsed),
                    icon: Icon(
                      collapsed
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.agentIntroBody,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.86),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: widget.onOpenProfile,
                        borderRadius: BorderRadius.circular(6),
                        child: Text(
                          l10n.agentIntroOpenProfile,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: collapsed
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 180),
                sizeCurve: Curves.easeOutCubic,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

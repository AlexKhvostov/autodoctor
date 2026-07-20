import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'automotive_widgets.dart';

class ExampleBadge extends StatelessWidget {
  const ExampleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: context.l10n.exampleSemantics,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 14,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.example,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PreviewGate extends StatelessWidget {
  const PreviewGate({
    required this.message,
    required this.onAddVehicle,
    super.key,
  });

  final String message;
  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: context.l10n.previewNoCar(message),
      child: AutomotivePanel(
        emphasized: true,
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.directions_car_filled_outlined,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TechnicalLabel(context.l10n.previewGarageEmpty),
                  const SizedBox(height: 5),
                  Text(message),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    key: const Key('preview-add-vehicle'),
                    onPressed: onAddVehicle,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.l10n.addVehicle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PreviewListTile extends StatelessWidget {
  const PreviewListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      enabled: false,
      hint: context.l10n.previewUnavailableHint,
      child: Opacity(
        opacity: 0.62,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 3, height: 44, color: colors.onSurfaceVariant),
              const SizedBox(width: 10),
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TechnicalLabel(context.l10n.demoEntry),
                    const SizedBox(height: 3),
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(subtitle),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Text(trailing!, style: Theme.of(context).textTheme.labelMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/widgets/automotive_widgets.dart';
import '../../../core/widgets/preview_widgets.dart';
import '../../../l10n/l10n.dart';

/// Живой справочник UI-компонентов для новых экранов.
class ComponentCatalogScreen extends StatelessWidget {
  const ComponentCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.uiKitTitle)),
      body: ListView(
        key: const Key('ui-kit-scroll'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            context.l10n.uiKitIntro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: context.l10n.uiKitSectionPanels,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AutomotivePanel(
                  child: Text(context.l10n.uiKitPanelDefault),
                ),
                const SizedBox(height: 8),
                AutomotivePanel(
                  emphasized: true,
                  child: Text(context.l10n.uiKitPanelEmphasized),
                ),
              ],
            ),
          ),
          _Section(
            title: context.l10n.uiKitSectionHeaders,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TechnicalLabel('TECHNICAL LABEL'),
                const SizedBox(height: 8),
                SectionHeader(
                  label: 'SECTION',
                  title: context.l10n.uiKitSectionHeaderExample,
                  trailing: const ExampleBadge(),
                ),
              ],
            ),
          ),
          _Section(
            title: context.l10n.uiKitSectionButtons,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: () {},
                  child: Text(context.l10n.uiKitPrimaryButton),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () {},
                  child: Text(context.l10n.uiKitTonalButton),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {},
                  child: Text(context.l10n.uiKitOutlinedButton),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: Text(context.l10n.uiKitTextButton),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: null,
                  child: Text(context.l10n.uiKitDisabledButton),
                ),
              ],
            ),
          ),
          _Section(
            title: context.l10n.uiKitSectionInputs,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: context.l10n.uiKitInputLabel,
                    hintText: context.l10n.uiKitInputHint,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    labelText: context.l10n.uiKitInputErrorLabel,
                    errorText: context.l10n.uiKitInputError,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: 'a',
                  decoration: InputDecoration(
                    labelText: context.l10n.uiKitDropdownLabel,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'a', child: Text('Option A')),
                    DropdownMenuItem(value: 'b', child: Text('Option B')),
                  ],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.uiKitSwitchLabel),
                  value: true,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          _Section(
            title: context.l10n.uiKitSectionStatus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatusRail(
                  label: context.l10n.uiKitStatusLabel,
                  statusText: context.l10n.uiKitStatusValue,
                  activeSegments: 3,
                  segmentCount: 5,
                ),
                const SizedBox(height: 12),
                ConsumableGauge(
                  icon: Icons.oil_barrel_outlined,
                  color: colors.primary,
                  semanticLabel: context.l10n.uiKitGaugeLabel,
                  progress: 0.62,
                  onTap: () {},
                ),
              ],
            ),
          ),
          _Section(
            title: context.l10n.uiKitSectionPreview,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: ExampleBadge(),
                ),
                const SizedBox(height: 8),
                PreviewGate(
                  message: context.l10n.uiKitPreviewGate,
                  onAddVehicle: () {},
                ),
                const SizedBox(height: 8),
                PreviewListTile(
                  icon: Icons.oil_barrel_outlined,
                  title: context.l10n.uiKitPreviewTileTitle,
                  subtitle: context.l10n.uiKitPreviewTileDetail,
                ),
              ],
            ),
          ),
          _Section(
            title: context.l10n.uiKitSectionColors,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in [
                  ('primary', colors.primary),
                  ('secondary', colors.secondary),
                  ('error', colors.error),
                  ('surface', colors.surfaceContainer),
                  ('outline', colors.outlineVariant),
                ])
                  _ColorSwatch(name: entry.$1, color: entry.$2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

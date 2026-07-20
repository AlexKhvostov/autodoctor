import 'package:flutter/material.dart';

import '../../app/theme.dart';

class AutomotivePanel extends StatelessWidget {
  const AutomotivePanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.emphasized = false,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool emphasized;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final panel = Container(
      decoration: BoxDecoration(
        color: emphasized
            ? colors.surfaceContainerHigh
            : colors.surfaceContainer,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Padding(padding: padding, child: child),
          if (emphasized)
            Positioned(
              left: 0,
              top: 8,
              bottom: 8,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );

    if (semanticLabel == null) {
      return panel;
    }
    return Semantics(container: true, label: semanticLabel, child: panel);
  }
}

class TechnicalLabel extends StatelessWidget {
  const TechnicalLabel(this.text, {this.color, this.icon, super.key});

  final String text;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.labelSmall?.copyWith(
      color: effectiveColor,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.25,
    );

    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: effectiveColor),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                text.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.label,
    this.trailing,
    super.key,
  });

  final String title;
  final String? label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          TechnicalLabel(label!),
          const SizedBox(height: 5),
        ],
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: titleWidget),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class StatusRail extends StatelessWidget {
  const StatusRail({
    required this.label,
    required this.statusText,
    required this.activeSegments,
    required this.segmentCount,
    this.color,
    super.key,
  }) : assert(segmentCount > 0),
       assert(activeSegments >= 0),
       assert(activeSegments <= segmentCount);

  final String label;
  final String statusText;
  final int activeSegments;
  final int segmentCount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final automotive =
        theme.extension<AutomotiveColors>() ?? AutomotiveColors.dark;
    final activeColor = color ?? automotive.trackActive;

    return Semantics(
      container: true,
      label: label,
      value: statusText,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: TechnicalLabel(label)),
                const SizedBox(width: 12),
                Text(
                  statusText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: activeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(segmentCount, (index) {
                final active = index < activeSegments;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == segmentCount - 1 ? 0 : 4,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: active ? 8 : 4,
                      decoration: BoxDecoration(
                        color: active ? activeColor : automotive.track,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class ConsumableGauge extends StatelessWidget {
  const ConsumableGauge({
    required this.icon,
    required this.color,
    required this.semanticLabel,
    required this.onTap,
    this.progress,
    this.stateIcon,
    this.selected = false,
    this.focusNode,
    super.key,
  }) : assert(progress == null || (progress >= 0 && progress <= 1));

  final IconData icon;
  final Color color;
  final String semanticLabel;
  final VoidCallback onTap;
  final double? progress;
  final IconData? stateIcon;
  final bool selected;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: InkResponse(
          onTap: onTap,
          focusNode: focusNode,
          customBorder: const CircleBorder(),
          radius: 28,
          child: SizedBox.square(
            dimension: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (progress != null)
                  SizedBox.square(
                    dimension: 46,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: selected ? 5 : 4,
                      strokeCap: StrokeCap.round,
                      color: color,
                      backgroundColor: colors.outlineVariant,
                    ),
                  )
                else
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: selected ? 4 : 2),
                    ),
                  ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? colors.surfaceContainerHighest
                        : colors.surfaceContainerHigh,
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                if (stateIcon != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: color),
                      ),
                      child: Icon(stateIcon, size: 12, color: color),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VehicleSilhouettePlaceholder extends StatelessWidget {
  const VehicleSilhouettePlaceholder({
    required this.message,
    this.action,
    super.key,
  });

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final automotive =
        theme.extension<AutomotiveColors>() ?? AutomotiveColors.dark;

    return Semantics(
      container: true,
      label: message,
      child: ExcludeSemantics(
        child: AutomotivePanel(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_car_filled_outlined,
                size: 72,
                color: automotive.metal,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/automotive_widgets.dart';
import '../../../l10n/l10n.dart';
import '../maintenance.dart';

class MileageTrendChart extends StatelessWidget {
  const MileageTrendChart({
    required this.observations,
    super.key,
  });

  final List<MileageObservation> observations;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final points = [
      for (final item in observations)
        (at: item.observedAt.toLocal(), km: item.valueKm),
    ]..sort((a, b) => a.at.compareTo(b.at));

    return AutomotivePanel(
      key: const Key('analytics-mileage-chart'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TechnicalLabel(context.l10n.odometerDynamics),
          const SizedBox(height: 4),
          Text(
            context.l10n.confirmedMileage,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: points.isEmpty
                ? _EmptyMileageChart(colors: colors)
                : _MileageLineChart(points: points, colors: colors),
          ),
          if (points.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.analyticsMileageEmpty,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyMileageChart extends StatelessWidget {
  const _EmptyMileageChart({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _EmptyAxesPainter(
        axisColor: colors.outlineVariant,
        gridColor: colors.outlineVariant.withValues(alpha: 0.35),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _EmptyAxesPainter extends CustomPainter {
  _EmptyAxesPainter({required this.axisColor, required this.gridColor});

  final Color axisColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = axisColor
      ..strokeWidth = 1.2;
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const left = 36.0;
    const bottom = 28.0;
    final right = size.width - 8;
    final top = 12.0;
    for (var i = 0; i < 4; i++) {
      final y = top + (size.height - bottom - top) * i / 3;
      canvas.drawLine(Offset(left, y), Offset(right, y), grid);
    }
    canvas.drawLine(Offset(left, top), Offset(left, size.height - bottom), axis);
    canvas.drawLine(
      Offset(left, size.height - bottom),
      Offset(right, size.height - bottom),
      axis,
    );
  }

  @override
  bool shouldRepaint(covariant _EmptyAxesPainter oldDelegate) =>
      oldDelegate.axisColor != axisColor || oldDelegate.gridColor != gridColor;
}

class _MileageLineChart extends StatelessWidget {
  const _MileageLineChart({required this.points, required this.colors});

  final List<({DateTime at, int km})> points;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final first = points.first.at;
    final last = points.last.at;
    final spanMs = last.difference(first).inMilliseconds;
    final safeSpan = spanMs <= 0 ? 1.0 : spanMs.toDouble();
    final spots = [
      for (final point in points)
        FlSpot(
          point.at.difference(first).inMilliseconds / safeSpan,
          point.km.toDouble(),
        ),
    ];
    final minY = points.map((p) => p.km).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.km).reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY).abs() * 0.08).clamp(50, 2000).toDouble();
    final dateFormat = DateFormat('dd.MM');

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 1,
        minY: (minY - pad).clamp(0, double.infinity),
        maxY: maxY + pad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colors.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: colors.outlineVariant),
            bottom: BorderSide(color: colors.outlineVariant),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                _compactKm(value),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: points.length == 1 ? 1 : 0.5,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > 1) return const SizedBox.shrink();
                if (value != 0 && value != 1 && points.length > 1) {
                  return const SizedBox.shrink();
                }
                final at = first.add(
                  Duration(milliseconds: (safeSpan * value).round()),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    dateFormat.format(at),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touched) => [
              for (final spot in touched)
                LineTooltipItem(
                  '${spot.y.round()} km\n${dateFormat.format(first.add(Duration(milliseconds: (safeSpan * spot.x).round())))}',
                  TextStyle(
                    color: colors.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: colors.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3.5,
                color: colors.primary,
                strokeWidth: 1.5,
                strokeColor: colors.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: colors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  static String _compactKm(double value) {
    if (value >= 10000) return '${(value / 1000).round()}k';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.round().toString();
  }
}

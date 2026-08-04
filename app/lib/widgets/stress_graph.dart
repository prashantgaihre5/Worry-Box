import 'package:flutter/material.dart';
import '../theme.dart';

class StressGraph extends StatelessWidget {
  final int totalCreated;
  final int totalReleased;
  final int totalImportant;

  const StressGraph({
    super.key,
    required this.totalCreated,
    required this.totalReleased,
    required this.totalImportant,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCreated == 0) return const SizedBox.shrink();

    final double releasedPercent = totalReleased / totalCreated;
    final double importantPercent = totalImportant / totalCreated;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(AppShape.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppColors.accentSoft, size: 20),
              const SizedBox(width: AppSpacing.sp2),
              Text(
                'Stress Analytics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp4),
          
          // Let Go Bar
          _buildBar(
            context,
            label: 'Stress Let Go',
            count: totalReleased,
            total: totalCreated,
            percent: releasedPercent,
            color: AppColors.accentSoft,
          ),
          
          const SizedBox(height: AppSpacing.sp3),
          
          // Marked Important Bar
          _buildBar(
            context,
            label: 'Marked Important',
            count: totalImportant,
            total: totalCreated,
            percent: importantPercent,
            color: AppColors.orb3, // Pink
          ),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, {
    required String label,
    required int count,
    required int total,
    required double percent,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count / $total',
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            color: AppColors.bg1,
            alignment: Alignment.centerLeft,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: AppDurations.base,
                  curve: Curves.easeOutCubic,
                  width: constraints.maxWidth * percent.clamp(0.0, 1.0),
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../services/storage.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';

class AnalyticsScreen extends StatelessWidget {
  final StorageService storage;
  final String locale;

  const AnalyticsScreen({
    super.key,
    required this.storage,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: storage,
      builder: (context, _) {
        final totalCaptured = storage.state.totalWorriesCreated;
        final totalLetGo = storage.state.totalWorriesReleased;
        final totalKept = storage.getKeptWorries().length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                AppStrings.get('analytics', locale: locale),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.get('analyticsSub', locale: locale),
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFBFDBFE).withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _buildStatCard(
                      title: AppStrings.get('totalCaptured', locale: locale),
                      value: totalCaptured.toString(),
                      icon: Icons.edit_note,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      title: AppStrings.get('totalLetGo', locale: locale),
                      value: totalLetGo.toString(),
                      icon: Icons.wind_power,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      title: AppStrings.get('totalKept', locale: locale),
                      value: totalKept.toString(),
                      icon: Icons.bookmark,
                      color: Colors.amberAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.glassPanelBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassPanelBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFBFDBFE).withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

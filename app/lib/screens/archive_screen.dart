import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/worry.dart';
import '../services/storage.dart';
import '../theme.dart';

class ArchiveScreen extends StatelessWidget {
  final StorageService storage;

  const ArchiveScreen({
    super.key,
    required this.storage,
  });

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder updates automatically when storage changes
    return ListenableBuilder(
      listenable: storage,
      builder: (context, _) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final archiveWorries = storage.getWorries().where((w) {
          final isPending = w.status == 'locked' && now < w.unlockAt;
          return !isPending;
        }).toList();
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Archive',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A complete history of everything you have captured.',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFBFDBFE).withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: archiveWorries.isEmpty 
                  ? _buildEmptyState() 
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: archiveWorries.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _ArchiveCard(worry: archiveWorries[index]);
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text(
            'No history yet.',
            style: TextStyle(fontSize: 14, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 4),
          Text(
            'Worries you capture will appear here over time.',
            style: TextStyle(fontSize: 12, color: const Color(0xFFCBD5E1).withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final Worry worry;

  const _ArchiveCard({required this.worry});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(DateTime.fromMillisecondsSinceEpoch(worry.createdAt));
    
    // Determine status UI elements
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (worry.status) {
      case 'released':
        statusColor = Colors.greenAccent;
        statusText = 'Released';
        statusIcon = Icons.air;
        break;
      case 'kept':
        statusColor = const Color(0xFF8B5CF6); // Violet
        statusText = 'Kept / Bookmarked';
        statusIcon = Icons.bookmark;
        break;
      case 'pending':
      default:
        statusColor = AppColors.accent;
        statusText = 'Pending';
        statusIcon = Icons.lock_clock;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassPanelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassPanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Icon(statusIcon, size: 14, color: statusColor.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  Text(
                    statusText.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: statusColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            worry.title.isNotEmpty ? worry.title : worry.text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          if (worry.isImportant) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  'Marked Important',
                  style: TextStyle(fontSize: 12, color: Colors.amber.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}

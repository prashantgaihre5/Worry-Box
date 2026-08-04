import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/worry.dart';
import '../services/storage.dart';
import '../theme.dart';
import 'package:intl/intl.dart';

class RevealScreen extends StatefulWidget {
  final StorageService storage;
  final String locale;
  final VoidCallback onAllCleared;
  final VoidCallback onNavigateToCapture;

  const RevealScreen({
    super.key,
    required this.storage,
    required this.locale,
    required this.onAllCleared,
    required this.onNavigateToCapture,
  });

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen> {
  List<Worry> _worries = [];

  String get _locale => widget.locale;

  @override
  void initState() {
    super.initState();
    _loadWorries();
  }

  void _loadWorries() {
    final unlocked = widget.storage.getUnlockedWorries();
    // Ensure all unlocked worries are marked as revealed if they are still locked
    for (final w in unlocked) {
      if (w.status == 'locked') {
        widget.storage.markRevealed(w.id);
      }
    }
    _refreshWorries();
  }
  
  void _refreshWorries() {
    final updated = widget.storage.getWorries()
        .where((w) => w.status == 'revealed')
        .toList();
    updated.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _worries = updated;
    });
    // If nothing left to reveal, go back to home
    if (updated.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAllCleared();
      });
    }
  }

  Future<void> _release(String id) async {
    await widget.storage.releaseWorry(id);
    _refreshWorries();
  }

  Future<void> _keep(String id) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF60A5FA),
            onPrimary: Colors.white,
            surface: Color(0xFF151D3B),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    if (!mounted) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF60A5FA),
            onPrimary: Colors.white,
            surface: Color(0xFF151D3B),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    final deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final finalDeadline = deadline.isBefore(now) ? now.add(const Duration(minutes: 1)) : deadline;

    await widget.storage.keepWorryWithDeadline(id, finalDeadline.millisecondsSinceEpoch);
    _refreshWorries();
  }
  
  Future<void> _deletePermanently(String id) async {
    // We don't have a strict delete method in our API, but we can set it to released 
    // or just omit it from the UI. To truly delete it, we'd need storage support.
    // Let's just remove it from _worries for now to match the frontend prototype.
    setState(() {
      _worries.removeWhere((w) => w.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Reveal Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1A3B82F6), // blue-500/10
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x3360A5FA)), // blue-400/20
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Color(0xFF93C5FD)), // blue-300
                    SizedBox(width: 6),
                    Text(
                      'WORRY TIME SESSION',
                      style: TextStyle(color: Color(0xFF93C5FD), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.get('revealHeadline', locale: _locale),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.get('revealSub', locale: _locale),
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFBFDBFE).withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Scrollable List
        Expanded(
          child: _worries.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: _worries.length,
                  itemBuilder: (context, index) {
                    return _WorryCard(
                      worry: _worries[index],
                      locale: _locale,
                      onRelease: () => _release(_worries[index].id),
                      onKeep: () => _keep(_worries[index].id),
                      onDelete: () => _deletePermanently(_worries[index].id),
                    );
                  },
                ),
        ),

        // Sticky Bottom Action
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xCC0B1020),
            border: const Border(top: BorderSide(color: Color(0x0DFFFFFF))),
          ),
          child: ElevatedButton.icon(
            onPressed: widget.onNavigateToCapture,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              foregroundColor: AppColors.accentSoft,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.4),
                )
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Add',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, size: 48, color: Color(0xFF60A5FA)), // blue-400
          const SizedBox(height: 12),
          const Text(
            'No worries revealed yet.',
            style: TextStyle(fontSize: 14, color: Color(0xFFBFDBFE)),
          ),
          const SizedBox(height: 4),
          Text(
            'Wait for your box to unlock.',
            style: TextStyle(fontSize: 12, color: const Color(0xFFBFDBFE).withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _WorryCard extends StatelessWidget {
  final Worry worry;
  final String locale;
  final VoidCallback onRelease;
  final VoidCallback onKeep;
  final VoidCallback onDelete;

  const _WorryCard({
    required this.worry,
    required this.locale,
    required this.onRelease,
    required this.onKeep,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLetGo = worry.status == 'released';
    final isKept = worry.status == 'kept';
    final isRevealed = worry.status == 'revealed';

    // Formatter
    final dateStr = DateFormat('M/d/yyyy').format(DateTime.fromMillisecondsSinceEpoch(worry.createdAt));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLetGo ? const Color(0x1A064E3B) : const Color(0xCC151D3B), // emerald-900/10 vs blue-800/80
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLetGo ? const Color(0x3310B981) : const Color(0x2660A5FA), // emerald-500/20 vs blue-400/15
        ),
        boxShadow: isLetGo ? null : const [
          BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isLetGo ? const Color(0x1A10B981) : const Color(0x1A3B82F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLetGo ? Icons.check_circle : Icons.bookmark_added,
                      size: 12,
                      color: isLetGo ? const Color(0xFF34D399) : const Color(0xFF93C5FD),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isLetGo ? AppStrings.get('letGoTag', locale: locale).toUpperCase() : AppStrings.get('keptTag', locale: locale).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: isLetGo ? const Color(0xFF34D399) : const Color(0xFF93C5FD),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Worry Text
          Text(
            worry.title.isNotEmpty ? worry.title : worry.text,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: isLetGo ? const Color(0xFF9CA3AF) : const Color(0xFFF3F4F6),
              decoration: isLetGo ? TextDecoration.lineThrough : null,
              decorationColor: const Color(0x4D10B981), // emerald-500/30
            ),
          ),

          // Actions
          if (isRevealed || isKept) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0x0DFFFFFF)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRelease,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: const Color(0x3310B981), // emerald-500/20
                      foregroundColor: const Color(0xFF6EE7B7), // emerald-300
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0x3310B981)),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 14),
                    label: Text(
                      AppStrings.get('letGo', locale: locale),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isRevealed)
                  ElevatedButton.icon(
                    onPressed: onKeep,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.grey,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.transparent),
                      ),
                    ),
                    icon: const Icon(Icons.bookmark_border, size: 14),
                    label: Text(
                      AppStrings.get('keepButton', locale: locale),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  )
                else if (isKept)
                  IconButton(
                    onPressed: onDelete,
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 16),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

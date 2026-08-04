import 'dart:async';
import 'package:flutter/material.dart';
import '../services/storage.dart';
import '../models/worry.dart';

class ExpiredDialog extends StatefulWidget {
  final StorageService storage;

  const ExpiredDialog({super.key, required this.storage});

  @override
  State<ExpiredDialog> createState() => _ExpiredDialogState();
}

class _ExpiredDialogState extends State<ExpiredDialog> {
  // One periodic timer per bookmark id, ticking every second for live countdowns
  final Map<String, Timer> _timers = {};
  // Track which items are "processing" (awaiting date picker) to prevent double-tap
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    widget.storage.addListener(_onStorageChange);
    _syncTimers();
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    widget.storage.removeListener(_onStorageChange);
    super.dispose();
  }

  // Called whenever storage changes (a task is marked done or extended)
  void _onStorageChange() {
    if (!mounted) return;
    final expired = widget.storage.getExpiredBookmarks();
    // Cancel timers for items that are no longer expired
    final expiredIds = expired.map((w) => w.id).toSet();
    final toRemove = _timers.keys.where((id) => !expiredIds.contains(id)).toList();
    for (final id in toRemove) {
      _timers[id]?.cancel();
      _timers.remove(id);
    }
    _syncTimers();
    setState(() {});
    if (expired.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  // Ensures every expired item has its own running timer
  void _syncTimers() {
    final expired = widget.storage.getExpiredBookmarks();
    for (final w in expired) {
      if (!_timers.containsKey(w.id)) {
        _timers[w.id] = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  Future<void> _extendDeadline(String id) async {
    if (_processing.contains(id)) return;
    setState(() => _processing.add(id));

    try {
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
      if (date == null || !mounted) return;

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
      if (time == null || !mounted) return;

      final deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      final finalDeadline = deadline.isBefore(now) ? now.add(const Duration(minutes: 1)) : deadline;

      await widget.storage.extendBookmarkDeadline(id, finalDeadline.millisecondsSinceEpoch);
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  String _overdueText(int unlockAtMs) {
    final diff = DateTime.now().millisecondsSinceEpoch - unlockAtMs;
    if (diff <= 0) return 'Just expired';
    final d = Duration(milliseconds: diff);
    if (d.inDays > 0) return 'Overdue by ${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return 'Overdue by ${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return 'Overdue by ${d.inMinutes}m ${d.inSeconds % 60}s';
    return 'Overdue by ${d.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final expired = widget.storage.getExpiredBookmarks();
    // Sync in case new items were added while dialog was open
    _syncTimers();

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: const Color(0xFF0B1020),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF2D2F4E)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notification_important_rounded, size: 48, color: Color(0xFFFDA4AF)),
              const SizedBox(height: 12),
              const Text(
                'Needs Review',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                '${expired.length} task${expired.length == 1 ? '' : 's'} past deadline',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: expired.map((w) {
                      final isProcessing = _processing.contains(w.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1035),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x88F43F5E)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.title.isNotEmpty ? w.title : w.text,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Live overdue counter for this individual item
                            Text(
                              _overdueText(w.unlockAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFDA4AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isProcessing
                                        ? null
                                        : () => widget.storage.removeWorry(w.id),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      backgroundColor: const Color(0x3310B981),
                                      foregroundColor: const Color(0xFF6EE7B7),
                                      shadowColor: Colors.transparent,
                                      disabledBackgroundColor: const Color(0x1A10B981),
                                    ),
                                    icon: const Icon(Icons.check_circle_outline, size: 14),
                                    label: const Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isProcessing
                                        ? null
                                        : () => _extendDeadline(w.id),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      backgroundColor: const Color(0x3360A5FA),
                                      foregroundColor: const Color(0xFF93C5FD),
                                      shadowColor: Colors.transparent,
                                      disabledBackgroundColor: const Color(0x1A60A5FA),
                                    ),
                                    icon: isProcessing
                                        ? const SizedBox(
                                            width: 14, height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF93C5FD)),
                                          )
                                        : const Icon(Icons.edit_calendar_outlined, size: 14),
                                    label: Text(
                                      isProcessing ? 'Picking...' : 'Extend',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/storage.dart';
import '../models/worry.dart';

/// An inline banner that shows expired bookmarks directly in the home screen.
/// Each item has its own live overdue counter.
class ExpiredBookmarksBanner extends StatefulWidget {
  final StorageService storage;

  const ExpiredBookmarksBanner({super.key, required this.storage});

  @override
  State<ExpiredBookmarksBanner> createState() => _ExpiredBookmarksBannerState();
}

class _ExpiredBookmarksBannerState extends State<ExpiredBookmarksBanner>
    with SingleTickerProviderStateMixin {
  final Map<String, Timer> _timers = {};
  final Set<String> _processing = {};
  bool _expanded = true;
  late AnimationController _rotateCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0, // starts expanded
    );
    widget.storage.addListener(_onStorageChange);
    _syncTimers();
  }

  @override
  void dispose() {
    for (final t in _timers.values) t.cancel();
    _timers.clear();
    widget.storage.removeListener(_onStorageChange);
    _rotateCtrl.dispose();
    super.dispose();
  }

  void _onStorageChange() {
    if (!mounted) return;
    final expiredIds = widget.storage.getExpiredBookmarks().map((w) => w.id).toSet();
    final toRemove = _timers.keys.where((id) => !expiredIds.contains(id)).toList();
    for (final id in toRemove) {
      _timers[id]?.cancel();
      _timers.remove(id);
    }
    _syncTimers();
    if (mounted) setState(() {});
  }

  void _syncTimers() {
    for (final w in widget.storage.getExpiredBookmarks()) {
      if (!_timers.containsKey(w.id)) {
        _timers[w.id] = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _rotateCtrl.forward();
    } else {
      _rotateCtrl.reverse();
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
        builder: (ctx, child) => Theme(
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
        builder: (ctx, child) => Theme(
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

      final dl = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      final final_dl = dl.isBefore(now) ? now.add(const Duration(minutes: 1)) : dl;
      await widget.storage.extendBookmarkDeadline(id, final_dl.millisecondsSinceEpoch);
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  String _overdueLabel(int unlockAtMs) {
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
    _syncTimers();
    if (expired.isEmpty) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0820),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xAAF43F5E)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — always visible
            InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x33F43F5E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notification_important_rounded,
                          size: 18, color: Color(0xFFFDA4AF)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Needs Review',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFDA4AF),
                            ),
                          ),
                          Text(
                            '${expired.length} task${expired.length == 1 ? '' : 's'} past deadline',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5).animate(_rotateCtrl),
                      child: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFFFDA4AF), size: 20),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded task list
            if (_expanded) ...[
              const Divider(height: 1, color: Color(0x44F43F5E)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: expired.map((w) {
                    final isProcessing = _processing.contains(w.id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0A1A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x55F43F5E)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.title.isNotEmpty ? w.title : w.text,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Per-item live overdue counter
                          Row(
                            children: [
                              const Icon(Icons.timer_off_outlined,
                                  size: 12, color: Color(0xFFFDA4AF)),
                              const SizedBox(width: 4),
                              Text(
                                _overdueLabel(w.unlockAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFFDA4AF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isProcessing
                                      ? null
                                      : () => widget.storage.removeWorry(w.id),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: const Color(0x2210B981),
                                    foregroundColor: const Color(0xFF6EE7B7),
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: const BorderSide(color: Color(0x3310B981)),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline, size: 14),
                                  label: const Text('Done',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isProcessing ? null : () => _extendDeadline(w.id),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: const Color(0x2260A5FA),
                                    foregroundColor: const Color(0xFF93C5FD),
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: const BorderSide(color: Color(0x3360A5FA)),
                                    ),
                                  ),
                                  icon: isProcessing
                                      ? const SizedBox(
                                          width: 12, height: 12,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: Color(0xFF93C5FD)),
                                        )
                                      : const Icon(Icons.edit_calendar_outlined, size: 14),
                                  label: Text(
                                    isProcessing ? 'Picking...' : 'Extend',
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600),
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
            ],
          ],
        ),
      ),
    );
  }
}

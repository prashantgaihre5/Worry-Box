import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/worry.dart';
import '../services/storage.dart';
import '../theme.dart';

class BookmarksScreen extends StatefulWidget {
  final StorageService storage;
  final String locale;

  const BookmarksScreen({
    super.key,
    required this.storage,
    required this.locale,
  });

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Worry> _bookmarks = [];
  Timer? _ticker;

  String get _locale => widget.locale;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _loadBookmarks() {
    setState(() {
      _bookmarks = widget.storage.getKeptWorries();
      _bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _markAsDone(String id) async {
    await widget.storage.removeWorry(id);
    _loadBookmarks();
  }

  Future<void> _extendDeadline(String id) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;

    final deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final finalDeadline = deadline.isBefore(now) ? now.add(const Duration(minutes: 1)) : deadline;

    await widget.storage.extendBookmarkDeadline(id, finalDeadline.millisecondsSinceEpoch);
    _loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1A8B5CF6), // violet-500/10
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x33A78BFA)), // violet-400/20
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark, size: 14, color: Color(0xFFC4B5FD)), // violet-300
                    SizedBox(width: 6),
                    Text(
                      'BOOKMARKS',
                      style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Kept for Review',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'These worries will prompt you again in 24 hours.',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFC4B5FD).withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _bookmarks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    return _BookmarkCard(
                      worry: _bookmarks[index],
                      locale: _locale,
                      onDone: () => _markAsDone(_bookmarks[index].id),
                      onExtend: () => _extendDeadline(_bookmarks[index].id),
                    );
                  },
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
          const Icon(Icons.bookmark_border, size: 48, color: Color(0xFF8B5CF6)), // violet-500
          const SizedBox(height: 12),
          const Text(
            'No bookmarks yet.',
            style: TextStyle(fontSize: 14, color: Color(0xFFC4B5FD)),
          ),
          const SizedBox(height: 4),
          Text(
            'Worries you choose to "Keep" will appear here.',
            style: TextStyle(fontSize: 12, color: const Color(0xFFC4B5FD).withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final Worry worry;
  final String locale;
  final VoidCallback onDone;
  final VoidCallback onExtend;

  const _BookmarkCard({
    required this.worry,
    required this.locale,
    required this.onDone,
    required this.onExtend,
  });

  String _formatDateTime(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final isToday = dt.year == DateTime.now().year && dt.month == DateTime.now().month && dt.day == DateTime.now().day;
    final isTomorrow = dt.year == DateTime.now().year && dt.month == DateTime.now().month && dt.day == DateTime.now().day + 1;
    
    final timeStr = DateFormat('h:mm a').format(dt);
    if (isToday) return 'Today at $timeStr';
    if (isTomorrow) return 'Tomorrow at $timeStr';
    return DateFormat('MMM d, y • h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('M/d/yyyy').format(DateTime.fromMillisecondsSinceEpoch(worry.createdAt));
    
    final remainingMs = worry.unlockAt - DateTime.now().millisecondsSinceEpoch;
    final isExpired = remainingMs <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xCC1E1B4B), // indigo-950/80
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isExpired ? const Color(0x66F43F5E) : const Color(0x268B5CF6), // rose/violet
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isExpired ? const Color(0x1AF43F5E) : const Color(0x1A8B5CF6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isExpired ? Icons.notification_important : Icons.timer,
                      size: 12,
                      color: isExpired ? const Color(0xFFFDA4AF) : const Color(0xFFC4B5FD),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isExpired ? 'NEEDS REVIEW' : _formatDateTime(worry.unlockAt),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1.0,
                        color: isExpired ? const Color(0xFFFDA4AF) : const Color(0xFFC4B5FD),
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
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFFF3F4F6),
            ),
          ),

          // Actions
          const SizedBox(height: 16),
          const Divider(color: Color(0x0DFFFFFF)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0x3310B981), // emerald-500/20
                    foregroundColor: const Color(0xFF6EE7B7), // emerald-300
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0x3310B981)),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text(
                    'Mark Done',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onExtend,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0x3360A5FA), // blue-500/20
                    foregroundColor: const Color(0xFF93C5FD), // blue-300
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0x3360A5FA)),
                    ),
                  ),
                  icon: const Icon(Icons.edit_calendar, size: 16),
                  label: const Text(
                    'Extend',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

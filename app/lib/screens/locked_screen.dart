import 'dart:async';
import 'package:flutter/material.dart';
import '../models/worry.dart';
import '../services/storage.dart';
import '../services/audio_service.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';
import '../widgets/box_animation.dart';
import '../widgets/glass_card.dart';

class LockedScreen extends StatefulWidget {
  final StorageService storage;
  final AudioService audio;
  final String locale;
  final VoidCallback onStateChange;

  const LockedScreen({
    super.key,
    required this.storage,
    required this.audio,
    required this.locale,
    required this.onStateChange,
  });

  @override
  State<LockedScreen> createState() => _LockedScreenState();
}

class _LockedScreenState extends State<LockedScreen> {
  Timer? _ticker;
  final _quickInputController = TextEditingController();

  String get _locale => widget.locale;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _quickInputController.dispose();
    super.dispose();
  }

  Future<void> _quickAdd() async {
    final text = _quickInputController.text.trim();
    if (text.isEmpty) return;

    try {
      await widget.storage.addWorry(text);
      _quickInputController.clear();
      FocusScope.of(context).unfocus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to your locked Worry Box')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds <= 0) return '0h 0m 00s';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final sStr = seconds < 10 ? '0$seconds' : '$seconds';
    return '${hours}h ${minutes}m ${sStr}s';
  }

  @override
  Widget build(BuildContext context) {
    final activeWorries = widget.storage.getWorries().where((w) => w.status != 'released').toList();
    if (activeWorries.isEmpty) return const SizedBox.shrink();

    // Find the closest unlock time
    activeWorries.sort((a, b) => a.unlockAt.compareTo(b.unlockAt));
    final closestWorry = activeWorries.first;
    final remainingMs = closestWorry.unlockAt - DateTime.now().millisecondsSinceEpoch;
    final remainingSeconds = remainingMs > 0 ? remainingMs ~/ 1000 : 0;
    
    // Automatically transition if timer hits 0
    if (remainingSeconds <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Mark all ready worries as revealed and change state
        for (var w in activeWorries) {
          if (w.unlockAt <= DateTime.now().millisecondsSinceEpoch) {
            widget.storage.markRevealed(w.id);
          }
        }
        widget.onStateChange();
      });
    }

    final worriesCountText = AppStrings.get('worriesCount', locale: _locale).replaceAll('{count}', '${activeWorries.length}');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Closed Box
          const SizedBox(
            width: 144,
            height: 144,
            child: BoxAnimationWidget(
              boxState: BoxState.closed,
              size: 144,
            ),
          ),
          const SizedBox(height: 24),

          // Headline
          Text(
            AppStrings.get('lockedHeadline', locale: _locale),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDBEAFE), // blue-100
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Locked away until your scheduled Worry Time',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFFBFDBFE).withValues(alpha: 0.6), // blue-200/60
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 24),

          // Countdown Timer Display Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.glassPanelBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassPanelBorder),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.get('opensIn', locale: _locale).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppColors.accentSoft.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(remainingSeconds),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  worriesCountText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFBFDBFE).withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0x1AFFFFFF)),
                TextButton.icon(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: widget.storage.state.settings.unlockHour,
                        minute: widget.storage.state.settings.unlockMinute,
                      ),
                    );
                    if (time != null) {
                      await widget.storage.setUnlockTime(time.hour, time.minute);
                      // Update existing pending worries to this new time
                      final now = DateTime.now();
                      var unlockDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
                      if (unlockDate.isBefore(now)) {
                        unlockDate = unlockDate.add(const Duration(days: 1));
                      }
                      
                      final pending = widget.storage.getPendingWorries();
                      for (final w in pending) {
                        w.unlockAt = unlockDate.millisecondsSinceEpoch;
                      }
                      // Need to save the changes explicitly
                      // A dirty hack is to just re-save via setUnlockTime
                      await widget.storage.setUnlockTime(time.hour, time.minute);
                      if (mounted) setState(() {});
                    }
                  },
                  icon: const Icon(Icons.edit_calendar, size: 16, color: Color(0xFF93C5FD)),
                  label: const Text(
                    'Change Unlock Time',
                    style: TextStyle(fontSize: 12, color: Color(0xFF93C5FD)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Add
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get('somethingElse', locale: _locale),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFBFDBFE).withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.glassInputBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _quickInputController,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _quickAdd(),
                          decoration: InputDecoration(
                            hintText: 'Quick capture...',
                            hintStyle: TextStyle(color: const Color(0xFFBFDBFE).withValues(alpha: 0.4)),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        backgroundColor: _quickInputController.text.trim().isNotEmpty 
                            ? AppColors.accent.withValues(alpha: 0.5) 
                            : Colors.white.withValues(alpha: 0.05),
                        foregroundColor: _quickInputController.text.trim().isNotEmpty ? const Color(0xFFDBEAFE) : Colors.grey,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _quickInputController.text.trim().isNotEmpty
                                ? AppColors.accent.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.05),
                          )
                        ),
                      ),
                      onPressed: _quickInputController.text.trim().isEmpty ? null : _quickAdd,
                      child: Text(AppStrings.get('quickPutAway', locale: _locale)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

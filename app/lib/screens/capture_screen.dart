import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/worry.dart';
import '../services/storage.dart';
import '../services/audio_service.dart';
import '../services/state.dart';
import '../theme.dart';
import '../widgets/box_animation.dart';

/// CAPTURE view — the home screen of the app.
///
/// New flow:
/// 1. User types worry text
/// 2. Timer picker appears to set lock duration
/// 3. "Put it away" → sealing animation
/// 4. Below the box, worry cards appear showing all locked/unlocked worries
/// 5. Each card has "Mark Important" (flag) and "Remove" buttons
class CaptureScreen extends StatefulWidget {
  final StorageService storage;
  final AudioService audio;
  final String locale;
  final VoidCallback onToggleLocale;
  final VoidCallback onToggleDevMode;

  const CaptureScreen({
    super.key,
    required this.storage,
    required this.audio,
    required this.locale,
    required this.onToggleLocale,
    required this.onToggleDevMode,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _controller = TextEditingController();
  bool _isSealing = false;

  // Timer duration options in seconds
  static const List<_DurationOption> _durationOptions = [
    _DurationOption('1 min', 60),
    _DurationOption('5 min', 300),
    _DurationOption('15 min', 900),
    _DurationOption('30 min', 1800),
    _DurationOption('1 hour', 3600),
    _DurationOption('3 hours', 10800),
    _DurationOption('6 hours', 21600),
    _DurationOption('12 hours', 43200),
  ];
  int _selectedDuration = 300; // default 5 min

  String get _locale => widget.locale;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitWorry() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSealing = true);

    try {
      await widget.storage.addWorryWithDuration(text, _selectedDuration);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      setState(() => _isSealing = false);
      return;
    }
  }

  void _onSealComplete() {
    _controller.clear();
    setState(() => _isSealing = false);
  }

  void _toggleImportant(Worry worry) {
    if (worry.isImportant) {
      widget.storage.unmarkImportant(worry.id);
    } else {
      widget.storage.markImportant(worry.id);
    }
    setState(() {});
  }

  void _removeWorry(String id) {
    widget.storage.removeWorry(id);
    setState(() {});
  }

  String _formatRemainingTime(Worry worry) {
    final remaining = worry.unlockAt - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) return 'Unlocked';
    final duration = Duration(milliseconds: remaining);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m left';
    if (minutes > 0) return '${minutes}m ${seconds}s left';
    return '${seconds}s left';
  }

  @override
  Widget build(BuildContext context) {
    // Get all worries that aren't released
    final worries = widget.storage.getWorries()
        .where((w) => w.status != 'released')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp6,
        vertical: AppSpacing.sp8,
      ),
      child: Column(
        children: [
          // ── Header row: Language toggle ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onToggleLocale,
                child: Text(
                  AppStrings.get('languageToggle', locale: _locale),
                  style: const TextStyle(color: AppColors.accent),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sp4),

          // ── Title (long-press for dev mode) ──
          GestureDetector(
            onLongPress: widget.onToggleDevMode,
            child: Text(
              AppStrings.get('appTitle', locale: _locale),
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.sp2),
          Text(
            AppStrings.get('subtitle', locale: _locale),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.sp6),

          // ── Box illustration ──
          BoxAnimation(
            isOpen: !_isSealing,
            isSealing: _isSealing,
            onSealComplete: _onSealComplete,
          ),

          const SizedBox(height: AppSpacing.sp6),

          // ── Text input ──
          TextField(
            controller: _controller,
            maxLines: 3,
            maxLength: 280,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: AppStrings.get('placeholder', locale: _locale),
              counterText: _controller.text.length > 240
                  ? '${_controller.text.length}/280'
                  : '',
            ),
          ),

          const SizedBox(height: AppSpacing.sp3),

          // ── Timer picker ──
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp4,
              vertical: AppSpacing.sp3,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceStrong,
              borderRadius: BorderRadius.circular(AppShape.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 18, color: AppColors.accent),
                    const SizedBox(width: AppSpacing.sp2),
                    Text(
                      'Lock for:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sp2),
                Wrap(
                  spacing: AppSpacing.sp2,
                  runSpacing: AppSpacing.sp2,
                  children: _durationOptions.map((option) {
                    final isSelected = _selectedDuration == option.seconds;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedDuration = option.seconds),
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color:
                                isSelected ? AppColors.accent : AppColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sp4),

          // ── Action buttons row ──
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _controller.text.trim().isEmpty ? null : _submitWorry,
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: Text(AppStrings.get('submitButton', locale: _locale)),
                ),
              ),
              const SizedBox(width: AppSpacing.sp3),
              IconButton(
                onPressed: () async {
                  await widget.audio.toggle();
                  setState(() {});
                },
                icon: Icon(
                  widget.audio.isPlaying
                      ? Icons.music_off_rounded
                      : Icons.music_note_rounded,
                  color: AppColors.accentSoft,
                ),
                tooltip: widget.audio.isPlaying
                    ? AppStrings.get('stopAudio', locale: _locale)
                    : AppStrings.get('playAudio', locale: _locale),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sp6),

          // ── Worry cards ──
          if (worries.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.inbox_rounded,
                    size: 18, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.sp2),
                Text(
                  'Your worries (${worries.length})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sp3),
            ...worries.map((worry) => _WorryCard(
                  worry: worry,
                  remainingTime: _formatRemainingTime(worry),
                  onToggleImportant: () => _toggleImportant(worry),
                  onRemove: () => _removeWorry(worry.id),
                )),
          ],

          const SizedBox(height: AppSpacing.sp8),

          // ── Safety footer ──
          Text(
            AppStrings.get('safetyLine', locale: _locale),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Timer duration option model
class _DurationOption {
  final String label;
  final int seconds;
  const _DurationOption(this.label, this.seconds);
}

/// Individual worry card with Mark Important and Remove buttons.
class _WorryCard extends StatelessWidget {
  final Worry worry;
  final String remainingTime;
  final VoidCallback onToggleImportant;
  final VoidCallback onRemove;

  const _WorryCard({
    required this.worry,
    required this.remainingTime,
    required this.onToggleImportant,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = remainingTime == 'Unlocked';
    final isImportant = worry.isImportant;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sp3),
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: BoxDecoration(
        color: isImportant
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(AppShape.radius),
        border: Border.all(
          color: isImportant
              ? AppColors.accent.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: status + important badge ──
          Row(
            children: [
              // Lock/unlock icon
              Icon(
                isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                size: 14,
                color: isUnlocked ? AppColors.accentSoft : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                remainingTime,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isUnlocked ? AppColors.accentSoft : AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (isImportant)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_rounded,
                          size: 12, color: AppColors.accent),
                      SizedBox(width: 2),
                      Text(
                        'Important',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp2),

          // ── Worry text (hidden if locked, visible if unlocked) ──
          Text(
            isUnlocked ? worry.text : '••• ${worry.text.length} characters locked •••',
            style: TextStyle(
              fontSize: 15,
              color: isUnlocked ? AppColors.text : AppColors.textMuted,
              fontStyle: isUnlocked ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.sp2),

          // ── Relative time ──
          Text(
            worry.relativeTime,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sp2),

          // ── Action buttons: Mark Important + Remove ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onToggleImportant,
                icon: Icon(
                  isImportant
                      ? Icons.flag_rounded
                      : Icons.flag_outlined,
                  size: 16,
                  color: isImportant ? AppColors.accent : AppColors.textMuted,
                ),
                label: Text(
                  isImportant ? 'Important' : 'Mark Important',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isImportant ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sp2),
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.error),
                label: const Text(
                  'Remove',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

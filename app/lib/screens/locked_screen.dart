import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/worry.dart';
import '../services/storage.dart';
import '../services/audio_service.dart';
import '../theme.dart';
import '../widgets/box_animation.dart';
import '../widgets/particle_burst.dart';
import 'dart:ui'; // for FontFeature

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
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  static const List<_DurationOption> _durationOptions = [
    _DurationOption('1m', 60),
    _DurationOption('5m', 300),
    _DurationOption('15m', 900),
    _DurationOption('1h', 3600),
    _DurationOption('3h', 10800),
    _DurationOption('12h', 43200),
    _DurationOption('1w', 604800),
    _DurationOption('1M', 2592000),
  ];
  int _selectedDuration = 300;

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
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitWorry() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty) return;

    try {
      await widget.storage.addWorryWithDuration(
        title: title,
        description: desc,
        durationSeconds: _selectedDuration,
      );
      _titleController.clear();
      _descController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
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
    
    // Check if we need to return to capture screen
    if (widget.storage.getWorries().where((w) => w.status != 'released').isEmpty) {
      widget.onStateChange();
    }
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
    final worries = widget.storage.getWorries()
        .where((w) => w.status != 'released')
        .toList();

    return SafeArea(
      child: Column(
        children: [
          // ── Insights Header ──
          if (widget.storage.state.totalWorriesCreated > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sp4, AppSpacing.sp4, AppSpacing.sp4, 0),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sp3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceStrong,
                  borderRadius: BorderRadius.circular(AppShape.radius),
                  border: Border.all(color: AppColors.borderHighlight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insights_rounded, color: AppColors.accentSoft, size: 20),
                    const SizedBox(width: AppSpacing.sp3),
                    Expanded(
                      child: Text(
                        '${((widget.storage.state.totalWorriesReleased / widget.storage.state.totalWorriesCreated) * 100).toInt()}% of your worries were let go. You are doing great!',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Worry Cards List ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.sp4),
              itemCount: worries.length,
              itemBuilder: (context, index) {
                final worry = worries[index];
                return _WorryCard(
                  key: ValueKey(worry.id),
                  worry: worry,
                  remainingTime: _formatRemainingTime(worry),
                  onToggleImportant: () => _toggleImportant(worry),
                  onRemove: () => _removeWorry(worry.id),
                  onOpenBox: () {
                    widget.storage.markRevealed(worry.id);
                    setState(() {});
                  },
                  onAddMoreTime: (seconds) {
                    widget.storage.addTimeToWorry(worry.id, seconds);
                    setState(() {});
                  },
                );
              },
            ),
          ),

          // ── Compact Input Form (Anchored to Bottom) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp4, vertical: AppSpacing.sp3),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_circle_outline, size: 16, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.sp2),
                      Text(
                        'Add another problem',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sp2),
                  
                  // Compact Text Fields
                  TextField(
                    controller: _titleController,
                    maxLength: 100,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'Title...',
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp2),
                  TextField(
                    controller: _descController,
                    maxLines: 2,
                    maxLength: 500,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Description...',
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp3),
                  
                  // Compact Timer & Submit Row
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _durationOptions.map((option) {
                              final isSelected = _selectedDuration == option.seconds;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedDuration = option.seconds),
                                child: AnimatedContainer(
                                  duration: AppDurations.fast,
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected ? AppColors.accent : AppColors.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    option.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? AppColors.accent : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sp2),
                      ElevatedButton(
                        onPressed: _titleController.text.trim().isEmpty ? null : _submitWorry,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Add', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationOption {
  final String label;
  final int seconds;
  const _DurationOption(this.label, this.seconds);
}

class _WorryCard extends StatefulWidget {
  final Worry worry;
  final String remainingTime;
  final VoidCallback onToggleImportant;
  final VoidCallback onRemove;
  final VoidCallback onOpenBox;
  final Function(int) onAddMoreTime;

  const _WorryCard({
    super.key,
    required this.worry,
    required this.remainingTime,
    required this.onToggleImportant,
    required this.onRemove,
    required this.onOpenBox,
    required this.onAddMoreTime,
  });

  @override
  State<_WorryCard> createState() => _WorryCardState();
}

class _WorryCardState extends State<_WorryCard> {
  bool _isExpanded = false;
  bool _isBursting = false;

  void _showAddTimeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bg0,
          title: const Text('Add more time', style: TextStyle(color: AppColors.text, fontSize: 16)),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DurationOption('15m', 900),
              _DurationOption('1h', 3600),
              _DurationOption('3h', 10800),
              _DurationOption('12h', 43200),
              _DurationOption('1w', 604800),
              _DurationOption('1M', 2592000),
            ].map((opt) => ActionChip(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
              label: Text(opt.label, style: const TextStyle(color: AppColors.text)),
              onPressed: () {
                Navigator.pop(context);
                widget.onAddMoreTime(opt.seconds);
              },
            )).toList(),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // A worry is 'Ready to Open' when timer ends but it hasn't been opened yet.
    final isTimerEnded = widget.remainingTime == 'Unlocked';
    final isUnlocked = widget.worry.status == 'revealed' || widget.worry.status == 'kept';
    final isImportant = widget.worry.isImportant;

    if (!isUnlocked && _isExpanded) {
      _isExpanded = false;
    }

    if (!isUnlocked) {
      // ── Locked Bin State ──
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sp3),
        padding: const EdgeInsets.all(AppSpacing.sp3),
        decoration: BoxDecoration(
          color: AppColors.surfaceStrong,
          borderRadius: BorderRadius.circular(AppShape.radius),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.bg1,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 24),
                  ),
                ),
                const SizedBox(width: AppSpacing.sp3),
                const Text(
                  'Locked in bin',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (isTimerEnded)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () => _showAddTimeDialog(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Keep Locked', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: AppSpacing.sp2),
                  ElevatedButton.icon(
                    onPressed: widget.onOpenBox,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.bg0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Open Bin', style: TextStyle(fontSize: 12)),
                  ),
                ],
              )
            else
              Text(
                widget.remainingTime,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      );
    }

    // ── Unlocked Card State ──
    return ParticleBurst(
      isBursting: _isBursting,
      onComplete: widget.onRemove,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sp3),
        padding: const EdgeInsets.all(AppSpacing.sp3),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 3D Claymorphic Box ──
              SizedBox(
                width: 60,
                height: 60,
                child: BoxAnimationWidget(
                  size: 60,
                  boxState: isUnlocked ? BoxState.open : BoxState.closed,
                ),
              ),
              const SizedBox(width: AppSpacing.sp3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sp1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.worry.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      if (isImportant) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag_rounded,
                                  size: 10, color: AppColors.accent),
                              SizedBox(width: 4),
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
                    ],
                  ),
                ),
              ),
              if (!isTimerEnded)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sp1),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.remainingTime,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                )
              else if (isUnlocked)
                IconButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(
                    _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: AppColors.accent,
                  ),
                  tooltip: _isExpanded ? 'Hide description' : 'Show description',
                ),
            ],
          ),


          AnimatedSize(
            duration: AppDurations.base,
            curve: Curves.easeInOut,
            child: _isExpanded && widget.worry.text.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sp3,
                      left: AppSpacing.sp1,
                      right: AppSpacing.sp1,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sp3),
                      decoration: BoxDecoration(
                        color: AppColors.bg0.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppShape.radiusSm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.worry.text,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.text,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sp3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.worry.relativeTime,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textMuted),
                              ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: widget.onToggleImportant,
                                    icon: Icon(
                                      isImportant ? Icons.flag_rounded : Icons.flag_outlined,
                                      size: 16,
                                      color: isImportant
                                          ? AppColors.accent
                                          : AppColors.textMuted,
                                    ),
                                    label: Text(
                                      isImportant ? 'Important' : 'Mark',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isImportant
                                            ? AppColors.accent
                                            : AppColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sp1),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() => _isBursting = true);
                                    },
                                    icon: const Icon(Icons.close_rounded,
                                        size: 16, color: AppColors.error),
                                    label: const Text(
                                      'Let go',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    ));
  }
}

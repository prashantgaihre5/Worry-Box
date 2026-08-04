import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../l10n/app_strings.dart';
import '../services/storage.dart';
import '../services/audio_service.dart';
import '../theme.dart';

class CaptureScreen extends StatefulWidget {
  final StorageService storage;
  final AudioService audio;
  final String locale;
  final Function(String) onWorryAdded;
  final VoidCallback onToggleLocale;
  final VoidCallback onToggleDevMode;

  const CaptureScreen({
    super.key,
    required this.storage,
    required this.audio,
    required this.locale,
    required this.onWorryAdded,
    required this.onToggleLocale,
    required this.onToggleDevMode,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  static const List<_DurationOption> _durationOptions = [
    _DurationOption('1 min', 60),
    _DurationOption('5 min', 300),
    _DurationOption('15 min', 900),
    _DurationOption('30 min', 1800),
    _DurationOption('1 hour', 3600),
    _DurationOption('3 hours', 10800),
    _DurationOption('6 hours', 21600),
    _DurationOption('12 hours', 43200),
    _DurationOption('1 week', 604800),
    _DurationOption('1 month', 2592000),
  ];
  int _selectedDuration = 300;

  String get _locale => widget.locale;

  @override
  void dispose() {
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
      
      // Navigate to Locked Screen
      widget.onWorryAdded(title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp6,
        vertical: AppSpacing.sp8,
      ),
      child: Column(
        children: [
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

          const SizedBox(height: AppSpacing.sp8),

          TextField(
            controller: _titleController,
            maxLength: 100,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Give it a title (e.g. Work Stress)',
              counterText: '',
            ),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sp3),
          TextField(
            controller: _descController,
            maxLines: 3,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: AppStrings.get('placeholder', locale: _locale),
              counterText: _descController.text.length > 450
                  ? '${_descController.text.length}/500'
                  : '',
            ),
          ),

          const SizedBox(height: AppSpacing.sp4),

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
                const SizedBox(height: AppSpacing.sp3),
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
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent.withValues(alpha: 0.25)
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
                                isSelected ? AppColors.accent : AppColors.text,
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

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _titleController.text.trim().isEmpty ? null : _submitWorry,
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

          const SizedBox(height: AppSpacing.sp8),

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

class _DurationOption {
  final String label;
  final int seconds;
  const _DurationOption(this.label, this.seconds);
}

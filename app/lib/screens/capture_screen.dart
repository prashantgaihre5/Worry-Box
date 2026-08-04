import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/storage.dart';
import '../services/audio_service.dart';
import '../widgets/stress_graph.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/box_animation.dart';

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

class _CaptureScreenState extends State<CaptureScreen> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  late AnimationController _dropController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  void initState() {
    super.initState();
    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.05).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.easeInBack),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.easeIn),
    );
    // Slide up into the box which is above the input
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.2)).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.easeInBack),
    );
  }

  @override
  void dispose() {
    _dropController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitWorry() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty && desc.isEmpty) return;
    
    // Start the drop animation
    await _dropController.forward();

    try {
      await widget.storage.addWorryWithDuration(
        title: title,
        description: desc,
        durationSeconds: _selectedDuration,
      );
      
      _titleController.clear();
      _descController.clear();
      FocusScope.of(context).unfocus();
      
      // Reset animation for next time
      _dropController.reset();
      
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

  void _addExample(String text) {
    if (_titleController.text.isEmpty) {
      _titleController.text = text;
    } else {
      _titleController.text += ' $text';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp6,
        vertical: AppSpacing.sp6,
      ),
      child: Column(
        children: [

          const SizedBox(height: AppSpacing.sp2),
          Text(
            AppStrings.get('subtitle', locale: _locale),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sp6),

          // ── Big 3D Box ──
          SizedBox(
            width: 160,
            height: 160,
            child: BoxAnimationWidget(
              boxState: BoxState.open,
              size: 160,
            ),
          ),

          const SizedBox(height: AppSpacing.sp6),

          // Inputs with Drop Animation
          AnimatedBuilder(
            animation: _dropController,
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: child,
                  ),
                ),
              );
            },
            child: GlassInputCard(
              isFocused: false, // Could be bound to a FocusNode
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    maxLength: 100,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Give it a title (e.g. Work Stress)',
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  Divider(height: 1, color: AppColors.border),
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    maxLength: 500,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: "What's on your mind? Describe what's troubling you...",
                      counterText: _descController.text.length > 450
                          ? '${_descController.text.length}/500'
                          : '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sp4),

          // Duration Selector
          GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp4,
              vertical: AppSpacing.sp3,
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.bg1,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppShape.radiusSm),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onPressed:
                      (_titleController.text.trim().isEmpty && _descController.text.trim().isEmpty) ? null : _submitWorry,
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

  Widget _buildPill(String text) {
    return GestureDetector(
      onTap: () => _addExample(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x12FFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}
class _DurationOption {
  final String label;
  final int seconds;
  const _DurationOption(this.label, this.seconds);
}

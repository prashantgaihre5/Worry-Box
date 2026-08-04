import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/storage.dart';
import '../services/audio_service.dart';
import '../theme.dart';
import '../widgets/box_animation.dart';

/// CAPTURE view — the default state when no worries are pending.
///
/// Contains:
/// - Title & subtitle
/// - Box illustration (lid open)
/// - TextField for worry input
/// - "Put it away" button
/// - "Play Calming Audio" toggle
/// - Language toggle in header
/// - Safety footer
class CaptureScreen extends StatefulWidget {
  final StorageService storage;
  final AudioService audio;
  final String locale;
  final VoidCallback onWorryAdded;
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
  final _controller = TextEditingController();
  bool _isSealing = false;

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
      await widget.storage.addWorry(text);
      _controller.clear();
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
    setState(() => _isSealing = false);
    widget.onWorryAdded();
  }

  @override
  Widget build(BuildContext context) {
    final unlockHour = widget.storage.state.settings.unlockHour;
    final unlockMinute = widget.storage.state.settings.unlockMinute;
    final timeStr =
        '${unlockHour > 12 ? unlockHour - 12 : unlockHour}:${unlockMinute.toString().padLeft(2, '0')} ${unlockHour >= 12 ? 'PM' : 'AM'}';

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

          const SizedBox(height: AppSpacing.sp6),

          // ── Title (long-press to toggle dev mode) ──
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

          // ── Box illustration ──
          BoxAnimation(
            isOpen: !_isSealing,
            isSealing: _isSealing,
            onSealComplete: _onSealComplete,
          ),

          const SizedBox(height: AppSpacing.sp8),

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

          const SizedBox(height: AppSpacing.sp4),

          // ── Action buttons row ──
          Row(
            children: [
              // Put it away
              Expanded(
                child: ElevatedButton(
                  onPressed: _controller.text.trim().isEmpty ? null : _submitWorry,
                  child: Text(AppStrings.get('submitButton', locale: _locale)),
                ),
              ),
              const SizedBox(width: AppSpacing.sp3),
              // Play calming audio
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

          const SizedBox(height: AppSpacing.sp3),

          // ── Helper line ──
          Text(
            AppStrings.format('captureHelper', {'time': timeStr}, locale: _locale),
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: AppSpacing.sp12),

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

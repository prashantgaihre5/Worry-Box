import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../l10n/consolation_messages.dart';
import '../services/audio_service.dart';
import '../services/storage.dart';
import '../services/state.dart';
import '../theme.dart';
import '../widgets/box_animation.dart';

/// LOCKED view — shown when pending worries exist and the unlock time hasn't arrived.
///
/// Contains:
/// - Box illustration (lid closed, padlock)
/// - "Your thoughts are safe." headline
/// - Live countdown
/// - Worry count
/// - Consolation message (fades after a few seconds)
/// - Compact secondary input to add more worries
class LockedScreen extends StatefulWidget {
  final StorageService storage;
  final AudioService audio;
  final String locale;
  final VoidCallback onStateChange;
  final String? lastWorryText;

  const LockedScreen({
    super.key,
    required this.storage,
    required this.audio,
    required this.locale,
    required this.onStateChange,
    this.lastWorryText,
  });

  @override
  State<LockedScreen> createState() => _LockedScreenState();
}

class _LockedScreenState extends State<LockedScreen> with WidgetsBindingObserver {
  Timer? _ticker;
  String _countdown = '';
  final _controller = TextEditingController();
  double _consolationOpacity = 0.0;
  String _consolationText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTicker();
    _updateCountdown();

    if (widget.lastWorryText != null) {
      _consolationText = ConsolationMessages.getForWorry(widget.lastWorryText!, locale: widget.locale);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _consolationOpacity = 1.0);
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _consolationOpacity = 0.0);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateCountdown();
      // Re-derive view state in case unlock time passed while backgrounded
      final newState = deriveViewState(widget.storage);
      if (newState != ViewState.locked) {
        widget.onStateChange();
      }
    }
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
      // Check if we should transition to REVEAL
      final newState = deriveViewState(widget.storage);
      if (newState != ViewState.locked) {
        _ticker?.cancel();
        widget.onStateChange();
      }
    });
  }

  void _updateCountdown() {
    final nextUnlock = widget.storage.nextUnlockAt();
    if (nextUnlock == null) {
      setState(() => _countdown = '');
      return;
    }
    setState(() => _countdown = formatCountdown(nextUnlock));
  }

  Future<void> _addMoreWorry() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      await widget.storage.addWorry(text);
      _controller.clear();
      setState(() {
        _consolationText = ConsolationMessages.getForWorry(text, locale: widget.locale);
        _consolationOpacity = 1.0;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _consolationOpacity = 0.0);
      });
      _updateCountdown();
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
    final pendingCount = widget.storage.getPendingWorries().length;
    final locale = widget.locale;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp6,
        vertical: AppSpacing.sp8,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sp12),

          // ── Box (closed) ──
          const BoxAnimation(isOpen: false),

          const SizedBox(height: AppSpacing.sp8),

          // ── Headline ──
          Text(
            AppStrings.get('lockedHeadline', locale: locale),
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.sp4),

          // ── Countdown ──
          if (_countdown.isNotEmpty)
            Text(
              AppStrings.format('lockedCountdown', {'time': _countdown}, locale: locale),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.accent,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: AppSpacing.sp3),

          // ── Worry count ──
          Text(
            pendingCount == 1
                ? AppStrings.get('lockedCountSingular', locale: locale)
                : AppStrings.format(
                    'lockedCount', {'count': '$pendingCount'},
                    locale: locale),
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: AppSpacing.sp6),

          // ── Consolation message ──
          AnimatedOpacity(
            opacity: _consolationOpacity,
            duration: AppDurations.base,
            child: _consolationText.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp4,
                      vertical: AppSpacing.sp3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppShape.radiusSm),
                    ),
                    child: Text(
                      _consolationText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.accentSoft,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.sp8),

          // ── Secondary input ──
          Text(
            AppStrings.get('lockedSubInput', locale: locale),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sp2),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLength: 280,
                  decoration: InputDecoration(
                    hintText: AppStrings.get('placeholder', locale: locale),
                    counterText: '',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addMoreWorry(),
                ),
              ),
              const SizedBox(width: AppSpacing.sp2),
              IconButton(
                onPressed: _addMoreWorry,
                icon: const Icon(Icons.send_rounded, color: AppColors.accent),
              ),
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
                    ? AppStrings.get('stopAudio', locale: locale)
                    : AppStrings.get('playAudio', locale: locale),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

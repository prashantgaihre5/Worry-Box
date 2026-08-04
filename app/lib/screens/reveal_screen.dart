import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/worry.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

/// REVEAL view — shown when one or more worries have passed their unlock time.
///
/// Contains:
/// - "The box is open." headline
/// - List of unlocked worry cards with "Let go" and "Keep" buttons
/// - Animations on release (fade + translate up)
/// - "All clear" state when list empties
class RevealScreen extends StatefulWidget {
  final StorageService storage;
  final String locale;
  final VoidCallback onAllCleared;

  const RevealScreen({
    super.key,
    required this.storage,
    required this.locale,
    required this.onAllCleared,
  });

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen> {
  List<Worry> _worries = [];

  @override
  void initState() {
    super.initState();
    _loadWorries();
  }

  void _loadWorries() {
    final unlocked = widget.storage.getUnlockedWorries();
    // Mark all as revealed
    for (final w in unlocked) {
      if (w.status == 'locked') {
        widget.storage.markRevealed(w.id);
      }
    }
    setState(() => _worries = widget.storage.getUnlockedWorries());
  }

  Future<void> _release(String id) async {
    await widget.storage.releaseWorry(id);
    setState(() => _worries.removeWhere((w) => w.id == id));
    if (_worries.isEmpty) widget.onAllCleared();
  }

  Future<void> _keep(String id) async {
    await widget.storage.keepWorry(id);
    setState(() => _worries.removeWhere((w) => w.id == id));
    if (_worries.isEmpty) widget.onAllCleared();
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.locale;

    if (_worries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 64, color: AppColors.accentSoft),
            const SizedBox(height: AppSpacing.sp4),
            Text(
              AppStrings.get('emptyReveal', locale: locale),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sp6),
            ElevatedButton(
              onPressed: widget.onAllCleared,
              child: Text(AppStrings.get('newWorryButton', locale: locale)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: AppSpacing.sp8),

        // ── Headline ──
        Text(
          AppStrings.get('revealHeadline', locale: locale),
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sp2),
        Text(
          AppStrings.get('revealSub', locale: locale),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.sp6),

        // ── Worry list ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp6),
            itemCount: _worries.length,
            itemBuilder: (context, index) {
              final worry = _worries[index];
              return _WorryCard(
                worry: worry,
                locale: locale,
                onRelease: () => _release(worry.id),
                onKeep: () => _keep(worry.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual worry card in the reveal list.
class _WorryCard extends StatefulWidget {
  final Worry worry;
  final String locale;
  final VoidCallback onRelease;
  final VoidCallback onKeep;

  const _WorryCard({
    required this.worry,
    required this.locale,
    required this.onRelease,
    required this.onKeep,
  });

  @override
  State<_WorryCard> createState() => _WorryCardState();
}

class _WorryCardState extends State<_WorryCard>
    with SingleTickerProviderStateMixin {
  double _opacity = 1.0;
  double _translateY = 0.0;

  void _animateRelease() {
    setState(() {
      _opacity = 0.0;
      _translateY = -24.0;
    });
    Future.delayed(AppDurations.base, widget.onRelease);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.base,
      curve: AppCurves.easeOut,
      transform: Matrix4.translationValues(0, _translateY, 0),
      child: AnimatedOpacity(
        duration: AppDurations.base,
        opacity: _opacity,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sp4),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.sp4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // ── Worry text ──
              Text(
                widget.worry.text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.sp2),

              // ── Relative time ──
              Text(
                widget.worry.relativeTime,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: AppSpacing.sp3),

              // ── Action buttons ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onKeep,
                    child: Text(
                      AppStrings.get('keepButton', locale: widget.locale),
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp2),
                  ElevatedButton(
                    onPressed: _animateRelease,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentSoft,
                    ),
                    child: Text(
                      AppStrings.get('releaseButton', locale: widget.locale),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/worry.dart';
import '../services/storage.dart';
import '../theme.dart';

/// REVEAL view — shown when one or more worries have passed their unlock time.
///
/// Contains:
/// - "The box is open." headline
/// - AnimatedList of unlocked worry cards with "Let go" and "Keep" buttons
/// - SizeTransition + FadeTransition removal animations (per SPEC.md §7)
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
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<Worry> _worries;

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
    _worries = widget.storage.getUnlockedWorries();
  }

  Future<void> _release(int index) async {
    if (index < 0 || index >= _worries.length) return;
    final worry = _worries[index];
    await widget.storage.releaseWorry(worry.id);
    _removeItemAnimated(index, worry);
  }

  Future<void> _keep(int index) async {
    if (index < 0 || index >= _worries.length) return;
    final worry = _worries[index];
    await widget.storage.keepWorry(worry.id);
    _removeItemAnimated(index, worry);
  }

  void _removeItemAnimated(int index, Worry worry) {
    _worries.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildAnimatedCard(worry, animation),
      duration: AppDurations.base,
    );

    if (_worries.isEmpty) {
      // Delay so the last card's exit animation completes before transitioning
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {}); // trigger empty state rebuild
          widget.onAllCleared();
        }
      });
    } else {
      setState(() {});
    }
  }

  /// Builds a card wrapped in SizeTransition + FadeTransition for AnimatedList.
  Widget _buildAnimatedCard(Worry worry, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animation,
        curve: AppCurves.easeOut,
      ),
      child: FadeTransition(
        opacity: animation,
        child: _buildCard(worry, -1), // index -1 = non-interactive during removal
      ),
    );
  }

  Widget _buildCard(Worry worry, int index) {
    final locale = widget.locale;
    final isInteractive = index >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sp4),
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(AppShape.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Worry text ──
          Text(
            worry.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.sp2),

          // ── Relative time ──
          Text(
            worry.relativeTime,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sp3),

          // ── Action buttons ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: isInteractive ? () => _keep(index) : null,
                child: Text(
                  AppStrings.get('keepButton', locale: locale),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: AppSpacing.sp2),
              ElevatedButton(
                onPressed: isInteractive ? () => _release(index) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentSoft,
                ),
                child: Text(
                  AppStrings.get('releaseButton', locale: locale),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

        // ── Worry list (AnimatedList for proper removal animations) ──
        Expanded(
          child: AnimatedList(
            key: _listKey,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp6),
            initialItemCount: _worries.length,
            itemBuilder: (context, index, animation) {
              return _buildAnimatedCard(_worries[index], animation);
            },
          ),
        ),
      ],
    );
  }
}

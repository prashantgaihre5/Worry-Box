import '../services/storage.dart';

/// The three possible views in the app.
/// Exactly one is visible at a time.
///
/// Derivation order (from SPEC.md §6):
/// 1. If unlocked worries exist → REVEAL
/// 2. If pending worries exist  → LOCKED
/// 3. Otherwise                 → CAPTURE
enum ViewState { capture, locked, reveal }

/// Derives the current view state from the storage service.
///
/// This function should be called:
/// - On app start / resume from background
/// - After every worry submission
/// - On every countdown tick (1s interval while LOCKED)
///
/// State is always derived from the clock — never stored as a boolean.
ViewState deriveViewState(StorageService storage) {
  if (storage.getUnlockedWorries().isNotEmpty) return ViewState.reveal;
  if (storage.getPendingWorries().isNotEmpty) return ViewState.locked;
  return ViewState.capture;
}

/// Formats a remaining-time duration into a human-readable countdown.
///
/// - Over 1 minute: "4h 12m"
/// - Under 1 minute: "0:42" (mm:ss)
String formatCountdown(int unlockAtMs) {
  final remaining = unlockAtMs - DateTime.now().millisecondsSinceEpoch;
  if (remaining <= 0) return 'Now';

  final duration = Duration(milliseconds: remaining);
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  } else {
    return '0:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Returns the count label with correct singular/plural.
String worryCountLabel(int count) {
  if (count == 1) return '1 worry put away';
  return '$count worries put away';
}

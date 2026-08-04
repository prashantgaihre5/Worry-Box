import 'dart:async';
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
  final activeWorries = storage.getWorries().where((w) => w.status != 'released').toList();
  if (activeWorries.isEmpty) return ViewState.capture;

  final hasRevealed = activeWorries.any((w) => w.status == 'revealed');
  if (hasRevealed) return ViewState.reveal;

  return ViewState.locked;
}

/// Formats a remaining-time duration into a human-readable countdown.
///
/// - Over 1 hour:   "4h 12m"
/// - Over 1 minute: "12m 34s"
/// - Under 1 minute: "0:42" (mm:ss)
String formatCountdown(int unlockAtMs, {String locale = 'en'}) {
  final remaining = unlockAtMs - DateTime.now().millisecondsSinceEpoch;
  if (remaining <= 0) return locale == 'ne' ? 'अहिले' : 'Now';

  final duration = Duration(milliseconds: remaining);
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;

  if (locale == 'ne') {
    if (hours > 0) {
      return '${_toNepaliNum(hours)} घण्टा ${_toNepaliNum(minutes)} मिनेट';
    } else if (minutes > 0) {
      return '${_toNepaliNum(minutes)} मिनेट ${_toNepaliNum(seconds)} सेकेन्ड';
    } else {
      return '${_toNepaliNum(0)}:${_toNepaliNum(seconds).padLeft(2, '०')}';
    }
  }

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  } else {
    return '0:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Returns the count label with correct singular/plural.
String worryCountLabel(int count, {String locale = 'en'}) {
  if (locale == 'ne') {
    if (count == 1) return '${_toNepaliNum(1)} चिन्ता राखिएको छ';
    return '${_toNepaliNum(count)} चिन्ताहरू राखिएका छन्';
  }
  if (count == 1) return '1 worry put away';
  return '$count worries put away';
}

/// Formats the unlock time into a display string like "6:00 PM".
String formatUnlockTime(int hour, int minute, {String locale = 'en'}) {
  if (locale == 'ne') {
    final period = hour >= 12 ? 'बेलुका' : 'बिहान';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${_toNepaliNum(displayHour)}:${_toNepaliNum(minute).padLeft(2, '०')} $period';
  }
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}

/// Converts an integer to Nepali numerals.
String _toNepaliNum(int n) {
  const nepaliDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
  return n.toString().split('').map((d) => nepaliDigits[int.parse(d)]).join();
}

/// Manages the 1-second countdown ticker.
///
/// Starts a periodic timer that calls [onTick] every second.
/// Call [dispose] to clean up.
class CountdownTicker {
  Timer? _timer;
  final VoidCallback onTick;

  CountdownTicker({required this.onTick});

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => onTick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
  }
}

typedef VoidCallback = void Function();

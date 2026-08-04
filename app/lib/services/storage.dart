import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';
import '../models/worry.dart';

/// The ONLY module that touches SharedPreferences.
///
/// Implements the Storage API from SPEC.md §5.
/// All other code accesses persistence through this service.
class StorageService {
  static const String _key = 'worryBox_v1';
  static const String _corruptPrefix = 'worryBox_v1_corrupt_';

  SharedPreferences? _prefs;
  AppState _state = AppState.defaults();

  /// Whether SharedPreferences is available.
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// The current in-memory state.
  AppState get state => _state;

  /// Initialize SharedPreferences. Must be called once at app start.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isAvailable = true;
      _state = loadState();
    } catch (_) {
      // SharedPreferences unavailable — app runs in memory only.
      _isAvailable = false;
      _state = AppState.defaults();
    }
  }

  /// Always returns a valid AppState. Never throws.
  /// Handles corruption per SPEC.md §4.
  AppState loadState() {
    if (!_isAvailable || _prefs == null) return AppState.defaults();

    try {
      final raw = _prefs!.getString(_key);
      if (raw == null) return AppState.defaults();

      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        // Corrupt — back it up and return fresh state.
        _backupCorrupt(raw);
        return AppState.defaults();
      }

      final parsed = AppState.fromJson(json);

      // If fromJson returned defaults due to schema mismatch, back up the raw.
      if (json.containsKey('schemaVersion') &&
          json['schemaVersion'] != AppState.currentSchemaVersion) {
        _backupCorrupt(raw);
      }

      return parsed;
    } catch (_) {
      // Unparseable — back up and return defaults.
      final raw = _prefs!.getString(_key);
      if (raw != null) _backupCorrupt(raw);
      return AppState.defaults();
    }
  }

  /// Persists the current state. Returns false on failure.
  Future<bool> saveState([AppState? newState]) async {
    if (newState != null) _state = newState;
    if (!_isAvailable || _prefs == null) return false;

    try {
      final json = jsonEncode(_state.toJson());
      return await _prefs!.setString(_key, json);
    } catch (_) {
      return false;
    }
  }

  // ────────────────────────────────
  // Worry CRUD
  // ────────────────────────────────

  /// Creates, persists, and returns a new Worry.
  /// Throws ArgumentError on invalid input.
  Future<Worry> addWorry(String text, {int? devUnlockSeconds}) async {
    final Worry worry;

    if (devUnlockSeconds != null) {
      worry = Worry.createDev(text: text, unlockSeconds: devUnlockSeconds);
    } else {
      worry = Worry.create(
        text: text,
        unlockHour: _state.settings.unlockHour,
        unlockMinute: _state.settings.unlockMinute,
      );
    }

    _state.worries.insert(0, worry); // newest first
    await saveState();
    return worry;
  }

  /// All worries, newest first.
  List<Worry> getWorries() => List.unmodifiable(_state.worries);

  /// Worries that are still locked and not yet unlockable.
  List<Worry> getPendingWorries() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _state.worries
        .where((w) => w.status == 'locked' && now < w.unlockAt)
        .toList();
  }

  /// Worries that are unlockable (time has passed) or already revealed.
  List<Worry> getUnlockedWorries() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _state.worries
        .where((w) =>
            (w.status == 'locked' && now >= w.unlockAt) ||
            w.status == 'revealed')
        .toList();
  }

  /// Worries that have been kept/archived.
  List<Worry> getKeptWorries() {
    return _state.worries.where((w) => w.status == 'kept').toList();
  }

  /// Earliest unlockAt among pending worries, or null.
  int? nextUnlockAt() {
    final pending = getPendingWorries();
    if (pending.isEmpty) return null;
    return pending
        .map((w) => w.unlockAt)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Deletes the worry from the list entirely.
  Future<void> releaseWorry(String id) async {
    _state.worries.removeWhere((w) => w.id == id);
    await saveState();
  }

  /// Archives the worry (status → "kept").
  Future<void> keepWorry(String id) async {
    final worry = _state.worries.firstWhere(
      (w) => w.id == id,
      orElse: () => throw ArgumentError('Worry not found: $id'),
    );
    worry.status = 'kept';
    await saveState();
  }

  /// Marks a worry as revealed.
  Future<void> markRevealed(String id) async {
    final worry = _state.worries.firstWhere(
      (w) => w.id == id,
      orElse: () => throw ArgumentError('Worry not found: $id'),
    );
    worry.status = 'revealed';
    await saveState();
  }

  /// Updates the unlock time for FUTURE worries only.
  Future<void> setUnlockTime(int hour, int minute) async {
    if (hour < 0 || hour > 23) throw RangeError.range(hour, 0, 23, 'hour');
    if (minute < 0 || minute > 59) throw RangeError.range(minute, 0, 59, 'minute');

    _state = AppState(
      schemaVersion: _state.schemaVersion,
      settings: _state.settings.copyWith(unlockHour: hour, unlockMinute: minute),
      worries: _state.worries,
    );
    await saveState();
  }

  /// Updates the locale preference.
  Future<void> setLocale(String locale) async {
    _state = AppState(
      schemaVersion: _state.schemaVersion,
      settings: _state.settings.copyWith(locale: locale),
      worries: _state.worries,
    );
    await saveState();
  }

  /// Returns pretty-printed JSON of the full state, for manual backup.
  String exportJSON() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(_state.toJson());
  }

  // ────────────────────────────────
  // Internal helpers
  // ────────────────────────────────

  /// Backs up corrupt data under a timestamped key.
  void _backupCorrupt(String rawValue) {
    if (_prefs == null) return;
    final backupKey = '$_corruptPrefix${DateTime.now().millisecondsSinceEpoch}';
    _prefs!.setString(backupKey, rawValue);
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';
import '../models/worry.dart';

/// The ONLY module that touches SharedPreferences.
///
/// Extends ChangeNotifier so screens can listen for state changes
/// and automatically rebuild when worries are added/removed.
///
/// Implements the Storage API from SPEC.md §5.
class StorageService extends ChangeNotifier {
  static const String _key = 'worryBox_v1';
  static const String _corruptPrefix = 'worryBox_v1_corrupt_';

  SharedPreferences? _prefs;
  AppState _state = AppState.defaults();

  /// Whether SharedPreferences is available.
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// Dev mode: override unlock duration in seconds.
  int? _devUnlockSeconds;
  bool get isDevMode => _devUnlockSeconds != null;

  /// The current in-memory state.
  AppState get state => _state;

  /// Initialize SharedPreferences. Must be called once at app start.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isAvailable = true;
      _state = _loadState();
    } catch (_) {
      _isAvailable = false;
      _state = AppState.defaults();
    }
  }

  /// Enable dev mode with a short unlock time for testing.
  void enableDevMode(int seconds) {
    _devUnlockSeconds = seconds;
    notifyListeners();
  }

  /// Disable dev mode.
  void disableDevMode() {
    _devUnlockSeconds = null;
    notifyListeners();
  }

  // ────────────────────────────────
  // State persistence
  // ────────────────────────────────

  /// Always returns a valid AppState. Never throws.
  /// Handles corruption per SPEC.md §4.
  AppState _loadState() {
    if (!_isAvailable || _prefs == null) return AppState.defaults();

    try {
      final raw = _prefs!.getString(_key);
      if (raw == null) return AppState.defaults();

      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        _backupCorrupt(raw);
        return AppState.defaults();
      }

      final parsed = AppState.fromJson(json);

      if (json.containsKey('schemaVersion') &&
          json['schemaVersion'] != AppState.currentSchemaVersion) {
        _backupCorrupt(raw);
      }

      return parsed;
    } catch (_) {
      final raw = _prefs!.getString(_key);
      if (raw != null) _backupCorrupt(raw);
      return AppState.defaults();
    }
  }

  /// Persists the current state. Returns false on failure.
  Future<bool> _saveState() async {
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
  Future<Worry> addWorry(String text) async {
    final Worry worry;

    if (_devUnlockSeconds != null) {
      worry = Worry.createDev(text: text, unlockSeconds: _devUnlockSeconds!);
    } else {
      worry = Worry.create(
        text: text,
        unlockHour: _state.settings.unlockHour,
        unlockMinute: _state.settings.unlockMinute,
      );
    }

    _state.worries.insert(0, worry);
    _state = AppState(
      schemaVersion: _state.schemaVersion,
      settings: _state.settings,
      worries: _state.worries,
      totalWorriesCreated: _state.totalWorriesCreated + 1,
      totalWorriesReleased: _state.totalWorriesReleased,
      totalWorriesMarkedImportant: _state.totalWorriesMarkedImportant,
    );
    await _saveState();
    notifyListeners();
    return worry;
  }

  /// Creates a Worry using Worry.createWithDuration, inserts at position 0, saves, notifies, returns the worry.
  Future<Worry> addWorryWithDuration({
    required String title,
    required String description,
    required int durationSeconds,
  }) async {
    final worry = Worry.createWithDuration(
      title: title,
      description: description,
      durationSeconds: durationSeconds,
    );
    _state.worries.insert(0, worry);
    _state = AppState(
      schemaVersion: _state.schemaVersion,
      settings: _state.settings,
      worries: _state.worries,
      totalWorriesCreated: _state.totalWorriesCreated + 1,
      totalWorriesReleased: _state.totalWorriesReleased,
      totalWorriesMarkedImportant: _state.totalWorriesMarkedImportant,
    );
    await _saveState();
    notifyListeners();
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
    return pending.map((w) => w.unlockAt).reduce((a, b) => a < b ? a : b);
  }

  /// Deletes the worry from the list entirely. (semantically named)
  Future<void> removeWorry(String id) async {
    _state.worries.removeWhere((w) => w.id == id);
    await _saveState();
    notifyListeners();
  }

  /// Deletes the worry from the list entirely and increments released counter.
  Future<void> releaseWorry(String id) async {
    final initialCount = _state.worries.length;
    _state.worries.removeWhere((w) => w.id == id);
    if (_state.worries.length < initialCount) {
      _state = AppState(
        schemaVersion: _state.schemaVersion,
        settings: _state.settings,
        worries: _state.worries,
        totalWorriesCreated: _state.totalWorriesCreated,
        totalWorriesReleased: _state.totalWorriesReleased + 1,
        totalWorriesMarkedImportant: _state.totalWorriesMarkedImportant,
      );
      await _saveState();
      notifyListeners();
    }
  }

  /// Archives the worry (status → "kept").
  Future<void> keepWorry(String id) async {
    final idx = _state.worries.indexWhere((w) => w.id == id);
    if (idx == -1) return;
    _state.worries[idx].status = 'kept';
    await _saveState();
    notifyListeners();
  }

  /// Marks a worry as revealed.
  Future<void> markRevealed(String id) async {
    final idx = _state.worries.indexWhere((w) => w.id == id);
    if (idx == -1) return;
    _state.worries[idx].status = 'revealed';
    await _saveState();
    notifyListeners();
  }

  /// Finds worry by id, sets isImportant = true, saves state, notifies listeners.
  Future<void> markImportant(String id) async {
    final idx = _state.worries.indexWhere((w) => w.id == id);
    if (idx == -1) return;
    if (!_state.worries[idx].isImportant) {
      _state.worries[idx].isImportant = true;
      _state = AppState(
        schemaVersion: _state.schemaVersion,
        settings: _state.settings,
        worries: _state.worries,
        totalWorriesCreated: _state.totalWorriesCreated,
        totalWorriesReleased: _state.totalWorriesReleased,
        totalWorriesMarkedImportant: _state.totalWorriesMarkedImportant + 1,
      );
      await _saveState();
      notifyListeners();
    }
  }

  /// Finds worry by id, sets isImportant = false, saves state, notifies listeners.
  Future<void> unmarkImportant(String id) async {
    final idx = _state.worries.indexWhere((w) => w.id == id);
    if (idx != -1 && _state.worries[idx].isImportant) {
      _state.worries[idx].isImportant = false;
      _state = AppState(
        schemaVersion: _state.schemaVersion,
        settings: _state.settings,
        worries: _state.worries,
        totalWorriesCreated: _state.totalWorriesCreated,
        totalWorriesReleased: _state.totalWorriesReleased,
        totalWorriesMarkedImportant: _state.totalWorriesMarkedImportant - 1,
      );
      await _saveState();
      notifyListeners();
    }
  }

  /// Adds more time to a locked worry
  Future<void> addTimeToWorry(String id, int durationSeconds) async {
    final idx = _state.worries.indexWhere((w) => w.id == id);
    if (idx != -1) {
      _state.worries[idx].unlockAt = DateTime.now().millisecondsSinceEpoch + (durationSeconds * 1000);
      _state.worries[idx].status = 'locked';
      await _saveState();
      notifyListeners();
    }
  }

  /// Updates the unlock time for FUTURE worries only.
  Future<void> setUnlockTime(int hour, int minute) async {
    if (hour < 0 || hour > 23) throw RangeError.range(hour, 0, 23, 'hour');
    if (minute < 0 || minute > 59) {
      throw RangeError.range(minute, 0, 59, 'minute');
    }

    _state = AppState(
      schemaVersion: _state.schemaVersion,
      settings:
          _state.settings.copyWith(unlockHour: hour, unlockMinute: minute),
      worries: _state.worries,
      totalWorriesCreated: _state.totalWorriesCreated,
      totalWorriesReleased: _state.totalWorriesReleased,
    );
    await _saveState();
    notifyListeners();
  }

  /// Updates the locale preference.
  Future<void> setLocale(String locale) async {
    _state = AppState(
      schemaVersion: _state.schemaVersion,
      settings: _state.settings.copyWith(locale: locale),
      worries: _state.worries,
      totalWorriesCreated: _state.totalWorriesCreated,
      totalWorriesReleased: _state.totalWorriesReleased,
    );
    await _saveState();
    notifyListeners();
  }

  /// Returns pretty-printed JSON of the full state, for manual backup.
  String exportJSON() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(_state.toJson());
  }

  /// Force re-reads state from disk. Useful for multi-instance sync.
  Future<void> reload() async {
    _state = _loadState();
    notifyListeners();
  }

  // ────────────────────────────────
  // Internal helpers
  // ────────────────────────────────

  void _backupCorrupt(String rawValue) {
    if (_prefs == null) return;
    final backupKey =
        '$_corruptPrefix${DateTime.now().millisecondsSinceEpoch}';
    _prefs!.setString(backupKey, rawValue);
  }
}

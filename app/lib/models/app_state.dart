/// Application state model.
///
/// Holds the settings and the list of worries.
/// Serialized to/from JSON for SharedPreferences persistence.
library;

import 'worry.dart';

class AppState {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final AppSettings settings;
  final List<Worry> worries;

  AppState({
    this.schemaVersion = currentSchemaVersion,
    AppSettings? settings,
    List<Worry>? worries,
  })  : settings = settings ?? AppSettings(),
        worries = worries ?? [];

  /// Returns the default/fresh state.
  factory AppState.defaults() => AppState();

  /// Deserializes from JSON map. Returns defaults on any failure.
  factory AppState.fromJson(Map<String, dynamic> json) {
    try {
      final version = json['schemaVersion'] as int?;
      if (version == null || version != currentSchemaVersion) {
        // Unknown schema — return defaults (caller handles backup).
        return AppState.defaults();
      }

      final settingsJson = json['settings'] as Map<String, dynamic>?;
      final worriesJson = json['worries'] as List<dynamic>?;

      return AppState(
        schemaVersion: version,
        settings: settingsJson != null
            ? AppSettings.fromJson(settingsJson)
            : AppSettings(),
        worries: worriesJson
                ?.map((w) => Worry.fromJson(w as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (_) {
      return AppState.defaults();
    }
  }

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'settings': settings.toJson(),
      'worries': worries.map((w) => w.toJson()).toList(),
    };
  }
}

/// User-configurable settings.
class AppSettings {
  final int unlockHour;
  final int unlockMinute;
  final String locale; // "en" or "ne"

  AppSettings({
    this.unlockHour = 18,
    this.unlockMinute = 0,
    this.locale = 'en',
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      unlockHour: (json['unlockHour'] as int?) ?? 18,
      unlockMinute: (json['unlockMinute'] as int?) ?? 0,
      locale: (json['locale'] as String?) ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unlockHour': unlockHour,
      'unlockMinute': unlockMinute,
      'locale': locale,
    };
  }

  /// Returns a copy with updated fields.
  AppSettings copyWith({
    int? unlockHour,
    int? unlockMinute,
    String? locale,
  }) {
    return AppSettings(
      unlockHour: unlockHour ?? this.unlockHour,
      unlockMinute: unlockMinute ?? this.unlockMinute,
      locale: locale ?? this.locale,
    );
  }
}

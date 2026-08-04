import 'package:flutter_test/flutter_test.dart';
import 'package:worry_box/models/worry.dart';
import 'package:worry_box/models/app_state.dart';
import 'package:worry_box/services/state.dart';
import 'package:worry_box/l10n/consolation_messages.dart';
import 'package:worry_box/l10n/app_strings.dart';

void main() {
  // ────────────────────────────────
  // Worry Model Tests
  // ────────────────────────────────
  group('Worry Model', () {
    test('creates a worry with valid text', () {
      final worry = Worry.create(text: 'Test worry', unlockHour: 18, unlockMinute: 0);
      expect(worry.text, 'Test worry');
      expect(worry.status, 'locked');
      expect(worry.id, isNotEmpty);
      expect(worry.createdAt, isPositive);
      expect(worry.unlockAt, greaterThan(worry.createdAt));
    });

    test('trims whitespace from text', () {
      final worry = Worry.create(text: '  spaced out  ', unlockHour: 18, unlockMinute: 0);
      expect(worry.text, 'spaced out');
    });

    test('rejects empty text', () {
      expect(
        () => Worry.create(text: '', unlockHour: 18, unlockMinute: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects whitespace-only text', () {
      expect(
        () => Worry.create(text: '   ', unlockHour: 18, unlockMinute: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects text over 280 characters', () {
      final longText = 'a' * 281;
      expect(
        () => Worry.create(text: longText, unlockHour: 18, unlockMinute: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts text exactly 280 characters', () {
      final maxText = 'a' * 280;
      final worry = Worry.create(text: maxText, unlockHour: 18, unlockMinute: 0);
      expect(worry.text.length, 280);
    });

    test('unlockAt rolls to tomorrow if unlock hour has passed', () {
      final now = DateTime.now();
      // Use an hour that's already passed (0 = midnight)
      final worry = Worry.create(text: 'test', unlockHour: 0, unlockMinute: 0);
      final unlockTime = DateTime.fromMillisecondsSinceEpoch(worry.unlockAt);
      expect(unlockTime.isAfter(now), isTrue);
    });

    test('dev mode creates worry with short unlock', () {
      final worry = Worry.createDev(text: 'dev test', unlockSeconds: 5);
      final expectedUnlock = worry.createdAt + 5000;
      expect(worry.unlockAt, expectedUnlock);
    });

    test('JSON serialization round-trip', () {
      final original = Worry.create(text: 'Round trip', unlockHour: 18, unlockMinute: 0);
      final json = original.toJson();
      final restored = Worry.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.text, original.text);
      expect(restored.createdAt, original.createdAt);
      expect(restored.unlockAt, original.unlockAt);
      expect(restored.status, original.status);
    });

    test('isPending returns true for future unlock', () {
      final worry = Worry.createDev(text: 'pending', unlockSeconds: 3600);
      expect(worry.isPending, isTrue);
      expect(worry.isUnlockable, isFalse);
    });

    test('relativeTime returns "just now" for recent worry', () {
      final worry = Worry.create(text: 'recent', unlockHour: 18, unlockMinute: 0);
      expect(worry.relativeTime, contains('just now'));
    });
  });

  // ────────────────────────────────
  // AppState Model Tests
  // ────────────────────────────────
  group('AppState Model', () {
    test('defaults have correct values', () {
      final state = AppState.defaults();
      expect(state.schemaVersion, 1);
      expect(state.settings.unlockHour, 18);
      expect(state.settings.unlockMinute, 0);
      expect(state.settings.locale, 'en');
      expect(state.worries, isEmpty);
    });

    test('JSON round-trip preserves all fields', () {
      final state = AppState(
        settings: AppSettings(unlockHour: 20, unlockMinute: 30, locale: 'ne'),
        worries: [
          Worry.create(text: 'test', unlockHour: 20, unlockMinute: 30),
        ],
      );

      final json = state.toJson();
      final restored = AppState.fromJson(json);

      expect(restored.settings.unlockHour, 20);
      expect(restored.settings.unlockMinute, 30);
      expect(restored.settings.locale, 'ne');
      expect(restored.worries.length, 1);
      expect(restored.worries.first.text, 'test');
    });

    test('fromJson returns defaults on invalid schema version', () {
      final json = {'schemaVersion': 999, 'settings': {}, 'worries': []};
      final state = AppState.fromJson(json);
      expect(state.schemaVersion, 1);
      expect(state.worries, isEmpty);
    });

    test('fromJson returns defaults on garbage input', () {
      final state = AppState.fromJson({'garbage': true});
      expect(state.schemaVersion, 1);
    });

    test('AppSettings copyWith works correctly', () {
      final original = AppSettings(unlockHour: 18, unlockMinute: 0, locale: 'en');
      final modified = original.copyWith(unlockHour: 20, locale: 'ne');
      expect(modified.unlockHour, 20);
      expect(modified.unlockMinute, 0); // unchanged
      expect(modified.locale, 'ne');
    });
  });

  // ────────────────────────────────
  // State Derivation Tests
  // ────────────────────────────────
  group('State Derivation', () {
    test('formatCountdown shows hours and minutes', () {
      final futureMs = DateTime.now().millisecondsSinceEpoch + (4 * 3600000 + 12 * 60000);
      final result = formatCountdown(futureMs);
      expect(result, contains('h'));
      expect(result, contains('m'));
    });

    test('formatCountdown shows "Now" for past time', () {
      final pastMs = DateTime.now().millisecondsSinceEpoch - 1000;
      expect(formatCountdown(pastMs), 'Now');
    });

    test('formatCountdown Nepali locale shows अहिले for past', () {
      final pastMs = DateTime.now().millisecondsSinceEpoch - 1000;
      expect(formatCountdown(pastMs, locale: 'ne'), 'अहिले');
    });

    test('worryCountLabel singular English', () {
      expect(worryCountLabel(1), '1 worry put away');
    });

    test('worryCountLabel plural English', () {
      expect(worryCountLabel(3), '3 worries put away');
    });

    test('worryCountLabel Nepali', () {
      final result = worryCountLabel(3, locale: 'ne');
      expect(result, contains('चिन्ता'));
    });

    test('formatUnlockTime English PM', () {
      expect(formatUnlockTime(18, 0), '6:00 PM');
    });

    test('formatUnlockTime English AM', () {
      expect(formatUnlockTime(9, 30), '9:30 AM');
    });

    test('formatUnlockTime Nepali', () {
      final result = formatUnlockTime(18, 0, locale: 'ne');
      expect(result, contains('बेलुका'));
    });
  });

  // ────────────────────────────────
  // Localization Tests
  // ────────────────────────────────
  group('Localization', () {
    test('AppStrings returns English by default', () {
      expect(AppStrings.get('appTitle'), 'Worry Box');
    });

    test('AppStrings returns Nepali when locale is ne', () {
      expect(AppStrings.get('appTitle', locale: 'ne'), 'चिन्ता बाकस');
    });

    test('AppStrings format replaces placeholders', () {
      final result = AppStrings.format('captureHelper', {'time': '6:00 PM'});
      expect(result, 'Opens at 6:00 PM');
    });

    test('AppStrings format works in Nepali', () {
      final result = AppStrings.format('captureHelper', {'time': '६:०० बेलुका'}, locale: 'ne');
      expect(result, contains('६:०० बेलुका'));
    });

    test('AppStrings falls back to English for unknown key', () {
      expect(AppStrings.get('nonexistent_key'), 'nonexistent_key');
    });

    test('ConsolationMessages returns a non-empty string', () {
      final msg = ConsolationMessages.getRandom();
      expect(msg, isNotEmpty);
    });

    test('ConsolationMessages returns Nepali when locale is ne', () {
      final msg = ConsolationMessages.getRandom(locale: 'ne');
      // Nepali text uses Devanagari script
      expect(msg.codeUnits.any((c) => c > 127), isTrue);
    });

    test('ConsolationMessages getByIndex is deterministic', () {
      final msg1 = ConsolationMessages.getByIndex(0);
      final msg2 = ConsolationMessages.getByIndex(0);
      expect(msg1, msg2);
    });

    test('ConsolationMessages count returns correct totals', () {
      expect(ConsolationMessages.count(), 10);
      expect(ConsolationMessages.count(locale: 'ne'), 10);
    });

    test('All English string keys have Nepali counterparts', () {
      for (final key in AppStrings.en.keys) {
        expect(AppStrings.ne.containsKey(key), isTrue,
            reason: 'Missing Nepali translation for key: $key');
      }
    });
  });
}

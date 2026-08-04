# Worry Box — Flutter Android App Build Specification

> **Purpose of this file:** this is the single source of truth for building Worry Box.
> Every decision here is final — there are no open questions. If an implementation detail
> is not covered here, prefer the simplest choice consistent with the rest of the document.

---

## 1. What we are building

A client-side Flutter Android app that lets a user write down an anxious thought, visually seal it in a
box, and only read it again at a scheduled time later in the day.

It implements a real CBT technique called **scheduled worry time** (worry postponement):
you don't suppress the thought, you *delay* it. Writing it down tells the brain it no longer
has to hold onto it; by the time the box opens, most worries have lost their urgency.

**The interaction is the product.** Lock → wait → reveal. Not a mood tracker, not a dashboard.

### Non-goals

Do not build these. They are out of scope for v1 and adding them is a regression:

- No backend, no accounts, no authentication, no cloud sync
- No AI, no external APIs, no analytics, no telemetry
- No complex state management frameworks (e.g., Redux, Bloc) unless strictly necessary for clean code (Provider/Riverpod are acceptable if kept simple).
- No notifications or background services in v1
- No mood scores, streaks, gamification, or charts

### Safety framing

This is a self-help tool, not medical care. The UI must never diagnose, score, or evaluate the
user's thoughts. Include a quiet, non-alarming footer line on the capture view:

> Worry Box is a self-help tool, not a substitute for professional care.
> If you are in crisis, contact your local emergency services or a crisis helpline.

---

## 2. Tech stack (decided)

| Layer | Choice |
|---|---|
| Framework | **Flutter** |
| Language | **Dart** |
| Persistence | **`shared_preferences`** package |
| Audio | **`audioplayers`** package (for the calming background audio) |
| Fonts | System stack first; optional self-hosted Inter in `pubspec.yaml` |

Rationale: Flutter provides a high-performance cross-platform engine with beautiful, smooth animations out of the box.

---

## 3. File structure

Create exactly this inside the `lib/` directory:

```
lib/
├── main.dart             # Entry point and MaterialApp config
├── models/
│   └── worry.dart        # Worry data model (from/to JSON)
├── services/
│   └── storage.dart      # SharedPreferences wrapper
├── screens/
│   ├── capture_screen.dart
│   ├── locked_screen.dart
│   └── reveal_screen.dart
├── widgets/
│   └── box_animation.dart # The visual box/lock widget
└── theme.dart            # Colors, text styles, and ThemeData
```

`storage.dart` is the only file allowed to reference `SharedPreferences`. Everything else goes through it.

---

## 4. Data model

Single `SharedPreferences` string key: **`worryBox_v1`**. Value is a JSON-encoded string.

```json
{
  "schemaVersion": 1,
  "settings": {
    "unlockHour": 18,
    "unlockMinute": 0
  },
  "worries": [
    {
      "id": "1754318400000-k3f9a",
      "text": "What if I fail the presentation?",
      "createdAt": 1754318400000,
      "unlockAt": 1754337600000,
      "status": "locked"
    }
  ]
}
```

### Field rules

| Field | Type | Rules |
|---|---|---|
| `schemaVersion` | int | Always `1` in v1. On mismatch, handle migration |
| `settings.unlockHour` | int | 0–23, local time. Default `18` |
| `settings.unlockMinute` | int | 0–59. Default `0` |
| `id` | String | `` `${DateTime.now().millisecondsSinceEpoch}-${Random string}` `` |
| `text` | String | Trimmed. 1–280 chars. Reject empty/whitespace-only |
| `createdAt` | int | Epoch milliseconds |
| `unlockAt` | int | Epoch milliseconds, computed at capture time |
| `status` | String | `"locked"` → `"revealed"` → `"released"` or `"kept"` |

**Store timestamps as epoch numbers, never ISO strings.** All comparisons are numeric.

### Status lifecycle

```
locked ──(now >= unlockAt)──> revealed ──┬──> released   (user let it go, removed from list)
                                          └──> kept       (user saved it to history)
```

### Computing `unlockAt`

At capture time, in **local time**:
1. Build today's unlock moment from `unlockHour` / `unlockMinute`.
2. If that moment is already in the past, roll it forward to the same time tomorrow.
3. Store the resulting epoch ms.

---

## 5. Storage API (`lib/services/storage.dart`)

```dart
class StorageService {
  Future<void> init();
  
  StateModel loadState();
  Future<bool> saveState(StateModel state);
  
  Worry addWorry(String text);
  
  List<Worry> getWorries();
  List<Worry> getPendingWorries();
  List<Worry> getUnlockedWorries();
  
  void releaseWorry(String id);
  void keepWorry(String id);
  void markRevealed(String id);
  
  void setUnlockTime(int hour, int minute);
}
```

---

## 6. View state machine

Three views. Exactly one is visible at a time.

```
                  ┌──────────────────────────────────────┐
                  │              CAPTURE                 │
                  │  no pending worries, nothing to open │
                  └───────────────┬──────────────────────┘
                                  │ user submits a worry
                                  ▼
                  ┌──────────────────────────────────────┐
                  │               LOCKED                 │
                  │  pending worries exist, now < unlock │
                  └───────────────┬──────────────────────┘
                                  │ countdown reaches zero
                                  ▼
                  ┌──────────────────────────────────────┐
                  │               REVEAL                 │
                  │  one or more worries are unlockable  │
                  └───────────────┬──────────────────────┘
                                  │ all worries released or kept
                                  ▼
                              CAPTURE
```

Derivation:
```dart
if (getUnlockedWorries().isNotEmpty) return ViewState.reveal;
if (getPendingWorries().isNotEmpty) return ViewState.locked;
return ViewState.capture;
```

### Rules
- **The user can always add a worry**, including while the box is locked.
- Use a `Timer.periodic` (1 second) for the countdown in `locked_screen.dart`.
- Re-evaluate state on `AppLifecycleState.resumed` (when the app returns from background).

---

## 7. UI specification

### Design tokens (`lib/theme.dart`)

```dart
class AppColors {
  static const bg0 = Color(0xFF0B1020);
  static const bg1 = Color(0xFF151D3B);
  static const surface = Color(0x0FFFFFFF); // 6% white
  static const text = Color(0xFFEAEEF7);
  static const textMuted = Color(0xFF97A3C4);
  static const accent = Color(0xFF7C9CF5);
  static const accentSoft = Color(0xFF8FD9C2);
}
```

Background is a slow, animated gradient between `bg0` and `bg1`.

### View: CAPTURE

- Title: **Worry Box**
- Subtitle: *Write it down. Put it away. Come back to it later.*
- The box illustration (CustomPainter or SVG)
- `TextField`, multiline, placeholder: *What's on your mind?*
- Primary button: **Put it away** — disabled while input is empty
- Secondary action / Icon: **Play Calming Audio** — toggles a looping, soothing ambient track using `audioplayers` package.
- Helper line: *Opens at 6:00 PM*
- Footer: safety line.

### View: LOCKED

- The box, lid closed, subtle padlock
- Headline: *Your thoughts are safe.*
- Countdown: `Opens in 4h 12m` (updates per second)
- Count: *3 worries put away*
- **No preview of the text.**
- Consolation message: Briefly display a short, comforting message (e.g., "That's safely put away," or "It's okay to feel this way") via a `SnackBar` or brief animated text immediately after a worry is added.
- Secondary compact input: *Something else? Put it away too.*
- Tone is reassuring, never punitive.

### View: REVEAL

- Headline: *The box is open.*
- Sub: *Read these back. Many will feel smaller now.*
- List of unlocked worries (ListView). Each card shows the text and two buttons:
  - **Let go** — card animates out of the list and is deleted
  - **Keep** — card is archived
- When empty: *All clear.* plus **Write a new worry** button.

### Animations
Use `AnimationController` and implicit animations (`AnimatedContainer`, `AnimatedOpacity`).
- **Drop & Seal**: Custom animation sequences.
- **Release**: Use `SizeTransition` and `FadeTransition` when removing items from the list.

---

## 8. Accessibility (required)

- Use Flutter's `Semantics` widget for custom painted items.
- Ensure text contrast is accessible.
- Countdown should not aggressively re-announce to screen readers every second.

---

## 9. Security

- **Android Permissions**: Do not include `<uses-permission android:name="android.permission.INTERNET" />` in `AndroidManifest.xml` unless absolutely required by a specific plugin (like audio). Ideally, keep the app completely offline.
- Data stays entirely in `SharedPreferences`.

---

## 10. Edge cases to handle explicitly

| Case | Required behavior |
|---|---|
| App backgrounded past unlock time | Re-derive state using `WidgetsBindingObserver` `didChangeAppLifecycleState`, don't wait for the next Timer tick |
| User changes device clock | Accept it. This is a self-help tool, not DRM. Do not fight the user |
| Very long single word | Use `TextOverflow.visible` or wrap appropriately so UI doesn't break |

---

## 11. Dev & testing shortcut

Time-locked behavior is untestable if you have to wait until 6pm. Support a dev flag in `main.dart` or via a long-press on the title.
If active, `addWorry` sets `unlockAt = DateTime.now().add(Duration(seconds: 10)).millisecondsSinceEpoch`.

---

## 12. Acceptance criteria

- [ ] **A1** Typing a worry and tapping *Put it away* clears the input, plays the drop + seal, and moves to LOCKED
- [ ] **A1.1** A short consolation message appears briefly upon moving to LOCKED (e.g. via SnackBar)
- [ ] **A1.2** Tapping the "Play Calming Audio" button toggles the calming background song
- [ ] **A2** App restarts during LOCKED stay LOCKED with the countdown correct
- [ ] **A3** Worry text is completely hidden in the UI while locked
- [ ] **A4** Countdown reaching zero transitions to REVEAL seamlessly
- [ ] **A5** REVEAL lists every unlocked worry
- [ ] **A6** *Let go* animates the card away
- [ ] **A7** *Keep* archives the worry
- [ ] **A8** Emptying the list returns to CAPTURE
- [ ] **A9** Backgrounding the app and returning after unlock time instantly shifts view to REVEAL
- [ ] **A10** `flutter build apk` succeeds without errors

# 🛡️ Project Abhaya

> **Abhaya** (अभय) — *Sanskrit for "fearlessness"*

A digital mental health companion built with Flutter that implements the Cognitive Behavioral Therapy (CBT) technique of **scheduled worry time**. Write down your worries, lock them away, and come back to them later — when they often feel smaller than before.

---

## 📖 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Data Models](#data-models)
- [Services](#services)
- [Screens](#screens)
- [Widgets](#widgets)
- [Theming & Design System](#theming--design-system)
- [Localization (i18n)](#localization-i18n)
- [Audio & Meditation](#audio--meditation)
- [Data Storage & Privacy](#data-storage--privacy)
- [State Management](#state-management)
- [Getting Started](#getting-started)
- [Building](#building)
- [Developer Mode](#developer-mode)
- [Tech Stack](#tech-stack)
- [License](#license)

---

## Overview

Project Abhaya guides users through a structured worry management cycle:

1. **Capture** — Write down what's troubling you.
2. **Lock** — The worry is sealed away with a countdown timer.
3. **Reveal** — When the timer expires, the box opens. Re-read your worries; most will feel smaller.
4. **Decide** — For each worry, choose to **Let Go** (release) or **Keep** (bookmark for action).

This cycle is rooted in the CBT principle that scheduled worry time reduces anxiety by preventing rumination throughout the day.

---

## Features

| Feature | Description |
|---|---|
| **Worry Capture** | Write worries with title + description; configurable lock duration (15m to 24h) |
| **Animated Lock Screen** | Glassmorphic UI with live countdown, rotating reassurance phrases, and a 3D box animation |
| **Reveal & Decide** | Swipe through unlocked worries — release them or bookmark for follow-up with a deadline |
| **Bookmarks** | Actionable worries are kept with customizable deadlines; expired items trigger a blocking review overlay |
| **Archive** | History of all released worries (only populated after a worry is let go) |
| **Analytics** | Dashboard showing Total Captured, Total Let Go, and Currently Kept metrics |
| **Meditation Soundscapes** | 10 ambient audio tracks (rain, ocean, piano, brown noise, etc.) with looping playback |
| **Bilingual UI** | Full English ↔ Nepali (नेपाली) toggle — all strings, numerals, and time formats adapt |
| **Glassmorphism Design** | Deep dark theme (#0B1020 → #151D3B) with frosted glass panels, gradient orbs, and particle effects |
| **Offline & Private** | 100% local storage via SharedPreferences — zero network calls, zero telemetry |
| **Dev Mode** | Long-press the title to enable 1-minute unlock cycles for testing |

---

## Architecture

The app follows a clean layered architecture:

```
┌─────────────────────────────────────┐
│           Presentation              │
│  (Screens, Widgets, Animations)     │
├─────────────────────────────────────┤
│          Business Logic             │
│  (State Derivation, Countdown)      │
├─────────────────────────────────────┤
│            Services                 │
│  (StorageService, AudioService)     │
├─────────────────────────────────────┤
│           Data Models               │
│  (Worry, AppState, AppSettings,     │
│   Track)                            │
├─────────────────────────────────────┤
│       Platform / Persistence        │
│  (SharedPreferences, AudioPlayers)  │
└─────────────────────────────────────┘
```

**Key architectural decisions:**

- **State derivation over state storage**: The current view (`capture`, `locked`, `reveal`) is always *derived* from the clock and worry statuses — never stored as a boolean flag. This eliminates stale-state bugs.
- **Single source of truth**: `StorageService` is the only class that touches `SharedPreferences`. All screens listen to it via `ChangeNotifier`.
- **No external state management library**: The app uses Flutter's built-in `ChangeNotifier` + `setState` pattern, keeping dependencies minimal.

---

## Project Structure

```
lib/
├── main.dart                     # App entry point, root widget, navigation router
├── theme.dart                    # Design tokens (colors, spacing, shapes, durations)
│
├── models/
│   ├── app_state.dart            # AppState & AppSettings — serializable state container
│   ├── worry.dart                # Worry data model with factory constructors
│   └── track.dart                # Meditation track model with static track list
│
├── services/
│   ├── storage.dart              # SharedPreferences persistence, CRUD operations
│   ├── state.dart                # View state derivation, countdown formatting
│   └── audio_service.dart        # AudioPlayers wrapper for meditation tracks
│
├── screens/
│   ├── capture_screen.dart       # Worry input form with duration picker
│   ├── locked_screen.dart        # Countdown timer with rotating headlines
│   ├── reveal_screen.dart        # Unlocked worries — release or keep
│   ├── bookmarks_screen.dart     # Actionable kept worries with deadlines
│   ├── archive_screen.dart       # History of released worries
│   ├── analytics_screen.dart     # Metrics dashboard
│   └── meditation_screen.dart    # Ambient soundscape player
│
├── widgets/
│   ├── animated_background.dart  # Gradient orb animation (background layer)
│   ├── box_animation.dart        # 3D worry box open/close animation
│   ├── glass_card.dart           # Reusable glassmorphism card widget
│   ├── particle_burst.dart       # Particle explosion effect on worry release
│   └── stress_graph.dart         # Visual stress level indicator
│
├── l10n/
│   ├── app_strings.dart          # English & Nepali string maps + format helpers
│   └── consolation_messages.dart # Extended consolation/encouragement phrases
│
assets/
├── audio/                        # 10 meditation tracks (WAV + MP3 formats)
│   ├── t1.wav … t10.wav
│   ├── t1.mp3 … t10.mp3
│   └── base.mp3
└── icon.jpg                      # App launcher icon
```

---

## Data Models

### `Worry` (`lib/models/worry.dart`)

Represents a single worry entry. Timestamps use **epoch milliseconds** to avoid timezone issues.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Unique ID (epoch-randomHash) |
| `title` | `String` | Short title (max 100 chars) |
| `text` | `String` | Description/body (max 500 chars) |
| `createdAt` | `int` | Creation timestamp (epoch ms) |
| `unlockAt` | `int` | When this worry becomes readable (epoch ms) |
| `status` | `String` | One of: `locked`, `revealed`, `released`, `kept` |
| `isImportant` | `bool` | Flagged as important by the user |

**Status Lifecycle:**

```
locked → revealed → released (let go)
                  → kept (bookmarked with deadline)
```

**Factory Constructors:**

- `Worry.create()` — Standard creation with unlock hour/minute
- `Worry.createDev()` — Dev mode with short unlock duration in seconds
- `Worry.createWithDuration()` — Duration-based creation with title + description

### `AppState` (`lib/models/app_state.dart`)

Top-level serializable container for the entire app state.

| Field | Type | Description |
|---|---|---|
| `schemaVersion` | `int` | Data schema version (currently `1`) |
| `settings` | `AppSettings` | User preferences |
| `worries` | `List<Worry>` | All worry entries |
| `totalWorriesCreated` | `int` | Lifetime counter |
| `totalWorriesReleased` | `int` | Lifetime counter |
| `totalWorriesMarkedImportant` | `int` | Lifetime counter |

### `AppSettings`

| Field | Type | Default | Description |
|---|---|---|---|
| `unlockHour` | `int` | `18` | Default unlock hour (24h format) |
| `unlockMinute` | `int` | `0` | Default unlock minute |
| `locale` | `String` | `"en"` | UI language (`"en"` or `"ne"`) |

### `Track` (`lib/models/track.dart`)

Represents a meditation audio track.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Track identifier (e.g., `"t1"`) |
| `name` | `String` | Display name (e.g., `"Gentle Rain + Felt Piano"`) |
| `emoji` | `String` | Visual emoji icon |
| `url` | `String` | Asset path to audio file |

---

## Services

### `StorageService` (`lib/services/storage.dart`)

The **only** module that touches `SharedPreferences`. Extends `ChangeNotifier` so all screens can reactively rebuild when state changes.

**Key Responsibilities:**

- `init()` — Initialize SharedPreferences on app startup
- `addWorry()` / `addWorryWithDuration()` — Create and persist new worries
- `releaseWorry()` — Mark as released + increment counter
- `keepWorryWithDeadline()` — Bookmark with action deadline
- `markRevealed()` / `markImportant()` — Status transitions
- `removeWorry()` — Permanent deletion
- `getWorries()` / `getPendingWorries()` / `getUnlockedWorries()` / `getKeptWorries()` — Filtered queries
- `getExpiredBookmarks()` — Bookmarks past their deadline (triggers blocking overlay)
- `exportJSON()` — Pretty-printed JSON export for manual backup

**Corruption Handling:** If stored JSON is malformed or has a mismatched schema version, the corrupt data is backed up under a timestamped key (`worryBox_v1_corrupt_<timestamp>`) and defaults are returned.

### `AudioService` (`lib/services/audio_service.dart`)

Wraps the `audioplayers` package for meditation soundscape playback.

- Supports track switching, looping, and toggle (play/stop)
- Graceful error handling — audio failures never crash the app
- Default volume: 50%

### State Derivation (`lib/services/state.dart`)

Pure function `deriveViewState(StorageService)` determines which screen to show:

```
1. Any unlocked/revealed worries exist? → REVEAL
2. Any pending (locked) worries exist?  → LOCKED
3. Otherwise                            → CAPTURE
```

Also provides:
- `formatCountdown()` — Human-readable countdown strings (supports Nepali numerals)
- `worryCountLabel()` — Pluralized worry count labels
- `formatUnlockTime()` — 12-hour time display with AM/PM (or Nepali equivalents)
- `CountdownTicker` — 1-second periodic timer for live countdowns

---

## Screens

### Capture Screen
The entry point where users write their worries. Features:
- Title + description input fields
- Duration picker (15m, 30m, 1h, 3h, 6h, 12h, 24h)
- Character count validation (title: 100, description: 500)
- Animated submission with glass card UI

### Locked Screen
Shown while worries are sealed. Features:
- Live countdown timer to unlock time
- **Rotating reassurance phrases** — cycles through 7 different encouraging messages
- Pending worry count display
- Quick-add input for additional worries
- 3D animated box visualization

### Reveal Screen
Opens when the countdown expires. Features:
- Card-based worry display with "Let Go" and "Keep" buttons
- "Keep" triggers a date/time picker for setting an action deadline
- Particle burst animation on release
- "All clear" state when every worry is resolved

### Bookmarks Screen
Shows worries marked as "Keep" with active deadlines. Features:
- Deadline countdown per item
- Mark done / extend deadline actions
- Expired items trigger a **blocking overlay** that must be resolved before the app can be used

### Archive Screen
Read-only history of all released worries. Only populated after a worry's box opens and the user chooses "Let Go."

### Analytics Screen
Dashboard with three metric cards:
- **Total Captured** — lifetime worry count
- **Total Let Go** — worries released
- **Currently Kept** — active bookmarks

### Meditation Screen
Ambient soundscape player with 10 tracks:

| # | Track | Emoji |
|---|---|---|
| 1 | Gentle Rain + Felt Piano | 🌧️ |
| 2 | Ocean Waves + Ambient Pads | 🌊 |
| 3 | Forest Stream + Birds | 🌲 |
| 4 | Fireplace + Soft Wind | 🔥 |
| 5 | Minimal Piano (no rain) | 🎹 |
| 6 | Night Crickets + Breeze | 🌙 |
| 7 | Deep Ambient Drone | ☁️ |
| 8 | Brown Noise | 🤍 |
| 9 | Bamboo Flute + Water | 🌸 |
| 10 | White Noise for focus | 💤 |

---

## Widgets

| Widget | Description |
|---|---|
| `AnimatedBackground` | Full-screen gradient with three slowly orbiting glowing orbs (blue, indigo, sky) |
| `BoxAnimation` | 3D perspective box that opens/closes with rotation and scale transforms |
| `GlassCard` | Reusable container with frosted-glass effect (translucent bg + border blur) |
| `ParticleBurst` | Explosion of colored particles triggered when a worry is released |
| `StressGraph` | Visual indicator showing worry stress levels over time |

---

## Theming & Design System

Defined in `lib/theme.dart`. The app uses a **deep dark glassmorphism** aesthetic.

### Color Palette

| Token | Hex | Usage |
|---|---|---|
| `bg0` | `#0B1020` | Deepest background |
| `bg1` | `#101730` | Card backgrounds |
| `bg2` | `#151D3B` | Glass panel base |
| `accent` | `#60A5FA` | Primary interactive color (Blue 400) |
| `accentSoft` | `#93C5FD` | Secondary accent (Blue 300) |
| `text` | `#F3F4F6` | Primary text (Gray 100) |
| `textMuted` | `#9CA3AF` | Secondary text (Gray 400) |
| `error` | `#F87171` | Error/warning states (Red 400) |

### Glass Panels

```dart
glassPanelBg:     rgba(21, 29, 59, 0.45)   // Translucent indigo
glassPanelBorder: rgba(255, 255, 255, 0.12) // Subtle white edge
```

### Spacing Scale

4px base unit: `sp1=4`, `sp2=8`, `sp3=12`, `sp4=16`, `sp6=24`, `sp8=32`, `sp12=48`

### Animation Durations

- `fast`: 180ms (micro-interactions)
- `base`: 400ms (transitions)
- `seal`: 700ms (box seal animation)

---

## Localization (i18n)

The app ships with full **English** and **Nepali** (नेपाली) translations in `lib/l10n/app_strings.dart`.

**Usage:**
```dart
AppStrings.get('appTitle', locale: _locale);
// → "Project Abhaya" (en) or "प्रोजेक्ट अभय" (ne)

AppStrings.format('lockedCountdown', {'time': '3h 12m'}, locale: 'ne');
// → "३ घण्टा १२ मिनेट मा खुल्छ"
```

**Features:**
- All UI strings (buttons, labels, headlines, safety text)
- Nepali numeral conversion (0→०, 1→१, etc.)
- Nepali time period names (बिहान/बेलुका instead of AM/PM)
- 7 rotating locked-screen reassurance phrases per language

---

## Data Storage & Privacy

### How Data is Stored

All data is persisted **locally** using Flutter's `shared_preferences` package:

| Platform | Storage Location |
|---|---|
| **Android** | Private XML in `/data/data/<package>/shared_prefs/` |
| **Web** | Browser `localStorage` |
| **Windows** | Windows Registry |
| **iOS** | `NSUserDefaults` |

### JSON Schema

The entire app state is serialized as a single JSON string under the key `worryBox_v1`:

```json
{
  "schemaVersion": 1,
  "settings": {
    "unlockHour": 18,
    "unlockMinute": 0,
    "locale": "en"
  },
  "worries": [
    {
      "id": "1722806400000-a3b2c",
      "title": "Exam results",
      "text": "Worried about the final exam results",
      "createdAt": 1722806400000,
      "unlockAt": 1722852000000,
      "status": "locked",
      "isImportant": false
    }
  ],
  "totalWorriesCreated": 5,
  "totalWorriesReleased": 3,
  "totalWorriesMarkedImportant": 1
}
```

### Privacy Guarantees

- ✅ **Zero network requests** — no analytics, no telemetry, no cloud sync
- ✅ **No third-party SDKs** collecting data
- ✅ **Data stays on device** — uninstalling the app permanently deletes all data
- ✅ **Corruption recovery** — malformed data is backed up before resetting to defaults

---

## State Management

The app uses a **derived state** pattern:

1. `StorageService` holds the canonical `AppState` and extends `ChangeNotifier`
2. `main.dart` listens to `StorageService` via `addListener()`
3. On any change, `deriveViewState()` recalculates which screen to show
4. A 5-second periodic timer ensures the UI updates even without user interaction (for countdown expiry)
5. `didChangeAppLifecycleState` re-derives state when the app returns from background

**Manual Override:** Users can tap the segmented control (`Capture | Locked | Reveal`) to manually navigate, overriding the derived state. The override resets on any significant state change (new worry added, worry released, etc.).

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (≥ 3.12.0)
- Android SDK (for Android builds)
- A connected device or emulator

### Installation

```bash
# Clone the repository
git clone https://github.com/prashantgaihre5/Worry-Box.git
cd Worry-Box/app

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Running on Web

```bash
flutter run -d chrome
```

### Running on Android Emulator

```bash
flutter run -d emulator-5554
```

---

## Building

### Debug APK

```bash
flutter build apk --debug
```

### Release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

> **Windows Cross-Drive Note:** If your project is on a different drive (e.g., `F:`) than your Flutter cache (`C:`), add `kotlin.incremental=false` to `android/gradle.properties` to avoid Kotlin compiler cache errors.

### Generate App Icons

```bash
flutter pub run flutter_launcher_icons
```

---

## Developer Mode

Long-press the app title ("Project Abhaya") in the top-left corner to toggle **dev mode**:

- **Enabled**: All new worries unlock in **1 minute** instead of the configured time
- **Disabled**: Normal unlock schedule resumes
- A red "dev mode" badge appears in the top-right when active

This is useful for testing the full capture → lock → reveal → decide cycle without waiting hours.

---

## Tech Stack

| Category | Technology |
|---|---|
| Framework | [Flutter](https://flutter.dev) 3.12+ |
| Language | Dart |
| Persistence | [shared_preferences](https://pub.dev/packages/shared_preferences) ^2.5.0 |
| Audio | [audioplayers](https://pub.dev/packages/audioplayers) ^6.1.0 |
| Date Formatting | [intl](https://pub.dev/packages/intl) ^0.20.0 |
| Icons | [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) ^0.13.1 |
| Platforms | Android, Web, Windows |

---

## License

This project is developed for personal and educational use.

---

<p align="center">
  <em>Built with ❤️ for mental wellness.</em><br>
  <strong>Your thoughts are safe here.</strong>
</p>

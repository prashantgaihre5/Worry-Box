# Worry Box — Build Specification

> **Purpose of this file:** this is the single source of truth for building Worry Box.
> Every decision here is final — there are no open questions. If an implementation detail
> is not covered here, prefer the simplest choice consistent with the rest of the document.

---

## 1. What we are building

A client-side web app that lets a user write down an anxious thought, visually seal it in a
box, and only read it again at a scheduled time later in the day.

It implements a real CBT technique called **scheduled worry time** (worry postponement):
you don't suppress the thought, you *delay* it. Writing it down tells the brain it no longer
has to hold onto it; by the time the box opens, most worries have lost their urgency.

**The interaction is the product.** Lock → wait → reveal. Not a mood tracker, not a dashboard.

### Non-goals

Do not build these. They are out of scope for v1 and adding them is a regression:

- No backend, no accounts, no authentication, no cloud sync
- No AI, no external APIs, no analytics, no telemetry, no cookies
- No frameworks (no React/Vue/Svelte)
- No notifications or service workers in v1
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
| Build tool / dev server | **Vite** (vanilla template, no framework) |
| Language | **Vanilla JavaScript, ES modules, ES2020+** |
| Styling | **Vanilla CSS** with custom properties. No preprocessor, no Tailwind |
| Persistence | **`window.localStorage`** only |
| Fonts | System stack first; optional self-hosted Inter. **No Google Fonts CDN call** |
| Dependencies | Zero runtime dependencies. Dev-only: Vite, Prettier |

Rationale: Vite gives a dev server and a `dist/` build for static hosting, while the app itself
stays plain HTML/CSS/JS that would still run if you deleted the build step.

---

## 3. File structure

Create exactly this:

```
Worry-Box/
├── index.html          # single page, all three views in the DOM
├── package.json        # vite + prettier, scripts: dev / build / preview
├── .gitignore          # node_modules, dist, .DS_Store
├── public/
│   └── favicon.svg
└── src/
    ├── main.js         # entry: wiring, event handlers, render loop
    ├── state.js        # view/state machine + derived state
    ├── storage.js      # the ONLY module that touches localStorage
    ├── ui.js           # DOM rendering helpers
    └── style.css       # design tokens + all styles
```

`storage.js` is the only file allowed to reference `localStorage`. Everything else goes through it.

---

## 4. Data model

Single localStorage key: **`worryBox_v1`**. Value is one JSON object.

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
| `schemaVersion` | number | Always `1` in v1. On mismatch, see migration below |
| `settings.unlockHour` | number | 0–23, local time. Default `18` |
| `settings.unlockMinute` | number | 0–59. Default `0` |
| `id` | string | `` `${Date.now()}-${Math.random().toString(36).slice(2, 7)}` `` |
| `text` | string | Trimmed. 1–280 chars. Reject empty/whitespace-only |
| `createdAt` | number | Epoch milliseconds |
| `unlockAt` | number | Epoch milliseconds, computed at capture time |
| `status` | string | `"locked"` → `"revealed"` → `"released"` or `"kept"` |

**Store timestamps as epoch numbers, never ISO strings.** All comparisons are numeric. This
sidesteps the timezone bug where an ISO string ending in `Z` gets read as UTC 6pm instead of
local 6pm.

### Status lifecycle

```
locked ──(now >= unlockAt)──> revealed ──┬──> released   (user let it go, removed from list)
                                          └──> kept       (user saved it to history)
```

`released` worries are deleted from the array immediately. `kept` worries stay in the array
so a future history view can read them.

### Computing `unlockAt`

At capture time, in **local time**:

1. Build today's unlock moment from `unlockHour` / `unlockMinute`.
2. If that moment is already in the past, roll it forward to the same time tomorrow.
3. Store the resulting epoch ms.

Each worry carries its own `unlockAt`, so a worry captured at 11pm correctly unlocks at 6pm
the *next* day rather than instantly.

### Migration & corruption

`loadState()` must never throw. If the key is missing, unparseable, not an object, or has an
unknown `schemaVersion`, return a fresh default state and leave the bad value untouched under
`worryBox_v1_corrupt_<timestamp>` so no user data is silently destroyed.

---

## 5. Storage API (`src/storage.js`)

```js
isAvailable(): boolean
// Feature-detects localStorage with a write/read/delete probe inside try/catch.
// Safari private mode and hardened browsers throw on setItem — must not crash the app.

loadState(): State
// Always returns a valid State. Never throws. Handles corruption per §4.

saveState(state: State): boolean
// Returns false on QuotaExceededError instead of throwing.

addWorry(text: string): Worry
// Trims, validates length, computes unlockAt, persists, returns the new worry.
// Throws a plain Error on invalid input — the caller shows inline validation.

getWorries(): Worry[]                 // all, newest first
getPendingWorries(): Worry[]          // status "locked" AND now < unlockAt
getUnlockedWorries(): Worry[]         // status "locked" AND now >= unlockAt, plus "revealed"
getKeptWorries(): Worry[]             // status "kept"

nextUnlockAt(): number | null         // earliest unlockAt among pending, or null

releaseWorry(id: string): void        // delete from array + persist
keepWorry(id: string): void           // status -> "kept" + persist
markRevealed(id: string): void        // status -> "revealed" + persist

setUnlockTime(hour: number, minute: number): void
// Validates ranges. Applies to FUTURE worries only — never retroactively re-locks
// or early-unlocks worries already in the box. This is a trust guarantee.

exportJSON(): string                  // pretty-printed full state, for manual backup
```

---

## 6. View state machine (`src/state.js`)

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
                  │  pending worries exist, now < unlock  │
                  └───────────────┬──────────────────────┘
                                  │ countdown reaches zero
                                  ▼
                  ┌──────────────────────────────────────┐
                  │               REVEAL                 │
                  │  one or more worries are unlockable   │
                  └───────────────┬──────────────────────┘
                                  │ all worries released or kept
                                  ▼
                              CAPTURE
```

Derivation — evaluate in this order:

```js
if (getUnlockedWorries().length > 0) return 'REVEAL';
if (getPendingWorries().length > 0)  return 'LOCKED';
return 'CAPTURE';
```

### Rules

- **The user can always add a worry**, including while the box is locked. Worries arrive all
  day; blocking capture defeats the purpose. The locked view therefore contains a compact
  input as well as the countdown.
- State is **derived from the clock on every tick**, never stored as a boolean. Re-evaluate
  on load, on submit, and once per second while a countdown is showing.
- Use one `setInterval` at 1000ms for the countdown. Clear it when leaving LOCKED. Also
  re-evaluate on `visibilitychange` — a backgrounded tab throttles timers and the countdown
  will otherwise be stale when the user returns.

---

## 7. UI specification

### Design tokens (`:root` in `style.css`)

```css
:root {
  /* Surface */
  --bg-0: #0b1020;
  --bg-1: #151d3b;
  --surface: rgba(255, 255, 255, 0.06);
  --surface-strong: rgba(255, 255, 255, 0.10);
  --border: rgba(255, 255, 255, 0.12);

  /* Text */
  --text: #eaeef7;
  --text-muted: #97a3c4;

  /* Accent */
  --accent: #7c9cf5;        /* primary actions, lock state */
  --accent-soft: #8fd9c2;   /* release / "let go" */

  /* Type */
  --font: "Inter", ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
  --step--1: clamp(0.83rem, 0.8rem + 0.15vw, 0.9rem);
  --step-0:  clamp(1rem, 0.95rem + 0.25vw, 1.125rem);
  --step-1:  clamp(1.35rem, 1.2rem + 0.7vw, 1.75rem);
  --step-2:  clamp(1.9rem, 1.6rem + 1.4vw, 2.75rem);

  /* Space (4px scale) */
  --sp-1: 0.25rem; --sp-2: 0.5rem; --sp-3: 0.75rem;
  --sp-4: 1rem;    --sp-6: 1.5rem; --sp-8: 2rem; --sp-12: 3rem;

  /* Shape & depth */
  --radius: 16px;
  --radius-sm: 10px;
  --shadow: 0 20px 60px rgba(0, 0, 0, 0.45);
  --blur: 14px;

  /* Motion */
  --ease-out: cubic-bezier(0.22, 1, 0.36, 1);
  --ease-seal: cubic-bezier(0.65, 0, 0.35, 1);
  --dur-fast: 180ms;
  --dur-base: 400ms;
  --dur-seal: 700ms;
}
```

Background is an animated mesh gradient between `--bg-0` and `--bg-1`, drifting slowly
(~20s loop) to suggest breathing. Cards use `background: var(--surface)` with
`backdrop-filter: blur(var(--blur))` and a 1px `--border` for the glass effect.

### Layout

Mobile-first. Single centered column, `max-width: 32rem`, vertically centered, generous
padding. Everything scales up gracefully — no separate desktop layout needed.

### View: CAPTURE

- Title: **Worry Box**
- Subtitle: *Write it down. Put it away. Come back to it later.*
- The box illustration, lid open (CSS/SVG — no image assets)
- `<textarea>`, 2 rows, autogrow, placeholder: *What's on your mind?*
- Character counter appears only past 240/280
- Primary button: **Put it away** — disabled while input is empty
- Secondary action / Icon: **Play Calming Audio** — toggles a looping, soothing ambient track to help reduce anxiety while writing or after putting the worry away.
- Helper line: *Opens at 6:00 PM* (reflects actual setting)
- Footer: the safety line from §1

### View: LOCKED

- The box, lid closed, subtle padlock
- Headline: *Your thoughts are safe.*
- Countdown: `Opens in 4h 12m` — switch to `4:12` mm:ss format under one minute
- Count: *3 worries put away* (singular/plural correct)
- **No preview of the text.** Not truncated, not blurred, not in the DOM. If it isn't
  rendered it can't be peeked at via devtools or a screen reader.
- Consolation message: Briefly display a short, comforting message (e.g., "That's safely put away," or "It's okay to feel this way") immediately after a worry is added, before fading out.
- Secondary compact input: *Something else? Put it away too.*
- Tone is reassuring, never punitive. No "you can't open this yet."

### View: REVEAL

- Headline: *The box is open.*
- Sub: *Read these back. Many will feel smaller now.*
- List of unlocked worries. Each card shows the text, a relative capture time
  (*put away 6 hours ago*), and two buttons:
  - **Let go** — card dissolves and floats up, then is deleted
  - **Keep** — card settles and dims, archived
- When the list empties: *All clear.* plus a **Write a new worry** button back to CAPTURE.
- The reveal must read as neutral and reflective. No congratulation, no scoring, no
  "you worried 5 times today."

### Animations

| Name | Trigger | Spec |
|---|---|---|
| Drop | Submit | Text lifts from input, scales to 0.6, translates into the box. `--dur-base`, `--ease-out` |
| Seal | After drop | Lid rotates shut on its hinge, padlock scales 1.15 → 1 and settles. `--dur-seal`, `--ease-seal` |
| Unlock | Entering REVEAL | Padlock fades, lid swings open, cards stagger in 60ms apart |
| Release | "Let go" | Card fades to 0, translates up 24px, blurs 4px, then removed from DOM. `--dur-base` |

All animation is CSS transitions/keyframes. JavaScript only toggles classes and listens for
`transitionend` / `animationend`.

### Reduced motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

Every state change must still be fully correct with animations disabled. Never gate a state
transition on an animation callback alone — always have a timeout fallback.

---

## 8. Accessibility (required, not optional)

- Semantic HTML: one `<h1>`, real `<button>`, `<textarea>` with an associated `<label>`
- Visible focus rings — 2px `--accent` outline with 2px offset. Never `outline: none` alone
- Countdown lives in `aria-live="polite"`, but updates the announcement **only once a minute**
  so screen readers aren't flooded every second
- View changes move focus to the new view's heading (`tabindex="-1"`)
- "Let go" / "Keep" buttons have `aria-label` including the worry text for context
- Text contrast ≥ 4.5:1 against the gradient. `--text-muted` on `--surface` must be verified
- Full keyboard path: type → Tab → Enter to submit. `Ctrl/Cmd + Enter` submits from the textarea

---

## 9. Security

- **Never use `innerHTML` with user text.** Always `textContent`. This is the single most
  important rule in the codebase — worry text is user input rendered back to the DOM.
- No `eval`, no `new Function`, no inline event handlers in HTML.
- No network requests at all. A correct build makes zero fetches after the initial page load.
- Ship a strict CSP meta tag: `default-src 'self'` with no `unsafe-inline` for scripts.

---

## 10. Edge cases to handle explicitly

| Case | Required behavior |
|---|---|
| localStorage unavailable | App still runs in memory for the session. Show a one-line notice: *Your worries won't be saved after you close this tab.* Do not crash |
| Quota exceeded | Catch, keep the worry in memory, show a non-blocking notice |
| Worry captured after unlock hour | `unlockAt` rolls to tomorrow (§4). Never unlocks instantly |
| Tab backgrounded past unlock time | Re-derive state on `visibilitychange`, don't wait for the next tick |
| User changes device clock | Accept it. This is a self-help tool, not DRM. Do not fight the user |
| Multiple tabs open | Listen for the `storage` event and re-render. Last write wins |
| Empty / whitespace-only input | Button stays disabled. No error toast needed |
| Text over 280 chars | Hard-stop input at 280, counter turns `--accent` past 240 |
| Very long single word | `overflow-wrap: anywhere` on worry text so cards never blow out the layout |

---

## 11. Dev & testing shortcut

Time-locked behavior is untestable if you have to wait until 6pm. Support a URL override:

```
?devUnlockSeconds=10
```

When present, `addWorry` sets `unlockAt = Date.now() + (seconds * 1000)`. This must:

- be read from the query string only, never persisted to settings
- be a no-op in a production build (`import.meta.env.PROD`) unless the flag is present
- show a small `dev mode` badge in the corner whenever it is active, so it can't be shipped silently

---

## 12. Acceptance criteria

Ship when every line passes.

- [ ] **A1** Typing a worry and clicking *Put it away* clears the input, plays the drop + seal, and moves to LOCKED
- [ ] **A1.1** A short consolation message appears briefly upon moving to LOCKED, then fades away
- [ ] **A1.2** Clicking the "Play Calming Audio" button toggles the calming background song
- [ ] **A2** Reloading during LOCKED stays LOCKED with the countdown correct
- [ ] **A3** Worry text does not appear anywhere in the DOM while locked
- [ ] **A4** Countdown reaching zero transitions to REVEAL without a reload
- [ ] **A5** REVEAL lists every unlocked worry with correct relative capture times
- [ ] **A6** *Let go* animates the card away and it does not return after reload
- [ ] **A7** *Keep* archives the worry; it does not reappear in REVEAL after reload
- [ ] **A8** Emptying the list returns to CAPTURE
- [ ] **A9** A worry added at 11pm (unlock hour 18) unlocks at 6pm the following day
- [ ] **A10** A second worry added while locked joins the box without disturbing the countdown
- [ ] **A11** `?devUnlockSeconds=10` unlocks after 10 seconds and shows the dev badge
- [ ] **A12** Entering `<img src=x onerror=alert(1)>` as a worry renders as literal text
- [ ] **A13** Blocking localStorage (Safari private mode) shows the notice and does not crash
- [ ] **A14** Corrupt JSON in `worryBox_v1` recovers to a clean state and preserves a backup key
- [ ] **A15** Full flow completable with keyboard only, focus always visible
- [ ] **A16** `prefers-reduced-motion: reduce` completes every transition correctly
- [ ] **A17** Layout holds from 320px to 1440px wide with no horizontal scroll
- [ ] **A18** Zero network requests after initial load (verify in devtools)
- [ ] **A19** `npm run build` succeeds and `dist/` runs correctly via `npm run preview`

---

## 13. Build order

Build in this sequence — each step is independently verifiable:

1. `package.json`, Vite scaffold, `index.html` skeleton with all three views as static markup
2. `style.css` tokens, layout, glass surfaces, animated background
3. `storage.js` complete with corruption/quota handling — test it in the console alone
4. `state.js` derivation + `main.js` wiring, no animations yet. Prove the state machine works
5. The box illustration and the seal/unlock/release animations
6. Countdown, `visibilitychange`, and `storage` event handling
7. Accessibility pass (focus, aria-live, contrast, keyboard)
8. Walk the §12 checklist top to bottom

---

## 14. Copy reference

Keep the voice calm, plain, and short. Never clinical, never cute.

| Location | Text |
|---|---|
| Submit button | Put it away |
| Textarea placeholder | What's on your mind? |
| Capture helper | Opens at 6:00 PM |
| Locked headline | Your thoughts are safe. |
| Locked count | 3 worries put away |
| Locked sub-input | Something else? Put it away too. |
| Reveal headline | The box is open. |
| Reveal sub | Read these back. Many will feel smaller now. |
| Release button | Let go |
| Keep button | Keep |
| Empty reveal | All clear. |
| Storage warning | Your worries won't be saved after you close this tab. |

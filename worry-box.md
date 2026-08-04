# Worry Box

A digital mental health tool that helps people manage anxious, intrusive thoughts using a real, clinically-recognized CBT technique called "scheduled worry time."

## Problem

Worries pop into your head all day and won't leave you alone. Anxious thoughts tend to demand attention the moment they appear, pulling focus and often spiraling into rumination. Trying to simply "stop worrying" rarely works and can even make things worse.

## Solution

Worry Box lets you "lock away" a worry the moment it appears and only look at it again later, at a set time. This delays engagement with the thought (without suppressing it), which reduces its urgency in the moment and often makes it feel smaller or less important by the time you revisit it.

## The psychology behind it

This app is based on a real, established CBT technique called **scheduled worry time** (also called worry postponement):

- Instead of telling yourself "stop worrying" (which usually backfires), you tell yourself "not now — I'll worry about this later, at a specific time."
- Writing the worry down and putting it away signals to your brain that it no longer needs to actively hold onto it.
- By the time the scheduled worry period arrives, many worries have naturally lost urgency or relevance.
- Over time, this retrains the automatic "worry now" reflex into a "note it, delay it" reflex, reducing how often worry spirals hijack the day.

## Core user flow

1. **Capture** — A worry crosses your mind. Open the app, type it in one line (e.g. "What if I fail the exam"), and tap "Put it away."
2. **Release ritual** — The text visually drops into a box/jar on screen. A lid animates shut (CSS animation, optional lock icon or sound). This physical/visual act reinforces that the worry has been "handled" for now.
3. **Lock** — The box stays sealed and cannot be reopened until a set time (e.g. 6pm, or a short countdown for demo purposes). If the worry resurfaces mentally, the honest response is "it's already put away, I'll see it later."
4. **Reveal** — At the scheduled time, the box unlocks. All worries logged that day are shown in a list. Many will feel smaller or resolved by this point — this is the core therapeutic payoff, made visible to the user.
5. **(Optional) Let go or keep** — After reading, the user can clear the worry (a small "release" animation) or save it to a running log/history.

## Features (MVP scope)

- Text input + "Put it away" button
- Lid/box seal animation on submit (CSS transform)
- Locked state showing a countdown or "unlocks at [time]"
- Local storage of worry text + timestamp (no backend needed)
- Unlock view: list of the day's worries once the time threshold passes
- Optional: "let go" (clear) vs. "keep" (save to log) action after reveal
- Optional: simple history/log view across multiple days

## Why it works as a project

- **Not another mood tracker or dashboard** — the interaction itself (lock, wait, reveal) is the product, which is uncommon in the digital wellbeing space.
- **Grounded in real psychology** — based on an established CBT technique (scheduled worry time / worry postponement), giving it credibility beyond being a novelty.
- **Simple to build** — no AI, no APIs, no sensors, no backend. Just a text input, a timestamp check, and a CSS animation.
- **Strong demo narrative** — type a worry → seal it → (fast-forward) → reveal it. Easy to walk through in under a minute.

## Tech stack

- HTML/CSS/JavaScript (or a lightweight web app/PWA)
- LocalStorage for persisting worries and timestamps
- CSS transitions/animations for the seal and unlock visuals
- No external APIs, AI models, or backend required

## Target users

- Anyone experiencing everyday anxiety, intrusive thoughts, or rumination
- Students, office workers, or anyone under chronic stress
- People looking for a lightweight, non-clinical self-help tool grounded in real therapeutic technique

## Data and privacy

- All data (worry text, timestamps) can be stored entirely in the browser via localStorage
- No data leaves the device unless explicitly opted into cloud sync
- No sensitive data processing beyond what the user chooses to type

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Users may want to check the box before the unlock time out of anxiety | Keep the locked state calm and reassuring rather than punitive; reinforce that it's safe there |
| Tool could be seen as suppressing rather than delaying worry | Be clear in framing/copy that this is about delay, not suppression, consistent with the CBT technique |
| Worries might feel dismissed if not taken seriously at reveal | Reveal view should feel neutral and reflective, not minimizing |

## Elevator pitch

Worry Box is a "scheduled worry time" app: type out what's bothering you, seal it away, and only revisit it later — a simple, science-backed way to quiet anxious thoughts without needing to suppress or solve them right away.

# Architecture

Worry Box is a completely client-side Web Application (SPA).

## High-Level Architecture
1. **Presentation Layer (DOM):** HTML/CSS driven UI. Uses CSS variables for theming and CSS transitions for animations.
2. **Logic Layer (JavaScript):** Manages DOM state transitions between `Input View`, `Locked View`, and `Reveal View`.
3. **Data Layer (LocalStorage):** Acts as the persistence mechanism.

## Component Breakdown
- **App Container:** The main wrapper handling view switching.
- **Input Component:** Text input and submit button.
- **Animation Component:** The visual representation of the Box.
- **Reveal Component:** The list view generated when the unlock threshold is met.

## State Management
State is derived from the current time compared to the stored "unlock time."
- `isLocked = currentTime < unlockTime`

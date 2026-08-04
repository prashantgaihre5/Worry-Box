# Requirements Specification

## Functional Requirements
- **Capture:** Users can input a text string representing their worry.
- **Seal:** Upon submission, the worry is removed from the screen with a visual animation of a box closing.
- **Lock:** The app enters a locked state until a specified time (e.g., 6:00 PM daily).
- **Reveal:** Once the time passes, the box "unlocks," and users can view the list of worries captured that day.
- **Action:** Users can choose to "let go" (delete) or "keep" (archive) the revealed worries.

## Non-Functional Requirements
- **Privacy:** 100% local data storage. No backend database or tracking.
- **Performance:** Instant load times, smooth 60fps animations for the box seal/unlock.
- **Accessibility:** High contrast text, screen reader compatibility, and keyboard navigability.
- **Responsiveness:** Mobile-first design that scales gracefully to desktop.

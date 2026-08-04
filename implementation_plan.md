# Worry Box Implementation Plan

This document outlines the proposed implementation for the "Worry Box" web application, based on the provided specifications.

## Goal

Build a digital mental health tool to help users manage anxious thoughts using the CBT technique of "scheduled worry time." The app will allow users to log a worry, visually "seal" it in a box, and delay engagement until a scheduled unlock time.

## User Review Required

> [!IMPORTANT]
> Please review the proposed technology stack and design direction below. If you approve, click the **Proceed** button to begin execution.

## Open Questions

> [!WARNING]
> 1. **Framework:** I propose using **Vite + Vanilla JS** for the project setup. It provides a simple development server and modern JavaScript features without the overhead of a heavy framework like React. Is this acceptable, or would you prefer a simple `index.html` with no build tools, or a different framework?
> 2. **Unlock Time:** For the purpose of testing the app during development, how long should the "lock" duration be? (e.g., a short 10-second countdown for testing, or a customizable setting?)
> 3. **Design Aesthetic:** I plan to use a calm, premium aesthetic with smooth gradients, glassmorphism, and a modern font (like Inter or Outfit). Does this align with your vision?

## Proposed Changes

We will build the application entirely within the `F:\Worry Box` directory.

### Core Application Setup

#### [NEW] `index.html`
The main entry point containing the semantic HTML structure for the app (input view, locked view, unlocked view).

#### [NEW] `src/style.css`
Will contain all styling, adhering to modern design principles, including the lid/box seal CSS animations.

#### [NEW] `src/main.js`
The core application logic, handling state transitions (Capture -> Lock -> Reveal) and DOM manipulation.

#### [NEW] `src/storage.js`
A utility module for managing `localStorage` interactions (saving worries, checking unlock times).

#### [NEW] `package.json`
Configuration for Vite and project scripts.

## Verification Plan

### Automated Tests
We will not implement automated tests for this MVP unless requested.

### Manual Verification
1. Run the local development server using `npm run dev`.
2. Verify the visual design and responsiveness.
3. Test the core user flow: 
   - Add a worry.
   - Verify the box animation and locked state.
   - Wait for the unlock time (or use a test shortcut) and verify the worries are revealed correctly.
   - Test the "let go" and "keep" functionalities.

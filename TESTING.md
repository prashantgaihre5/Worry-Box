# Testing Strategy

## Manual Testing Flows
Since the application relies heavily on time-based states and visual animations, manual testing is the primary QA method for the MVP.

### Scenario 1: Capturing a Worry
1. Load the app.
2. Enter "Test Worry" into the input.
3. Click "Put it away".
4. **Expected:** Input clears, animation plays, app enters Locked state.

### Scenario 2: Time Lock Check
1. Set unlock time to 1 minute in the future.
2. Refresh the page.
3. **Expected:** App remains in Locked state.

### Scenario 3: Reveal
1. Manually alter `localStorage` or wait for the unlock time to pass.
2. Refresh the page.
3. **Expected:** App enters Reveal state, displaying "Test Worry".

## Future Automation
In later versions, we will implement:
- **Unit Tests (Vitest):** To test the `StorageController` logic independently.
- **E2E Tests (Cypress/Playwright):** To mock the system clock and test the Lock/Reveal transitions automatically.

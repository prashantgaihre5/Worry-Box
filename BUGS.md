# Bugs and Known Issues

This file tracks current known issues and provides a template for reporting new ones.

## Known Issues
- **Timezone edge cases:** If a user travels across timezones while a worry is locked, the unlock time may trigger earlier or later than expected relative to their local time.
- **Storage Limits:** `localStorage` has a ~5MB limit. While text takes up very little space, years of usage without clearing the archive could theoretically hit this limit.

## Reporting a Bug
Please open a GitHub Issue using the following format:

```markdown
**Description:**
A clear description of the bug.

**Steps to Reproduce:**
1. Go to '...'
2. Type '...'
3. Click '...'

**Expected Behavior:**
What should have happened.

**Environment:**
- Device: [e.g. iPhone 12]
- Browser: [e.g. Safari 15]
```

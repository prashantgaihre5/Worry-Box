# Coding Standards

To ensure consistency and quality across the codebase, please adhere to the following standards.

## JavaScript
- Use **ES6+ syntax** (`let`, `const`, arrow functions, destructuring).
- Avoid global variables. Encapsulate logic within modules or classes.
- Use strictly equal (`===`) instead of loosely equal (`==`).
- Use descriptive variable names (`unlockTime` instead of `ut`).

## CSS
- Use **CSS Variables** (`--primary-color`) for all colors, spacing, and typography to maintain a consistent design system.
- Use BEM (Block Element Modifier) methodology for class naming (e.g., `box__lid--locked`).
- Prefer CSS transitions and keyframes over JavaScript-based animations for performance.

## Formatting
- Use **Prettier** with the default configuration.
- 2 spaces for indentation.
- Single quotes for JavaScript strings.
- Semicolons are required.

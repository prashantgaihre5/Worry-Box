# Security Policy

## Data Privacy
Worry Box is designed with absolute privacy in mind.
- **Zero Data Collection:** No analytics, no tracking pixels, no crashlytics.
- **Local Storage Only:** All user inputs are saved exclusively in the browser's `localStorage`. The data never leaves the user's device.

## Threat Model
Since there is no backend, traditional threats like SQL Injection or Server-Side Request Forgery are inapplicable. 

### Cross-Site Scripting (XSS)
Even though data is local, the app must sanitize user input before rendering it to the DOM to prevent local XSS attacks.
- **Mitigation:** Never use `innerHTML` when displaying user worries. Always use `textContent` or `innerText` to ensure browser rendering engines treat the input as a string, not executable HTML/JS.

## Vulnerability Reporting
If you discover a security issue, please open an issue on GitHub.

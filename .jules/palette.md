## 2025-05-10 - Terminal CLI Output Accessibility (WCAG 1.4.1)
**Learning:** Relying solely on ANSI color codes for terminal log status (e.g. green for success, yellow for warning, red for error) violates WCAG 1.4.1 (Use of Color) and makes status indistinguishable for colorblind users or environments stripping color escape codes.
**Action:** Always pair ANSI color formatting with explicit status symbols or text tags (e.g. `[spawn] ✓`, `[spawn] ⚠`, `[spawn] ✖`) in CLI output helpers.

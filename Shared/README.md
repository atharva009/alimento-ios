# Shared

Reusable types and utilities used across the app.

## Errors vs ErrorHandling

- **`Errors/`** — **Domain and API error types** (thrown and handled in code):
  - `AIError` — AI/Gemini and network failures (missing key, rate limit, malformed response, etc.).
  - `DomainError` — Business rules and persistence (validation, invalid location, grocery list not found, etc.).
  - Use these when throwing or switching on error kinds in services and view models.

- **`ErrorHandling/`** — **UI presentation of errors** (what the user sees):
  - `AppAlert` — Model for showing an alert (title, message, retry/OK actions). Use `.appAlert($alert)` and `AppAlert.from(error)` or `AppAlert.withRetry(...)` in views.
  - `ErrorMapper` — Maps any `Error` to a user-friendly message and whether it’s recoverable (for retry). Used by `AppAlert` and views.
  - Use these when presenting errors in SwiftUI (alerts, toasts).

Summary: **Errors** = what went wrong in the domain/API; **ErrorHandling** = how we show it in the UI.

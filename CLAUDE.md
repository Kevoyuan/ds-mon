# ds-mon Development Guide

## Build and Run
- Build: `swift build`
- Run: `swift run ds-mon`
- Test: `swift test`

## Project Structure
- `Sources/ds-mon/Views`: SwiftUI views.
- `Sources/ds-mon/ViewModels`: Observation-based view models.
- `Sources/ds-mon/Services`: API clients and Keychain management.
- `Sources/ds-mon/Models`: Data structures and codable types.

## Tech Stack
- Swift 6.0
- SwiftUI
- macOS 14+

## Security
- API keys are stored in the macOS Keychain.
- Use `SecureField` for all sensitive inputs.

## Skill Routing
- Use `@[/cso]` for security audits.
- Use `@[/ux-psychology]` for UI/UX reviews.

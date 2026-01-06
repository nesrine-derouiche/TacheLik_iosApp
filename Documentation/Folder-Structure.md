# Folder Structure

This document explains the purpose of each major folder and what belongs inside it.

> The iOS code lives under `TacheLik_iosApp/projectDAM/`.

---

## Top-Level (TacheLik_iosApp)

### `projectDAM/`

Main application target.

### `projectDAMTests/`

XCTest target (unit tests and lightweight smoke tests).

### `Config.xcconfig`

Tracked configuration values (default base URL, feature flags).

### `Config.local.xcconfig`

Local machine overrides.

- Intended for developer-specific settings
- Should not be committed

See: [Environment-Configuration.md](Environment-Configuration.md)

---

## Application Folder (projectDAM)

### `projectDAMApp.swift`

App entry point.

Contains:

- Portrait lock (AppDelegate adapter)
- Global navigation appearance
- Root routing (`RootView`)
- Splash screen display

### `DI/`

Dependency injection container.

What belongs here:

- `DIContainer.swift`

Naming:

- `*Container`, `*Factory`, `*Assembly` patterns are acceptable

### `Config/`

Application configuration helpers.

Example:

- `AppConfig.swift` (reads values from Info.plist)

### `Services/`

Networking and feature API clients.

What belongs here:

- `NetworkService.swift` and request helpers
- Feature services: `AuthService`, `CourseService`, `QuizService`, etc.
- Realtime: `SocketService`
- Cross-cutting runtime services: `SessionManager`, `RoleManager`, `NetworkMonitor`

Naming conventions:

- `XxxService.swift` for feature APIs
- `XxxManager.swift` for runtime coordination
- Protocols: `XxxServiceProtocol`

### `ViewModels/`

State containers for screens.

What belongs here:

- `LoginViewModel.swift`
- `HomeViewModel.swift`
- `ChatViewModel.swift`

Naming:

- `XxxViewModel.swift`

### `Views/`

SwiftUI screens and components.

Recommended structure:

- Feature folders: `Auth/`, `Main/`, `Chat/`, etc.
- Shared components: `Components/` or `Shared/`

Naming:

- `XxxView.swift`
- Smaller components can be grouped, but avoid “mega files” when possible.

### `Models/`

Data models.

What belongs here:

- API payloads: requests and responses
- Domain entities used throughout the app

Naming:

- `User.swift`, `Course.swift`, `Message.swift`

### `Theme/`

Centralized theme and appearance integration.

Example:

- `AppColors.swift` (dynamic colors)
- `AppAppearance.swift` (navigation styling)

### `Utilities/` and `Utils/`

General helpers.

Rule:

- If a helper becomes domain-specific, move it to its feature folder.

### `Assets.xcassets/`

Images, app icons, colorsets.

### `projectDAM.xcdatamodeld/`

Core Data model definition.

---

## Practical Examples

- Add a new API client:
  - `projectDAM/Services/PaymentsService.swift`
  - protocol: `PaymentsServiceProtocol`
- Add a new screen:
  - `projectDAM/Views/Main/PaymentsView.swift`
  - `projectDAM/ViewModels/PaymentsViewModel.swift`

---

## Common Mistakes to Avoid

- Putting endpoint strings in Views
- Putting navigation appearance tweaks inside feature Views
- Storing tokens in multiple locations

See: [Coding-Guidelines.md](Coding-Guidelines.md)

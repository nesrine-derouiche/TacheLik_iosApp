# Coding Guidelines

This document defines project-level coding standards aligned with Apple best practices.

---

## Swift Naming Conventions

- Types: `UpperCamelCase` (e.g., `HomeViewModel`)
- Methods/variables: `lowerCamelCase` (e.g., `fetchCourses()`)
- Protocols:
  - Prefer `XxxProtocol` (e.g., `AuthServiceProtocol`)

---

## File Organization

Recommended per file:

1. Imports
2. Type declaration
3. MARK sections in this order:
   - Properties
   - Initialization
   - Public API
   - Private helpers

---

## SwiftUI Best Practices

- Keep `View.body` declarative and readable.
- Avoid side-effects in `body`.
- Prefer `@StateObject` for owned ViewModels.
- Use `.task` or explicit `Task {}` for async operations.

---

## MVVM Boundaries

**Views**

- UI only
- navigation UI only

**ViewModels**

- state + orchestration
- input validation
- error mapping

**Services**

- API endpoints + request building
- decoding

See: [Architecture.md](Architecture.md)

---

## Dependency Injection Rules

- ViewModels should receive dependencies through initializers.
- Use `DIContainer` factory methods for ViewModel creation.
- Avoid creating services directly inside Views.

---

## Error Handling Rules

- Do not show raw `error.localizedDescription` to users without review.
- Map errors into friendly copy.

See: [Error-Handling.md](Error-Handling.md)

---

## Commenting Rules

- Prefer self-documenting code.
- Add comments when code is non-obvious or when there is a trade-off.

Avoid:

- obvious comments that restate the code

---

## Do’s & Don’ts

Do:

- Keep endpoints inside Services
- Use DS tokens for spacing and radius
- Write tests for ViewModels

Don’t:

- Store secrets in UserDefaults in production
- Duplicate UI styling rules across screens
- Add global singletons beyond the DI container

---

## Formatting

- Use Xcode default formatting.
- Keep lines readable.
- Prefer explicit types in APIs when it improves clarity.

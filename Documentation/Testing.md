# Testing

This project includes a dedicated test target: `projectDAMTests`.

---

## Testing Philosophy

- Test ViewModels and pure logic first (fast, stable tests).
- Keep UI tests for critical end-to-end flows only.
- Prefer dependency injection and protocols to enable mocking.

---

## What Exists Today

Examples in `projectDAMTests`:

- `SmokeTests`: validates dynamic colors resolve correctly.
- `ValidatorsTests`: tests input validation rules.
- `WalletViewModelTests`: tests ViewModel behavior using mocked services.

This provides a solid foundation for a product-ready test suite.

---

## Unit Tests

### What to unit test

- Validation logic (`Validators`)
- ViewModels (loading, pagination, error mapping)
- Cache stores (serialization + read/write)

### Patterns used in this project

- Mock services implementing `*ServiceProtocol`
- `@MainActor` tests for ViewModels that publish UI state

---

## UI Tests (Recommended)

If you add UI tests, focus on:

- Login success/failure
- Session termination handling
- Basic tab navigation by role

---

## Test Folder Structure

```text
projectDAMTests/
  SmokeTests.swift
  ValidatorsTests.swift
  WalletViewModelTests.swift
```

Recommended growth pattern:

```text
projectDAMTests/
  Helpers/
  Mocks/
  ViewModels/
  Services/
```

---

## Running Tests

In Xcode:

- Product → Test (⌘U)

In CI (recommended):

- `xcodebuild test` against a simulator destination

---

## Coverage Guidelines

- Target: cover ViewModel logic and validators first.
- Avoid chasing 100% coverage if it reduces test quality.

---

## Diagram: Test Pyramid

```text
        UI Tests (few)
     ─────────────────
     Integration (some)
  ───────────────────────
       Unit (many)
```

---

## When Adding New Features

Minimum expectation:

- At least one ViewModel test for success path
- At least one test for error path
- Validators tested if inputs are introduced

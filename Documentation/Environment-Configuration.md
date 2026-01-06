# Environment Configuration

This project uses **xcconfig files** and **Info.plist variable substitution** to manage environment-specific values.

---

## Files

- `Config.xcconfig` (tracked)
- `Config.local.xcconfig` (local overrides; should not be committed)
- `projectDAM/Info.plist` (reads variables)

---

## How It Works

1. Xcode build settings include xcconfig(s).
2. Values are substituted into `Info.plist` using `$(VARIABLE_NAME)`.
3. Runtime code reads values from `Bundle.main`.

Example in `Info.plist`:

- `API_BASE_URL` = `$(API_BASE_URL)`

Runtime code reads it via:

- `Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL")`

---

## Variables

### `API_BASE_URL`

Base URL for the backend API.

Examples:

- Simulator: `http://127.0.0.1:3001/api`
- Remote dev: `https://dev.api.tache-lik.tn/api`

Notes:

- When testing on a physical device, `localhost` points to the device, not your Mac.
- Use your Mac’s LAN IP for device testing.

### `USE_MOCK_DATA`

Feature flag for mock data.

- `true` → app may switch to mock services (if implemented)
- `false` → real services

---

## Recommended Workflow

1. Keep `Config.xcconfig` pointing to the shared dev/staging environment.
2. Each developer uses `Config.local.xcconfig` for local testing.
3. CI uses an explicit config for consistency.

---

## Socket URL

Socket URL is derived from API base URL:

- If `API_BASE_URL` ends with `/api`, the socket URL removes that suffix.

This logic lives in `AppConfig.socketURL`.

---

## ATS (App Transport Security)

`Info.plist` currently allows arbitrary loads.

Product guideline:

- Use HTTPS endpoints and tighten ATS for Release.

See: [Security.md](Security.md)

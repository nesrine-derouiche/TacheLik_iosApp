# Changing the Base URL Configuration

## Quick Guide

The iOS app uses **Xcode Configuration Files (.xcconfig)** to manage the API base URL.

## How It Works

```
Config.xcconfig → Info.plist → AppConfig.swift → Your Code
```

## Change the URL (2 Methods)

### Method 1: Local Override (Recommended)

Create `Config.local.xcconfig` in the project root:

```bash
cd /Users/mac/Projects/Tache-lik-dev/TacheLik_iosApp
nano Config.local.xcconfig
```

Add your URL:
```
API_BASE_URL = http://YOUR_IP:3001/api
USE_MOCK_DATA = false
```

**Benefits**: Not committed to Git, personal settings only.

### Method 2: Edit Default Config

Edit `Config.xcconfig` line 5:
```
API_BASE_URL = http://YOUR_NEW_URL:3001/api
```

**Note**: This affects all developers (committed to Git).

## Common URLs

| Environment | URL |
|-------------|-----|
| **Simulator** | `http://127.0.0.1:3001/api` |
| **Physical Device** | `http://192.168.1.XXX:3001/api` |
| **Production** | `https://api.yourdomain.com` |

## Find Your Mac's IP

```bash
ipconfig getifaddr en0  # WiFi
ipconfig getifaddr en1  # Ethernet
```

## After Changing

1. Clean build: `Cmd + Shift + K`
2. Rebuild: `Cmd + B`
3. Run app

## Verify Configuration

Add this to your code:
```swift
AppConfig.printConfiguration()
```

## Troubleshooting

**Can't connect on physical device?**
- Use your Mac's IP (not 127.0.0.1)
- Ensure same WiFi network
- Check backend is running

**Config not updating?**
- Clean build folder
- Delete derived data
- Restart Xcode

## Files

- `Config.xcconfig` - Default config (committed)
- `Config.local.xcconfig` - Your overrides (gitignored)
- `AppConfig.swift` - Reads configuration
- `Info.plist` - Receives build-time values

## Security

⚠️ Never commit `Config.local.xcconfig` or API keys to Git.

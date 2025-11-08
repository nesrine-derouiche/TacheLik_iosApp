# Configuration Setup Guide

This guide explains how to configure the iOS app for different environments.

## Quick Start

### 1. Create Local Configuration

Copy the example configuration file:
```bash
cp Config.local.xcconfig.example Config.local.xcconfig
```

Or create `Config.local.xcconfig` manually with:
```
API_BASE_URL = http:/$()/127.0.0.1:3001/api
USE_MOCK_DATA = false
```

### 2. Update Info.plist

The configuration values from `.xcconfig` files need to be added to `Info.plist`:

1. Open `projectDAM/Info.plist`
2. Add the following keys:
   - `API_BASE_URL` with value `$(API_BASE_URL)`
   - `USE_MOCK_DATA` with value `$(USE_MOCK_DATA)`

Or add this XML to your Info.plist:
```xml
<key>API_BASE_URL</key>
<string>$(API_BASE_URL)</string>
<key>USE_MOCK_DATA</key>
<string>$(USE_MOCK_DATA)</string>
```

### 3. Link Configuration to Xcode Project

1. Open your project in Xcode
2. Select the project in the navigator
3. Select your target (projectDAM)
4. Go to "Build Settings"
5. Search for "Configuration"
6. Under "Info" section, set the configuration file for Debug and Release builds

## Configuration Files

### `Config.xcconfig`
- **Purpose**: Default configuration for all developers
- **Committed to Git**: ✅ Yes
- **Contains**: Safe default values

### `Config.local.xcconfig`
- **Purpose**: Your personal local configuration
- **Committed to Git**: ❌ No (in .gitignore)
- **Contains**: Your specific settings (local IP, custom URLs, etc.)

## Environment-Specific Settings

### Development (Simulator)
```
API_BASE_URL = http:/$()/127.0.0.1:3001/api
```

### Development (Physical Device)
Replace `127.0.0.1` with your Mac's local IP address:
```
API_BASE_URL = http:/$()/192.168.1.100:3001/api
```

To find your Mac's IP:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

### Production
Update the base URL to your production API:
```
API_BASE_URL = https:/$()/api.yourdomain.com
```

## Using Configuration in Code

The `AppConfig` struct provides access to all configuration values:

```swift
// Get base URL
let baseURL = AppConfig.baseURL

// Check environment
if AppConfig.isDebug {
    print("Running in debug mode")
}

// Get app version
let version = AppConfig.appVersion

// Print all configuration
AppConfig.printConfiguration()
```

## Available Configuration Options

| Key | Type | Description | Default |
|-----|------|-------------|---------|
| `API_BASE_URL` | String | Backend API base URL | `http://127.0.0.1:3001/api` |
| `USE_MOCK_DATA` | Boolean | Use mock data instead of real API | `false` |

## Troubleshooting

### "Could not connect to the server"
- **On Simulator**: Use `127.0.0.1` or `localhost`
- **On Physical Device**: Use your Mac's local IP address
- Ensure your backend is running on the specified port
- Check that App Transport Security allows HTTP connections (already configured)

### Configuration not updating
1. Clean build folder: `Cmd + Shift + K`
2. Delete derived data
3. Rebuild the project

### Finding your Mac's IP address
```bash
# macOS
ipconfig getifaddr en0  # WiFi
ipconfig getifaddr en1  # Ethernet
```

## Security Notes

⚠️ **Important**: 
- Never commit `Config.local.xcconfig` to Git
- Never hardcode API keys or secrets in the code
- Use environment-specific configuration files for sensitive data
- For production, use HTTPS and proper certificate validation

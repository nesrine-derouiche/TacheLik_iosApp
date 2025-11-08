# iOS App Setup Instructions

## 🚀 Quick Setup (5 minutes)

### Step 1: Link Configuration Files to Xcode

1. **Open the project in Xcode**
   ```bash
   open projectDAM.xcodeproj
   ```

2. **Add configuration files to the project:**
   - In Xcode, select the project in the navigator (blue icon at the top)
   - Select the **projectDAM** target
   - Go to the **Info** tab
   - Under **Configurations**, you'll see Debug and Release

3. **Set the configuration file:**
   - For **Debug**: Click on the dropdown and select `Config.xcconfig`
   - For **Release**: Click on the dropdown and select `Config.xcconfig`
   
   If `Config.xcconfig` doesn't appear in the list:
   - Click the "+" button at the bottom
   - Select "Add Other..."
   - Navigate to and select `Config.xcconfig`

### Step 2: Add AppConfig.swift to Xcode

1. In Xcode, right-click on the `projectDAM` folder
2. Select "Add Files to projectDAM..."
3. Navigate to `projectDAM/Config/AppConfig.swift`
4. Make sure "Copy items if needed" is checked
5. Click "Add"

### Step 3: Configure for Your Environment

**For Simulator (default):**
- No changes needed! Uses `127.0.0.1:3001`

**For Physical Device:**
1. Find your Mac's IP address:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   
2. Create `Config.local.xcconfig`:
   ```bash
   cd /Users/mac/Projects/Tache-lik-dev/TacheLik_iosApp
   cp Config.local.xcconfig Config.local.xcconfig
   ```
   
3. Edit `Config.local.xcconfig` and replace with your IP:
   ```
   API_BASE_URL = http:/$()/192.168.1.XXX:3001/api
   ```

4. In Xcode, set `Config.local.xcconfig` for Debug configuration

### Step 4: Build and Run

1. Clean build folder: `Cmd + Shift + K`
2. Build: `Cmd + B`
3. Run: `Cmd + R`

You should see the configuration printed in the console:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 App Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Environment: DEBUG
Base URL: http://127.0.0.1:3001/api
Version: 1.0.0 (1)
Mock Data: Disabled
Logging: Enabled
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 📁 Files Created

```
TacheLik_iosApp/
├── Config.xcconfig                      # Default config (committed to Git)
├── Config.local.xcconfig                # Your local config (NOT in Git)
├── .gitignore                           # Ignores local config files
├── README_CONFIG.md                     # Detailed configuration guide
├── SETUP_INSTRUCTIONS.md                # This file
└── projectDAM/
    └── Config/
        └── AppConfig.swift              # Configuration manager
```

## 🔧 Configuration Options

Edit `Config.xcconfig` or `Config.local.xcconfig`:

```
// API Configuration
API_BASE_URL = http:/$()/127.0.0.1:3001/api

// Feature Flags
USE_MOCK_DATA = false
```

## ⚠️ Troubleshooting

### "Could not connect to the server"
- ✅ Ensure backend is running: `cd tache-lik.tn-back-end-typescript-dev && npm run dev`
- ✅ Check the base URL in console output matches your backend
- ✅ For physical device, use your Mac's IP, not 127.0.0.1

### Configuration not updating
1. Clean build: `Cmd + Shift + K`
2. Delete derived data: `Cmd + Option + Shift + K`
3. Restart Xcode

### AppConfig not found
- Make sure `AppConfig.swift` is added to the Xcode project
- Check it's in the target membership (right panel in Xcode)

## 📝 Notes

- `Config.local.xcconfig` is in `.gitignore` - safe for your personal settings
- Configuration is printed on app launch in debug mode
- For production, update `API_BASE_URL` to your production server

## 🎯 Next Steps

1. Start your backend server
2. Run the iOS app
3. Try logging in!

For more details, see `README_CONFIG.md`

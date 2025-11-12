# 🔤 Adding Nunito Fonts to Xcode Project - Step by Step

## Quick Start

Follow these steps to add the Nunito fonts to make the splash screen look perfect.

---

## Step 1: Download Nunito Fonts

### Option A: Google Fonts (Recommended)
1. Visit: https://fonts.google.com/specimen/Nunito
2. Click the download icon (↓) in top right
3. You'll get a ZIP file with all Nunito variants

### Option B: Direct Download
Download directly:
- **Nunito-Bold.ttf** - For splash screen text
- **Nunito-SemiBold.ttf** - For secondary text
- **Nunito-Regular.ttf** - For body text

### File Names Expected
```
Nunito-Bold.ttf
Nunito-SemiBold.ttf
Nunito-Regular.ttf
```

---

## Step 2: Add Fonts to Xcode Project

### 2A: In Xcode (Recommended Method)

1. **Open your project** in Xcode
   ```
   TacheLik_iosApp.xcodeproj
   ```

2. **Create a Fonts folder** (optional but organized)
   - Right-click on project folder
   - Select: New Group
   - Name: "Fonts"
   - Press Enter

3. **Add font files**
   - Open Finder
   - Locate your downloaded .ttf files
   - Drag and drop them into the Fonts folder in Xcode

4. **Import Settings Dialog**
   When prompted:
   - ✅ Check "Copy items if needed"
   - ✅ Select target: projectDAM
   - Click "Finish"

### 2B: Manual File Manager Method

1. Locate your project folder:
   ```
   ~/Documents/esprit/4sim1/DAM/project/TacheLik_iosApp/projectDAM/
   ```

2. Create a new folder:
   ```
   mkdir Fonts
   ```

3. Copy .ttf files into it:
   ```
   cp ~/Downloads/Nunito-*.ttf Fonts/
   ```

4. In Xcode, drag the Fonts folder into project

---

## Step 3: Verify in Build Phases

1. **Select your project** in Xcode
2. **Select target**: projectDAM
3. **Go to Build Phases** tab
4. **Expand**: Copy Bundle Resources
5. **Verify** all .ttf files are listed:
   - ✅ Nunito-Bold.ttf
   - ✅ Nunito-SemiBold.ttf
   - ✅ Nunito-Regular.ttf

### If files are NOT listed:
1. Click "+" button
2. Select the .ttf files
3. Make sure target "projectDAM" is checked
4. Click "Add"

---

## Step 4: Verify Info.plist

The Info.plist should already have this section:

```xml
<key>UIAppFonts</key>
<array>
    <string>Nunito-Bold.ttf</string>
    <string>Nunito-SemiBold.ttf</string>
    <string>Nunito-Regular.ttf</string>
</array>
```

**Status**: ✅ Already added!

---

## Step 5: Test Font Installation

### Method 1: Run the App
1. Build and run the project
2. Watch the splash screen
3. Check if "Tache-lik" text appears in **Nunito-Bold** (not system font)

### Method 2: Debug Print (Advanced)
Add this to check available fonts:

```swift
import SwiftUI

struct DebugFontsView: View {
    var body: some View {
        VStack {
            Text("Available Fonts:")
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(UIFont.familyNames, id: \.self) { family in
                        Text(family)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
    }
}

// Add to preview or temp view
#Preview {
    DebugFontsView()
}
```

Look for "Nunito" in the list of family names.

---

## Step 6: Troubleshooting

### Problem: Font Not Loading (Text looks like system font)

**Cause 1: Files not in Copy Bundle Resources**
- Solution: Add to Build Phases as shown in Step 3

**Cause 2: Incorrect font names**
- Solution: Verify exact filenames in Info.plist match .ttf files
- Compare: `Nunito-Bold.ttf` vs what's in Info.plist

**Cause 3: Font file corrupted**
- Solution: Re-download from Google Fonts

**Cause 4: Xcode cache**
- Solution:
  ```bash
  # Clean build folder
  Cmd + Shift + K
  # Clean derived data
  rm -rf ~/Library/Developer/Xcode/DerivedData/*
  # Restart Xcode
  ```

### Problem: File not recognized

**Solution:**
1. Verify file is actually a .ttf file
2. Try renaming: `mv "Nunito Bold.ttf" "Nunito-Bold.ttf"`
3. Ensure no special characters in filename

### Problem: App crashes when loading splash

**Solution:**
1. Make sure "tache_lik_logo" image asset exists
2. Check image name in Assets.xcassets
3. Fallback to system font by removing `.font(.custom(...))`

---

## Verification Checklist

- [ ] Downloaded Nunito-Bold.ttf
- [ ] Downloaded Nunito-SemiBold.ttf
- [ ] Downloaded Nunito-Regular.ttf
- [ ] Added files to Xcode project (Fonts folder)
- [ ] Files appear in Build Phases → Copy Bundle Resources
- [ ] Info.plist has UIAppFonts array with all 3 fonts
- [ ] Built and ran the app successfully
- [ ] Splash screen text displays in Nunito-Bold font
- [ ] No console errors about missing fonts
- [ ] Animation completes smoothly

---

## File Structure After Setup

```
projectDAM/
├── Fonts/                          ← NEW
│   ├── Nunito-Bold.ttf            ← NEW
│   ├── Nunito-SemiBold.ttf        ← NEW
│   └── Nunito-Regular.ttf         ← NEW
├── Views/
│   ├── SplashView.swift           ← UPDATED
│   └── ...
├── projectDAMApp.swift             ← UPDATED
└── Info.plist                       ← UPDATED
```

---

## Before vs After

### Before (Without Fonts)
```
Splash appears with:
- Logo animation ✅
- Text in system font ❌
- No Nunito-Bold styling
```

### After (With Fonts)
```
Splash appears with:
- Logo animation ✅
- Text in Nunito-Bold font ✅
- Professional branding ✅
```

---

## Common Font Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Text looks thin/light | System font fallback | Add fonts to Build Phases |
| Text looks different | Font name mismatch | Verify Info.plist font names |
| Can't find files | Wrong directory | Check ~/Downloads or source |
| Build fails | Corrupt .ttf file | Re-download from Google Fonts |
| Font in preview but not device | Caching issue | Clean build folder (Cmd+Shift+K) |

---

## Alternative: Using System Fonts Only

If you prefer not to add custom fonts, you can modify `SplashView.swift`:

Change this:
```swift
.font(.custom("Nunito-Bold", size: 70))
```

To this:
```swift
.font(.system(size: 70, weight: .bold))
```

This will use the system's default bold font instead of Nunito.

---

## Summary

✅ **Step 1**: Download Nunito fonts from Google Fonts
✅ **Step 2**: Add .ttf files to Xcode project
✅ **Step 3**: Verify in Build Phases
✅ **Step 4**: Confirm Info.plist configuration (already done)
✅ **Step 5**: Test by running app
✅ **Step 6**: Troubleshoot if needed

---

## Getting Help

If fonts still don't work:

1. Check Xcode console for font loading errors
2. Verify filenames exactly match Info.plist entries
3. Try cleaning build folder: `Cmd + Shift + K`
4. Restart Xcode completely
5. Rebuild project from scratch

---

## Next Steps

1. ✅ Download fonts
2. ✅ Add to Xcode
3. ✅ Verify configuration
4. ✅ Test the app
5. ✅ Enjoy your professional splash screen! 🎉

---

**Font Setup Guide Complete!** 

Your splash screen is ready to display with beautiful Nunito-Bold typography. 🎨

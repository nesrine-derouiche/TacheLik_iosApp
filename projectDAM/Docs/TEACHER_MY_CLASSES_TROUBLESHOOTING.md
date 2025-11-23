# Teacher My Classes - Troubleshooting Guide

**Last Updated:** November 23, 2025

## 🚨 Common Issues and Solutions

### Issue 1: "Network error occurred" or "Unable to connect to server"

**Symptoms:**
- Error screen appears immediately after loading
- Message: "Network error occurred" or "Unable to connect to server"
- iOS shows network error icon

**Causes & Solutions:**

#### A. Backend Server Not Running
**Check:**
```bash
# In backend directory
cd /Users/macbookm4pro/Documents/ESPRIT/projet/tache-lik.tn-back-end-typescript-dev
npm run dev
```

**Expected Output:**
```
Server is running on port 3001
Database connected successfully
```

**Fix:** Start the backend server before testing iOS app

---

#### B. Wrong Base URL Configuration
**Check:**
```swift
// In AppConfig.swift, verify baseURL
print(AppConfig.baseURL)  // Should print: http://127.0.0.1:3001/api
```

**Common Issues:**
- ❌ `http://localhost:3001/api` (use 127.0.0.1 instead)
- ❌ `http://192.168.x.x:3001/api` (only works on real device with correct IP)
- ❌ Missing `/api` suffix
- ❌ Wrong port number

**Fix:**
```swift
// For iOS Simulator (default)
"http://127.0.0.1:3001/api"

// For Real Device (replace with your computer's IP)
"http://192.168.1.100:3001/api"
```

---

#### C. iOS App Transport Security (ATS) Blocking HTTP
**Check Info.plist:**
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Fix:** Already configured ✅

---

#### D. Teacher Not Authenticated
**Check:**
```swift
// In Xcode console, look for:
"❌ [TeacherCoursesService] No auth token available"
```

**Fix:** 
1. Log out completely
2. Log back in with teacher credentials
3. Ensure `mentor` role is set in backend

---

#### E. Database Has No Courses
**Check:**
```sql
-- In PostgreSQL
SELECT * FROM courses WHERE author_id = 'YOUR_TEACHER_ID';
```

**Expected:** Should return at least one course

**Fix:** Create a test course in database or via admin panel

---

### Issue 2: "Failed to decode response"

**Symptoms:**
- Backend responds but iOS can't parse the data
- Console shows decoding errors

**Causes & Solutions:**

#### A. API Response Structure Mismatch
**Check Console:**
```
❌ [NetworkService] Response JSON: {...}
❌ Missing key: XXX
```

**Fix:** Compare actual JSON with Swift models

**Expected Response:**
```json
{
  "classesWithCourses": [
    {
      "class": {
        "id": "string",
        "title": "string",
        "description": "string?",
        "image": "string?",
        "class_order": "string?",
        "filter_name": { "filter_name": "string" },
        "created_at": "string",
        "updated_at": "string"
      },
      "courses": [...]
    }
  ],
  "success": true
}
```

---

#### B. Missing Fields in Database
**Check:**
- Courses table has all required fields
- Classes table has filter_name relation
- author_id foreign key is valid

---

### Issue 3: "Session expired. Please login again."

**Symptoms:**
- 401 Unauthorized error
- Happens immediately on load

**Causes & Solutions:**

#### A. JWT Token Expired
**Fix:** 
1. Log out
2. Log in again
3. Try loading classes

#### B. Token Not Saved
**Check:**
```swift
// In AuthService
guard let token = authService.getAuthToken() else {
    print("No token found")
}
```

**Fix:** Ensure login saves token properly

---

### Issue 4: Empty State Shows (But Teacher Has Courses)

**Symptoms:**
- Empty state UI appears
- Backend has courses for this teacher
- No errors shown

**Causes & Solutions:**

#### A. Wrong Teacher ID
**Check Console:**
```
Backend returned courses for teacher: XXXX
Current logged-in user ID: YYYY
```

**Fix:** Ensure logged-in user's ID matches course author_id

#### B. Courses Not Approved
**Check:**
- Only approved courses show (approval_status = 'approved')
- Teacher role can see pending courses too

**Fix:** Approve courses in admin panel or check filters

---

## 🔍 Debugging Steps

### Step 1: Enable Detailed Logging

**In AppConfig.swift:**
```swift
static var enableLogging: Bool { return true }
```

**Expected Console Output:**
```
📡 [TeacherCoursesService] Fetching my courses from: http://127.0.0.1:3001/api/course/my-courses
📡 [TeacherCoursesService] Token prefix: eyJhbGciOiJIUzI1NiIs...
📡 [NetworkService] Response status: 200 for /course/my-courses
✅ [TeacherCoursesService] Received 2 classes with courses
✅ [TeacherMyClassesViewModel] Loaded 2 classes successfully
```

---

### Step 2: Test Backend Directly

**Using curl:**
```bash
# Replace TOKEN with your actual JWT token
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://127.0.0.1:3001/api/course/my-courses
```

**Expected Response:**
```json
{
  "classesWithCourses": [...],
  "success": true
}
```

**If this fails:** Problem is in backend
**If this works:** Problem is in iOS app

---

### Step 3: Check Network Traffic

**Using Charles Proxy or Proxyman:**
1. Install proxy tool
2. Configure iOS Simulator to use proxy
3. Observe actual HTTP requests/responses
4. Compare with Android app requests

---

### Step 4: Compare with Android

**Android Endpoint:**
```kotlin
// In Android code
GET /course/my-courses
Headers: Authorization: Bearer TOKEN
```

**Should be identical to iOS:**
```swift
GET /course/my-courses
Headers: Authorization: Bearer TOKEN
```

---

## 🏥 Health Check Procedure

### Quick Test Script

**Run in Xcode console:**
```swift
// Test 1: Check URL
print("Base URL: \(AppConfig.baseURL)")

// Test 2: Check Token
if let token = DIContainer.shared.authService.getAuthToken() {
    print("Token exists: \(String(token.prefix(20)))...")
} else {
    print("❌ No token")
}

// Test 3: Test Endpoint
Task {
    do {
        let service = DIContainer.shared.teacherCoursesService
        let result = try await service.fetchMyCourses()
        print("✅ Success: \(result.count) classes")
    } catch {
        print("❌ Error: \(error)")
    }
}
```

---

## 📱 iOS Simulator vs Real Device

### Simulator (Default)
- Use `127.0.0.1` or `localhost`
- Backend runs on same Mac
- No network configuration needed

### Real Device
- Use Mac's IP address (e.g., `192.168.1.100`)
- Both devices on same WiFi network
- Backend must accept connections from LAN

**Get Mac IP:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Update AppConfig.swift:**
```swift
// For real device testing
static var baseURL: String {
    return "http://YOUR_MAC_IP:3001/api"
}
```

---

## 🔄 Complete Reset Procedure

If nothing works:

### 1. Clean iOS App
```bash
# In terminal
cd /Users/macbookm4pro/Documents/ESPRIT/projet/TacheLik_iosApp
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### 2. Reset Backend
```bash
cd /Users/macbookm4pro/Documents/ESPRIT/projet/tache-lik.tn-back-end-typescript-dev
npm run dev
```

### 3. Reset iOS App Data
- Delete app from Simulator
- Clean Build Folder (Cmd+Shift+K)
- Rebuild (Cmd+B)
- Run (Cmd+R)

### 4. Fresh Login
1. Open app
2. Enter teacher credentials
3. Navigate to My Classes
4. Should work now

---

## 📊 Expected vs Actual Comparison

### Expected Behavior (Android)
1. Loading spinner appears
2. API call to `/course/my-courses`
3. Data loads and displays classes
4. Each class shows course count
5. Expandable to show courses
6. Statistics show correct numbers

### iOS Implementation
- ✅ Loading spinner
- ✅ API call identical to Android
- ✅ Data parsing and display
- ✅ Class expansion animation
- ✅ Statistics calculation
- ✅ Pull-to-refresh
- ✅ Search and sort

**Should be 100% identical to Android!**

---

## 🆘 Still Not Working?

### Check These Files

1. **AppConfig.swift** - Verify baseURL
2. **NetworkService.swift** - Check request construction
3. **TeacherCoursesService.swift** - Verify endpoint and headers
4. **TeacherClassModels.swift** - Check DTO structure
5. **DIContainer.swift** - Ensure service is registered

### Console Errors to Look For

```
❌ [NetworkService] URLError: Code 7 = Can't connect
❌ [NetworkService] URLError: Code 60 = SSL certificate invalid
❌ [TeacherCoursesService] No auth token available
❌ [NetworkService] Response status: 401
❌ [NetworkService] Response status: 404
❌ [NetworkService] Decoding error
```

### Backend Logs to Check

```
GET /api/course/my-courses 200  // Good
GET /api/course/my-courses 401  // Bad - auth issue
GET /api/course/my-courses 500  // Bad - server error
```

---

## 📞 Contact Information

**Backend API:** `http://127.0.0.1:3001/api`
**Endpoint:** `/course/my-courses`
**Auth:** Required (Bearer JWT)
**Role:** mentor (teacher)

---

## ✅ Success Indicators

When everything works:

1. ✅ No console errors
2. ✅ Data loads within 2-3 seconds
3. ✅ Classes appear with correct counts
4. ✅ Can expand/collapse classes
5. ✅ Can search courses
6. ✅ Can sort by Newest/Enrollment/Rating
7. ✅ Pull-to-refresh works
8. ✅ Statistics update correctly
9. ✅ Matches Android version exactly

---

**Last Verified:** November 23, 2025  
**Status:** Production Ready ✅

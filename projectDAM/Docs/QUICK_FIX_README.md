# Production Server Configuration - Quick Guide

## 🎯 Current Configuration

The iOS app is configured to use the **production server exclusively**:

**Server:** `https://dev.api.tache-lik.tn/api`  
**Protocol:** HTTPS (Secure)  
**Status:** ✅ PRODUCTION READY

---

## ✅ CONFIGURATION

### All Configuration Files Point to Production:

**Config.xcconfig:**
```plaintext
API_BASE_URL = https:/$()/dev.api.tache-lik.tn/api
```

**Config.local.xcconfig:**
```plaintext
API_BASE_URL = https:/$()/dev.api.tache-lik.tn/api
```

**AppConfig.swift:**
```swift
// Fallback: "https://dev.api.tache-lik.tn/api"
```

---

## 🚀 To Use Your App

### 1. Verify Production Server Access
```bash
# Test server availability
curl -I https://dev.api.tache-lik.tn/api
```

**Expected:** HTTP/2 200 OK or similar response

### 2. Run iOS App
- Open Xcode
- Clean Build (⌘⇧K)
- Build (⌘B)
- Run (⌘R)
- Login with production account credentials
- Navigate to "My Classes" tab

### 3. Expected Result
✅ Connects to production server via HTTPS  
✅ Classes load from production database  
✅ Data appears exactly like Android version  
✅ All API calls use secure HTTPS protocol

---

## � Production Server Details

### Server Information
- **Base URL:** `https://dev.api.tache-lik.tn/api`
- **Protocol:** HTTPS (SSL/TLS encrypted)
- **Authentication:** JWT Bearer tokens
- **Database:** Production PostgreSQL

### Key Endpoints
- **Login:** POST `/auth/login`
- **My Courses:** GET `/course/my-courses`
- **Available Classes:** GET `/course/available-classes`

### Requirements
- Active internet connection
- Valid production account (teacher role)
- Valid JWT authentication token
- HTTPS support (automatically handled by iOS)

---

## 🔒 Security Features

### HTTPS Configuration
✅ All API calls use secure HTTPS  
✅ SSL certificate validation enabled  
✅ JWT tokens transmitted securely  
✅ Info.plist configured for secure transport

### Data Protection
- Encrypted communication (HTTPS)
- Secure token storage (Keychain)
- Session management
- Automatic token refresh (if implemented)

---

## 📊 Architecture

### Data Flow
```
iOS App (Swift)
    ↓ HTTPS
Production Server (dev.api.tache-lik.tn)
    ↓
PostgreSQL Database
    ↓ JSON Response
iOS App (Display)
```

### No Local Backend Required
- ✅ No need to run `npm run dev`
- ✅ No localhost configuration
- ✅ Works on any device with internet
- ✅ Consistent data across all platforms

---

## 🎯 Quick Checklist

Before running the app, verify:

- [ ] Backend server running: `lsof -i :3001` shows node process
- [ ] Config file points to correct URL
- [ ] Xcode cleaned and rebuilt
- [ ] User logged in with teacher account
- [ ] Network accessible (simulator can reach localhost)

---

## 🐛 Troubleshooting Production Issues

### Error: "Something went wrong"
**Possible Causes:**
1. Production server is down or unreachable
2. No internet connection
3. Invalid authentication token
4. API endpoint changed

**Check:**
```bash
# Test server availability
curl -I https://dev.api.tache-lik.tn/api

# Test with authentication
curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://dev.api.tache-lik.tn/api/course/my-courses
```

### Error: "Session expired" or "Unauthorized"
**Cause:** JWT token expired or invalid  
**Fix:** Log out and log back in to get new production token

### Error: Empty classes list
**Cause:** Teacher account has no courses on production database  
**Check:** 
- Verify account has teacher/mentor role
- Check production database for courses with your author_id
- Ensure courses are approved (if required)

### Error: "Cannot connect to server"
**Causes:**
- No internet connection
- Production server is down
- Firewall blocking HTTPS
- DNS resolution issues

**Verify:**
```bash
# Check DNS resolution
nslookup dev.api.tache-lik.tn

# Check server response
ping dev.api.tache-lik.tn

# Check HTTPS connection
curl -v https://dev.api.tache-lik.tn/api
```

### Xcode Console Shows Wrong URL
**If you see localhost URL in logs:**
1. Clean build folder (⌘⇧K)
2. Delete derived data
3. Quit Xcode completely
4. Reopen and build again
5. Check logs should show: `https://dev.api.tache-lik.tn/api/...`

---

## ✅ Success Indicators

When working correctly, Xcode console shows:

```
� App Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
API Base URL: https://dev.api.tache-lik.tn/api
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

�📡 [TeacherCoursesService] Fetching my courses from: https://dev.api.tache-lik.tn/api/course/my-courses
📡 [TeacherCoursesService] Token prefix: eyJhbGciOiJIUzI1NiIs...
✅ [TeacherCoursesService] Received 3 classes with courses
✅ [TeacherMyClassesViewModel] Loaded 3 classes successfully
```

### What You Should See
- ✅ Base URL shows production server (HTTPS)
- ✅ All endpoints use production URL
- ✅ Data loads from production database
- ✅ Classes and courses appear immediately
- ✅ No "local backend" or "localhost" in logs

---

## 📚 Additional Documentation

- **`Docs/PRODUCTION_SERVER_CONFIGURATION.md`** - Complete production setup guide
- **`Docs/TEACHER_MY_CLASSES_FINAL_FIX.md`** - Technical implementation details
- **`Docs/TEACHER_MY_CLASSES_TROUBLESHOOTING.md`** - Comprehensive troubleshooting

---

**Status:** ✅ PRODUCTION READY  
**Server:** https://dev.api.tache-lik.tn/api  
**Impact:** iOS now exclusively uses production backend  
**Action Required:** Clean build, run app with production credentials  

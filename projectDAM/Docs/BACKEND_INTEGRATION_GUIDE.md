# Backend Integration Guide

## 📋 Overview
This guide will help you connect your iOS e-learning app to your backend API at:
`/Users/macbookm4pro/Documents/ESPRIT/tache-lik.tn-back-end-typescript-dev-main`

---

## ✅ What I've Already Configured

### 1. Network Service
- **Base URL**: Changed to `http://localhost:3000/api`
- **Location**: `Services/NetworkService.swift`

### 2. Authentication Service
- **Status**: Now using **real API calls** (not mock data)
- **Endpoints**: 
  - Login: `POST /auth/login`
  - Register: `POST /auth/register`
- **Location**: `Services/AuthService.swift`

### 3. Dependency Injection
- **Status**: Switched from `MockAuthService` to real `AuthService`
- **Location**: `DI/DIContainer.swift`

---

## 🔧 Steps to Make It Work

### Step 1: Start Your Backend Server

1. Open Terminal
2. Navigate to your backend:
   ```bash
   cd /Users/macbookm4pro/Documents/ESPRIT/tache-lik.tn-back-end-typescript-dev-main
   ```

3. Install dependencies (if not done):
   ```bash
   npm install
   ```

4. Start the server:
   ```bash
   npm start
   # or
   npm run dev
   ```

5. Verify it's running on `http://localhost:3000`

---

### Step 2: Check Your Backend API Endpoints

Your iOS app expects these endpoints:

#### **Login Endpoint**
- **URL**: `POST http://localhost:3000/api/auth/login`
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```
- **Expected Response**:
  ```json
  {
    "user": {
      "id": "123",
      "email": "user@example.com",
      "name": "John Doe",
      "avatar": "https://...",
      "role": "Student"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```

#### **Register Endpoint**
- **URL**: `POST http://localhost:3000/api/auth/register`
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password123",
    "name": "John Doe"
  }
  ```
- **Expected Response**: Same as login

---

### Step 3: Update Backend Endpoints (If Different)

If your backend uses different endpoints, update these files:

#### A. If your login endpoint is different (e.g., `/user/login` instead of `/auth/login`):

**File**: `Services/AuthService.swift`

Find line ~68:
```swift
let response: AuthResponse = try await networkService.request(
    endpoint: "/auth/login",  // ← Change this
    method: .POST,
    body: requestData,
    headers: nil
)
```

Change to match your backend:
```swift
endpoint: "/user/login",  // Your actual endpoint
```

#### B. If your register endpoint is different:

Find line ~81:
```swift
let response: AuthResponse = try await networkService.request(
    endpoint: "/auth/register",  // ← Change this
    method: .POST,
    body: requestData,
    headers: nil
)
```

---

### Step 4: Update User Model (If Needed)

If your backend returns different user properties, update the `User` model:

**File**: `Models/Models.swift`

Current model:
```swift
struct User: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
    let avatar: String?
    let role: UserRole
}
```

Add any additional fields your backend returns, for example:
```swift
struct User: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
    let avatar: String?
    let role: UserRole
    let createdAt: String?  // Add if your backend has this
    let phoneNumber: String?  // Add if your backend has this
}
```

---

### Step 5: Configure App Transport Security

To allow HTTP connections to localhost during development:

1. Open `Info.plist`
2. Add this configuration:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**⚠️ Important**: Remove `NSAllowsArbitraryLoads` before production release!

---

### Step 6: Test the Connection

1. **Start your backend server** (see Step 1)

2. **Build and run your iOS app** in Xcode (⌘R)

3. **On the login screen**:
   - Enter email: (use a valid email from your backend)
   - Enter password: (use the correct password)
   - Tap "Sign In"

4. **Check Xcode Console** for network logs

---

## 🐛 Troubleshooting

### Issue 1: "Invalid URL" Error
**Problem**: Base URL is wrong  
**Solution**: Check `NetworkService.swift` line 54, ensure it matches your backend URL

### Issue 2: "Cannot connect to server"
**Problem**: Backend is not running  
**Solution**: 
```bash
cd /Users/macbookm4pro/Documents/ESPRIT/tache-lik.tn-back-end-typescript-dev-main
npm start
```

### Issue 3: "Decoding Error"
**Problem**: Backend response doesn't match iOS models  
**Solution**: 
1. Print the raw response in Xcode console
2. Update `User` model or `AuthResponse` to match

Add this to `NetworkService.swift` after line 86:
```swift
// Debug: Print raw response
if let jsonString = String(data: data, encoding: .utf8) {
    print("📥 Response: \(jsonString)")
}
```

### Issue 4: 401 Unauthorized
**Problem**: Wrong credentials or backend authentication issue  
**Solution**: Check your backend logs for the actual error

### Issue 5: CORS Error
**Problem**: Backend doesn't accept requests from iOS  
**Solution**: Add CORS middleware to your backend (usually needed for web, not iOS)

---

## 📱 Info.plist Configuration

Your app needs permission to make HTTP requests to localhost. Create or update your `Info.plist`:

**File**: `projectDAM/Info.plist`

If the file doesn't exist, I'll create it in the next step.

---

## 🔐 Token Management

The app automatically:
1. ✅ Saves the JWT token from login/register responses
2. ✅ Stores it in UserDefaults with key "authToken"
3. ✅ Includes it in future API requests (see `CourseService.swift` line 97)

To use the token in your backend requests:
```swift
let token = DIContainer.shared.authService.getAuthToken()
// Token is automatically added to headers in authenticated requests
```

---

## 🎯 Quick Test Checklist

- [ ] Backend server is running on port 3000
- [ ] Can access `http://localhost:3000/api/auth/login` endpoint
- [ ] Backend returns JSON with `user` and `token` fields
- [ ] Info.plist allows local networking
- [ ] iOS app base URL is `http://localhost:3000/api`
- [ ] Test user credentials are ready

---

## 📞 Need to Adjust the Response Format?

If your backend returns a different format, let me know and I'll update:

1. `AuthResponse` struct in `AuthService.swift`
2. `User` model in `Models.swift`
3. JSON decoding logic

---

## 🚀 Next Steps After Login Works

Once login/register work:

1. **Implement Course APIs**: Update `CourseService.swift` with real endpoints
2. **Add Error Messages**: Show user-friendly errors in the UI
3. **Add Loading States**: Already implemented in ViewModels
4. **Test Logout**: Verify token is cleared properly
5. **Add Token Refresh**: Implement if your backend uses refresh tokens

---

## 📝 Common Backend Response Formats

### Option 1: Direct Response (Current)
```json
{
  "user": {...},
  "token": "..."
}
```

### Option 2: Nested Data
```json
{
  "success": true,
  "data": {
    "user": {...},
    "token": "..."
  }
}
```

If you use Option 2, update `AuthResponse`:
```swift
struct AuthResponse: Decodable {
    let success: Bool
    let data: AuthData
    
    struct AuthData: Decodable {
        let user: User
        let token: String
    }
}
```

---

## ✨ Current Status

✅ Network layer configured  
✅ Auth service connected to real API  
✅ Login/Register endpoints set up  
✅ Token storage implemented  
✅ Dependency injection configured  
⏳ Waiting for you to start backend server  
⏳ Waiting to test actual API connection  

---

## 📧 Questions to Answer

To finalize the integration, please check:

1. **What port is your backend running on?** (I assumed 3000)
2. **What are the exact endpoint paths?** (I assumed `/api/auth/login`)
3. **What fields does your User object have?** (to update the model)
4. **Does your backend use a different response format?** (nested, different field names)

Once you confirm these, I can make final adjustments!

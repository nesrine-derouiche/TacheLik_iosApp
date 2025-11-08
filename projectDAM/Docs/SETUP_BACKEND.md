# 🚀 Quick Setup: Connect iOS App to Your Backend

## ✅ What I've Done for You

I've already configured your iOS app to connect to your backend! Here's what changed:

### 1. ✅ Updated Network Service
- **Changed base URL** from `https://api.yourbackend.com` to `http://localhost:3000/api`
- **Added debug logging** to see all API requests/responses in Xcode console
- **File**: `Services/NetworkService.swift`

### 2. ✅ Switched to Real Authentication
- **Changed** from mock data to real API calls
- **File**: `DI/DIContainer.swift`
- Now uses `AuthService` instead of `MockAuthService`

### 3. ✅ Created Debug Helper
- **Added** `NetworkService+Debug.swift` for detailed logging
- You'll see all API requests and responses in the console

---

## 🎯 Now YOU Need To Do (3 Simple Steps)

### Step 1: Configure Info.plist for HTTP Access

Since iOS blocks HTTP by default (only allows HTTPS), you need to allow localhost connections:

1. **Open Xcode**
2. **Select** your project `projectDAM` in the navigator (top file)
3. **Select** the `projectDAM` target
4. **Go to** the "Info" tab
5. **Right-click** in the custom properties area and select "Add Row"
6. **Add this key**: `App Transport Security Settings` (Type: Dictionary)
7. **Expand it** and add two items:
   - Key: `Allow Arbitrary Loads` → Value: `YES` (Boolean)
   - Key: `NSAllowsLocalNetworking` → Value: `YES` (Boolean)

**Visual Guide:**
```
Info.plist
└── App Transport Security Settings (Dictionary)
    ├── Allow Arbitrary Loads: YES
    └── NSAllowsLocalNetworking: YES
```

**⚠️ Important**: This allows HTTP only for development. Remove before production!

---

### Step 2: Start Your Backend Server

Open Terminal and run:

```bash
# Navigate to your backend
cd /Users/macbookm4pro/Documents/ESPRIT/tache-lik.tn-back-end-typescript-dev-main

# Install dependencies (first time only)
npm install

# Start the server
npm start
# OR if you have a dev script:
npm run dev
```

**Make sure you see**: `Server running on port 3000` or similar message

---

### Step 3: Test the Login

1. **Keep your backend running** in Terminal
2. **Open Xcode** and run your iOS app (⌘R)
3. **On the login screen**, enter credentials that exist in your backend
4. **Tap "Sign In"**
5. **Watch the Xcode console** for API logs

---

## 📋 What to Expect in Xcode Console

When you tap "Sign In", you'll see:

```
🌐 ============ API REQUEST ============
📍 POST http://localhost:3000/api/auth/login
📤 Request Body:
{"email":"user@example.com","password":"password123"}
======================================

📥 ============ API RESPONSE ===========
📊 Status Code: 200
📦 Response Data:
{"user":{...},"token":"..."}
======================================

✅ Successfully decoded response
```

---

## 🐛 Troubleshooting

### Problem 1: "Cannot connect to server"

**Console shows**: `NSURLErrorDomain Code=-1004` or similar

**Solutions**:
1. ✅ Make sure your backend is running (`npm start`)
2. ✅ Check the backend is on port 3000
3. ✅ Try accessing `http://localhost:3000` in Safari on your Mac
4. ✅ Check Info.plist has `NSAllowsLocalNetworking`

---

### Problem 2: "Decoding error"

**Console shows**: `❌ Decoding error`

**This means**: Your backend returns different JSON than expected

**Solution**: Check the response in console, then tell me what fields your backend returns and I'll update the models.

**Expected format**:
```json
{
  "user": {
    "id": "123",
    "email": "user@example.com",
    "name": "John Doe",
    "avatar": null,
    "role": "Student"
  },
  "token": "jwt_token_here"
}
```

---

### Problem 3: 404 Not Found

**Console shows**: `📊 Status Code: 404`

**This means**: The endpoint path is wrong

**Solution**: Check your backend routes. If login is at `/user/login` instead of `/auth/login`, tell me and I'll update it.

---

### Problem 4: Backend Returns Different Fields

If your User object has different fields (e.g., `firstName`, `lastName` instead of `name`), I need to update the iOS model.

**Example**: If your backend returns:
```json
{
  "user": {
    "id": "123",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "student"
  },
  "accessToken": "..."  // Not "token"
}
```

Then tell me, and I'll update:
- `Models/Models.swift` (User struct)
- `Services/AuthService.swift` (AuthResponse struct)

---

## 📊 Backend API Requirements

Your backend should have these endpoints:

### Login: `POST /api/auth/login`
```typescript
// Request
{
  "email": "user@example.com",
  "password": "password123"
}

// Response (200 OK)
{
  "user": {
    "id": "string",
    "email": "string",
    "name": "string",
    "avatar": "string | null",
    "role": "Student" | "Mentor" | "Admin"
  },
  "token": "string"
}
```

### Register: `POST /api/auth/register`
```typescript
// Request
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe"
}

// Response (201 Created)
// Same as login response
```

---

## 🔧 If Your Backend is Different

### Different Port?
If your backend runs on port 5000, 8080, etc.:

**File**: `Services/NetworkService.swift` line 54
```swift
init(baseURL: String = "http://localhost:5000/api", session: URLSession = .shared) {
                                          ^^^^
                                       Change this
```

### Different Base Path?
If your API is at `/v1/auth/login` instead of `/api/auth/login`:

**Option 1**: Update NetworkService base URL
```swift
init(baseURL: String = "http://localhost:3000/v1", ...)
```

**Option 2**: Update AuthService endpoints
```swift
endpoint: "/v1/auth/login"  // in login method
endpoint: "/v1/auth/register"  // in register method
```

---

## ✅ Quick Checklist

Before testing, make sure:

- [ ] Backend server is running (`npm start`)
- [ ] Backend responds to `http://localhost:3000/api/auth/login`
- [ ] Info.plist allows HTTP connections (Step 1 above)
- [ ] You have valid test credentials in your backend
- [ ] Xcode console is visible to see logs

---

## 🎉 Success Looks Like This

When everything works:

1. ✅ You tap "Sign In"
2. ✅ Console shows successful API request
3. ✅ Console shows 200 status code
4. ✅ Console shows user data
5. ✅ App navigates to the home screen automatically
6. ✅ You see the beautiful tab bar with Home, Classes, Progress, Settings

---

## 📞 Need Help?

If something doesn't work:

1. **Copy the error from Xcode console**
2. **Tell me**:
   - What error you see
   - What's in your backend response
   - What port your backend uses
   - What your endpoint paths are
3. **I'll fix it immediately!**

---

## 🚀 After Login Works

Once login is working, you'll want to:

1. ✅ Add course API endpoints to `CourseService.swift`
2. ✅ Implement real data loading in home screen
3. ✅ Add profile picture upload
4. ✅ Implement forgot password
5. ✅ Add biometric authentication (Face ID/Touch ID)

Let me know when you're ready for these!

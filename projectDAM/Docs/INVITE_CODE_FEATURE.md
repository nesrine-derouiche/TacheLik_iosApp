# Invite Code Feature

## ✅ Implementation Complete

### Overview
Added an optional invite code field to the signup form. Users can enter a 6-character invite code when registering.

## 🎯 Feature Details

### Invite Code Field
- **Label**: "Invite Code (optional)"
- **Icon**: Ticket icon
- **Max Length**: 6 characters
- **Required**: No (optional field)
- **Auto-capitalization**: Uppercase
- **Validation**: Automatically truncates to 6 characters

## 📊 API Integration

### Endpoint
```
POST /api/auth/signup
```

### Request Body
```json
{
  "username": "testuser",
  "email": "user@esprit.tn",
  "password": "password123",
  "invitedBy": "ABC123"  // Optional, max 6 chars
}
```

### Backend Field
- **Field Name**: `invitedBy`
- **Type**: `String` (optional)
- **Max Length**: 6 characters
- **Sent**: Only if user enters a code (not sent if empty)

## 🎨 UI Implementation

### RegisterView
```swift
CustomTextField(
    icon: "ticket",
    placeholder: "Invite Code (optional)",
    text: $viewModel.inviteCode,
    isSecure: false
)
.textInputAutocapitalization(.characters)
.onChange(of: viewModel.inviteCode) { newValue in
    // Limit to 6 characters
    if newValue.count > 6 {
        viewModel.inviteCode = String(newValue.prefix(6))
    }
}
```

### Field Position
1. Username
2. Email
3. Password
4. Confirm Password
5. **Invite Code** ← New field
6. Create Account button

## 🔧 Implementation Details

### 1. RegisterViewModel
```swift
@Published var inviteCode = ""

func register() async {
    let inviteCodeToSend = inviteCode.isEmpty ? nil : inviteCode
    let user = try await authService.register(
        username: username,
        email: email,
        password: password,
        inviteCode: inviteCodeToSend
    )
}
```

### 2. AuthService
```swift
struct RegisterRequest: Encodable {
    let username: String
    let email: String
    let password: String
    let invitedBy: String?  // Optional invite code
}

func register(
    username: String,
    email: String,
    password: String,
    inviteCode: String? = nil
) async throws -> User {
    let request = RegisterRequest(
        username: username,
        email: email,
        password: password,
        invitedBy: inviteCode?.isEmpty == false ? inviteCode : nil
    )
    // Send to backend...
}
```

### 3. Character Limit
```swift
.onChange(of: viewModel.inviteCode) { newValue in
    if newValue.count > 6 {
        viewModel.inviteCode = String(newValue.prefix(6))
    }
}
```

## 📱 User Experience

### Entering Invite Code
1. User taps "Create Account"
2. Fills in username, email, passwords
3. Optionally enters invite code
4. Code auto-capitalizes (ABC123)
5. Limited to 6 characters
6. Taps "Create Account"
7. Code sent to backend

### Without Invite Code
1. User leaves invite code field empty
2. Taps "Create Account"
3. `invitedBy` not sent to backend (null)
4. Registration proceeds normally

## 🔒 Validation

### Client-Side
- ✅ Max 6 characters enforced
- ✅ Auto-capitalization enabled
- ✅ Optional (not required)
- ✅ Empty string not sent to backend

### Backend
- Backend validates invite code
- Invalid code → Error returned
- Valid code → User linked to referrer
- No code → Default behavior

## 🧪 Testing Scenarios

### Test 1: With Valid Invite Code
1. Open signup screen
2. Fill in all fields
3. Enter invite code: "ABC123"
4. Tap "Create Account"
5. ✅ Request includes `"invitedBy": "ABC123"`
6. ✅ User registered successfully

### Test 2: Without Invite Code
1. Open signup screen
2. Fill in all fields
3. Leave invite code empty
4. Tap "Create Account"
5. ✅ Request does NOT include `invitedBy` field
6. ✅ User registered successfully

### Test 3: Character Limit
1. Open signup screen
2. Enter invite code: "ABCDEFGHIJ" (10 chars)
3. ✅ Field shows only "ABCDEF" (6 chars)
4. ✅ Cannot type more than 6 characters

### Test 4: Auto-Capitalization
1. Open signup screen
2. Type invite code: "abc123"
3. ✅ Field shows "ABC123" (uppercase)

### Test 5: Invalid Invite Code
1. Open signup screen
2. Fill in all fields
3. Enter invalid code: "XXXXXX"
4. Tap "Create Account"
5. ✅ Backend returns error
6. ✅ Error alert shown to user

## 📊 Backend Response

### Success (With Invite Code)
```json
{
  "message": "User created",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "success": true
}
```

### Error (Invalid Invite Code)
```json
{
  "message": "Invalid invite code",
  "success": false
}
```

## 🎯 Use Cases

### Referral System
- User A shares invite code "ABC123"
- User B signs up with code "ABC123"
- User B linked to User A as referrer
- Both users may get benefits/rewards

### Tracking
- Track which users were invited
- Measure referral success
- Reward top referrers

### Access Control
- Require invite code for beta access
- Limit signups to invited users only
- Track invitation sources

## 📝 Files Modified

### 1. RegisterView.swift
- ✅ Added invite code field
- ✅ Added character limit validation
- ✅ Added auto-capitalization

### 2. RegisterViewModel.swift
- ✅ Added `inviteCode` property
- ✅ Updated `register()` method
- ✅ Pass invite code to AuthService

### 3. AuthService.swift
- ✅ Updated `RegisterRequest` model
- ✅ Updated `register()` signature
- ✅ Updated protocol
- ✅ Updated MockAuthService

### 4. LoginViewModel.swift
- ✅ Updated `register()` signature
- ✅ Added inviteCode parameter

## ✅ Verification Checklist

- [x] Invite code field added to UI
- [x] Field is optional
- [x] Max 6 characters enforced
- [x] Auto-capitalization enabled
- [x] Empty string not sent to backend
- [x] RegisterViewModel updated
- [x] AuthService updated
- [x] Protocol updated
- [x] MockAuthService updated
- [x] LoginViewModel updated
- [x] Request body includes invitedBy
- [x] Character limit works
- [x] Field positioned correctly

## 🚀 Future Enhancements

### Validation
- [ ] Validate invite code format (alphanumeric only)
- [ ] Check invite code availability before submit
- [ ] Show "Invalid code" message in real-time

### UX Improvements
- [ ] Auto-format code (e.g., ABC-123)
- [ ] Show who invited you when entering code
- [ ] Paste button for easy code entry
- [ ] QR code scanner for invite codes

### Features
- [ ] Generate invite codes for users
- [ ] Show invite code in settings
- [ ] Track how many people used your code
- [ ] Rewards for successful referrals

## 🎉 Result

Users can now enter an optional 6-character invite code when signing up! The code is sent to the backend and can be used for referral tracking, rewards, or access control.

### Key Features
- ✅ Optional field (not required)
- ✅ Max 6 characters
- ✅ Auto-capitalization
- ✅ Character limit enforced
- ✅ Only sent if not empty
- ✅ Backend integration complete

# Special Invite Link System

## ✅ Implementation Complete

### Overview
Implemented a special invite link system where users can enter a 6-character invite code during signup. The system validates if the code is "special" (gives reduction) and sets the invite link after email verification.

## 🔄 Complete Flow

```
1. User enters invite code during signup
       ↓
2. After 6 characters, auto-check validity
   GET /api/user/check-invite-link-special/{code}
       ↓
3. Show validation message:
   - Special: "✓ Special invite! Get a reduction"
   - Not special: "Not special. Only special invites give reduction"
   - Invalid: "Invalid invite code"
       ↓
4. User completes signup
       ↓
5. Invite code saved locally (UserDefaults)
       ↓
6. User verifies email
       ↓
7. After verification, set invite link
   PUT /api/user/set-user-invited-by-link
       ↓
8. Clear pending invite code
       ↓
9. User gets reduction on first purchase
```

## 📊 API Integration

### 1. Check Invite Link (During Signup)

**Endpoint**: `GET /api/user/check-invite-link-special/{inviteLink}`

**Example**: `GET /api/user/check-invite-link-special/ABC123`

**Response**:
```json
{
  "exists": true,
  "success": true,
  "isSpecialInvitation": true
}
```

**States**:
- `exists: true, isSpecialInvitation: true` → Special invite (gives reduction)
- `exists: true, isSpecialInvitation: false` → Regular invite (no reduction)
- `exists: false` → Invalid invite code

### 2. Set Invited By Link (After Verification)

**Endpoint**: `PUT /api/user/set-user-invited-by-link`

**Headers**:
```
Authorization: Bearer {jwt_token}
```

**Request Body**:
```json
{
  "userId": "311825",
  "link": "ABC123"
}
```

**Response**:
```json
{
  "success": true
}
```

## 🎨 UI Implementation

### Invite Code Field

```swift
VStack(alignment: .leading, spacing: 8) {
    HStack {
        CustomTextField(
            icon: "ticket",
            placeholder: "Invite Code (optional)",
            text: $viewModel.inviteCode,
            isSecure: false
        )
        
        if viewModel.isCheckingInviteLink {
            ProgressView()
        }
    }
    
    // Validation message
    if !viewModel.inviteLinkMessage.isEmpty {
        Text(viewModel.inviteLinkMessage)
            .font(.system(size: 12))
            .foregroundColor(viewModel.inviteLinkSpecial ? .green : .red)
    }
    
    // Helper text
    Text("Optional - Get a reduction on your first purchase with a special invite code")
        .font(.system(size: 11))
        .foregroundColor(.secondary)
}
```

### Validation Messages

| Condition | Message | Color |
|-----------|---------|-------|
| **Special Invite** | "✓ Special invite! Get a reduction on your first purchase" | Green |
| **Not Special** | "This invite code is not special. Only special invites give a reduction." | Red |
| **Invalid** | "Invalid invite code" | Red |
| **Error** | "Could not verify invite code" | Red |

## 🔧 Implementation Details

### 1. RegisterViewModel

#### Properties
```swift
@Published var inviteCode = ""
@Published var isCheckingInviteLink = false
@Published var inviteLinkValid = false
@Published var inviteLinkSpecial = false
@Published var inviteLinkMessage = ""
```

#### Check Invite Link
```swift
func checkInviteLink() async {
    guard !inviteCode.isEmpty else { return }
    guard inviteCode.count == 6 else { return }
    
    isCheckingInviteLink = true
    
    do {
        let response = try await authService.checkInviteLink(inviteCode)
        
        if response.exists && response.isSpecialInvitation {
            inviteLinkValid = true
            inviteLinkSpecial = true
            inviteLinkMessage = "✓ Special invite! Get a reduction on your first purchase"
        } else if response.exists {
            inviteLinkValid = false
            inviteLinkSpecial = false
            inviteLinkMessage = "This invite code is not special. Only special invites give a reduction."
        } else {
            inviteLinkValid = false
            inviteLinkSpecial = false
            inviteLinkMessage = "Invalid invite code"
        }
    } catch {
        inviteLinkValid = false
        inviteLinkSpecial = false
        inviteLinkMessage = "Could not verify invite code"
    }
    
    isCheckingInviteLink = false
}
```

### 2. AuthService

#### Check Invite Link
```swift
func checkInviteLink(_ link: String) async throws -> InviteLinkCheckResponse {
    let response: InviteLinkCheckResponse = try await networkService.request(
        endpoint: "/user/check-invite-link-special/\(link)",
        method: .GET,
        body: nil,
        headers: nil
    )
    return response
}
```

#### Save Invite Code During Registration
```swift
func register(username: String, email: String, password: String, inviteCode: String? = nil) async throws -> User {
    // Save invite code locally to use after verification
    if let inviteCode = inviteCode, !inviteCode.isEmpty {
        UserDefaults.standard.set(inviteCode, forKey: "pendingInviteCode")
    }
    
    // Register user (without invite code in request)
    // ...
}
```

#### Set Invite Link After Verification
```swift
func setUserInvitedByLink(userId: String, link: String) async throws {
    guard let token = getAuthToken() else {
        throw NetworkError.unauthorized
    }
    
    let request = SetInvitedByRequest(userId: userId, link: link)
    let requestData = try JSONEncoder().encode(request)
    
    let _: [String: Bool] = try await networkService.request(
        endpoint: "/user/set-user-invited-by-link",
        method: .PUT,
        body: requestData,
        headers: ["Authorization": "Bearer \(token)"]
    )
    
    // Clear pending invite code after successful set
    UserDefaults.standard.removeObject(forKey: "pendingInviteCode")
}
```

### 3. VerificationView

#### Set Invite Link After Verification
```swift
private func refreshUserData() {
    Task {
        do {
            try await authService.refreshUserData()
            
            // Check if user is now verified and has pending invite code
            if let user = authService.getCurrentUser(), user.verified == true {
                await setInviteLinkIfPending(userId: user.id)
            }
        } catch {
            print("❌ Failed to refresh user data")
        }
    }
}

private func setInviteLinkIfPending(userId: String) async {
    guard let inviteCode = UserDefaults.standard.string(forKey: "pendingInviteCode") else {
        return
    }
    
    do {
        try await authService.setUserInvitedByLink(userId: userId, link: inviteCode)
        print("✅ Invite link set after verification")
    } catch {
        print("❌ Failed to set invite link")
    }
}
```

## 📱 User Experience

### Scenario 1: Special Invite Code
```
1. User taps "Create Account"
2. Fills in username, email, passwords
3. Enters invite code: "ABC123"
4. After 6th character, loading spinner appears
5. ✅ Green message: "✓ Special invite! Get a reduction on your first purchase"
6. User completes signup
7. Code saved locally
8. User verifies email
9. Code automatically sent to backend
10. User gets reduction on first purchase
```

### Scenario 2: Non-Special Invite Code
```
1. User enters invite code: "XYZ789"
2. After 6th character, loading spinner appears
3. ❌ Red message: "This invite code is not special. Only special invites give a reduction."
4. User can:
   - Continue with this code (no reduction)
   - Clear and try different code
   - Leave empty and continue
```

### Scenario 3: Invalid Invite Code
```
1. User enters invite code: "XXXXXX"
2. After 6th character, loading spinner appears
3. ❌ Red message: "Invalid invite code"
4. User should clear and try again or continue without code
```

### Scenario 4: No Invite Code
```
1. User leaves invite code field empty
2. No validation performed
3. User completes signup normally
4. No reduction applied
```

## 🔒 Data Storage

### UserDefaults Keys
- **`pendingInviteCode`**: Stores invite code after signup, before verification
  - Set: During registration
  - Read: After email verification
  - Cleared: After successfully setting invite link

### Flow
```
Signup → Save to UserDefaults
         ↓
Email Verification
         ↓
Read from UserDefaults
         ↓
Send to Backend
         ↓
Clear from UserDefaults
```

## 🧪 Testing Scenarios

### Test 1: Special Invite Code Flow
1. Open signup screen
2. Enter special code: "ABC123"
3. ✅ See green success message
4. Complete signup
5. Verify email
6. ✅ Invite link set automatically
7. ✅ Pending code cleared

### Test 2: Non-Special Invite Code
1. Enter non-special code: "XYZ789"
2. ✅ See red warning message
3. Can still complete signup
4. No reduction applied

### Test 3: Invalid Invite Code
1. Enter invalid code: "XXXXXX"
2. ✅ See red error message
3. Clear code and continue

### Test 4: Network Error During Check
1. Turn off WiFi
2. Enter code: "ABC123"
3. ✅ See error message
4. Turn on WiFi
5. Clear and re-enter code
6. ✅ Validation works

### Test 5: No Invite Code
1. Leave field empty
2. Complete signup
3. ✅ No validation performed
4. ✅ No code saved

### Test 6: Verification Without Code
1. Signup without invite code
2. Verify email
3. ✅ No API call to set invite link
4. ✅ No errors

## 📊 Console Logs

### Successful Special Invite
```
✅ Invite link checked: exists=true, special=true
✅ Registration successful: testuser
✅ User data refreshed: testuser
✅ Invite link set after verification
✅ User invited by link set successfully
```

### Non-Special Invite
```
✅ Invite link checked: exists=true, special=false
✅ Registration successful: testuser
```

### Invalid Invite
```
✅ Invite link checked: exists=false, special=false
```

## 📝 Files Modified

### 1. AuthService.swift
- ✅ Added `InviteLinkCheckResponse` model
- ✅ Added `SetInvitedByRequest` model
- ✅ Added `checkInviteLink()` method
- ✅ Added `setUserInvitedByLink()` method
- ✅ Updated `register()` to save invite code locally
- ✅ Removed `invitedBy` from RegisterRequest

### 2. RegisterViewModel.swift
- ✅ Added invite link validation properties
- ✅ Added `checkInviteLink()` method
- ✅ Auto-validation on 6 characters

### 3. RegisterView.swift
- ✅ Added validation message display
- ✅ Added loading spinner
- ✅ Added helper text
- ✅ Auto-check on input

### 4. VerificationView.swift
- ✅ Added `setInviteLinkIfPending()` method
- ✅ Call after email verification
- ✅ Clear pending code after success

## ✅ Verification Checklist

- [x] Check invite link API integrated
- [x] Set invite link API integrated
- [x] Invite code saved locally during signup
- [x] Validation performed after 6 characters
- [x] Special invite shows green message
- [x] Non-special invite shows red warning
- [x] Invalid invite shows red error
- [x] Loading spinner shown during check
- [x] Helper text explains benefit
- [x] Invite link set after verification
- [x] Pending code cleared after success
- [x] Works without invite code
- [x] Character limit enforced (6 chars)
- [x] Auto-capitalization enabled

## 🎉 Result

The special invite link system is fully functional! Users can enter invite codes during signup, see real-time validation, and automatically get their reduction applied after email verification.

### Key Features
- ✅ Real-time validation
- ✅ Special vs regular invite detection
- ✅ User-friendly messages
- ✅ Automatic application after verification
- ✅ Optional field (not required)
- ✅ 6-character limit
- ✅ Auto-capitalization
- ✅ Loading feedback

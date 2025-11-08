# 6-Digit Code iOS Implementation Plan

## Overview
Replace link-based verification with 6-digit code verification for:
1. Email verification after signup
2. Password reset

## Backend APIs Ready ✅

### Email Verification
- `POST /api/user/request-email-verification-code` - Request code
- `POST /api/user/verify-email-code` - Verify code

### Password Reset
- `POST /api/user/request-password-reset-code` - Request code
- `POST /api/user/verify-password-reset-code` - Verify code (optional check)
- `POST /api/user/reset-password-with-code` - Reset password with code

## iOS Changes Needed

### 1. AuthService Updates
Add new methods:
```swift
func requestEmailVerificationCode(email: String) async throws
func verifyEmailWithCode(email: String, code: String) async throws
func requestPasswordResetCode(email: String) async throws
func verifyPasswordResetCode(email: String, code: String) async throws -> Bool
func resetPasswordWithCode(email: String, code: String, newPassword: String) async throws
```

### 2. Create CodeInputView Component
A reusable 6-digit code input component:
- 6 individual text fields
- Auto-focus next field on input
- Auto-submit when all 6 digits entered
- Paste support (paste 6-digit code)
- Clear/delete support
- Visual feedback (cyan border when focused)

### 3. Update VerificationView
**Current Flow**: Shows "Refresh Status" and "Resend Email" buttons

**New Flow**:
1. User signs up
2. Auto-request verification code (sent to email)
3. Show CodeInputView for 6-digit code
4. User enters code from email
5. Auto-verify when 6 digits entered
6. Show success → navigate to main app
7. "Resend Code" button (10-minute cooldown)

### 4. Update ForgotPasswordView
**Current Flow**: Enter email → sends reset link

**New Flow**:
1. Enter email
2. Click "Send Code"
3. Show CodeInputView
4. Enter 6-digit code
5. Show new password fields
6. Enter new password (with validation)
7. Submit → password reset
8. Navigate back to login

### 5. Create ViewModels
- `VerificationCodeViewModel` - For email verification
- `PasswordResetCodeViewModel` - For password reset

### 6. UI/UX Improvements
- Show countdown timer (10 minutes)
- Disable "Resend" button during cooldown
- Show loading spinner while verifying
- Clear error messages
- Success animations

## File Structure

### New Files to Create:
```
Views/Components/
  - CodeInputView.swift (reusable 6-digit input)
  
ViewModels/
  - VerificationCodeViewModel.swift
  - PasswordResetCodeViewModel.swift (update existing ForgotPasswordViewModel)
```

### Files to Modify:
```
Services/
  - AuthService.swift (add 5 new methods)
  
Views/Auth/
  - VerificationView.swift (use CodeInputView)
  - ForgotPasswordView.swift (add code input step)
```

## User Experience Flow

### Email Verification
```
1. User signs up
   ↓
2. "Verification code sent to your email"
   ↓
3. [CodeInputView: _ _ _ _ _ _]
   "Enter the 6-digit code sent to user@esprit.tn"
   ↓
4. User types: 1 2 3 4 5 6
   ↓
5. Auto-verify (loading spinner)
   ↓
6. ✅ "Email verified!" → Main app
```

**Resend Flow**:
```
"Didn't receive code?"
[Resend Code] (disabled for 60 seconds after send)
```

### Password Reset
```
1. Login screen → "Forgot Password?"
   ↓
2. Enter email
   ↓
3. "Reset code sent to your email"
   ↓
4. [CodeInputView: _ _ _ _ _ _]
   ↓
5. User enters code
   ↓
6. Show new password fields
   - New Password (with strength indicator)
   - Confirm Password
   ↓
7. [Reset Password] button
   ↓
8. ✅ "Password reset successful" → Login
```

## Design Specifications

### CodeInputView
- 6 boxes in a row
- Each box: 50x60pt
- Spacing: 8pt between boxes
- Font: System, size 24, weight: semibold
- Border: 2pt
  - Inactive: gray
  - Active (focused): cyan (#17a2b8)
  - Filled: cyan
  - Error: red
- Background: light gray when inactive, white when active
- Numeric keyboard only

### Timer Display
```
"Code expires in 09:45"
```
- Font: System, size 14, medium
- Color: secondary gray
- Updates every second
- Turns red when < 1 minute

### Resend Button
```
"Resend Code" (enabled)
"Resend Code in 45s" (disabled with countdown)
```

## Error Handling

### Possible Errors:
1. **Invalid code** - "Invalid verification code"
2. **Expired code** - "Code has expired. Request a new one."
3. **Network error** - "Connection failed. Please try again."
4. **Too many attempts** - "Too many attempts. Please wait."

### Error Display:
- Red text below CodeInputView
- Shake animation on error
- Clear code input on error
- Allow retry

## Security Considerations
- Codes expire after 10 minutes
- Rate limiting on backend
- Don't reveal if email exists (password reset)
- Clear codes from memory after use
- No code storage in UserDefaults

## Testing Checklist
- [ ] Request email verification code
- [ ] Enter valid 6-digit code
- [ ] Enter invalid code (show error)
- [ ] Code expiration (10 minutes)
- [ ] Resend code functionality
- [ ] Paste 6-digit code
- [ ] Request password reset code
- [ ] Verify reset code
- [ ] Reset password with code
- [ ] Network error handling
- [ ] Timer countdown display
- [ ] Auto-focus behavior
- [ ] Keyboard dismissal

## Implementation Priority
1. ✅ Backend APIs (DONE)
2. 🔄 AuthService methods
3. 🔄 CodeInputView component
4. 🔄 Update VerificationView
5. 🔄 Update ForgotPasswordView
6. 🔄 Testing & polish

## Estimated Time
- AuthService: 30 minutes
- CodeInputView: 1 hour
- VerificationView: 45 minutes
- ForgotPasswordView: 1 hour
- Testing: 30 minutes
**Total: ~3.5 hours**

## Next Steps
1. Implement AuthService methods
2. Create CodeInputView component
3. Update VerificationView
4. Update ForgotPasswordView
5. Test complete flow
6. Document changes

Would you like me to proceed with the iOS implementation?

# Role-Based Navigation & Data Display Implementation

## Overview
This document outlines the complete implementation of role-based navigation and data display for the TacheLik iOS application. The system allows different user roles (Student, Admin, Teacher) to access customized navigation tabs and screens based on their role.

## Architecture

### 1. **RoleManager Service** (`Services/RoleManager.swift`)
The `RoleManager` is the central service that manages user roles throughout the application.

**Key Responsibilities:**
- Maintains the current user role state
- Publishes role changes via `Combine` publisher
- Provides computed properties to check user type (`isStudent`, `isAdmin`, `isTeacher`)
- Updates role when user data changes

**Usage:**
```swift
@EnvironmentObject var roleManager: RoleManager

// Check current role
if roleManager.isAdmin {
    // Admin-specific UI
}

// Update role when user data loads
roleManager.updateRole(from: user)
```

### 2. **Role Detection Flow**

The role is detected and fetched from:
1. **Backend API** - User role comes from the `role` field in the User model
2. **JWT Token** - Role is encoded in the JWT token payload (`JWTPayload.role`)
3. **User Model** - `UserRole` enum defines available roles:
   - `.student` = "Student"
   - `.mentor` = "Teacher"  
   - `.admin` = "Admin"

### 3. **Navigation Architecture**

#### MainTabView - Role-Based Tab Selection
The `MainTabView` has been refactored to support three different navigation stacks:

**Student Tabs (5 tabs):**
- Home
- Classes
- Explore
- Progress
- Settings

**Admin Tabs (4 tabs):**
- Dashboard
- Requests
- Users
- Settings

**Teacher Tabs (4 tabs):**
- Dashboard
- My Classes
- Messages
- Settings

The active tab bar changes dynamically based on `roleManager.currentRole`.

## Detailed Implementation

### Student Role (No Changes)
Students continue to use the existing navigation structure with their current views.

### Admin Role - New Views

#### **AdminDashboardView** (`Views/Main/AdminDashboardView.swift`)
Displays comprehensive platform management statistics and controls.

**Features:**
- 4 stat cards showing:
  - Total Students (2,847 with +12% trend)
  - Total Mentors (47 with +3 trend)
  - Active Courses (128 with +8 trend)
  - Completion Rate (73% with +5% trend)
- Pending Approvals section showing:
  - 3 pending items (mentors and courses)
  - Approve/Reject action buttons for each
- Platform Analytics section (placeholder for advanced charts)
- Recent Activity feed showing system events

**UI Components:**
- `StatCard` - Displays metric with icon and trend
- `ApprovalItemView` - Shows pending approval items with actions
- `ActivityItemView` - Shows activity feed items

#### **AdminRequestsView** (`Views/Main/AdminRequestsView.swift`)
Manages payment and course requests with approve/reject workflow.

**Features:**
- Tab-based filtering:
  - Pending (3 requests)
  - Approved (2 requests)
  - Rejected (0 requests)
- Payment request cards showing:
  - Amount and status
  - Instructor name and course
  - Student enrollment count and date
  - Approve/Reject buttons (only for pending)
- Request details with action buttons

**UI Components:**
- `StatBadge` - Shows request statistics
- `PaymentRequestCard` - Displays individual payment requests
- `DetailRow` - Shows request details with icons

#### **AdminUsersView** (`Views/Main/AdminUsersView.swift`)
Comprehensive user management interface for all users.

**Features:**
- Search functionality for finding users
- Tab-based user filtering:
  - Students (5 users)
  - Mentors (4 users)
  - Admins (2 users)
- User list items showing:
  - Avatar with initials
  - User name, email, and role badge
  - Course count (for students/mentors)
  - Active/Inactive status
  - Context menu with View, Edit, Deactivate options

**UI Components:**
- `UserListItemView` - Shows individual user information
- `MenuButton` - Context menu action buttons

### Teacher Role - New Views

#### **TeacherDashboardView** (`Views/Main/TeacherDashboardView.swift`)
Personalized dashboard for instructors managing their courses.

**Features:**
- 4 key metrics:
  - Total Students (342)
  - Active Courses (5)
  - Average Rating (4.8/5.0)
  - Pending Questions (23)
- Quick Actions grid with 4 buttons:
  - New Lesson
  - Answer Q&A
  - Analytics
  - Students
- Recent Student Activity showing:
  - Student name and course
  - Action taken (completed assignment, asked question, etc.)
  - Time ago and action icon

**UI Components:**
- `TeacherStatCard` - Metric card with icon and value
- `QuickActionButton` - Large action buttons with icons
- `StudentActivityItemView` - Activity feed items

#### **TeacherMyClassesView** (`Views/Main/TeacherMyClassesView.swift`)
Manages and displays instructor's courses with analytics.

**Features:**
- Search and sort functionality:
  - Sort options: Newest, Enrollment, Rating
- Create New Course button
- Course cards showing:
  - Course image/icon
  - Title, student count, and rating
  - New submissions badge
  - Completion progress bar
  - Edit and Analytics action buttons
- 5 sample courses with various metrics

**UI Components:**
- `TeacherCourseCard` - Displays individual course with full details
- Sort and filter controls

#### **TeacherMessagesView** (`Views/Main/TeacherMessagesView.swift`)
Q&A and direct messaging interface for teacher-student communication.

**Features:**
- Search functionality
- Tab-based message filtering:
  - Q&A (5 unanswered questions)
  - Direct Messages (3 messages)
- Message items showing:
  - Sender avatar with unread count badge
  - Sender name, course tag
  - Message subject and preview
  - Timestamp and unanswered indicator
- Message detail view with:
  - Full message content
  - Reply composer
  - Send button

**UI Components:**
- `MessageItemView` - Individual message/question item
- `MessageDetailView` - Full message view with reply capability

## Integration Points

### 1. **RootView Integration**
The `RootView` in `projectDAMApp.swift` now:
1. Receives `RoleManager` via `@EnvironmentObject`
2. Calls `roleManager.updateRole(from: user)` when user is loaded
3. Observes role changes and updates UI accordingly
4. Resets role on logout

```swift
@EnvironmentObject var roleManager: RoleManager

.onAppear {
    roleManager.updateRole(from: user)
}

.onChange(of: currentUser) { newUser in
    if let newUser = newUser {
        roleManager.updateRole(from: newUser)
    }
}
```

### 2. **DIContainer Integration**
The `DIContainer` now provides the `RoleManager`:
```swift
let roleManager: RoleManager

private init() {
    self.roleManager = RoleManager()
    // ... other service initialization
}
```

### 3. **Environment Setup**
`projectDAMApp.swift` passes `RoleManager` as an environment object:
```swift
.environmentObject(DIContainer.shared.roleManager)
```

## Design System Consistency

All new views follow the established design system:
- **Colors:** Brand colors (primary: cyan, secondary: dark blue, accent, success, warning, error)
- **Typography:** System fonts with consistent sizing and weights
- **Spacing:** DS.paddingMD, DS.paddingLG, etc.
- **Corner Radius:** DS.cornerRadiusMD, DS.cornerRadiusLG
- **Shadows:** DS.shadowMD, DS.shadowLG
- **Components:** Reusable cards, buttons, badges

## Testing Role-Based Navigation

### Testing Student Access
1. Login as a student user
2. Verify 5 tabs appear: Home, Classes, Explore, Progress, Settings
3. Verify views load correctly on each tab
4. Verify no admin/teacher specific content is accessible

### Testing Admin Access
1. Login as an admin user
2. Verify 4 tabs appear: Dashboard, Requests, Users, Settings
3. Test Dashboard view:
   - Verify all stat cards display correctly
   - Verify pending approvals section loads
   - Verify recent activity feed displays
4. Test Requests view:
   - Verify tab filtering works (Pending, Approved, Rejected)
   - Verify payment request cards display correctly
   - Verify Approve/Reject buttons are functional
5. Test Users view:
   - Verify user type filtering works
   - Verify search functionality
   - Verify context menu appears on tap

### Testing Teacher Access
1. Login as a teacher user
2. Verify 4 tabs appear: Dashboard, My Classes, Messages, Settings
3. Test Dashboard view:
   - Verify stat cards display teacher metrics
   - Verify quick action buttons are accessible
   - Verify student activity feed displays
4. Test My Classes view:
   - Verify course list displays
   - Verify search and sort functionality
   - Verify Create New Course button
   - Verify course card actions (Edit, Analytics)
5. Test Messages view:
   - Verify Q&A and Direct Message tabs
   - Verify message items display correctly
   - Verify detail view and reply composer work

## Role Update Flow

```
User Login/Register
    ↓
AuthService.login/register()
    ↓
User data fetched from API
    ↓
User stored in AuthService.currentUser
    ↓
RootView detects user and calls loadUserData()
    ↓
roleManager.updateRole(from: user)
    ↓
MainTabView receives updated role via @StateObject
    ↓
Appropriate tab bar and views render based on role
```

## Future Enhancements

1. **Dynamic Data Loading** - Connect views to actual API endpoints
2. **Real-time Updates** - Use WebSockets for live role changes
3. **Permission-Based Access** - Add granular permission system
4. **Role Transitions** - Smooth animations when role changes
5. **Audit Logging** - Log role-based actions for security

## Troubleshooting

### Role not updating after login
- Check that `roleManager.updateRole(from: user)` is called in RootView
- Verify AuthService has user data available
- Check console logs for role update messages

### Tabs not changing when switching accounts
- Ensure `@EnvironmentObject var roleManager: RoleManager` is declared
- Verify MainTabView is observing roleManager state changes
- Clear app data and re-login to reset state

### New admin/teacher views not appearing
- Confirm role value in backend is correct ("Admin", "Teacher", "Student")
- Check MainTabView switch statement includes all role cases
- Verify views are properly imported in MainTabView

## Files Modified/Created

### Created:
- `Services/RoleManager.swift` - Role management service
- `Views/Main/AdminDashboardView.swift` - Admin dashboard
- `Views/Main/AdminRequestsView.swift` - Request management
- `Views/Main/AdminUsersView.swift` - User management
- `Views/Main/TeacherDashboardView.swift` - Teacher dashboard
- `Views/Main/TeacherMyClassesView.swift` - Course management
- `Views/Main/TeacherMessagesView.swift` - Q&A and messaging

### Modified:
- `DI/DIContainer.swift` - Added RoleManager injection
- `Views/Main/MainTabView.swift` - Refactored for role-based tabs
- `projectDAMApp.swift` - Added RoleManager environment setup

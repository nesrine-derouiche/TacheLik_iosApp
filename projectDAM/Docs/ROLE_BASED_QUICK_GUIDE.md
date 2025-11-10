# Role-Based Navigation - Quick Reference Guide

## How User Roles are Fetched

The user's role is retrieved from the **User model** returned by the API:

```swift
struct User: Identifiable, Codable {
    let role: UserRole  // ← This comes from backend
    // ...
}

enum UserRole: String, Codable {
    case student = "Student"
    case mentor = "Teacher"
    case admin = "Admin"
}
```

### Role Sources:
1. **Login Response** - API returns user with role field
2. **JWT Token** - Role is encoded in token payload
3. **User Profile API** - `/user?userId=XXX` endpoint returns role
4. **Auto-Refresh** - `authService.refreshUserData()` fetches latest role

## Role Detection Flow

```
1. User authenticates via LoginView
2. AuthService.login() → AuthResponse with JWT token
3. Decode JWT to extract user ID
4. Fetch full user data from API → includes role
5. RootView.loadUserData() calls this on app launch
6. RoleManager.updateRole(from: user) sets current role
7. MainTabView reads roleManager.currentRole
8. Appropriate tab bar renders based on role
```

## Accessing Current Role in Views

### Method 1: Using @EnvironmentObject
```swift
struct MyView: View {
    @EnvironmentObject var roleManager: RoleManager
    
    var body: some View {
        if roleManager.isAdmin {
            AdminView()
        } else if roleManager.isTeacher {
            TeacherView()
        } else {
            StudentView()
        }
    }
}
```

### Method 2: Using StateObject
```swift
struct MyView: View {
    @StateObject private var roleManager = DIContainer.shared.roleManager
    
    var body: some View {
        Text("Role: \(roleManager.currentRole?.rawValue ?? "unknown")")
    }
}
```

### Method 3: Direct Access
```swift
let currentRole = DIContainer.shared.roleManager.currentRole
if currentRole == .admin {
    // Admin-specific code
}
```

## Navigation Tabs by Role

### 👨‍🎓 Student (No Changes)
```
┌─────────────────────────────────────┐
│ Home│Classes│Explore│Progress│Settings│
└─────────────────────────────────────┘
```
**Tab Destinations:**
- Home → HomeView
- Classes → ClassesView
- Explore → ExploreView
- Progress → LearningProgressView
- Settings → SettingsView

### 👨‍💼 Admin (New)
```
┌─────────────────────────────────┐
│ Dashboard│Requests│Users│Settings│
└─────────────────────────────────┘
```
**Tab Destinations:**
- Dashboard → AdminDashboardView
- Requests → AdminRequestsView
- Users → AdminUsersView
- Settings → SettingsView (reused)

### 👨‍🏫 Teacher (New)
```
┌────────────────────────────────────┐
│ Dashboard│My Classes│Messages│Settings│
└────────────────────────────────────┘
```
**Tab Destinations:**
- Dashboard → TeacherDashboardView
- My Classes → TeacherMyClassesView
- Messages → TeacherMessagesView
- Settings → SettingsView (reused)

## Key Files

| File | Purpose | Role |
|------|---------|------|
| `Services/RoleManager.swift` | Role state management | All |
| `Views/Main/MainTabView.swift` | Role-based tab routing | All |
| `Views/Main/AdminDashboardView.swift` | Admin overview | Admin |
| `Views/Main/AdminRequestsView.swift` | Payment/course approvals | Admin |
| `Views/Main/AdminUsersView.swift` | User management | Admin |
| `Views/Main/TeacherDashboardView.swift` | Teacher overview | Teacher |
| `Views/Main/TeacherMyClassesView.swift` | Course management | Teacher |
| `Views/Main/TeacherMessagesView.swift` | Q&A and messaging | Teacher |

## Admin Dashboard Components

### Stats Cards
- Total Students: 2,847 (+12%)
- Total Mentors: 47 (+3)
- Active Courses: 128 (+8)
- Completion Rate: 73% (+5%)

### Pending Approvals Section
- Dr. Amine Khelifi (Mentor) - 2h ago
- Blockchain Development (Course) - 5h ago
- Prof. Hichem Mansour (Mentor) - 1d ago

### Recent Activity Feed
- New student enrolled
- Course completed
- New mentor joined
- Course updated

## Admin Requests Management

### Request Statuses
- **Pending** - Awaiting approval (3 requests)
- **Approved** - Successfully processed (2 requests)
- **Rejected** - Denied requests (0 requests)

### Payment Requests Example
- Dr. Sami Rezgui: $850.00 → Advanced Web Development → 45 students
- Prof. Leila Ben Amor: $1200.00 → Data Structures & Algorithms → 67 students
- Eng. Karim Hassine: $650.00 → Mobile App Development → 38 students

## Admin Users Management

### User Types
- **Students** - Learning course content
- **Mentors** - Creating and teaching courses
- **Admins** - Platform administration

### User Actions
- View Profile
- Edit User
- Deactivate User

## Teacher Dashboard Components

### Key Metrics
- Total Students: 342
- Active Courses: 5
- Average Rating: 4.8/5.0
- Pending Questions: 23

### Quick Actions
- New Lesson (Create new course content)
- Answer Q&A (Respond to student questions)
- Analytics (View course analytics)
- Students (Manage enrolled students)

### Recent Activity
Shows student actions:
- Ahmed Ben Ali - completed assignment - 2h ago
- Sarra Mansour - asked a question - 4h ago
- Youssef Trabelsi - submitted project - 6h ago

## Teacher My Classes

### Course Display
- Course title and image
- Student count and rating
- New submissions badge
- Completion progress bar

### Actions per Course
- **Edit** - Modify course content
- **Analytics** - View course performance
- **More** - Additional options

### Sort Options
- Newest - Recently created/updated
- Enrollment - By student count
- Rating - By average rating

## Teacher Messages & Q&A

### Tab 1: Q&A Section
Shows unanswered student questions:
- Student name and course
- Question subject and preview
- Timestamp and unread count
- Unanswered indicator

### Tab 2: Direct Messages
Student-teacher direct conversations:
- Student name and course
- Message subject and preview
- Timestamp and unread badge

### Message Details
- Full message content
- Reply composer at bottom
- Send button for responses

## Debugging Tips

### Check Current Role
```swift
// In Xcode console
po DIContainer.shared.roleManager.currentRole

// Output: Optional(Student), Optional(Teacher), or Optional(Admin)
```

### Watch Role Changes
```swift
DIContainer.shared.roleManager.roleDidChange
    .sink { newRole in
        print("👤 Role changed to: \(newRole?.rawValue ?? "nil")")
    }
```

### Verify User Data
```swift
if let user = DIContainer.shared.authService.getCurrentUser() {
    print("User role from API: \(user.role.rawValue)")
}
```

### Check Tab Visibility
Print in MainTabView to see which tabs are rendered:
```swift
print("Current role: \(roleManager.currentRole?.rawValue ?? "unknown")")
```

## Common Issues & Solutions

### Issue: Tabs don't change after login
**Solution:** Verify that RootView calls `roleManager.updateRole(from: user)` when user loads

### Issue: Role stays as student after logging in as admin
**Solution:** Check backend returns correct role value in User response

### Issue: New admin views show errors
**Solution:** Ensure views are imported in MainTabView.swift and all preview files are included

### Issue: Previous user's role persists
**Solution:** RoleManager resets on logout - verify logout flow calls `roleManager.updateRole` with nil

## API Integration

When connecting to your backend, ensure the User endpoint returns:

```json
{
  "user": {
    "id": "user123",
    "username": "john_doe",
    "email": "john@example.com",
    "role": "Admin",  // ← Must be "Student", "Teacher", or "Admin"
    "verified": true,
    "banned": false,
    ...
  }
}
```

## Next Steps

1. **Connect to API** - Link new Admin/Teacher views to backend endpoints
2. **Add Real Data** - Replace mock data with API calls
3. **Implement Actions** - Add functionality to Approve, Reject, Edit buttons
4. **Real-time Updates** - Use WebSockets for live data
5. **Analytics** - Connect Dashboard charts to actual data
6. **Testing** - Test all three roles thoroughly before production

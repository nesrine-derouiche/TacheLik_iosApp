# Role-Based Navigation - Visual Architecture & Diagrams

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        iOS App (TacheLik)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              projectDAMApp (Entry Point)                 │   │
│  │  - Initializes DIContainer                               │   │
│  │  - Sets up environment                                   │   │
│  │  - Passes RoleManager as @EnvironmentObject             │   │
│  └──────────────────────────┬───────────────────────────────┘   │
│                             │                                    │
│  ┌──────────────────────────▼───────────────────────────────┐   │
│  │           RootView (Authentication)                      │   │
│  │  - Checks login status                                   │   │
│  │  - Verifies user (verified, not banned)                  │   │
│  │  - Fetches user data on launch                           │   │
│  │  - Updates RoleManager with user role                    │   │
│  │  - Observes user changes                                 │   │
│  └──────────────────────────┬───────────────────────────────┘   │
│                             │                                    │
│  ┌──────────────────────────▼───────────────────────────────┐   │
│  │        MainTabView (Role-Based Navigation)               │   │
│  │  - Observes roleManager.currentRole                      │   │
│  │  - Renders role-specific tab bar                         │   │
│  │  - Routes to appropriate views                           │   │
│  │                                                            │   │
│  │  ┌─────────────────┬─────────────────┬─────────────────┐ │   │
│  │  │     Student     │      Admin      │     Teacher     │ │   │
│  │  │    (5 tabs)     │    (4 tabs)     │    (4 tabs)     │ │   │
│  │  ├─────────────────┼─────────────────┼─────────────────┤ │   │
│  │  │ Home            │ Dashboard       │ Dashboard       │ │   │
│  │  │ Classes         │ Requests        │ My Classes      │ │   │
│  │  │ Explore         │ Users           │ Messages        │ │   │
│  │  │ Progress        │ Settings        │ Settings        │ │   │
│  │  │ Settings        │                 │                 │ │   │
│  │  └─────────────────┴─────────────────┴─────────────────┘ │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  RoleManager Service                     │   │
│  │  - currentRole: UserRole? (Student, Teacher, Admin)      │   │
│  │  - isStudent, isTeacher, isAdmin properties              │   │
│  │  - roleDidChange Publisher                               │   │
│  │  - updateRole(from user) method                          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  DIContainer (DI)                        │   │
│  │  - authService: AuthServiceProtocol                      │   │
│  │  - roleManager: RoleManager                              │   │
│  │  - networkService: NetworkServiceProtocol                │   │
│  │  - courseService: CourseServiceProtocol                  │   │
│  │  - profileService: ProfileServiceProtocol                │   │
│  │  - socketService: SocketServiceProtocol                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## User Role Detection Flow

```
┌─────────────────────┐
│   User Action       │
│   (Login/Signup)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  AuthService                        │
│  - Send credentials to backend      │
│  - Receive JWT token                │
│  - Extract user ID from JWT         │
└──────────┬──────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  Backend API                        │
│  - Validate credentials             │
│  - Return JWT token                 │
│  - Token includes: id, email, role  │
└──────────┬──────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  Fetch User Data                    │
│  GET /user?userId=XXX               │
│  Returns User object with:          │
│  - id, username, email              │
│  - role: "Student"|"Teacher"|"Admin"│
└──────────┬──────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  RootView.loadUserData()            │
│  - Store user in AuthService        │
│  - Store token in UserDefaults      │
└──────────┬──────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  RoleManager.updateRole(from: user) │
│  - Extract user.role                │
│  - Update @Published var            │
│  - Send roleDidChange notification  │
└──────────┬──────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  MainTabView Observes               │
│  - Reads roleManager.currentRole    │
│  - Renders appropriate tab bar      │
│  - Routes to correct views          │
└─────────────────────────────────────┘
```

---

## Tab Navigation Architecture

```
MainTabView
│
├─► roleManager.currentRole = .student
│   │
│   ├─► StudentTab.home        → HomeView
│   ├─► StudentTab.classes     → ClassesView
│   ├─► StudentTab.explore     → ExploreView
│   ├─► StudentTab.progress    → LearningProgressView
│   └─► StudentTab.settings    → SettingsView
│
├─► roleManager.currentRole = .admin
│   │
│   ├─► AdminTab.dashboard     → AdminDashboardView
│   │   ├─ Stats Cards
│   │   ├─ Pending Approvals
│   │   ├─ Analytics Section
│   │   └─ Recent Activity
│   │
│   ├─► AdminTab.requests      → AdminRequestsView
│   │   ├─ Pending Requests
│   │   ├─ Approved Requests
│   │   └─ Rejected Requests
│   │
│   ├─► AdminTab.users         → AdminUsersView
│   │   ├─ Students List
│   │   ├─ Mentors List
│   │   └─ Admins List
│   │
│   └─► AdminTab.settings      → SettingsView
│
└─► roleManager.currentRole = .mentor (Teacher)
    │
    ├─► TeacherTab.dashboard   → TeacherDashboardView
    │   ├─ Teacher Metrics
    │   ├─ Quick Actions
    │   └─ Student Activity
    │
    ├─► TeacherTab.myClasses   → TeacherMyClassesView
    │   ├─ Course List
    │   ├─ Search & Sort
    │   ├─ Create Course Button
    │   └─ Course Analytics
    │
    ├─► TeacherTab.messages    → TeacherMessagesView
    │   ├─ Q&A Section
    │   ├─ Direct Messages
    │   └─ Message Detail View
    │
    └─► TeacherTab.settings    → SettingsView
```

---

## Component Hierarchy - Admin Dashboard

```
AdminDashboardView
│
├─► headerSection()
│   ├─ "Welcome back, Admin"
│   └─ "Platform Overview & Management"
│
├─► statsGrid()
│   ├─► Row 1
│   │   ├─ StatCard (Total Students, 2847, +12%)
│   │   └─ StatCard (Total Mentors, 47, +3)
│   │
│   └─► Row 2
│       ├─ StatCard (Active Courses, 128, +8)
│       └─ StatCard (Completion Rate, 73%, +5%)
│
├─► pendingApprovalsSection()
│   ├─ Title with badge (3)
│   ├─► ApprovalItemView
│   │   ├─ Dr. Amine Khelifi (mentor) - 2h ago
│   │   ├─ Approve button
│   │   └─ Reject button
│   ├─► ApprovalItemView
│   │   ├─ Blockchain Development (course)
│   │   ├─ Approve button
│   │   └─ Reject button
│   └─► ApprovalItemView
│       ├─ Prof. Hichem Mansour (mentor)
│       ├─ Approve button
│       └─ Reject button
│
├─► analyticsSection()
│   └─ Analytics Dashboard Placeholder
│
└─► recentActivitySection()
    ├─► ActivityItemView (New student enrolled)
    ├─► ActivityItemView (Course completed)
    ├─► ActivityItemView (New mentor joined)
    └─► ActivityItemView (Course updated)
```

---

## Data Flow Diagram

```
┌──────────────────────┐
│   Backend API        │
│  - /auth/login       │
│  - /auth/signup      │
│  - /user             │
│  - /admin/*          │
│  - /teacher/*        │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────────┐
│   NetworkService         │
│   - HTTP Requests        │
│   - Error Handling       │
│   - Response Parsing     │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────┐
│   AuthService            │
│   - Login/Logout         │
│   - Token Management     │
│   - User Data Storage    │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────┐
│   RoleManager            │
│   - Role State           │
│   - Role Updates         │
│   - Change Notifications │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────┐
│   MainTabView            │
│   - Tab Routing          │
│   - View Display         │
│   - State Management     │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────┐
│   Admin/Teacher Views    │
│   - UI Display           │
│   - User Interactions    │
│   - Local State          │
└──────────────────────────┘
```

---

## Role-Based Access Control Matrix

```
┌────────────────────┬─────────┬──────────┬─────────┐
│       Feature      │ Student │  Admin   │ Teacher │
├────────────────────┼─────────┼──────────┼─────────┤
│ Home               │   ✅    │    ❌    │   ❌    │
│ Classes            │   ✅    │    ❌    │   ❌    │
│ Explore            │   ✅    │    ❌    │   ❌    │
│ Progress           │   ✅    │    ❌    │   ❌    │
│ Dashboard (Admin)  │   ❌    │    ✅    │   ❌    │
│ Dashboard (Teacher)│   ❌    │    ❌    │   ✅    │
│ Requests           │   ❌    │    ✅    │   ❌    │
│ Users Management   │   ❌    │    ✅    │   ❌    │
│ My Classes         │   ❌    │    ❌    │   ✅    │
│ Messages           │   ❌    │    ❌    │   ✅    │
│ Settings           │   ✅    │    ✅    │   ✅    │
└────────────────────┴─────────┴──────────┴─────────┘
```

---

## Tab Bar Styling Comparison

```
STUDENT TAB BAR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│ 🏠 Home │ 📚 Classes │ 🔍 Explore │ 📊 Progress │ ⚙️ Settings │
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Colors: Cyan, Accent, Secondary, Success, Warning
Total Height: 70pt
Icons: SF Symbols (22-24pt)
Animation: Spring with damping

ADMIN TAB BAR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│ 📊 Dashboard │ 📋 Requests │ 👥 Users │ ⚙️ Settings │
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Colors: Primary, Warning, Success, Error
Total Height: 70pt
Icons: SF Symbols (22-24pt)
Animation: Spring with damping

TEACHER TAB BAR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│ 📊 Dashboard │ 📕 My Classes │ 💬 Messages │ ⚙️ Settings │
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Colors: Primary, Accent, Success, Warning
Total Height: 70pt
Icons: SF Symbols (22-24pt)
Animation: Spring with damping
```

---

## State Management Flow

```
┌────────────────────────────────────┐
│     App-Level State                │
│  (@EnvironmentObject)              │
│                                    │
│  ├─ SessionManager                │
│  │   ├─ isSessionTerminated       │
│  │   ├─ showSessionAlert          │
│  │   └─ sessionTerminationReason  │
│  │                                │
│  ├─ RoleManager (@Published)      │
│  │   ├─ currentRole               │
│  │   └─ roleDidChange Publisher   │
│  │                                │
│  └─ AuthService (@ObservedObject) │
│      ├─ currentUser               │
│      └─ isAuthenticated           │
└────────────┬───────────────────────┘
             │
             ▼
┌────────────────────────────────────┐
│     View-Level State               │
│  (@State, @StateObject)            │
│                                    │
│  ├─ MainTabView                   │
│  │   ├─ selectedStudentTab        │
│  │   ├─ selectedAdminTab          │
│  │   └─ selectedTeacherTab        │
│  │                                │
│  ├─ AdminDashboardView            │
│  │   ├─ totalStudents             │
│  │   ├─ totalMentors              │
│  │   ├─ activeCourses             │
│  │   └─ completionRate            │
│  │                                │
│  └─ Other Admin/Teacher Views     │
│      └─ Specific view state       │
└────────────────────────────────────┘
```

---

## Component Communication

```
┌──────────────────┐
│  AdminDashboard  │
│       View       │
└────────┬─────────┘
         │
    ┌────┴────┐
    │          │
    ▼          ▼
┌─────────┐ ┌──────────────┐
│  State  │ │ Environment  │
│ @State  │ │  @Environment│
│         │ │ colorScheme  │
└────┬────┘ └──────────────┘
     │
     ├──► StatCard
     │    ├─ icon
     │    ├─ title
     │    ├─ value
     │    └─ trend
     │
     ├──► ApprovalItemView
     │    ├─ title
     │    ├─ subtitle
     │    ├─ approve()
     │    └─ reject()
     │
     └──► ActivityItemView
          ├─ icon
          ├─ title
          └─ timestamp
```

---

## Error Handling Flow

```
┌──────────────────┐
│  API Request     │
└────────┬─────────┘
         │
         ▼
    ┌─────────────────────────────────┐
    │   NetworkService.request()      │
    │   Throw NetworkError?           │
    └─────────────────────────────────┘
         │
    ┌────┴────┬─────────┬────────────┐
    │          │         │            │
    ▼          ▼         ▼            ▼
 Success   Unauthorized NotFound   ServerError
    │          │         │            │
    ▼          ▼         ▼            ▼
 Update UI  Show Login   Error      Error
           Message      Message     Message
```

---

## File Organization

```
projectDAM/
│
├─ Services/
│  ├─ RoleManager.swift           ← NEW
│  ├─ AuthService.swift
│  ├─ NetworkService.swift
│  └─ ...
│
├─ Views/
│  ├─ Main/
│  │  ├─ MainTabView.swift        ← MODIFIED
│  │  ├─ AdminDashboardView.swift    ← NEW
│  │  ├─ AdminRequestsView.swift     ← NEW
│  │  ├─ AdminUsersView.swift        ← NEW
│  │  ├─ TeacherDashboardView.swift  ← NEW
│  │  ├─ TeacherMyClassesView.swift  ← NEW
│  │  ├─ TeacherMessagesView.swift   ← NEW
│  │  ├─ HomeView.swift
│  │  ├─ SettingsViewNew.swift
│  │  └─ ...
│  ├─ Auth/
│  └─ Components/
│
├─ Models/
│  ├─ Models.swift
│  ├─ SocketModels.swift
│  └─ ...
│
├─ DI/
│  └─ DIContainer.swift           ← MODIFIED
│
├─ Docs/
│  ├─ ROLE_BASED_NAVIGATION.md        ← NEW
│  ├─ ROLE_BASED_QUICK_GUIDE.md       ← NEW
│  ├─ IMPLEMENTATION_COMPLETE.md      ← NEW
│  ├─ API_INTEGRATION_GUIDE.md        ← NEW
│  └─ ...
│
└─ projectDAMApp.swift            ← MODIFIED
```

---

## Deployment Architecture

```
┌────────────────────────────────────────────┐
│          Production Environment            │
├────────────────────────────────────────────┤
│                                            │
│  ┌──────────────┐      ┌──────────────┐  │
│  │  iOS Device  │◄────►│  Backend API │  │
│  │   TacheLik   │      │   (Node.js)  │  │
│  │    v1.0      │      │   Server     │  │
│  └──────────────┘      └──────────────┘  │
│        ▲                                   │
│        │                                   │
│  ┌─────┴────────────────────────────┐    │
│  │  Roles Handled By API            │    │
│  │  - Student (default)             │    │
│  │  - Teacher (instructor)          │    │
│  │  - Admin (platform management)   │    │
│  └──────────────────────────────────┘    │
│                                            │
│  ┌──────────────┐      ┌──────────────┐  │
│  │   Database   │◄────►│   Backend    │  │
│  │  (MongoDB)   │      │     API      │  │
│  │              │      │              │  │
│  └──────────────┘      └──────────────┘  │
│                                            │
└────────────────────────────────────────────┘
```

---

This comprehensive visual guide shows the complete architecture of the role-based navigation system from top-level overview down to individual component interactions.

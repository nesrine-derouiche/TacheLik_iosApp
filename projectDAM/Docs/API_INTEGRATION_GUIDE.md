# API Integration Guide for Role-Based Views

## Overview
This guide explains how to connect the new Admin and Teacher views to your backend API endpoints.

## Backend Requirements

### User Role Values
Ensure your backend returns one of these exact values for the `role` field:

```json
{
  "role": "Student"  // or "Teacher" or "Admin"
}
```

### Example User Response
```json
{
  "id": "user123",
  "username": "john_doe",
  "email": "john@example.com",
  "role": "Admin",
  "verified": true,
  "banned": false,
  "created_date": "2025-11-01T00:00:00Z",
  "image": null
}
```

---

## Admin Dashboard - API Integration

### Current State
Mock data with hardcoded values:
```swift
@State private var totalStudents = 2847
@State private var totalMentors = 47
@State private var activeCourses = 128
@State private var completionRate = 73
@State private var pendingApprovals = 3
```

### Required API Endpoints

#### 1. Get Dashboard Stats
```
GET /admin/dashboard/stats
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalStudents": 2847,
    "studentsTrend": 12,
    "totalMentors": 47,
    "mentorsTrend": 3,
    "activeCourses": 128,
    "coursesTrend": 8,
    "completionRate": 73,
    "completionTrend": 5
  }
}
```

**Implementation:**
```swift
@State private var dashboardStats: DashboardStats?
@State private var isLoading = false

.onAppear {
    loadDashboardStats()
}

private func loadDashboardStats() {
    isLoading = true
    Task {
        do {
            let response: DashboardStatsResponse = try await networkService.request(
                endpoint: "/admin/dashboard/stats",
                method: .GET,
                body: nil,
                headers: ["Authorization": "Bearer \(token)"]
            )
            dashboardStats = response.data
            isLoading = false
        } catch {
            print("Error loading dashboard stats: \(error)")
            isLoading = false
        }
    }
}
```

#### 2. Get Pending Approvals
```
GET /admin/approvals/pending
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "approval1",
      "type": "mentor",  // "mentor" or "course"
      "name": "Dr. Amine Khelifi",
      "title": "AI & Machine Learning",
      "createdAt": "2025-11-08T10:00:00Z"
    }
  ]
}
```

#### 3. Approve/Reject Request
```
POST /admin/approvals/{id}/approve
POST /admin/approvals/{id}/reject
```

---

## Admin Requests - API Integration

### Current State
Mock payment requests with hardcoded data.

### Required API Endpoints

#### 1. Get Payment Requests by Status
```
GET /admin/requests/payments?status=pending
GET /admin/requests/payments?status=approved
GET /admin/requests/payments?status=rejected
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "payment1",
      "amount": 850.00,
      "instructorName": "Dr. Sami Rezgui",
      "courseName": "Advanced Web Development",
      "studentCount": 45,
      "requestDate": "2025-11-03",
      "status": "pending"
    }
  ]
}
```

#### 2. Approve Payment Request
```
POST /admin/requests/payments/{id}/approve
```

#### 3. Reject Payment Request
```
POST /admin/requests/payments/{id}/reject
```

---

## Admin Users - API Integration

### Current State
Mock user data with hardcoded user lists.

### Required API Endpoints

#### 1. Get Users by Role
```
GET /admin/users?role=student
GET /admin/users?role=mentor
GET /admin/users?role=admin
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "user1",
      "name": "Ahmed Ben Ali",
      "email": "ahmed.benali@esprit.tn",
      "role": "student",
      "status": "active",
      "enrolledCourses": 5,
      "image": null
    }
  ]
}
```

#### 2. Search Users
```
GET /admin/users?search=ahmed
```

#### 3. Update User Status
```
PUT /admin/users/{id}/status
Body: { "status": "active" | "inactive" | "banned" }
```

#### 4. Delete/Deactivate User
```
DELETE /admin/users/{id}
```

---

## Teacher Dashboard - API Integration

### Current State
Mock metrics with hardcoded values.

### Required API Endpoints

#### 1. Get Teacher Stats
```
GET /teacher/dashboard/stats
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalStudents": 342,
    "activeCourses": 5,
    "averageRating": 4.8,
    "pendingQuestions": 23
  }
}
```

#### 2. Get Recent Student Activity
```
GET /teacher/activity/recent
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "studentName": "Ahmed Ben Ali",
      "course": "Web Development",
      "action": "completed assignment",
      "timestamp": "2025-11-10T14:30:00Z"
    }
  ]
}
```

---

## Teacher My Classes - API Integration

### Current State
Mock courses with hardcoded data.

### Required API Endpoints

#### 1. Get Teacher's Courses
```
GET /teacher/courses
GET /teacher/courses?sort=enrollment  // or rating, newest
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "course1",
      "title": "Advanced Web Development",
      "image": "webdev",
      "studentCount": 89,
      "rating": 4.9,
      "newSubmissions": 5,
      "completionRate": 0.67
    }
  ]
}
```

#### 2. Create New Course
```
POST /teacher/courses
Body: {
  "title": "New Course",
  "description": "...",
  "level": "Beginner"
}
```

#### 3. Update Course
```
PUT /teacher/courses/{id}
Body: { "title": "...", "description": "..." }
```

#### 4. Get Course Analytics
```
GET /teacher/courses/{id}/analytics
```

---

## Teacher Messages - API Integration

### Current State
Mock Q&A and messages with hardcoded data.

### Required API Endpoints

#### 1. Get Q&A Questions
```
GET /teacher/qa?status=unanswered
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "q1",
      "studentName": "Ahmed Ben Ali",
      "course": "Web Development",
      "subject": "How to implement JWT authentication?",
      "preview": "I'm trying to implement JWT...",
      "timestamp": "2025-11-10T12:00:00Z",
      "isAnswered": false,
      "unreadCount": 1
    }
  ]
}
```

#### 2. Get Direct Messages
```
GET /teacher/messages?type=direct
```

#### 3. Send Message/Answer
```
POST /teacher/messages/{id}/reply
Body: { "content": "..." }
```

---

## Model Definitions

### Create These Models in `Models/Models.swift`

```swift
// MARK: - Admin Models

struct DashboardStats: Decodable {
    let totalStudents: Int
    let studentsTrend: Int
    let totalMentors: Int
    let mentorsTrend: Int
    let activeCourses: Int
    let coursesTrend: Int
    let completionRate: Int
    let completionTrend: Int
}

struct Approval: Identifiable, Decodable {
    let id: String
    let type: String  // "mentor" or "course"
    let name: String
    let title: String
    let createdAt: String
}

struct PaymentRequest: Identifiable, Decodable {
    let id: String
    let amount: Double
    let instructorName: String
    let courseName: String
    let studentCount: Int
    let requestDate: String
    let status: String  // "pending", "approved", "rejected"
}

struct AdminUser: Identifiable, Decodable {
    let id: String
    let name: String
    let email: String
    let role: String
    let status: String
    let enrolledCourses: Int?
    let image: String?
}

// MARK: - Teacher Models

struct TeacherCourse: Identifiable, Decodable {
    let id: String
    let title: String
    let image: String
    let studentCount: Int
    let rating: Double
    let newSubmissions: Int
    let completionRate: Double
}

struct StudentActivity: Decodable {
    let studentName: String
    let course: String
    let action: String
    let timestamp: String
}

struct QAQuestion: Identifiable, Decodable {
    let id: String
    let studentName: String
    let course: String
    let subject: String
    let preview: String
    let timestamp: String
    let isAnswered: Bool
    let unreadCount: Int
}

struct DirectMessage: Identifiable, Decodable {
    let id: String
    let senderName: String
    let course: String
    let subject: String
    let preview: String
    let timestamp: String
    let unreadCount: Int
}
```

---

## Example Implementation

### Replace Mock Data in AdminDashboardView

**Before:**
```swift
@State private var totalStudents = 2847
@State private var totalMentors = 47
@State private var activeCourses = 128
@State private var completionRate = 73
```

**After:**
```swift
@State private var dashboardStats: DashboardStats?
@State private var isLoading = false
@State private var approvals: [Approval] = []

.onAppear {
    loadData()
}

private func loadData() {
    isLoading = true
    Task {
        do {
            // Load dashboard stats
            let statsResponse: ApiResponse<DashboardStats> = try await networkService.request(
                endpoint: "/admin/dashboard/stats",
                method: .GET
            )
            dashboardStats = statsResponse.data
            
            // Load pending approvals
            let approvalsResponse: ApiResponse<[Approval]> = try await networkService.request(
                endpoint: "/admin/approvals/pending",
                method: .GET
            )
            approvals = approvalsResponse.data
            
            isLoading = false
        } catch {
            print("Error loading data: \(error)")
            isLoading = false
        }
    }
}

// Update UI to use dashboardStats instead of hardcoded values
var body: some View {
    if let stats = dashboardStats {
        StatCard(
            icon: "person.2.fill",
            iconColor: .brandPrimary,
            title: "Total Students",
            value: "\(stats.totalStudents)",
            trend: "+\(stats.studentsTrend)%",
            trendColor: .brandSuccess
        )
    }
}
```

---

## Error Handling

Add error handling to all API calls:

```swift
do {
    let data = try await networkService.request(...)
    // Update UI
} catch NetworkError.unauthorized {
    // Show login screen
} catch NetworkError.notFound {
    // Show error message
} catch {
    // Show generic error
}
```

---

## Authentication

All endpoints require Bearer token:

```swift
headers: ["Authorization": "Bearer \(authService.getAuthToken() ?? "")"]
```

---

## Rate Limiting

Consider implementing:
- Debouncing for search
- Pagination for user lists
- Caching for dashboard stats
- Background refresh

---

## Testing

Test endpoints using:
1. Postman
2. curl commands
3. Xcode network debugging
4. Charles Proxy for packet inspection

---

## Deployment Checklist

- [ ] All API endpoints tested
- [ ] Error handling implemented
- [ ] Loading states shown
- [ ] Empty states handled
- [ ] Pagination implemented (if needed)
- [ ] Search functionality verified
- [ ] Images loading correctly
- [ ] Timestamps formatted properly
- [ ] Numbers formatted with proper decimals
- [ ] Date formatting matches backend

---

## Performance Tips

1. **Lazy Loading** - Load data on-demand
2. **Pagination** - Load 10-20 items at a time
3. **Caching** - Cache dashboard stats for 5 minutes
4. **Background Refresh** - Refresh in background
5. **Debouncing** - Debounce search queries
6. **Image Caching** - Cache user avatars

---

## Troubleshooting

### Data Not Loading
- Check network connectivity
- Verify API endpoints are correct
- Check authentication token
- Verify response format matches model

### Role Not Detected
- Check backend returns correct role value
- Verify JWT token includes role
- Check role enum matches backend values

### UI Not Updating
- Verify @State variables are marked @State
- Check onChange observers
- Verify .onAppear is called
- Check for SwiftUI caching issues

---

This guide provides everything needed to connect the new Admin and Teacher views to your backend API!

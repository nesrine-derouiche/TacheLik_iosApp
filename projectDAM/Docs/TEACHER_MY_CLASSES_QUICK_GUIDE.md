# TeacherMyClassesView - Quick Integration Guide

## 🚀 Quick Start (Copy & Paste)

### 1. Use in Navigation
```swift
// In your main navigation or tab view:
NavigationLink("My Classes") {
    let viewModel = DIContainer.shared.makeTeacherMyClassesViewModel()
    TeacherMyClassesView(viewModel: viewModel)
}
```

### 2. Use in TabView (for Teachers)
```swift
TabView {
    // ... other tabs ...
    
    let viewModel = DIContainer.shared.makeTeacherMyClassesViewModel()
    TeacherMyClassesView(viewModel: viewModel)
        .tabItem {
            Label("My Classes", systemImage: "book.fill")
        }
}
```

### 3. Direct Navigation
```swift
Button("View My Classes") {
    let viewModel = DIContainer.shared.makeTeacherMyClassesViewModel()
    navigationDestination = .teacherClasses(viewModel)
}
```

## 📋 Requirements Checklist

Before using this view, ensure:

- ✅ User is authenticated
- ✅ User has teacher role
- ✅ Backend is running and accessible
- ✅ JWT token is valid
- ✅ API endpoints are available:
  - `GET /course/my-courses`
  - `GET /course/available-classes`

## 🔧 Backend Setup

### Required Backend Endpoints

#### 1. Get My Courses
**Endpoint**: `GET /api/course/my-courses`  
**Auth**: Required (Bearer token)  
**Returns**: Classes with courses grouped

**Example Response:**
```json
{
  "classesWithCourses": [
    {
      "class": {
        "id": "class-mb1",
        "title": "MB1",
        "description": "Première année Master",
        "image": "mb1.jpg",
        "class_order": "1",
        "filter_name": { "filter_name": "Master" }
      },
      "courses": [
        {
          "id": "course-1",
          "name": "Logique et méthodes de raisonnement",
          "description": "Introduction to logic",
          "image": "logic.jpg",
          "time": 2.5,
          "nb_videos": 12,
          "nb_quizzes": 3,
          "price": 49.99,
          "level": "Introduction",
          "course_order": "1",
          "course_reduction": 0,
          "hot": true,
          "approval_status": "approved",
          "folder_id": null,
          "author": {
            "id": "teacher-1",
            "username": "Dr. Mohamed",
            "email": "mohamed@esprit.tn",
            "image": null
          },
          "studentCount": 9
        }
      ]
    }
  ],
  "success": true
}
```

#### 2. Get Available Classes
**Endpoint**: `GET /api/course/available-classes`  
**Auth**: Required (Bearer token)  
**Returns**: List of classes where teacher can create courses

**Example Response:**
```json
{
  "availableClasses": [
    {
      "id": "class-mb1",
      "title": "MB1",
      "image": null,
      "class_order": "1",
      "filter_name": { "filter_name": "Master" }
    },
    {
      "id": "class-mb2",
      "title": "MB2",
      "image": null,
      "class_order": "2",
      "filter_name": { "filter_name": "Master" }
    }
  ],
  "success": true
}
```

## 🎨 Customization

### Change Colors
```swift
// In TeacherMyClassesView.swift, modify status badge colors:
private var statusColor: Color {
    switch course.approvalStatus.lowercased() {
    case "approved":
        return .brandSuccess  // Change this
    case "pending":
        return .brandWarning  // Change this
    case "declined":
        return .brandError    // Change this
    default:
        return .secondary
    }
}
```

### Add More Sort Options
```swift
// In TeacherMyClassesViewModel.swift, add to enum:
enum SortOption: String, CaseIterable {
    case newest = "Newest"
    case enrollment = "Enrollment"
    case rating = "Rating"
    case price = "Price"       // NEW
    case alphabetical = "A-Z"  // NEW
}

// Add sorting logic in sortCourses method
```

### Customize Empty State
```swift
// In TeacherMyClassesView.swift, modify emptyView:
private var emptyView: some View {
    VStack(spacing: 20) {
        Image(systemName: "books.vertical")  // Change icon
            .font(.system(size: 60, weight: .light))
        
        Text("No Classes Yet")  // Change title
        Text("Your custom message here")  // Change message
        
        // Your custom button
    }
}
```

## 🐛 Troubleshooting

### Issue 1: "No classes displayed"
**Possible causes:**
- User is not a teacher
- No courses created yet
- Backend not returning data

**Solution:**
```swift
// Add debug logging in ViewModel:
func loadCourses() async {
    print("🔍 Loading courses...")
    // ... existing code
    print("✅ Loaded \(classes.count) classes")
}
```

### Issue 2: "Images not loading"
**Possible causes:**
- Image URLs incorrect
- CORS issues
- File not found on server

**Solution:**
Check image URL construction in `TeacherClass` model:
```swift
var imageURL: URL? {
    guard let image = image else { return nil }
    print("🖼️ Image URL: \(baseURL)/uploads/classes/\(image)")
    // ... rest of code
}
```

### Issue 3: "Search not working"
**Possible cause:**
- Case sensitivity
- Special characters

**Solution:**
Search is case-insensitive and searches in class titles, course names, and descriptions. Check the filtering logic in ViewModel.

### Issue 4: "Empty state shown but data exists"
**Possible cause:**
- Filtering too aggressive
- Backend returning unexpected structure

**Solution:**
```swift
// In TeacherMyClassesViewModel, add logging:
var filteredAndSortedClasses: [ClassWithCourses] {
    print("📊 All classes: \(allClasses.count)")
    print("🔍 Search text: \(searchText)")
    // ... rest of code
}
```

## 📊 Testing

### Test with Mock Data
```swift
// In previews or development:
let mockService = MockTeacherCoursesService()
let viewModel = TeacherMyClassesViewModel(teacherCoursesService: mockService)
TeacherMyClassesView(viewModel: viewModel)
```

### Test API Endpoints
```bash
# Test my-courses endpoint
curl -X GET "http://localhost:3001/api/course/my-courses" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Test available-classes endpoint
curl -X GET "http://localhost:3001/api/course/available-classes" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 📱 UI States Reference

### 1. Loading State
- Shows spinner
- Message: "Loading your classes..."

### 2. Empty State
- Book icon
- Title: "No Classes Yet"
- Button: "Create Your First Course"

### 3. Error State
- Warning icon
- Error message displayed
- Retry button

### 4. Loaded State (Normal)
- Search bar
- Sort options (Newest, Enrollment, Rating)
- Statistics cards
- Create New Course button
- Classes list (expandable)
- Course cards inside classes

## 🎯 Features Quick Reference

| Feature | Gesture/Action | Result |
|---------|---------------|--------|
| **Search** | Type in search bar | Filters classes & courses |
| **Clear Search** | Tap X button | Clears search text |
| **Sort** | Tap sort option | Reorders courses |
| **Expand Class** | Tap class header | Shows/hides courses |
| **Refresh** | Pull down | Reloads data |
| **Create Course** | Tap "+ Create" | Opens creation sheet |
| **Edit Course** | Tap "Edit" button | Navigate to edit (TODO) |
| **View Analytics** | Tap "Analytics" | Navigate to stats (TODO) |

## 🔗 Related Files

```
Models/
  ├─ TeacherClassModels.swift         ← DTOs and domain models

Services/
  ├─ TeacherCoursesService.swift      ← API service
  ├─ NetworkService.swift             ← Network layer
  └─ AuthService.swift                ← Authentication

ViewModels/
  └─ TeacherMyClassesViewModel.swift  ← Business logic

Views/Main/
  └─ TeacherMyClassesView.swift       ← UI components

DI/
  └─ DIContainer.swift                ← Dependency injection

Config/
  └─ AppConfig.swift                  ← Configuration
```

## 💡 Next Steps

After integrating this view, consider:

1. **Course Creation Flow**
   - Implement full course creation form
   - Add image upload
   - Add validation
   
2. **Course Editing**
   - Create edit course view
   - Handle image updates
   - Submit to backend
   
3. **Analytics Integration**
   - Navigate to course analytics
   - Show detailed stats
   - Display charts
   
4. **Course Management**
   - Archive courses
   - Delete courses
   - Manage students

## 📚 Additional Resources

- **Backend API**: See `course.routes.ts` in backend
- **Android Version**: See `TeacherMyClassesScreen.kt` for reference
- **Full Documentation**: See `TEACHER_MY_CLASSES_IMPLEMENTATION.md`
- **Architecture**: Follow MVVM pattern used throughout app

## ✅ Verification Checklist

Before deploying:

- [ ] Backend endpoints responding correctly
- [ ] Authentication working
- [ ] Images loading properly
- [ ] Search functioning
- [ ] Sort options working
- [ ] Expand/collapse smooth
- [ ] Pull-to-refresh working
- [ ] Empty state displays correctly
- [ ] Error handling tested
- [ ] Loading states shown
- [ ] Statistics calculating correctly
- [ ] Memory usage acceptable
- [ ] No force unwraps
- [ ] Logging appropriate
- [ ] Preview working

---

**Quick Help**: If you encounter any issues, check the console logs for detailed debug information. All network requests and responses are logged when `AppConfig.enableLogging` is true.

import SwiftUI

// MARK: - Section Model
struct ClassSection: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    let color: Color
    let courses: [Course]
}

struct ClassesView: View {
    @State private var selectedFilter = 0
    
    let filters = ["All", "1A", "2A", "3A & 3B"]
    
    // MARK: - Section 1A Courses
    let section1ACourses = [
        Course(id: "1", title: "Algorithme", instructor: "MB1", image: "algorithm", category: "Programming", level: .beginner, rating: 4.7, progress: nil, duration: 15.0, totalLessons: 20, completedLessons: 0, lastAccessDate: nil),
        Course(id: "2", title: "Web Design Basics", instructor: "Dr. Hichem Ben Said", image: "web", category: "Design", level: .beginner, rating: 4.8, progress: nil, duration: 12.0, totalLessons: 18, completedLessons: 0, lastAccessDate: nil),
        Course(id: "5", title: "Database Fundamentals", instructor: "Prof. Leila Ben Amor", image: "database", category: "Database", level: .beginner, rating: 4.6, progress: nil, duration: 10.0, totalLessons: 15, completedLessons: 0, lastAccessDate: nil)
    ]
    
    // MARK: - Section 2A Courses
    let section2ACourses = [
        Course(id: "3", title: "Qt", instructor: "MB3", image: "qt", category: "Programming", level: .intermediate, rating: 4.6, progress: 0.42, duration: 18.0, totalLessons: 30, completedLessons: 13, lastAccessDate: Date()),
        Course(id: "4", title: "Data Structures & Algorithms", instructor: "Dr. Sarah Smith", image: "datastructures", category: "Programming", level: .intermediate, rating: 4.9, progress: 0.25, duration: 25.0, totalLessons: 35, completedLessons: 9, lastAccessDate: Date()),
        Course(id: "6", title: "Network Programming", instructor: "Prof. Karim Feki", image: "network", category: "Networking", level: .intermediate, rating: 4.5, progress: nil, duration: 16.0, totalLessons: 22, completedLessons: 0, lastAccessDate: nil)
    ]
    
    // MARK: - Section 3A & 3B Courses
    let section3ABCourses = [
        Course(id: "7", title: "Théorie des langages (TLA)", instructor: "Dr. Mohamed Trabelsi", image: "language", category: "Theory", level: .advanced, rating: 4.8, progress: nil, duration: 20.0, totalLessons: 25, completedLessons: 0, lastAccessDate: nil),
        Course(id: "8", title: "Flutter Flow", instructor: "Dr. Amina Saidi", image: "flutter", category: "Mobile Development", level: .advanced, rating: 4.7, progress: 0.60, duration: 28.0, totalLessons: 40, completedLessons: 24, lastAccessDate: Date()),
        Course(id: "9", title: "Cloud Architecture", instructor: "Prof. Sami Rezgui", image: "cloud", category: "Cloud", level: .advanced, rating: 4.6, progress: nil, duration: 22.0, totalLessons: 32, completedLessons: 0, lastAccessDate: nil)
    ]
    
    var sections: [ClassSection] {
        [
            ClassSection(name: "1A", displayName: "1A", color: .blue, courses: section1ACourses),
            ClassSection(name: "2A", displayName: "2A", color: .purple, courses: section2ACourses),
            ClassSection(name: "3A & 3B", displayName: "3A & 3B", color: .orange, courses: section3ABCourses)
        ]
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Filter Pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<filters.count, id: \.self) { index in
                                    FilterPill(
                                        title: filters[index],
                                        isSelected: selectedFilter == index
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedFilter = index
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Content based on selected filter
                        if selectedFilter == 0 {
                            // All Sections View
                            AllSectionsView(sections: sections, onSectionTap: { sectionName in
                                if let index = filters.firstIndex(of: sectionName) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedFilter = index
                                    }
                                }
                            })
                        } else {
                            // Individual Section View
                            if let selectedSection = sections[safe: selectedFilter - 1] {
                                SectionCoursesView(section: selectedSection)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.bottom, DS.barHeight + 8)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Classes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Button(action: {}) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                }
            }
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient.brandPrimaryGradient
                        } else {
                            Color(.secondarySystemBackground)
                        }
                    }
                )
                .cornerRadius(20)
                .shadow(color: isSelected ? Color.brandPrimary.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
    }
}

struct BeautifulCourseListCard: View {
    let course: Course
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Course Icon
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: "book.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                )
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(course.title)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(2)
                
                Text(course.instructor)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                if let rating = course.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.brandWarning)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                
                if let progress = course.progress {
                    HStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.tertiarySystemFill))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(color)
                                    .frame(width: geometry.size.width * progress, height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(color)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - All Sections View
struct AllSectionsView: View {
    let sections: [ClassSection]
    let onSectionTap: (String) -> Void
    
    var body: some View {
        VStack(spacing: 28) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 16) {
                    // Section Header
                    HStack {
                        Text(section.displayName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(section.courses.count) Courses")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    
                    // Preview: Show first 2 courses
                    VStack(spacing: 12) {
                        ForEach(section.courses.prefix(2)) { course in
                            NavigationLink(destination: OurCoursesView(section: section, courses: OurCoursesView.getCoursesForSection(section), className: course.title)) {
                                BeautifulCourseListCard(course: course, color: section.color)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    // Navigation Button
                    Button(action: {
                        onSectionTap(section.displayName)
                    }) {
                        HStack(spacing: 8) {
                            Text("Go to \(section.displayName)")
                                .font(.system(size: 15, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                colors: [section.color, section.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: section.color.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 0)
            }
        }
    }
}

// MARK: - Section Courses View
struct SectionCoursesView: View {
    let section: ClassSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Title with Course Count
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.displayName)
                        .font(.system(size: 28, weight: .bold))
                    Text("All courses in this section")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(section.courses.count)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(section.color)
                    .opacity(0.3)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            
            // All Courses in Section - Navigatable
            ForEach(section.courses) { course in
                NavigationLink(destination: OurCoursesView(section: section, courses: OurCoursesView.getCoursesForSection(section), className: course.title)) {
                    BeautifulCourseListCard(course: course, color: section.color)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Array Safe Subscript Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

import SwiftUI

struct ClassesView: View {
    @State private var selectedFilter = 0
    
    let filters = ["All", "In Progress", "Completed", "Saved"]
    
    let beginnerCourses = [
        Course(id: "1", title: "Cloud Computing Essentials", instructor: "Dr. Hichem Ben Said", image: "cloud", category: "Infrastructure", level: .beginner, rating: 4.7, progress: nil, duration: 15.0, totalLessons: 20, completedLessons: 0, lastAccessDate: nil),
        Course(id: "2", title: "Cybersecurity Basics", instructor: "Dr. Mohamed Trabelsi", image: "security", category: "Security", level: .beginner, rating: 4.8, progress: nil, duration: 12.0, totalLessons: 18, completedLessons: 0, lastAccessDate: nil)
    ]
    
    let intermediateCourses = [
        Course(id: "3", title: "Data Structures & Algorithms", instructor: "Prof. Leila Ben Amor", image: "algorithms", category: "Programming", level: .intermediate, rating: 4.6, progress: 0.42, duration: 18.0, totalLessons: 30, completedLessons: 13, lastAccessDate: Date()),
        Course(id: "4", title: "Machine Learning", instructor: "Dr. Sarah Smith", image: "ml", category: "AI", level: .intermediate, rating: 4.9, progress: nil, duration: 25.0, totalLessons: 35, completedLessons: 0, lastAccessDate: nil)
    ]
    
    var body: some View {
        NavigationView {
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
                    
                    // Beginner Courses
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Beginner Level")
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal, 20)
                        
                        ForEach(beginnerCourses) { course in
                            BeautifulCourseListCard(course: course, color: .green)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    // Intermediate Courses
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Intermediate Level")
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal, 20)
                        
                        ForEach(intermediateCourses) { course in
                            BeautifulCourseListCard(course: course, color: .purple)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
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

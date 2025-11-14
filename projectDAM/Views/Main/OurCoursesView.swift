//
//  OurCoursesView.swift
//  projectDAM
//
//  Created on 11/14/2025.
//

import SwiftUI

// MARK: - Our Courses View
struct OurCoursesView: View {
    // MARK: - Properties
    let classItem: ClassItem
    @StateObject private var viewModel: OurCoursesViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    init(classItem: ClassItem, courseService: CourseServiceProtocol) {
        self.classItem = classItem
        _viewModel = StateObject(wrappedValue: OurCoursesViewModel(courseService: courseService))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.showError {
                errorView
            } else if viewModel.hasNoCourses {
                emptyStateView
            } else {
                coursesListView
            }
        }
        .navigationTitle(classItem.title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.fetchCourses(forClass: classItem.title)
        }
        .refreshable {
            await viewModel.fetchCourses(forClass: classItem.title)
        }
    }
    
    // MARK: - View Components
    
    private var coursesListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header Section
                headerSection
                
                // Courses Grid
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.courses) { course in
                        courseCard(course)
                    }
                }
                .padding(20)
                .padding(.bottom, 20)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(classItem.title)
                        .font(.system(size: 28, weight: .bold))
                    Text("All \(classItem.title) Courses")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(viewModel.courses.count)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(classColor)
                    .opacity(0.3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Section Info
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(viewModel.courses.count) Courses")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(classColor.opacity(0.1))
                .foregroundColor(classColor)
                .cornerRadius(8)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(
            LinearGradient(
                colors: [classColor.opacity(0.08), classColor.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private func courseCard(_ course: Course) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Course Header with Image
            HStack(spacing: 16) {
                // Course Image
                courseImageView(course)
                
                // Course Info
                VStack(alignment: .leading, spacing: 10) {
                    Text(course.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    // Meta Info
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 12) {
                            metaInfoItem(icon: "clock.fill", text: "\(course.durationInMinutes) min")
                            metaInfoItem(icon: "play.circle.fill", text: "\(course.nbVideos)")
                        }
                        
                        // Level Badge
                        levelBadge(course.level)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Description
            Text(course.description)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .padding(16)
            
            // Footer with instructor and price
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text(course.author.username)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if course.price > 0 {
                    if course.courseReduction > 0 {
                        HStack(spacing: 6) {
                            Text("\(Int(course.price)) DT")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .strikethrough()
                            Text("\(Int(course.price * (1 - Double(course.courseReduction) / 100))) DT")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(classColor)
                        }
                    } else {
                        Text("\(Int(course.price)) DT")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(classColor)
                    }
                } else {
                    Text("Free")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Hot badge if applicable
            if course.hot {
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("NEW")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8, corners: [.topLeft, .bottomRight])
                }
                .offset(y: -16)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
    
    private func courseImageView(_ course: Course) -> some View {
        Group {
            if let imageURL = course.imageURL {
                AsyncImage(url: imageURL, transaction: Transaction(animation: .easeInOut)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: classColor.opacity(0.3), radius: 12, x: 0, y: 6)
                    case .empty:
                        placeholderImage
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
    }
    
    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Image(systemName: "book.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 90, height: 90)
        .shadow(color: gradientColors.first?.opacity(0.3) ?? Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
    }
    
    private func metaInfoItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(.secondary)
    }
    
    private func levelBadge(_ level: Course.CourseLevel) -> some View {
        Text(level.rawValue)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(classColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(classColor.opacity(0.1))
            .cornerRadius(6)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading courses...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .font(.system(size: 24, weight: .bold))
            
            Text(viewModel.errorMessage ?? "Something went wrong")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                Task {
                    await viewModel.retry(forClass: classItem.title)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(classColor)
                .cornerRadius(12)
            }
        }
        .padding(40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Courses Yet")
                .font(.system(size: 24, weight: .bold))
            
            Text("There are no courses available for \(classItem.title) at the moment.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(40)
    }
    
    // MARK: - Computed Properties
    
    private var classColor: Color {
        // Determine color based on filter name
        switch classItem.filterName.uppercased() {
        case "1A":
            return Color(red: 0.2, green: 0.75, blue: 0.95)
        case "2A":
            return Color(red: 0.8, green: 0.4, blue: 1.0)
        case "3A", "3B":
            return Color(red: 1.0, green: 0.6, blue: 0.2)
        default:
            return Color.blue
        }
    }
    
    private var gradientColors: [Color] {
        switch classItem.filterName.uppercased() {
        case "1A":
            return [Color(red: 0.3, green: 0.8, blue: 1.0), Color(red: 0.0, green: 0.6, blue: 0.9)]
        case "2A":
            return [Color(red: 0.8, green: 0.4, blue: 1.0), Color(red: 0.7, green: 0.2, blue: 0.9)]
        case "3A", "3B":
            return [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.95, green: 0.5, blue: 0.0)]
        default:
            return [Color.blue, Color.blue.opacity(0.7)]
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#if DEBUG
struct OurCoursesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OurCoursesView(
                classItem: ClassItem(
                    id: "class-1",
                    title: "Algorithme",
                    image: nil,
                    classOrder: "1-1",
                    filterName: "1A"
                ),
                courseService: MockCourseService()
            )
        }
    }
}
#endif

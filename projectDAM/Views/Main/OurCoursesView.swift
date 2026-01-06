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
    init(classItem: ClassItem, courseService: CourseServiceProtocol = DIContainer.shared.courseService) {
        self.classItem = classItem
        _viewModel = StateObject(wrappedValue: OurCoursesViewModel(courseService: courseService))
    }

// MARK: - Adaptive Badge Stack
private struct AdaptiveBadgeStack<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: spacing) {
            content
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
        }
        .multilineTextAlignment(.center)
    }
}

    // MARK: - Body
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.visibleCourses.isEmpty {
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
        .appForceNavigationTitle(classItem.title, displayMode: .always)
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
            VStack(spacing: 24) {
                headerSection
                
                LazyVStack(spacing: 20, pinnedViews: []) {
                    ForEach(viewModel.visibleCourses) { course in
                        NavigationLink {
                            LessonsView(
                                courseId: course.id,
                                accessType: accessType(for: course),
                                isOwned: viewModel.ownedCourseIds.contains(course.id)
                            )
                        } label: {
                            courseCard(course)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            viewModel.loadMoreCoursesIfNeeded(currentCourseID: course.id)
                        }
                    }
                    if viewModel.canLoadMoreCourses {
                        CoursesLoadMoreIndicator(accentColor: classColor)
                            .onAppear {
                                viewModel.loadMoreCoursesIfNeeded(currentCourseID: viewModel.visibleCourses.last?.id)
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            .padding(.bottom, 60) // ensures last card clears the tab bar / home indicator
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("All \(classItem.title) Courses")
                        .font(.system(size: 26, weight: .heavy))
                    Text("Curated learning path for \(classItem.filterName.uppercased())")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text("Total")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("\(viewModel.courses.count)")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(classColor)
                        .opacity(0.35)
                }
            }
            
            Divider()
                .background(classColor.opacity(0.15))
                .padding(.vertical, 4)
            
            HStack(spacing: 12) {
                headerBadge(icon: "book.fill", title: "\(viewModel.courses.count) Courses")
                headerBadge(icon: "arrow.triangle.2.circlepath", title: "Updated daily")
                Spacer()
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [classColor.opacity(0.16), classColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(Color.white.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(classColor.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: classColor.opacity(0.18), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
    }
    
    private func courseCard(_ course: Course) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 18) {
                courseImageView(course)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(course.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 18) {
                        metaInfoItem(icon: "clock", text: "\(course.durationInMinutes) min")
                        metaInfoItem(icon: "play.fill", text: "\(course.nbVideos)")
                        Spacer(minLength: 10)
                    }
                }
            }
            
            Text(course.description)
                .font(.system(size: 13.5, weight: .regular))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            levelAndPriceRow(for: course)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.6))
                )
        )
        .overlay(alignment: .topLeading) {
            if course.hot {
                newRibbon
                    .padding(.leading, 8)
                    .padding(.top, 8)
            }
        }
        .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 10)
    }
    
    private func courseImageView(_ course: Course) -> some View {
        RemoteThumbnailImageView(
            url: course.imageURL,
            width: 94,
            height: 94,
            cornerRadius: 20,
            baseColor: classColor
        ) {
            placeholderImage
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(classColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: classColor.opacity(0.25), radius: 18, x: 0, y: 10)
    }
    
    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "book.closed.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    private func levelAndPriceRow(for course: Course) -> some View {
        HStack(alignment: .center) {
            levelBadge(course.level)
            Spacer()
            priceTag(for: course)
        }
    }

    private func priceTag(for course: Course) -> some View {
        let isOwned = viewModel.ownedCourseIds.contains(course.id)
        if isOwned {
            return AnyView(
                priceTagChip(
                    background: AnyShapeStyle(
                        LinearGradient(
                            colors: [Color.green.opacity(0.95), Color.green.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    ),
                    strokeColor: Color.clear
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Owned")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
                .animation(.easeInOut(duration: 0.2), value: isOwned)
            )
        }
        let finalPrice = course.courseReduction > 0 ? Int(course.price * (1 - Double(course.courseReduction) / 100)) : Int(course.price)
        return AnyView(
            priceTagChip(
                background: course.price > 0 ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(LinearGradient(colors: [Color.green.opacity(0.95), Color.green.opacity(0.75)], startPoint: .leading, endPoint: .trailing)),
                strokeColor: course.price > 0 ? classColor.opacity(0.15) : Color.clear
            ) {
                if course.price > 0 {
                    HStack(spacing: 6) {
                        Image("T-Credits")
                            .resizable()
                            .renderingMode(.original)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                        Text("\(finalPrice)")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(classColor)
                    }
                } else {
                    Text("Free")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: course.price)
        )
    }

    private func priceTagChip<Content: View>(background: AnyShapeStyle, strokeColor: Color, @ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .frame(width: tagSize.width, height: tagSize.height)
            .background(
                Capsule()
                    .fill(background)
                    .overlay(
                        Capsule()
                            .stroke(strokeColor, lineWidth: strokeColor == .clear ? 0 : 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            )
    }
    
    private var newRibbon: some View {
        Text("NEW")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.46, blue: 0.45), Color(red: 1.0, green: 0.32, blue: 0.25)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(Capsule())
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: Color(red: 1.0, green: 0.45, blue: 0.25).opacity(0.25), radius: 8, x: 0, y: 4)
    }
    
    private func headerBadge(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(.system(size: 13, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.8))
        .foregroundColor(.black.opacity(0.7))
        .clipShape(Capsule())
    }
    
    private func metaInfoItem(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(classColor.opacity(0.15))
                .frame(width: 26, height: 26)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(classColor)
                )
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }
    
    private func levelBadge(_ level: Course.CourseLevel) -> some View {
        Text(level.rawValue)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(classColor)
            .padding(.horizontal, 10)
            .frame(width: tagSize.width, height: tagSize.height)
            .background(classColor.opacity(0.1))
            .clipShape(Capsule())
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ForEach(0..<3, id: \.self) { index in
                ShimmerCourseCardPlaceholder(accentColor: classColor.opacity(0.4 + Double(index) * 0.1))
                    .padding(.horizontal, 20)
            }
        }
        .padding(.top, 30)
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
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: gradientColors.map { $0.opacity(0.2) }, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 160, height: 160)
                        Circle()
                            .stroke(classColor.opacity(0.15), lineWidth: 1.5)
                            .frame(width: 190, height: 190)
                        ZStack {
                            Image(systemName: "book.closed.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(classColor.opacity(0.85))
                                .font(.system(size: 56, weight: .bold))
                            Image(systemName: "sparkles")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(classColor.opacity(0.9))
                                .offset(x: 24, y: -28)
                        }
                    }
                    .padding(.top, 10)
                    
                    VStack(spacing: 10) {
                        Text("Courses Coming Soon")
                            .font(.system(size: 26, weight: .heavy))
                            .multilineTextAlignment(.center)
                        Text("We're curating the best \(classItem.title) experiences for you. Check back shortly or explore other classes in the meantime.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    
                    VStack(spacing: 16) {
                        AdaptiveBadgeStack(spacing: 12) {
                            availabilityPill(icon: "clock.badge.questionmark", text: "Not published yet")
                            availabilityPill(icon: "sparkles", text: "New modules soon")
                        }
                        .padding(.horizontal, 12)
                        
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                Text("Browse other classes")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(classColor)
                            .clipShape(Capsule())
                            .shadow(color: classColor.opacity(0.4), radius: 14, x: 0, y: 8)
                        }
                    }
                }
                .frame(maxWidth: min(proxy.size.width - 32, 420))
                .padding(.horizontal, 16)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.white.opacity(0.35))
                        .shadow(color: Color.black.opacity(0.04), radius: 30, x: 0, y: 12)
                )
                .padding(.horizontal, max(16, (proxy.size.width - 420) / 2))
                .frame(minHeight: proxy.size.height - 32)
            }
            .frame(width: proxy.size.width)
            .padding(.horizontal, 8)
        }
    }

    private func availabilityPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(classColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(classColor.opacity(0.12))
        .clipShape(Capsule())
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.9)
        .fixedSize(horizontal: false, vertical: true)
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

    private var tagSize: CGSize {
        CGSize(width: 104, height: 34)
    }

    private func accessType(for course: Course) -> LessonAccessType {
        course.price > 0 ? .privateCourse : .publicCourse
    }
}

// MARK: - Supporting Views
private struct ShimmerCourseCardPlaceholder: View {
    let accentColor: Color
    @State private var phase: CGFloat = -1
    
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(.systemBackground))
            .overlay(shimmerOverlay)
            .frame(height: 150)
            .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 10)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
    
    private var shimmerOverlay: some View {
        GeometryReader { geometry in
            let gradient = LinearGradient(
                colors: [accentColor.opacity(0.25), accentColor.opacity(0.1), accentColor.opacity(0.25)],
                startPoint: .leading,
                endPoint: .trailing
            )
            Rectangle()
                .fill(gradient)
                .rotationEffect(.degrees(12))
                .offset(x: geometry.size.width * phase)
        }
        .mask(
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 94, height: 94)
                    VStack(alignment: .leading, spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 18)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 14)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 14)
                    }
                }
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 14)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 34)
            }
            .padding(22)
        )
    }
}

private struct CoursesLoadMoreIndicator: View {
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
            Text("Loading more")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
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

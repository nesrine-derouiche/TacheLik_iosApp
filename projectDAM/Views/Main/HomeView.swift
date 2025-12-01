//
//  HomeView.swift
//  projectDAM
//
//  Professional student home dashboard with dynamic data
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = DIContainer.shared.makeStudentHomeViewModel()
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var isShowingWalletAlert = false
    
    private var currentUser: User? {
        authService.currentUser
    }
    
    private var userCredits: Int {
        currentUser?.credit ?? 0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // MARK: - Header Section
                            headerSection
                            
                            // MARK: - Learning Overview Card
                            learningOverviewCard
                            
                            // MARK: - Quick Stats Grid
                            quickStatsGrid
                            
                            // MARK: - Continue Learning Section
                            if !viewModel.recentCourses.isEmpty {
                                continueLearningSection
                            } else if !viewModel.isLoading {
                                // Empty state for no courses
                                emptyCoursesSection
                            }
                            
                            // MARK: - Quick Actions
                            quickActionsSection
                            
                            // MARK: - Classes Summary
                            if !viewModel.classesSummary.isEmpty {
                                classesSummarySection
                            }
                            
                            // MARK: - Achievements Section
                            if !viewModel.userBadges.isEmpty {
                                achievementsSection
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.bottom, DS.barHeight + 16)
                    }
                    .background(Color(.systemGroupedBackground))
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    UnifiedTopAppBarLogoView()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    UnifiedTopAppBarActions(
                        userCredits: userCredits,
                        isShowingWalletAlert: $isShowingWalletAlert
                    )
                }
            }
            .alert("Wallet", isPresented: $isShowingWalletAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Wallet Screen will be developed soon.")
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        Color.black.opacity(0.1)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.brandPrimary)
                    Text("Loading your dashboard...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                )
            )
    }
    
    // MARK: - Empty Courses Section
    private var emptyCoursesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Continue Learning")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
            }
            
            VStack(spacing: 16) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.brandPrimary.opacity(0.6))
                
                VStack(spacing: 8) {
                    Text("No courses yet")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Explore our catalog and start your learning journey today!")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                NavigationLink {
                    ExploreView()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Explore Courses")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.brandPrimary)
                    .cornerRadius(12)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Achievements")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                if let user = currentUser {
                    NavigationLink {
                        UserBadgesView(userId: user.id, username: user.username)
                    } label: {
                        Text("See All")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.brandPrimary)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.userBadges.prefix(5)) { badge in
                        BadgeCard(badge: badge)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.greeting)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(viewModel.userName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                // Role badge
                if let user = currentUser {
                    HStack(spacing: 6) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(user.role.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.brandPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.brandPrimary.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            Spacer()
            
            // Profile Avatar
            if let user = currentUser {
                ProfileAvatarView(user: user, size: 52)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Learning Overview Card
    private var learningOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Learning Overview")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Your Progress")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            HStack(spacing: 20) {
                OverviewStatItem(
                    value: "\(viewModel.totalCourses)",
                    label: "Courses",
                    icon: "book.fill"
                )
                
                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.3))
                
                OverviewStatItem(
                    value: viewModel.formattedTotalHours,
                    label: "Learning Hours",
                    icon: "clock.fill"
                )
                
                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.3))
                
                OverviewStatItem(
                    value: "\(viewModel.classesSummary.count)",
                    label: "Classes",
                    icon: "folder.fill"
                )
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.brandPrimary.opacity(0.3), radius: 15, x: 0, y: 8)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Quick Stats Grid
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            StudentStatCard(
                title: "In Progress",
                value: "\(viewModel.coursesInProgress)",
                icon: "play.circle.fill",
                color: .blue
            )
            
            StudentStatCard(
                title: "Completed",
                value: "\(viewModel.coursesCompleted)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StudentStatCard(
                title: "Day Streak",
                value: "\(viewModel.learningStreak)",
                icon: "flame.fill",
                color: .orange
            )
            
            StudentStatCard(
                title: "Achievements",
                value: "\(viewModel.achievementsCount)",
                icon: "trophy.fill",
                color: .purple
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Continue Learning Section
    private var continueLearningSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Continue Learning")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                if viewModel.recentCourses.count > 3 {
                    Button(action: {}) {
                        Text("See All")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.brandPrimary)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(viewModel.recentCourses.prefix(5).enumerated()), id: \.element.id) { index, ownedCourse in
                        NavigationLink {
                            LessonsView(
                                courseId: ownedCourse.course.id,
                                accessType: .privateCourse,
                                isOwned: true
                            )
                        } label: {
                            StudentCourseCard(
                                course: ownedCourse.course,
                                color: cardColors[index % cardColors.count]
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                // My Courses - Navigate to MyCoursesView
                NavigationLink {
                    MyCoursesView()
                } label: {
                    QuickActionButton(
                        icon: "book.fill",
                        title: "My Courses",
                        color: .brandPrimary,
                        badge: viewModel.totalCourses
                    )
                }
                .buttonStyle(.plain)
                
                // Classes - Navigate to ClassesView
                NavigationLink {
                    ClassesView()
                } label: {
                    QuickActionButton(
                        icon: "folder.fill",
                        title: "Classes",
                        color: .purple,
                        badge: viewModel.classesSummary.count
                    )
                }
                .buttonStyle(.plain)
                
                // Explore - Navigate to ExploreView
                NavigationLink {
                    ExploreView()
                } label: {
                    QuickActionButton(
                        icon: "magnifyingglass",
                        title: "Explore",
                        color: .orange,
                        badge: 0
                    )
                }
                .buttonStyle(.plain)
                
                // Settings - Navigate to SettingsView
                NavigationLink {
                    SettingsView()
                } label: {
                    QuickActionButton(
                        icon: "gear",
                        title: "Settings",
                        color: .gray,
                        badge: 0
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Classes Summary Section
    private var classesSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Classes")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(viewModel.classesSummary.prefix(4)) { classSummary in
                    ClassSummaryRow(classSummary: classSummary)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Color Palette for Cards
    private var cardColors: [Color] {
        [.brandPrimary, .purple, .blue, .orange, .green]
    }
}

// MARK: - Overview Stat Item
private struct OverviewStatItem: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Student Stat Card
private struct StudentStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Student Course Card
private struct StudentCourseCard: View {
    let course: OwnedCourseDetail
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Course Icon/Image
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: "book.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let author = course.author {
                    Text(author.username)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Duration
            if let duration = course.duration, duration > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(formatDuration(duration))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            // Continue Label (navigation handled by parent NavigationLink)
            HStack(spacing: 4) {
                Text("Continue")
                    .font(.system(size: 12, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color)
            .cornerRadius(10)
        }
        .padding(16)
        .frame(width: 180, height: 220)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
    }
    
    private func formatDuration(_ hours: Double) -> String {
        if hours >= 1 {
            return String(format: "%.1fh", hours)
        } else {
            return String(format: "%.0fm", hours * 60)
        }
    }
}

// MARK: - Quick Action Button
private struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let badge: Int
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(8)
                        .offset(x: 4, y: -4)
                }
            }
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Class Summary Row
private struct ClassSummaryRow: View {
    let classSummary: ClassSummary
    
    var body: some View {
        HStack(spacing: 14) {
            // Class Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brandPrimary.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Text(classSummary.filterName.prefix(2).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.brandPrimary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(classSummary.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(classSummary.coursesCount) course\(classSummary.coursesCount == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Profile Avatar View
private struct ProfileAvatarView: View {
    let user: User
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.brandPrimary, .brandPrimary.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            Text(userInitials)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundColor(.white)
        }
        .shadow(color: Color.brandPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
    }
    
    private var userInitials: String {
        let name = user.username
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Legacy Components (kept for compatibility)
struct TCreditsWalletChip: View {
    let credits: Int
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.brandPrimary)
                .frame(width: 28, height: 28)
                .overlay(
                    Image("T-Credits")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                )
                .shadow(color: Color.brandPrimary.opacity(colorScheme == .dark ? 0.3 : 0.12), radius: 4, x: 0, y: 2)
            
            Text("\(credits)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.primary)
                .padding(.trailing, 2)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
}

struct StatCardHome: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct BeautifulCourseCard: View {
    let title: String
    let instructor: String
    let progress: Double
    let timeLeft: String
    let lessonsCompleted: Int
    let totalLessons: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "book.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .lineLimit(2)
                    Text(instructor)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Progress Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(color)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(color)
                        Text("\(lessonsCompleted)/\(totalLessons) lessons")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(timeLeft)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Continue Button
            Button(action: {}) {
                HStack {
                    Text("Continue Learning")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Badge Card
private struct BadgeCard: View {
    let badge: UserBadge
    
    private var badgeColor: Color {
        // Assign colors based on badge name patterns
        let name = badge.name.lowercased()
        if name.contains("gold") || name.contains("master") {
            return .yellow
        } else if name.contains("silver") || name.contains("advanced") {
            return .gray
        } else if name.contains("bronze") || name.contains("beginner") {
            return .orange
        } else if name.contains("streak") || name.contains("fire") {
            return .red
        } else if name.contains("complete") || name.contains("finish") {
            return .green
        } else {
            return .brandPrimary
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Badge Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [badgeColor, badgeColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: badgeColor.opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 4) {
                Text(badge.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let description = badge.description {
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(width: 100)
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

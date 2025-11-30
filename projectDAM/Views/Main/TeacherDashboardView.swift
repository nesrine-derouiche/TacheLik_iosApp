//
//  TeacherDashboardView.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import SwiftUI

struct TeacherDashboardView: View {
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService
    @StateObject private var viewModel = DIContainer.shared.makeTeacherDashboardViewModel()
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
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header with greeting
                        headerSection()
                        
                        // Revenue Overview Card
                        revenueOverviewCard()
                        
                        // Performance Stats Grid
                        performanceStatsGrid()
                        
                        // Top Courses Section
                        topCoursesSection()
                        
                        // Quick Actions
                        quickActionsSection()
                        
                        // Recent Student Activity
                        recentActivitySection()
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, DS.paddingMD)
                    .padding(.vertical, DS.paddingMD)
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.3)
                                .tint(.brandPrimary)
                            Text("Loading dashboard...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 10)
                        )
                    }
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
                        isShowingWalletAlert: $isShowingWalletAlert,
                        searchAction: {},
                        notificationsAction: {}
                    )
                }
            }
            .onAppear {
                viewModel.fetchDashboardData()
            }
            .refreshable {
                viewModel.refreshData()
            }
            .alert("Wallet", isPresented: $isShowingWalletAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Wallet Screen will be developed soon.")
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Header Section
    private func headerSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(getGreeting())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(currentUser?.username ?? "Instructor")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Profile avatar
            if let profileImage = currentUser?.image, !profileImage.isEmpty {
                AsyncImage(url: URL(string: profileImage)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.brandPrimary)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.brandPrimary.opacity(0.3), lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.brandPrimary)
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Revenue Overview Card
    private func revenueOverviewCard() -> some View {
        VStack(spacing: 0) {
            // Main revenue display
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Revenue")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(viewModel.formattedRevenue)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .bold))
                        Text("\(viewModel.totalSales) sales this month")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Revenue icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
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
            
            // Revenue breakdown
            HStack(spacing: 0) {
                RevenueBreakdownItem(
                    title: "Pending",
                    value: viewModel.formattedPendingPayout,
                    icon: "clock.fill",
                    color: .brandWarning
                )
                
                Divider()
                    .frame(height: 40)
                
                RevenueBreakdownItem(
                    title: "Withdrawn",
                    value: viewModel.formattedWithdrawn,
                    icon: "arrow.down.circle.fill",
                    color: .brandSuccess
                )
                
                Divider()
                    .frame(height: 40)
                
                RevenueBreakdownItem(
                    title: "Your Share",
                    value: "\(Int(viewModel.teacherEarningsPercentage))%",
                    icon: "percent",
                    color: .brandSecondary
                )
            }
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Performance Stats Grid
    private func performanceStatsGrid() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                PerformanceStatCard(
                    icon: "person.2.fill",
                    title: "Total Students",
                    value: "\(viewModel.totalStudents)",
                    trend: viewModel.activeStudents > 0 ? "+\(viewModel.activeStudents) active" : nil,
                    trendPositive: true,
                    color: .brandPrimary
                )
                
                PerformanceStatCard(
                    icon: "book.closed.fill",
                    title: "Active Courses",
                    value: "\(viewModel.activeCourses)",
                    trend: nil,
                    trendPositive: true,
                    color: .brandSecondary
                )
                
                PerformanceStatCard(
                    icon: "play.circle.fill",
                    title: "Video Views",
                    value: formatNumber(viewModel.videoViews),
                    trend: nil,
                    trendPositive: true,
                    color: .brandSuccess
                )
                
                PerformanceStatCard(
                    icon: "creditcard.fill",
                    title: "Avg. Price",
                    value: String(format: "%.0f TND", viewModel.averagePrice),
                    trend: nil,
                    trendPositive: true,
                    color: .brandWarning
                )
            }
        }
    }
    
    // MARK: - Top Courses Section
    private func topCoursesSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Performing Courses")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !viewModel.topCourses.isEmpty {
                    Text("View All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.brandPrimary)
                }
            }
            
            if viewModel.topCourses.isEmpty {
                EmptyStateCard(
                    icon: "trophy",
                    message: "No course data yet",
                    submessage: "Your top courses will appear here"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.topCourses.prefix(3), id: \.id) { course in
                        TopCourseRow(course: course, rank: (viewModel.topCourses.firstIndex(where: { $0.id == course.id }) ?? 0) + 1)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private func quickActionsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "book.fill",
                    title: "My Courses",
                    color: .brandPrimary,
                    badge: viewModel.activeCourses > 0 ? viewModel.activeCourses : nil
                ) {}
                
                QuickActionButton(
                    icon: "person.2.fill",
                    title: "Students",
                    color: .brandSecondary,
                    badge: viewModel.totalStudents > 0 ? viewModel.totalStudents : nil
                ) {}
                
                QuickActionButton(
                    icon: "chart.bar.fill",
                    title: "Analytics",
                    color: .brandSuccess,
                    badge: nil
                ) {}
                
                QuickActionButton(
                    icon: "wallet.pass.fill",
                    title: "Earnings",
                    color: .brandWarning,
                    badge: nil
                ) {}
            }
        }
    }
    
    // MARK: - Recent Activity Section
    private func recentActivitySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !viewModel.recentTransactions.isEmpty {
                    Text("See All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.brandPrimary)
                }
            }
            
            if viewModel.recentTransactions.isEmpty && !viewModel.isLoading {
                EmptyStateCard(
                    icon: "person.2.slash",
                    message: "No recent activity",
                    submessage: "Student enrollments will appear here"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recentTransactions.prefix(5).enumerated()), id: \.element.id) { index, transaction in
                        StudentActivityItemView(
                            initials: transaction.studentInitials,
                            name: transaction.studentName,
                            course: transaction.courseName,
                            action: transaction.activityAction,
                            timeAgo: transaction.timeAgo,
                            actionIcon: transaction.activityIcon,
                            actionColor: .brandSuccess
                        )
                        
                        if index < min(viewModel.recentTransactions.count - 1, 4) {
                            Divider()
                                .padding(.vertical, 10)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }
}

// MARK: - Revenue Breakdown Item
private struct RevenueBreakdownItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Performance Stat Card
private struct PerformanceStatCard: View {
    let icon: String
    let title: String
    let value: String
    let trend: String?
    let trendPositive: Bool
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                if let trend = trend {
                    Text(trend)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(trendPositive ? .brandSuccess : .brandError)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Top Course Row
private struct TopCourseRow: View {
    let course: TopCourse
    let rank: Int
    
    var rankColor: Color {
        switch rank {
        case 1: return .brandWarning
        case 2: return .gray
        case 3: return .orange.opacity(0.7)
        default: return .secondary
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(rankColor)
            }
            
            // Course info
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(course.enrollments) students")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Revenue
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f", course.revenue))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.brandSuccess)
                
                Text("TND")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Empty State Card
private struct EmptyStateCard: View {
    let icon: String
    let message: String
    let submessage: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 4) {
                Text(message)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text(submessage)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Quick Action Button Component
private struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    var badge: Int? = nil
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.2),
                                    color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                    
                    // Badge
                    if let badge = badge, badge > 0 {
                        Text(badge > 99 ? "99+" : "\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.brandError)
                            )
                            .offset(x: 18, y: -18)
                    }
                }
                .frame(height: 56)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.paddingMD)
            .background(
                RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                    .fill(Color(.systemBackground))
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Student Activity Item Component
private struct StudentActivityItemView: View {
    let initials: String
    let name: String
    let course: String
    let action: String
    let timeAgo: String
    let actionIcon: String
    let actionColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.brandPrimary.opacity(0.3),
                                Color.brandAccent.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(initials)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.brandPrimary)
            }
            .frame(width: 40, height: 40)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Image(systemName: actionIcon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(actionColor)
                }
                
                HStack(spacing: 6) {
                    Text(course)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(action)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(timeAgo)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    TeacherDashboardView()
}

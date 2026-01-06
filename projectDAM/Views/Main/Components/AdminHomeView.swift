import SwiftUI
import Combine
import Foundation

// MARK: - View

struct AdminHomeView: View {
    @StateObject private var viewModel = AdminHomeViewModel()
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService
    
    // For navigation switching
    @State private var didAppear = false
    @State private var headerLoadingState: HeaderLoadingState = .loading
    @State private var animateContent = false
    
    enum HeaderLoadingState: Equatable {
        case loading
        case loaded
        case error(String)
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header Section - Always Visible
                headerSectionWrapper
                    .padding(.top, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                quickActionsGrid
                    .opacity(animateContent ? 1 : 0)

                contentSection
                    .opacity(animateContent ? 1 : 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, DS.barHeight + 20)
        }
        .refreshable {
            viewModel.send(action: .refresh)
        }
        .background(Color.appGroupedBackground)
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationBarStyle(.transparent)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                toolbarLeadingView
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                toolbarTrailingView
            }
        }
        .onAppear {
            if !didAppear {
                didAppear = true
                initializeHeader()
                viewModel.send(action: .loadData)
            }
        }
        .onChange(of: authService.currentUser) { _, _ in
            updateHeaderState()
        }
    }
    
    // MARK: - Header Section Wrapper
    
    @ViewBuilder
    private var headerSectionWrapper: some View {
        switch headerLoadingState {
        case .loading:
            HeaderSkeletonView()
                .redacted(reason: .placeholder)
        case .loaded:
            headerSection
        case .error(let message):
            ErrorHeaderView(message: message) {
                updateHeaderState()
            }
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        if let user = authService.currentUser {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(greeting)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .opacity(0.8)

                    Text(user.username)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Administrator")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.brandPrimary, .brandPrimary.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                Spacer()
                
                ProfileAvatarView(user: user, size: 56)
                    .transition(.scale.combined(with: .opacity))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: Color.black.opacity(0.08),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
        } else {
            HeaderSkeletonView()
        }
    }
    
    // MARK: - Helper Methods
    
    private func initializeHeader() {
        updateHeaderState()
    }
    
    private func updateHeaderState() {
        if authService.currentUser != nil {
            withAnimation(.easeInOut(duration: 0.3)) {
                headerLoadingState = .loaded
                animateContent = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                headerLoadingState = .loading
                animateContent = false
            }
        }
    }
    
    // MARK: - Toolbar Views
    
    @ViewBuilder
    private var toolbarLeadingView: some View {
        UnifiedTopAppBarLogoView()
            .transition(.opacity.combined(with: .scale))
    }
    
    @ViewBuilder
    private var toolbarTrailingView: some View {
        if headerLoadingState == .loaded, let user = authService.currentUser {
            UnifiedTopAppBarActions(
                userCredits: user.credit ?? 0,
                isShowingWalletAlert: .constant(false),
                searchAction: {},
                notificationsAction: {},
                showSearch: false,
                showNotifications: false,
                showNotificationDot: false
            )
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        } else {
            // Skeleton loading for credit display
            ToolbarCreditsSkeleton()
                .transition(.opacity)
        }
    }
    
    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Student Actions
                quickActionButton(title: "Students", icon: "person.2.fill", color: .brandPrimary) {
                    switchToTeacherTab(.myClasses)
                }
                
                // Teacher Actions
                quickActionButton(title: "Teachers", icon: "graduationcap.fill", color: .brandSecondary) {
                    switchToTeacherTab(.myClasses)
                }
                
                // Quizzes
                quickActionButton(title: "Quizzes", icon: "checkmark.circle.fill", color: .brandSuccess) {
                    switchToTeacherTab(.quizzes)
                }
                
                // Messages
                quickActionButton(title: "Messages", icon: "message.fill", color: .brandAccent) {
                    switchToTeacherTab(.messages)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    @ViewBuilder
    private var contentSection: some View {
        switch viewModel.viewState {
        case .loading, .idle:
            VStack(spacing: 16) {
                SkeletonChartView()
                SkeletonChartView()
            }
            .transition(.opacity)
        case .content(let data):
            VStack(spacing: 20) {
                UserGrowthChart(title: "Student Growth", data: data.students, color: .brandPrimary)
                UserGrowthChart(title: "Teacher Growth", data: data.teachers, color: .brandSecondary)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        case .error(let message):
            ContentErrorView(message: message) {
                viewModel.send(action: .loadData)
            }
            .transition(.opacity)
        }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    private func switchToTeacherTab(_ tab: MainTabView.TeacherTab) {
        NotificationCenter.default.post(
            name: .adminTabSwitchRequest,
            object: nil,
            userInfo: ["tabRawValue": tab.rawValue]
        )
    }
}

// MARK: - Helper Views

// Skeleton Loading View for Header
struct HeaderSkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 14)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 28)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.brandPrimary.opacity(0.15))
                    .frame(width: 110, height: 32)
            }
            
            Spacer()
            
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 56, height: 56)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .shimmer(isActive: isAnimating)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// Error State View for Header
struct ErrorHeaderView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Header Loading Failed")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            Button(action: retryAction) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.brandPrimary)
                .cornerRadius(10)
            }
        }
        .padding(14)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(16)
        .border(Color.orange.opacity(0.2), width: 1)
    }
}

// Skeleton Loading View for Charts
struct SkeletonChartView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 18)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 16)
            }
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 180)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .shimmer(isActive: isAnimating)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// Content Error View
struct ContentErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Unable to Load Dashboard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: retryAction) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.brandPrimary)
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(20)
    }
}

// MARK: - Shimmer Extension
extension View {
    func shimmer(isActive: Bool) -> some View {
        self
            .opacity(isActive ? 0.6 : 1)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isActive)
    }
}

// MARK: - Charts

struct UserGrowthChart: View {
    let title: String
    let data: [MonthlyStat]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if let last = data.last {
                    Text("\(last.count) total")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            ChartDataView(data: data, color: color)
                .frame(height: 180)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct ChartDataView: View {
    let data: [MonthlyStat]
    let color: Color
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let maxVal = (data.map(\.count).max() ?? 1)
            let counts = data.map { CGFloat($0.count) }
            let stepX = width / CGFloat(max(data.count - 1, 1))
            
            ZStack {
                // Path
                Path { path in
                    guard !counts.isEmpty else { return }
                    
                    path.move(to: CGPoint(x: 0, y: height - (counts[0] / CGFloat(maxVal) * height)))
                    
                    for i in 1..<counts.count {
                        let x = CGFloat(i) * stepX
                        let y = height - (counts[i] / CGFloat(maxVal) * height)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(
                    LinearGradient(colors: [color, color.opacity(0.5)], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                
                // Gradient Fill (Optional)
                Path { path in
                    guard !counts.isEmpty else { return }
                    
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height - (counts[0] / CGFloat(maxVal) * height)))
                    
                    for i in 1..<counts.count {
                        let x = CGFloat(i) * stepX
                        let y = height - (counts[i] / CGFloat(maxVal) * height)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(colors: [color.opacity(0.2), color.opacity(0.0)], startPoint: .top, endPoint: .bottom)
                )
            }
        }
    }
}

// MARK: - Profile Avatar Helper
// Copied/Simplified from TeacherDashboardView or just use existing if shared.
// Since User model is shared, I'll inline a simple one.

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

// MARK: - Toolbar Credits Skeleton
struct ToolbarCreditsSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 20)
            
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 20, height: 20)
        }
        .shimmer(isActive: isAnimating)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}


// MARK: - Notification Extension
extension Notification.Name {
    static let adminTabSwitchRequest = Notification.Name("AdminTabSwitchRequest")
}

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = DIContainer.shared.makeStudentDashboardHomeViewModel()
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService

    @StateObject private var reelGenerator = AiReelGeneratorCardViewModel()

    @State private var didAppear = false

    private var currentUser: User? { authService.currentUser }
    private var userCredits: Int { currentUser?.credit ?? 0 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                headerSection

                if !viewModel.isOnline {
                    OfflineBanner(subtitle: lastUpdatedText)
                        .padding(.horizontal, 20)
                }

                switch viewModel.uiState {
                case .loading:
                    skeletonContent
                case .error(let message, _, let isOffline, _):
                    if isOffline {
                        OfflineBanner(subtitle: lastUpdatedText)
                            .padding(.horizontal, 20)
                    }
                    errorCard(message: message)
                case .content(let home, _):
                    quickActionsRow
                    quickStatsGrid(home: home)
                    aiReelGeneratorSection
                    goalsSection(home: home)
                }
            }
            .padding(.vertical, 16)
            .padding(.bottom, DS.barHeight + 16)
        }
        .background(Color.appGroupedBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                UnifiedTopAppBarLogoView()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                UnifiedTopAppBarActions(
                    userCredits: userCredits,
                    isShowingWalletAlert: .constant(false),
                    searchAction: {},
                    notificationsAction: {},
                    showSearch: false,
                    showNotifications: false,
                    showNotificationDot: unreadDot
                )
            }
        }
        .appNavigationBarStyle(.transparent)
        .onAppear {
            if !didAppear {
                didAppear = true
                viewModel.onAppear()
            }
        }
    }

    private var quickActionsRow: some View {
        HStack(spacing: 14) {
            Button {
                switchToStudentTab(.messages)
            } label: {
                quickActionButton(title: "Messages", systemImage: "message.fill", tint: .brandSecondary)
            }

            Button {
                switchToStudentTab(.classes)
            } label: {
                quickActionButton(title: "Courses", systemImage: "book.fill", tint: .brandAccent)
            }

            Button {
                switchToStudentTab(.quiz)
            } label: {
                quickActionButton(title: "Quizzes", systemImage: "checkmark.circle.fill", tint: .brandSuccess)
            }

            NavigationLink(destination: BadgesView()) {
                quickActionButton(title: "Badges", systemImage: "rosette", tint: .brandPrimary)
            }
        }
        .padding(.horizontal, 20)
        .buttonStyle(PressableScaleButtonStyle())
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)

                Text(displayName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if let role = currentUser?.role.rawValue, !role.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(role)
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

            if let user = currentUser {
                ProfileAvatarView(user: user, size: 52)
            }
        }
        .padding(.horizontal, 20)
    }

    private var skeletonContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                SkeletonBlock(height: 18, cornerRadius: 10)
                    .frame(maxWidth: 180, alignment: .leading)
                SkeletonBlock(height: 44, cornerRadius: 14)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                SkeletonBlock(height: 20, cornerRadius: 10)
                    .frame(maxWidth: 140, alignment: .leading)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    SkeletonBlock(height: 92)
                    SkeletonBlock(height: 92)
                    SkeletonBlock(height: 92)
                    SkeletonBlock(height: 92)
                }
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 12) {
                SkeletonBlock(height: 20, cornerRadius: 10)
                    .frame(maxWidth: 180, alignment: .leading)
                SkeletonBlock(height: 140)
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 12) {
                SkeletonBlock(height: 20, cornerRadius: 10)
                    .frame(maxWidth: 120, alignment: .leading)
                SkeletonBlock(height: 120)
            }
            .padding(.horizontal, 20)
        }
    }

    private func errorCard(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.brandWarning)
            Text("We couldn't refresh right now")
                .font(.system(size: 16, weight: .semibold))
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Text(viewModel.isOnline ? "Retrying automatically…" : "Will retry when you're back online.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .appCardStyle()
        .padding(.horizontal, 20)
    }

    private func quickStatsGrid(home: StudentHomeData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick stats")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                Button {
                    switchToStudentTab(.messages)
                } label: {
                    metricCard(title: "Messages", value: "\(home.quickActions.unreadMessages)", icon: "message.fill", tint: .brandSecondary)
                }

                Button {
                    switchToStudentTab(.classes)
                } label: {
                    metricCard(title: "Courses", value: "\(home.quickActions.ownedCourses)", icon: "book.closed.fill", tint: .brandAccent)
                }

                Button {
                    switchToStudentTab(.quiz)
                } label: {
                    metricCard(title: "Quizzes", value: "\(home.quickActions.quizzesTaken)", icon: "checkmark.seal.fill", tint: .brandSuccess)
                }

                NavigationLink(destination: BadgesView()) {
                    metricCard(title: "Badges", value: "\(home.quickActions.badgesEarned)", icon: "rosette", tint: .brandPrimary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private var aiReelGeneratorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Reel Generator")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.brandPrimary)

                    TextField("Paste a YouTube URL", text: $reelGenerator.videoUrlText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.URL)
                        .submitLabel(.done)
                        .onChange(of: reelGenerator.videoUrlText) { _ in
                            reelGenerator.clearStatus()
                        }

                    if !reelGenerator.trimmedVideoUrl.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                reelGenerator.videoUrlText = ""
                                reelGenerator.clearStatus()
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Clear link")
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)
                .animation(.easeInOut(duration: 0.16), value: reelGenerator.trimmedVideoUrl.isEmpty)

                if !reelGenerator.trimmedVideoUrl.isEmpty && !reelGenerator.isValidYouTubeUrl {
                    Text("Enter a valid YouTube link (youtube.com or youtu.be).")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.brandWarning)
                }

                if !viewModel.isOnline {
                    Text("You’re offline. Connect to the internet to generate reels.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                switch reelGenerator.uiState {
                case .idle:
                    EmptyView()
                case .generating:
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Generating reels…")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                case .success(let count):
                    Text(count > 0 ? "Reels generated and added to Explore." : "No reels were generated for that video.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.brandSuccess)
                case .error(let message):
                    Text(message)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.brandWarning)
                }

                Button {
                    Task { await reelGenerator.generate() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .semibold))
                        Text("AI Generate")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        (reelGenerator.canGenerate && viewModel.isOnline)
                        ? LinearGradient(colors: [.brandPrimary, .purple], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(14)
                }
                .disabled(!(reelGenerator.canGenerate && viewModel.isOnline))
                .opacity((reelGenerator.canGenerate && viewModel.isOnline) ? 1 : 0.6)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
        }
        .padding(.horizontal, 20)
    }

    private func switchToStudentTab(_ tab: MainTabView.StudentTab) {
        NotificationCenter.default.post(
            name: .studentTabSwitchRequest,
            object: nil,
            userInfo: ["tab": tab.rawValue]
        )
    }

    private func goalsSection(home: StudentHomeData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Goals")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
            }

            VStack(spacing: 12) {
                goalCard(title: "Daily", goal: home.goals.daily)
                goalCard(title: "Weekly", goal: home.goals.weekly)
            }
        }
        .padding(.horizontal, 20)
    }

    private func metricCard(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint)
                Spacer()
            }
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .appCardStyle()
    }

    private func quickActionButton(title: String, systemImage: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.appBorder.opacity(0.8), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)

                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tint)
            }
            .frame(width: 64, height: 54)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private struct PressableScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .opacity(configuration.isPressed ? 0.92 : 1)
                .animation(.spring(response: 0.22, dampingFraction: 0.85), value: configuration.isPressed)
        }
    }

    private func continueLearningCard(item: StudentContinueLearningItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            ProgressView(value: Double(max(0, min(100, item.progress))), total: 100)
                .tint(.brandPrimary)

            Text("\(max(0, min(100, item.progress)))% complete")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .appCardStyle()
    }

    private func goalCard(title: String, goal: StudentGoalWindow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(goal.xp.value) \(goal.xp.unit)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }

            Text("Quizzes completed: \(goal.quizzesCompleted)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            if let msg = goal.message, !msg.isEmpty {
                Text(msg)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var displayName: String {
        switch viewModel.uiState {
        case .content(let home, _):
            return home.user.username.isEmpty ? (currentUser?.username ?? "Student") : home.user.username
        default:
            return currentUser?.username ?? "Student"
        }
    }

    private var unreadDot: Bool {
        guard case .content(let home, _) = viewModel.uiState else { return false }
        return home.quickActions.unreadMessages > 0
    }

    private var lastUpdatedText: String? {
        guard case .content(_, let savedAt) = viewModel.uiState else { return nil }
        guard let savedAt else { return nil }
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return "Last updated: \(df.string(from: savedAt))"
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

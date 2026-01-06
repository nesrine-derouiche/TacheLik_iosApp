import SwiftUI

struct TeacherDashboardView: View {
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService
    @StateObject private var viewModel = DIContainer.shared.makeTeacherDashboardHomeViewModel()

    @State private var didAppear = false

    private var currentUser: User? { authService.currentUser }
    private var userCredits: Int { currentUser?.credit ?? 0 }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                headerSection

                if !viewModel.isOnline {
                    OfflineBanner(subtitle: lastUpdatedText)
                }

                quickActionsRow

                switch viewModel.uiState {
                case .loading:
                    skeletonContent
                case .error(let message, _, let isOffline, _):
                    if isOffline {
                        OfflineBanner(subtitle: lastUpdatedText)
                    }
                    errorCard(message: message)
                case .content(let home, _):
                    quickStatsGrid(home: home)
                    pendingActionsSection(home: home)
                    engagementSection(home: home)
                    analyticsSection(home: home)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, DS.barHeight + 16)
        }
        .refreshable {
            await viewModel.refreshSilently()
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
                    showNotificationDot: hasAttentionItems
                )
            }
        }
        .onAppear {
            if !didAppear {
                didAppear = true
                viewModel.onAppear()
            }
        }
    }

    private var quickActionsRow: some View {
        HStack(spacing: 14) {
            NavigationLink(destination: BadgesView()) {
                quickActionButton(title: "Badges", systemImage: "rosette", tint: .brandAccent)
            }
            Button {
                switchToTeacherTab(.quizzes)
            } label: {
                quickActionButton(title: "Quiz", systemImage: "checkmark.circle.fill", tint: .brandPrimary)
            }
            NavigationLink(destination: WalletView()) {
                quickActionButton(title: "Wallet", systemImage: "wallet.pass.fill", tint: .brandSuccess)
            }
            Button {
                switchToTeacherTab(.messages)
            } label: {
                quickActionButton(title: "Messages", systemImage: "message.fill", tint: .brandSecondary)
            }
        }
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

                Text("Teacher")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.brandPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.brandPrimary.opacity(0.1))
                    .cornerRadius(12)
            }

            Spacer()

            if let user = currentUser {
                ProfileAvatarView(user: user, size: 52)
            }
        }
    }

    private var skeletonContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                SkeletonBlock(height: 20, cornerRadius: 10)
                    .frame(maxWidth: 160, alignment: .leading)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    SkeletonBlock(height: 92)
                    SkeletonBlock(height: 92)
                    SkeletonBlock(height: 92)
                    SkeletonBlock(height: 92)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                SkeletonBlock(height: 20, cornerRadius: 10)
                    .frame(maxWidth: 140, alignment: .leading)
                SkeletonBlock(height: 140)
            }

            VStack(alignment: .leading, spacing: 12) {
                SkeletonBlock(height: 20, cornerRadius: 10)
                    .frame(maxWidth: 140, alignment: .leading)
                SkeletonBlock(height: 160)
            }
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
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private func quickStatsGrid(home: TeacherHomeData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick stats")
                .font(.system(size: 18, weight: .bold))

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                Button {
                    switchToTeacherTab(.myClasses)
                } label: {
                    statCard(title: "Students", value: "\(home.quickStats.totalStudents)", icon: "person.2.fill", tint: .brandPrimary)
                }

                Button {
                    switchToTeacherTab(.myClasses)
                } label: {
                    statCard(title: "Active courses", value: "\(home.quickStats.activeCourses)", icon: "book.closed.fill", tint: .brandSecondary)
                }

                Button {
                    switchToTeacherTab(.myClasses)
                } label: {
                    statCard(title: "Pending courses", value: "\(home.quickStats.pendingCourses)", icon: "clock.fill", tint: .brandWarning)
                }
                NavigationLink(destination: WalletView()) {
                    statCard(title: "Revenue", value: formattedCurrency(home.quickStats.totalRevenue), icon: "dollarsign.circle.fill", tint: .brandSuccess)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func switchToTeacherTab(_ tab: MainTabView.TeacherTab) {
        NotificationCenter.default.post(
            name: .teacherTabSwitchRequest,
            object: nil,
            userInfo: ["tab": tab.rawValue]
        )
    }

    private func pendingActionsSection(home: TeacherHomeData) -> some View {
        let pa = home.pendingActions
        return VStack(alignment: .leading, spacing: 12) {
            Text("Needs attention")
                .font(.system(size: 18, weight: .bold))

            VStack(spacing: 10) {
                attentionRow(title: "Course requests", value: pa.pendingCourseRequests, icon: "doc.text.fill")
                attentionRow(title: "Withdrawals", value: pa.pendingWithdrawals, icon: "arrow.down.circle.fill")
                attentionRow(title: "Unread messages", value: pa.unreadMessages, icon: "message.fill")
                attentionRow(title: "Edits awaiting approval", value: pa.courseEditsAwaitingApproval, icon: "pencil.circle.fill")
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
        }
    }

    @ViewBuilder
    private func engagementSection(home: TeacherHomeData) -> some View {
        let items = recentActivityItems(home: home)
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent activity")
                    .font(.system(size: 18, weight: .bold))

                VStack(spacing: 10) {
                    ForEach(items.prefix(3)) { item in
                        activityRow(item)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
            }
        }
    }

    @ViewBuilder
    private func analyticsSection(home: TeacherHomeData) -> some View {
        let points = home.analyticsCards.revenueChart
        if !points.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Revenue")
                    .font(.system(size: 18, weight: .bold))

                RevenueLineChart(points: points)
                    .frame(height: 160)
                    .padding(14)
                    .background(Color(.systemBackground))
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
            }
        }
    }

    private func quickActionButton(title: String, systemImage: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)

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

    private struct ActivityItem: Identifiable {
        enum Kind {
            case enrollment
            case message
        }

        let id: String
        let kind: Kind
        let date: Date?
        let title: String
        let subtitle: String
    }

    private func recentActivityItems(home: TeacherHomeData) -> [ActivityItem] {
        let enrollmentItems: [ActivityItem] = home.engagementFeed.recentEnrollments.map { enrollment in
            ActivityItem(
                id: "enrollment|\(enrollment.id)",
                kind: .enrollment,
                date: parseISODate(enrollment.enrolledAt),
                title: enrollment.studentName,
                subtitle: "Enrolled in \(enrollment.courseName)"
            )
        }

        let messageItems: [ActivityItem] = home.engagementFeed.recentMessages.map { message in
            ActivityItem(
                id: "message|\(message.id)",
                kind: .message,
                date: parseISODate(message.sentAt),
                title: message.senderName,
                subtitle: message.content
            )
        }

        return (enrollmentItems + messageItems)
            .sorted { lhs, rhs in
                switch (lhs.date, rhs.date) {
                case let (l?, r?):
                    return l > r
                case (nil, _?):
                    return false
                case (_?, nil):
                    return true
                case (nil, nil):
                    return lhs.id > rhs.id
                }
            }
    }

    private func activityRow(_ item: ActivityItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.12))
                Image(systemName: item.kind == .enrollment ? "person.badge.plus.fill" : "message.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.brandPrimary)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    private func parseISODate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterWithFraction.date(from: value) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    private struct RevenueLineChart: View {
        let points: [TeacherRevenueChartPoint]

        private var normalizedPoints: [(label: String, value: Double)] {
            points.map { (label: $0.month, value: $0.revenue) }
        }

        var body: some View {
            let data = normalizedPoints
            let values = data.map { $0.value }
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 0
            let range = max(0.000001, maxValue - minValue)
            let count = max(1, data.count)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Last months")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    if let last = data.last {
                        Text(formatCurrency(last.value))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }

                GeometryReader { proxy in
                    let size = proxy.size
                    ZStack {
                        Path { path in
                            guard data.count >= 2 else { return }
                            for index in data.indices {
                                let x = size.width * CGFloat(index) / CGFloat(count - 1)
                                let y = size.height * (1 - CGFloat((data[index].value - minValue) / range))
                                if index == data.startIndex {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.brandSuccess, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                        if data.count == 1 {
                            let y = size.height * (1 - CGFloat((data[0].value - minValue) / range))
                            Circle()
                                .fill(Color.brandSuccess)
                                .frame(width: 8, height: 8)
                                .position(x: size.width / 2, y: y)
                        }
                    }
                }
                .frame(height: 98)

                HStack(spacing: 0) {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                        Text(item.label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
        }

        private func formatCurrency(_ value: Double) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "TND"
            formatter.currencySymbol = "TND"
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        }
    }

    private func statCard(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint)
                Spacer()
            }
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
    }

    private func attentionRow(title: String, value: Int, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.brandPrimary)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
            Text("\(value)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(value > 0 ? .brandWarning : .secondary)
        }
    }

    private func feedCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.brandPrimary)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                Spacer()
            }
            content()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
    }

    private func feedRow(primary: String, secondary: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(primary)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            Text(secondary)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func emptyCard(title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.brandPrimary.opacity(0.7))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
    }

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TND"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
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
            return home.teacher.username.isEmpty ? (currentUser?.username ?? "Instructor") : home.teacher.username
        default:
            return currentUser?.username ?? "Instructor"
        }
    }

    private var hasAttentionItems: Bool {
        guard case .content(let home, _) = viewModel.uiState else { return false }
        let pa = home.pendingActions
        return pa.pendingCourseRequests > 0 || pa.pendingWithdrawals > 0 || pa.unreadMessages > 0 || pa.courseEditsAwaitingApproval > 0
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

#Preview {
    TeacherDashboardView()
}

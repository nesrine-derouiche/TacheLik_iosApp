
import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
class AdminHomeViewModel: ObservableObject {
    @Published var uiState: UIState = .loading
    @Published var isOnline: Bool = true // Simplified for now, can hook into NetworkMonitor later
    
    private let service: AdminDashboardServiceProtocol
    
    enum UIState {
        case loading
        case content(AdminStatsData)
        case error(String)
    }
    
    init(service: AdminDashboardServiceProtocol) {
        self.service = service
    }
    
    func onAppear() {
        loadData()
    }
    
    func refresh() async {
        await loadData(isRefresh: true)
    }
    
    private func loadData(isRefresh: Bool = false) {
        if !isRefresh { uiState = .loading }
        
        Task {
            do {
                let data = try await service.fetchDashboardStats()
                uiState = .content(data)
            } catch {
                uiState = .error(error.localizedDescription)
            }
        }
    }
}

// MARK: - View

struct AdminHomeView: View {
    @StateObject private var viewModel = DIContainer.shared.makeAdminHomeViewModel()
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService
    
    // For navigation switching
    @State private var didAppear = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                        .padding(.top, 16)
                    
                    quickActionsGrid
                    
                    contentSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, DS.barHeight + 20)
            }
            .refreshable {
                await viewModel.refresh()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            if !didAppear {
                didAppear = true
                viewModel.onAppear()
            }
        }
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                Text(authService.currentUser?.username ?? "Admin")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
            }
            Spacer()
            // Admin Avatar or Logo
            if let user = authService.currentUser {
                ProfileAvatarView(user: user, size: 50)
            }
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
                    // Navigate to Teacher MyClasses (which Admin uses now)
                     switchToTeacherTab(.myClasses)
                }
                
                // Teacher Actions (maybe same MyClasses or distinct if available)
                quickActionButton(title: "Teachers", icon: "graduationcap.fill", color: .brandSecondary) {
                    switchToTeacherTab(.myClasses) // Admin sees everything there
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
        switch viewModel.uiState {
        case .loading:
            ProgressView()
                .padding(.top, 40)
        case .content(let data):
            VStack(spacing: 24) {
                UserGrowthChart(title: "Student Growth", data: data.students, color: .brandPrimary)
                UserGrowthChart(title: "Teacher Growth", data: data.teachers, color: .brandSecondary)
            }
        case .error(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button("Retry") {
                    viewModel.onAppear()
                }
            }
            .padding(.top, 40)
        }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning," }
        if hour < 17 { return "Good afternoon," }
        return "Good evening,"
    }
    
    private func switchToTeacherTab(_ tab: MainTabView.TeacherTab) {
        // Admin uses TeacherTabs for navigation now
        // But wait, MainTabView for Admin has AdminTab enum.
        // We need to request switch.
        // If Admin shares views with Teacher, we need to map AdminTab to TeacherTab functionality OR just switch AdminTab.
        // AdminTab: dashboard, requests, quizzes, users, settings.
        // MyClasses and Messages are NOT in AdminTab enum in original code.
        // The plan was to duplicate Teacher tabs logic into Admin tabs.
        // So I will update MainTabView to likely just use TeacherTab ENUM for Admin too?
        // Or keep AdminTab but rename cases to match Teacher.
        // Let's assume MainTabView will be updated to have .classes, .messages.
        
        // For now, I will post a notification that MainTabView listens to.
        // Since I haven't updated MainTabView yet, I'll define keys assuming I'll update them.
        // Actually, I can just use a new Notification name "AdminTabSwitchRequest".
        
        NotificationCenter.default.post(
            name: .adminTabSwitchRequest,
            object: nil,
            userInfo: ["tabRawValue": tab.rawValue] // This is tricky if Enums don't match.
        )
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

// Notification Extension
extension Notification.Name {
    static let adminTabSwitchRequest = Notification.Name("AdminTabSwitchRequest")
}

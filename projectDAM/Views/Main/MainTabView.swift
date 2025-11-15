import SwiftUI

struct MainTabView: View {
    // MARK: - Student Tabs
    enum StudentTab: Int, CaseIterable { case home, classes, explore, progress, settings }
    
    // MARK: - Admin Tabs
    enum AdminTab: Int, CaseIterable { case dashboard, requests, users, settings }
    
    // MARK: - Teacher Tabs
    enum TeacherTab: Int, CaseIterable { case dashboard, myClasses, messages, settings }
    
    // MARK: - Properties
    @StateObject private var roleManager = DIContainer.shared.roleManager
    @State private var selectedStudentTab: StudentTab = .home
    @State private var selectedAdminTab: AdminTab = .dashboard
    @State private var selectedTeacherTab: TeacherTab = .dashboard
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch roleManager.currentRole {
                case .admin:
                    adminTabContent()
                case .mentor:
                    teacherTabContent()
                case .student, .none:
                    studentTabContent()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Show appropriate tab bar based on role
            if roleManager.currentRole == .admin {
                adminTabBar()
            } else if roleManager.currentRole == .mentor {
                teacherTabBar()
            } else {
                studentTabBar()
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    // MARK: - Student Tab Content
    @ViewBuilder
    private func studentTabContent() -> some View {
        switch selectedStudentTab {
        case .home: HomeView()
        case .classes: ClassesView()
        case .explore: ExploreView()
        case .progress: LearningProgressView()
        case .settings: SettingsView()
        }
    }
    
    // MARK: - Admin Tab Content
    @ViewBuilder
    private func adminTabContent() -> some View {
        switch selectedAdminTab {
        case .dashboard:
            AdminDashboardView()
        case .requests:
            AdminRequestsView()
        case .users:
            AdminUsersView()
        case .settings:
            SettingsView()
        }
    }
    
    // MARK: - Teacher Tab Content
    @ViewBuilder
    private func teacherTabContent() -> some View {
        switch selectedTeacherTab {
        case .dashboard:
            TeacherDashboardView()
        case .myClasses:
            TeacherMyClassesView()
        case .messages:
            TeacherMessagesView()
        case .settings:
            SettingsView()
        }
    }
    
    // MARK: - Student Tab Bar
    @ViewBuilder
    private func studentTabBar() -> some View {
        StudentTabBar(selected: $selectedStudentTab)
    }
    
    // MARK: - Admin Tab Bar
    @ViewBuilder
    private func adminTabBar() -> some View {
        AdminTabBar(selected: $selectedAdminTab)
    }
    
    // MARK: - Teacher Tab Bar
    @ViewBuilder
    private func teacherTabBar() -> some View {
        TeacherTabBar(selected: $selectedTeacherTab)
    }
}

// MARK: - Student Tab Bar
private struct StudentTabBar: View {
    @Binding var selected: MainTabView.StudentTab
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let compact = width < 380
            let tabWidth = compact ? (width - 32) / 5 : (width - 48) / 5
            
            HStack(spacing: compact ? 4 : 8) {
                StudentTabButton(
                    icon: "house.fill",
                    title: "Home",
                    tab: .home,
                    selected: $selected,
                    compact: compact,
                    tint: .brandPrimary,
                    animation: animation,
                    tabWidth: tabWidth
                )
                
                StudentTabButton(
                    icon: "book.fill",
                    title: "Classes",
                    tab: .classes,
                    selected: $selected,
                    compact: compact,
                    tint: .brandAccent,
                    animation: animation,
                    tabWidth: tabWidth
                )
                
                StudentTabButton(
                    icon: "magnifyingglass.circle.fill",
                    title: "Explore",
                    tab: .explore,
                    selected: $selected,
                    compact: compact,
                    tint: .brandSecondary,
                    animation: animation,
                    tabWidth: tabWidth
                )
                
                StudentTabButton(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress",
                    tab: .progress,
                    selected: $selected,
                    compact: compact,
                    tint: .brandSuccess,
                    animation: animation,
                    tabWidth: tabWidth
                )
                
                StudentTabButton(
                    icon: "gearshape.fill",
                    title: "Profile",
                    tab: .settings,
                    selected: $selected,
                    compact: compact,
                    tint: .brandWarning,
                    animation: animation,
                    tabWidth: tabWidth,
                    avatarConfig: .init(
                        imageSource: profileImageSource,
                        initials: profileInitials
                    )
                )
            }
            .padding(.horizontal, compact ? 8 : 12)
            .padding(.vertical, compact ? 5 : 6)
            .frame(width: width)
            .background(tabBarBackground(colorScheme))
            .frame(height: DS.barHeight, alignment: .center)
            .position(x: width/2, y: DS.barHeight/2)
        }
        .frame(height: DS.barHeight)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.1), radius: 20, x: 0, y: -5)
    }
    
    private func tabBarBackground(_ colorScheme: ColorScheme) -> some View {
        ZStack {
            BlurBackground()
            
            LinearGradient(
                colors: [
                    Color.brandPrimary.opacity(0.1),
                    Color.brandSecondary.opacity(0.1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
            .frame(maxHeight: .infinity, alignment: .top)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 8)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }
    
    private var currentUser: User? {
        authService.currentUser
    }
    
    private var profileImageSource: String? {
        guard let source = currentUser?.image, !source.isEmpty else { return nil }
        return source
    }
    
    private var profileInitials: String {
        let fallback = "YOU"
        guard let username = currentUser?.username, !username.isEmpty else { return fallback }
        let components = username.split(separator: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        if initials.isEmpty {
            return String(username.prefix(2)).uppercased()
        }
        return initials.map { String($0) }.joined().uppercased()
    }
}

private struct TabAvatarConfig {
    let imageSource: String?
    let initials: String
}

private struct StudentTabButton: View {
    let icon: String
    let title: String
    let tab: MainTabView.StudentTab
    @Binding var selected: MainTabView.StudentTab
    let compact: Bool
    let tint: Color
    let animation: Namespace.ID
    let tabWidth: CGFloat
    let avatarConfig: TabAvatarConfig?
    
    init(
        icon: String,
        title: String,
        tab: MainTabView.StudentTab,
        selected: Binding<MainTabView.StudentTab>,
        compact: Bool,
        tint: Color,
        animation: Namespace.ID,
        tabWidth: CGFloat,
        avatarConfig: TabAvatarConfig? = nil
    ) {
        self.icon = icon
        self.title = title
        self.tab = tab
        self._selected = selected
        self.compact = compact
        self.tint = tint
        self.animation = animation
        self.tabWidth = tabWidth
        self.avatarConfig = avatarConfig
    }
    
    @State private var isPressed = false
    
    var isSelected: Bool { selected == tab }
    private var iconBackgroundSize: CGFloat {
        let base = compact ? 36.0 : 40.0
        return isSelected ? base + 6 : base
    }
    private var iconSize: CGFloat {
        let base = compact ? 18.0 : 20.0
        return isSelected ? base + 1.5 : base
    }
    private var avatarDiameter: CGFloat {
        max(iconBackgroundSize - 6, 30)
    }
    private var iconContainerHeight: CGFloat {
        iconBackgroundSize + 2
    }
    private var labelSpacing: CGFloat { compact ? 4 : 5 }
    
    var body: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selected = tab
            }
        } label: {
            VStack(spacing: labelSpacing) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.2), tint.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: iconBackgroundSize, height: iconBackgroundSize)
                            .matchedGeometryEffect(id: "STUDENT_TAB_BACKGROUND", in: animation)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    if let avatarConfig {
                        ProfileAvatarView(
                            imageSource: avatarConfig.imageSource,
                            initials: avatarConfig.initials,
                            tint: tint,
                            isSelected: isSelected,
                            diameter: avatarDiameter
                        )
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundStyle(
                                isSelected ?
                                    LinearGradient(
                                        colors: [tint, tint.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.secondary, Color.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .scaleEffect(isPressed ? 0.85 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                    }
                }
                .frame(height: iconContainerHeight)
                
                Text(title)
                    .font(.system(size: isSelected ? 11 : 10, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? tint : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
            }
            .frame(width: tabWidth)
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 3 : 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonPressStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

private struct ProfileAvatarView: View {
    let imageSource: String?
    let initials: String
    let tint: Color
    let isSelected: Bool
    let diameter: CGFloat
    
    private var strokeWidth: CGFloat { isSelected ? 2.2 : 1.6 }
    
    var body: some View {
        avatarContent
            .frame(width: diameter, height: diameter)
            .background(Color.clear)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(tint.opacity(isSelected ? 0.9 : 0.35), lineWidth: strokeWidth)
            )
            .shadow(color: tint.opacity(isSelected ? 0.35 : 0.12), radius: isSelected ? 10 : 6, x: 0, y: 4)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    @ViewBuilder
    private var avatarContent: some View {
        if let image = decodedBase64Image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .transition(.opacity)
        } else if let url = remoteURL {
            AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.25))) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                case .failure:
                    placeholder
                case .empty:
                    ProgressView()
                        .progressViewStyle(.circular)
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }
    
    private var placeholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [tint.opacity(0.85), tint.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Text(initials)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            )
    }
    
    private var remoteURL: URL? {
        guard let source = imageSource,
              !source.isEmpty,
              !source.hasPrefix("data:image") else { return nil }
        return URL(string: source)
    }
    
    private var decodedBase64Image: UIImage? {
        guard let source = imageSource,
              source.hasPrefix("data:image"),
              let cleaned = source.components(separatedBy: "base64,").last,
              let data = Data(base64Encoded: cleaned, options: .ignoreUnknownCharacters),
              let image = UIImage(data: data) else { return nil }
        return image
    }
}

// MARK: - Admin Tab Bar
private struct AdminTabBar: View {
    @Binding var selected: MainTabView.AdminTab
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let compact = width < 380
            let tabWidth = compact ? (width - 24) / 4 : (width - 40) / 4
            
            HStack(spacing: compact ? 4 : 8) {
                AdminTabButton(
                    icon: "square.grid.2x2.fill",
                    title: "Dashboard",
                    tab: .dashboard,
                    selected: $selected,
                    compact: compact,
                    tint: .brandPrimary,
                    animation: animation,
                    tabWidth: tabWidth
                )
                
                AdminTabButton(
                    icon: "list.clipboard.fill",
                    title: "Requests",
                    tab: .requests,
                    selected: $selected,
                    compact: compact,
                    tint: .brandWarning,
                    animation: animation,
                    tabWidth: tabWidth
                )
                
                AdminTabButton(
                    icon: "person.3.fill",
                    title: "Users",
                    tab: .users,
                    selected: $selected,
                    compact: compact,
                    tint: .brandSuccess,
                    animation: animation,
                    tabWidth: tabWidth
                )
                
                AdminTabButton(
                    icon: "gearshape.fill",
                    title: "Profile",
                    tab: .settings,
                    selected: $selected,
                    compact: compact,
                    tint: .brandError,
                    animation: animation,
                    tabWidth: tabWidth,
                    avatarConfig: .init(
                        imageSource: profileImageSource,
                        initials: profileInitials
                    )
                )
            }
            .padding(.horizontal, compact ? 8 : 12)
            .padding(.vertical, compact ? 5 : 6)
            .frame(width: width)
            .background(tabBarBackground(colorScheme))
            .frame(height: DS.barHeight, alignment: .center)
            .position(x: width/2, y: DS.barHeight/2)
        }
        .frame(height: DS.barHeight)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.1), radius: 20, x: 0, y: -5)
    }
    
    private func tabBarBackground(_ colorScheme: ColorScheme) -> some View {
        ZStack {
            BlurBackground()
            
            LinearGradient(
                colors: [
                    Color.brandPrimary.opacity(0.1),
                    Color.brandSecondary.opacity(0.1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
            .frame(maxHeight: .infinity, alignment: .top)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 8)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }
    
    private var currentUser: User? {
        authService.currentUser
    }
    
    private var profileImageSource: String? {
        guard let source = currentUser?.image, !source.isEmpty else { return nil }
        return source
    }
    
    private var profileInitials: String {
        let fallback = "YOU"
        guard let username = currentUser?.username, !username.isEmpty else { return fallback }
        let components = username.split(separator: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        if initials.isEmpty {
            return String(username.prefix(2)).uppercased()
        }
        return initials.map { String($0) }.joined().uppercased()
    }
}

private struct AdminTabButton: View {
    let icon: String
    let title: String
    let tab: MainTabView.AdminTab
    @Binding var selected: MainTabView.AdminTab
    let compact: Bool
    let tint: Color
    let animation: Namespace.ID
    let tabWidth: CGFloat
    let avatarConfig: TabAvatarConfig?
    
    init(
        icon: String,
        title: String,
        tab: MainTabView.AdminTab,
        selected: Binding<MainTabView.AdminTab>,
        compact: Bool,
        tint: Color,
        animation: Namespace.ID,
        tabWidth: CGFloat,
        avatarConfig: TabAvatarConfig? = nil
    ) {
        self.icon = icon
        self.title = title
        self.tab = tab
        self._selected = selected
        self.compact = compact
        self.tint = tint
        self.animation = animation
        self.tabWidth = tabWidth
        self.avatarConfig = avatarConfig
    }
    
    @State private var isPressed = false
    
    var isSelected: Bool { selected == tab }
    private var iconBackgroundSize: CGFloat {
        let base = compact ? 36.0 : 40.0
        return isSelected ? base + 6 : base
    }
    private var iconSize: CGFloat {
        let base = compact ? 18.0 : 20.0
        return isSelected ? base + 1.5 : base
    }
    private var avatarDiameter: CGFloat {
        max(iconBackgroundSize - 6, 30)
    }
    private var iconContainerHeight: CGFloat {
        iconBackgroundSize + 2
    }
    private var labelSpacing: CGFloat { compact ? 4 : 5 }
    
    var body: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selected = tab
            }
        } label: {
            VStack(spacing: labelSpacing) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.2), tint.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: iconBackgroundSize, height: iconBackgroundSize)
                            .matchedGeometryEffect(id: "ADMIN_TAB_BACKGROUND", in: animation)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    if let avatarConfig {
                        ProfileAvatarView(
                            imageSource: avatarConfig.imageSource,
                            initials: avatarConfig.initials,
                            tint: tint,
                            isSelected: isSelected,
                            diameter: avatarDiameter
                        )
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundStyle(
                                isSelected ?
                                    LinearGradient(
                                        colors: [tint, tint.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.secondary, Color.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .scaleEffect(isPressed ? 0.85 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                    }
                }
                .frame(height: iconContainerHeight)
                
                Text(title)
                    .font(.system(size: isSelected ? 11 : 10, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? tint : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
            }
            .frame(width: tabWidth)
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 3 : 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonPressStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Teacher Tab Bar
private struct TeacherTabBar: View {
    @Binding var selected: MainTabView.TeacherTab
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let compact = width < 380
            let tabWidth = compact ? (width - 24) / 4 : (width - 40) / 4
            
            HStack(spacing: compact ? 4 : 8) {
                TeacherTabButton(
                    icon: "square.grid.2x2.fill",
                    title: "Dashboard",
                    tab: .dashboard,
                    selected: $selected,
                    compact: compact,
                    tint: .brandPrimary,
                    animation: animation,
                    tabWidth: tabWidth
                )
                
                TeacherTabButton(
                    icon: "book.circle.fill",
                    title: "My Classes",
                    tab: .myClasses,
                    selected: $selected,
                    compact: compact,
                    tint: .brandAccent,
                    animation: animation,
                    tabWidth: tabWidth
                )
                
                TeacherTabButton(
                    icon: "message.fill",
                    title: "Messages",
                    tab: .messages,
                    selected: $selected,
                    compact: compact,
                    tint: .brandWarning,
                    animation: animation,
                    tabWidth: tabWidth
                )
                
                TeacherTabButton(
                    icon: "gearshape.fill",
                    title: "Profile",
                    tab: .settings,
                    selected: $selected,
                    compact: compact,
                    tint: .brandWarning,
                    animation: animation,
                    tabWidth: tabWidth,
                    avatarConfig: .init(
                        imageSource: profileImageSource,
                        initials: profileInitials
                    )
                )
            }
            .padding(.horizontal, compact ? 8 : 12)
            .padding(.vertical, compact ? 5 : 6)
            .frame(width: width)
            .background(tabBarBackground(colorScheme))
            .frame(height: DS.barHeight, alignment: .center)
            .position(x: width/2, y: DS.barHeight/2)
        }
        .frame(height: DS.barHeight)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.1), radius: 20, x: 0, y: -5)
    }
    
    private func tabBarBackground(_ colorScheme: ColorScheme) -> some View {
        ZStack {
            BlurBackground()
            
            LinearGradient(
                colors: [
                    Color.brandPrimary.opacity(0.1),
                    Color.brandSecondary.opacity(0.1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
            .frame(maxHeight: .infinity, alignment: .top)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 8)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }
    
    private var currentUser: User? {
        authService.currentUser
    }
    
    private var profileImageSource: String? {
        guard let source = currentUser?.image, !source.isEmpty else { return nil }
        return source
    }
    
    private var profileInitials: String {
        let fallback = "YOU"
        guard let username = currentUser?.username, !username.isEmpty else { return fallback }
        let components = username.split(separator: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        if initials.isEmpty {
            return String(username.prefix(2)).uppercased()
        }
        return initials.map { String($0) }.joined().uppercased()
    }
}

private struct TeacherTabButton: View {
    let icon: String
    let title: String
    let tab: MainTabView.TeacherTab
    @Binding var selected: MainTabView.TeacherTab
    let compact: Bool
    let tint: Color
    let animation: Namespace.ID
    let tabWidth: CGFloat
    let avatarConfig: TabAvatarConfig?
    
    init(
        icon: String,
        title: String,
        tab: MainTabView.TeacherTab,
        selected: Binding<MainTabView.TeacherTab>,
        compact: Bool,
        tint: Color,
        animation: Namespace.ID,
        tabWidth: CGFloat,
        avatarConfig: TabAvatarConfig? = nil
    ) {
        self.icon = icon
        self.title = title
        self.tab = tab
        self._selected = selected
        self.compact = compact
        self.tint = tint
        self.animation = animation
        self.tabWidth = tabWidth
        self.avatarConfig = avatarConfig
    }
    
    @State private var isPressed = false
    
    var isSelected: Bool { selected == tab }
    private var iconBackgroundSize: CGFloat {
        let base = compact ? 36.0 : 40.0
        return isSelected ? base + 6 : base
    }
    private var iconSize: CGFloat {
        let base = compact ? 18.0 : 20.0
        return isSelected ? base + 1.5 : base
    }
    private var avatarDiameter: CGFloat {
        max(iconBackgroundSize - 6, 30)
    }
    private var iconContainerHeight: CGFloat {
        iconBackgroundSize + 2
    }
    private var labelSpacing: CGFloat { compact ? 4 : 5 }
    
    var body: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selected = tab
            }
        } label: {
            VStack(spacing: labelSpacing) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.2), tint.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: iconBackgroundSize, height: iconBackgroundSize)
                            .matchedGeometryEffect(id: "TEACHER_TAB_BACKGROUND", in: animation)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    if let avatarConfig {
                        ProfileAvatarView(
                            imageSource: avatarConfig.imageSource,
                            initials: avatarConfig.initials,
                            tint: tint,
                            isSelected: isSelected,
                            diameter: avatarDiameter
                        )
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundStyle(
                                isSelected ?
                                    LinearGradient(
                                        colors: [tint, tint.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.secondary, Color.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .scaleEffect(isPressed ? 0.85 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                    }
                }
                .frame(height: iconContainerHeight)
                
                Text(title)
                    .font(.system(size: isSelected ? 11 : 10, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? tint : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
            }
            .frame(width: tabWidth)
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 3 : 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonPressStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// Custom button style for press effect
private struct TabButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
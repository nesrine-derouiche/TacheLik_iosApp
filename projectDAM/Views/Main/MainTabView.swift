import SwiftUI

struct MainTabView: View {
    enum Tab: Int, CaseIterable { case home, classes, explore, progress, settings }
    @State private var selected: Tab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .home: HomeView()
                case .classes: ClassesView()
                case .explore: ExploreView()
                case .progress: LearningProgressView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            CustomTabBar(selected: $selected)
        }
        .ignoresSafeArea(.keyboard) // keep bar above keyboard
    }
}

private struct CustomTabBar: View {
    @Binding var selected: MainTabView.Tab
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let compact = width < 380
            let tabWidth = compact ? (width - 32) / 5 : (width - 48) / 5
            
            HStack(spacing: compact ? 4 : 8) {
                TabButton(
                    icon: "house.fill",
                    title: "Home",
                    tab: .home,
                    selected: $selected,
                    compact: compact,
                    tint: .brandPrimary,
                    animation: animation,
                    tabWidth: tabWidth
                )
                
                TabButton(
                    icon: "book.fill",
                    title: "Classes",
                    tab: .classes,
                    selected: $selected,
                    compact: compact,
                    tint: .brandAccent,
                    animation: animation,
                    tabWidth: tabWidth
                )
                
                TabButton(
                    icon: "magnifyingglass.circle.fill",
                    title: "Explore",
                    tab: .explore,
                    selected: $selected,
                    compact: compact,
                    tint: .brandSecondary,
                    animation: animation,
                    tabWidth: tabWidth
                )
                
                TabButton(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress",
                    tab: .progress,
                    selected: $selected,
                    compact: compact,
                    tint: .brandSuccess,
                    animation: animation,
                    tabWidth: tabWidth
                )
                
                TabButton(
                    icon: "gearshape.fill",
                    title: "Settings",
                    tab: .settings,
                    selected: $selected,
                    compact: compact,
                    tint: .brandWarning,
                    animation: animation,
                    tabWidth: tabWidth
                )
            }
            .padding(.horizontal, compact ? 8 : 12)
            .padding(.vertical, 8)
            .frame(width: width)
            .background(
                ZStack {
                    // Blur background
                    BlurBackground()
                    
                    // Top border with gradient
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
                    
                    // Subtle shadow overlay
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
            )
            .frame(height: DS.barHeight, alignment: .center)
            .position(x: width/2, y: DS.barHeight/2)
        }
        .frame(height: DS.barHeight)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.1), radius: 20, x: 0, y: -5)
    }
}

private struct TabButton: View {
    let icon: String
    let title: String
    let tab: MainTabView.Tab
    @Binding var selected: MainTabView.Tab
    let compact: Bool
    let tint: Color
    let animation: Namespace.ID
    let tabWidth: CGFloat
    
    @State private var isPressed = false
    
    var isSelected: Bool { selected == tab }
    
    var body: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Background indicator for selected tab
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.2), tint.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .matchedGeometryEffect(id: "TAB_BACKGROUND", in: animation)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Icon with gradient for selected state
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 24 : 22, weight: .semibold))
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
                .frame(height: 32)
                
                // Label
                Text(title)
                    .font(.system(size: isSelected ? 11 : 10, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? tint : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: tabWidth)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
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

// BlurBackground is now defined in DesignSystem.swift

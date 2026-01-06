import SwiftUI

struct UnifiedTopAppBarActions: View {
    let userCredits: Int
    @Binding var isShowingWalletAlert: Bool
    var searchAction: () -> Void = {}
    var notificationsAction: () -> Void = {}
    var showSearch: Bool = true
    var showNotifications: Bool = true
    var showNotificationDot: Bool = true
    
    var body: some View {
        HStack(spacing: 12) {
            if showSearch {
                Button(action: searchAction) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if showNotifications {
                Button(action: notificationsAction) {
                    ZStack {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        if showNotificationDot {
                            Circle()
                                .fill(LinearGradient.brandPrimaryGradient)
                                .frame(width: 8, height: 8)
                                .offset(x: 12, y: -12)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            NavigationLink(destination: WalletView()) {
                TCreditsWalletChip(credits: userCredits)
                    .frame(minWidth: 68, idealWidth: 84, maxHeight: 44)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                TapGesture().onEnded {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            )
        }
    }
}

struct UnifiedTopAppBarLogoView: View {
    var body: some View {
        Image("tache_lik_logo")
            .resizable()
            .scaledToFit()
            .frame(height: 32)
            .rotationEffect(.degrees(-45))
            .accessibilityLabel(Text("TacheLik"))
    }
}

struct ToolbarIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

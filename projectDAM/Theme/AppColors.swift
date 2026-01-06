import SwiftUI
import UIKit

// Centralized app palette to improve dark-mode hierarchy while preserving brand colors.
// Uses dynamic UIColors so the same identifiers adapt automatically to light/dark.

enum AppColors {
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}

extension UIColor {
    // Backgrounds
    static let appBackground: UIColor = AppColors.dynamic(
        light: .systemGroupedBackground,
        dark: UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1.0) // near-black, not pure black
    )

    static let appGroupedBackground: UIColor = AppColors.dynamic(
        light: .systemGroupedBackground,
        dark: UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1.0)
    )

    // Surfaces (cards / panels)
    static let appSurface: UIColor = AppColors.dynamic(
        light: .systemBackground,
        dark: UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.0)
    )

    static let appSurfaceElevated: UIColor = AppColors.dynamic(
        light: .secondarySystemBackground,
        dark: UIColor(red: 0.14, green: 0.14, blue: 0.17, alpha: 1.0)
    )

    // Borders / dividers
    static let appBorder: UIColor = AppColors.dynamic(
        light: UIColor.separator,
        dark: UIColor.white.withAlphaComponent(0.14)
    )

    static let appDivider: UIColor = AppColors.dynamic(
        light: UIColor.separator.withAlphaComponent(0.55),
        dark: UIColor.white.withAlphaComponent(0.10)
    )

    // Navigation chrome
    static let appNavBarBackground: UIColor = appGroupedBackground

    // Glass-like chrome for transparent headers (Home)
    static let appNavBarGlassBackground: UIColor = AppColors.dynamic(
        light: UIColor.systemBackground.withAlphaComponent(0.75),
        dark: UIColor.black.withAlphaComponent(0.45)
    )

    // Reels feed background should stay dark in both modes.
    static let reelsBackground: UIColor = UIColor(red: 0.02, green: 0.02, blue: 0.025, alpha: 1.0)

    // Chat
    static let appChatOutgoingBubble: UIColor = AppColors.dynamic(
        light: UIColor(red: 0.09, green: 0.635, blue: 0.722, alpha: 1.0),
        dark: UIColor(red: 0.075, green: 0.557, blue: 0.631, alpha: 1.0)
    )

    static let appChatIncomingBubble: UIColor = AppColors.dynamic(
        light: UIColor.secondarySystemBackground,
        dark: UIColor(red: 0.16, green: 0.16, blue: 0.19, alpha: 1.0)
    )

    static let appChatInputBarBackground: UIColor = appGroupedBackground
    static let appChatInputFieldBackground: UIColor = appSurface

    // Overlays / pills that sit on top of brand gradients.
    static let appPillOverlay: UIColor = AppColors.dynamic(
        light: UIColor.white.withAlphaComponent(0.22),
        dark: UIColor.white.withAlphaComponent(0.16)
    )
}

extension Color {
    static let appBackground = Color(uiColor: .appBackground)
    static let appGroupedBackground = Color(uiColor: .appGroupedBackground)
    static let appSurface = Color(uiColor: .appSurface)
    static let appSurfaceElevated = Color(uiColor: .appSurfaceElevated)
    static let appBorder = Color(uiColor: .appBorder)
    static let appDivider = Color(uiColor: .appDivider)
    static let appNavBarBackground = Color(uiColor: .appNavBarBackground)
    static let appNavBarGlassBackground = Color(uiColor: .appNavBarGlassBackground)
    static let reelsBackground = Color(uiColor: .reelsBackground)

    static let appChatOutgoingBubble = Color(uiColor: .appChatOutgoingBubble)
    static let appChatIncomingBubble = Color(uiColor: .appChatIncomingBubble)
    static let appChatInputBarBackground = Color(uiColor: .appChatInputBarBackground)
    static let appChatInputFieldBackground = Color(uiColor: .appChatInputFieldBackground)
    static let appPillOverlay = Color(uiColor: .appPillOverlay)
}

// Reusable surface styling for consistent hierarchy.
private struct AppCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: DS.cornerRadiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.cornerRadiusLG, style: .continuous)
                    .stroke(Color.appBorder.opacity(colorScheme == .dark ? 1.0 : 0.7), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08),
                radius: colorScheme == .dark ? 16 : 10,
                x: 0,
                y: colorScheme == .dark ? 8 : 4
            )
    }
}

extension View {
    func appCardStyle() -> some View {
        modifier(AppCardModifier())
    }
}

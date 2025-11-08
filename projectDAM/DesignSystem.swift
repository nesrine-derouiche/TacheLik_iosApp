import SwiftUI

// MARK: - Design System
struct DS {
    // MARK: - Colors
    struct Colors {
        static let primary = Color(red: 0.28, green: 0.52, blue: 0.85)
        static let secondary = Color(red: 0.42, green: 0.67, blue: 0.92)
        static let accent = Color(red: 0.95, green: 0.47, blue: 0.38)
        static let success = Color(red: 0.34, green: 0.73, blue: 0.42)
        static let warning = Color(red: 1.0, green: 0.76, blue: 0.03)
        static let error = Color(red: 0.93, green: 0.26, blue: 0.31)
        
        static let cardBackground = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
    }
    
    // MARK: - Spacing
    static let paddingXS: CGFloat = 4
    static let paddingSM: CGFloat = 8
    static let paddingMD: CGFloat = 16
    static let paddingLG: CGFloat = 24
    static let paddingXL: CGFloat = 32
    
    // MARK: - Corner Radius
    static let cornerRadiusSM: CGFloat = 8
    static let cornerRadiusMD: CGFloat = 12
    static let cornerRadiusLG: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 20
    
    // MARK: - Shadows
    static let shadowSM = Shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    static let shadowMD = Shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    static let shadowLG = Shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    // MARK: - Layout
    static let maxFormWidth: CGFloat = 500
    static let barHeight: CGFloat = 70
}

// MARK: - Color Extensions for Easy Access
extension Color {
    static let brandPrimary = Color(red: 0.28, green: 0.52, blue: 0.85)
    static let brandSecondary = Color(red: 0.42, green: 0.67, blue: 0.92)
    static let brandAccent = Color(red: 0.95, green: 0.47, blue: 0.38)
    static let brandSuccess = Color(red: 0.34, green: 0.73, blue: 0.42)
    static let brandWarning = Color(red: 1.0, green: 0.76, blue: 0.03)
    static let brandError = Color(red: 0.93, green: 0.26, blue: 0.31)
}

// MARK: - Gradient Extensions
extension LinearGradient {
    static let brandPrimaryGradient = LinearGradient(
        colors: [Color.brandPrimary, Color.brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let brandAccentGradient = LinearGradient(
        colors: [Color.brandAccent, Color.orange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [Color.brandSuccess, Color.green],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let brandHeader = LinearGradient(
        colors: [Color.brandPrimary, Color.brandSecondary, Color.brandAccent.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(LinearGradient.brandPrimaryGradient)
            .cornerRadius(DS.cornerRadiusLG)
            .shadow(color: Color.brandPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.brandPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.brandPrimary.opacity(0.1))
            .cornerRadius(DS.cornerRadiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: DS.cornerRadiusLG)
                    .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Card Modifiers
extension View {
    func cardStyle() -> some View {
        self
            .background(DS.Colors.cardBackground)
            .cornerRadius(DS.cornerRadiusLG)
            .shadow(color: DS.shadowMD.color, radius: DS.shadowMD.radius, x: DS.shadowMD.x, y: DS.shadowMD.y)
    }
    
    func glassMorphicCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DS.cornerRadiusLG)
                    .fill(Color.white.opacity(0.2))
                    .background(.ultraThinMaterial)
            )
            .cornerRadius(DS.cornerRadiusLG)
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(DS.paddingMD)
        .cardStyle()
    }
}

// MARK: - Custom Blur Background
struct BlurBackground: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea()
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Loading...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: DS.cornerRadiusLG)
                    .fill(Color.black.opacity(0.7))
            )
        }
    }
}

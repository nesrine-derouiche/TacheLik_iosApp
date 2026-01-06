import SwiftUI

// MARK: - Design System
struct DS {
    // MARK: - Colors (Tache-lik Brand)
    struct Colors {
        // Primary: #17a2b8 (cyan)
        static let primary = Color(red: 0.09, green: 0.635, blue: 0.722)
        // Secondary: #00394f (dark blue)
        static let secondary = Color(red: 0.0, green: 0.224, blue: 0.310)
        // Accent: Keep for highlights
        static let accent = Color(red: 0.09, green: 0.635, blue: 0.722)
        // Success: #28a745 (green)
        static let success = Color(red: 0.157, green: 0.655, blue: 0.271)
        // Warning: #ffc107 (yellow)
        static let warning = Color(red: 1.0, green: 0.757, blue: 0.027)
        // Error/Danger: #dc3545 (red)
        static let error = Color(red: 0.863, green: 0.208, blue: 0.271)
        
        // Use app surfaces to keep cards readable in dark mode (systemBackground becomes pure black).
        static let cardBackground = Color.appSurface
        static let secondaryBackground = Color.appSurfaceElevated
        static let tertiaryBackground = Color.appSurfaceElevated
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
    static let barHeight: CGFloat = 64
}

// MARK: - Color Extensions for Easy Access (Tache-lik Brand)
extension Color {
    // Primary: #17a2b8 (cyan)
    static let brandPrimary = Color(red: 0.09, green: 0.635, blue: 0.722)
    // Primary Hover: #138ea1
    static let brandPrimaryHover = Color(red: 0.075, green: 0.557, blue: 0.631)
    // Secondary: #00394f (dark blue)
    static let brandSecondary = Color(red: 0.0, green: 0.224, blue: 0.310)
    // Accent: Same as primary
    static let brandAccent = Color(red: 0.09, green: 0.635, blue: 0.722)
    // Success: #28a745
    static let brandSuccess = Color(red: 0.157, green: 0.655, blue: 0.271)
    // Warning: #ffc107
    static let brandWarning = Color(red: 1.0, green: 0.757, blue: 0.027)
    // Error: #dc3545
    static let brandError = Color(red: 0.863, green: 0.208, blue: 0.271)
    // Background: #f5f5f5
    static let brandBackground = Color(red: 0.961, green: 0.961, blue: 0.961)
    // Text: #333
    static let brandText = Color(red: 0.2, green: 0.2, blue: 0.2)
}

// MARK: - Gradient Extensions (Tache-lik Brand)
extension LinearGradient {
    static let brandPrimaryGradient = LinearGradient(
        colors: [Color.brandPrimary, Color.brandPrimaryHover],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let brandAccentGradient = LinearGradient(
        colors: [Color.brandPrimary, Color.brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [Color.brandSuccess, Color.green],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let brandHeader = LinearGradient(
        colors: [Color.brandSecondary, Color.brandPrimary],
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
        self.appCardStyle()
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

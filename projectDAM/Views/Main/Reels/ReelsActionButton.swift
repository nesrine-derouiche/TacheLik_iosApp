import SwiftUI

/// Shared action button used in Reel overlays (likes, comments, bookmark, share).
struct ActionButton: View {
    let icon: String
    let text: String
    var isSelected: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    private var isHeartButton: Bool {
        icon == "heart.fill"
    }

    private var isBookmarkButton: Bool {
        icon == "bookmark.fill" || icon == "bookmark"
    }

    private var selectedColor: Color {
        if isHeartButton { return .red }
        if isBookmarkButton { return .brandWarning }
        return .brandPrimary
    }

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? selectedColor : .white)
                    .scaleEffect(isPressed ? 0.86 : (isSelected ? 1.08 : 1.0))
                    .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 2)
                    .frame(width: 44, height: 44)

                Text(text)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? selectedColor : .white)
                    .monospacedDigit()
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

import SwiftUI

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -0.8

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .rotationEffect(.degrees(20))
                    .offset(x: phase * geo.size.width)
                }
                .blendMode(.screen)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

extension View {
    @ViewBuilder
    func shimmering(_ enabled: Bool) -> some View {
        if enabled {
            self.modifier(Shimmer())
        } else {
            self
        }
    }
}

struct SkeletonBlock: View {
    var height: CGFloat
    var cornerRadius: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray5))
            .frame(height: height)
            .shimmering(true)
    }
}

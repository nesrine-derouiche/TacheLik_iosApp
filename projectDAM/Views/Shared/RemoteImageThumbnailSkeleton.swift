import SwiftUI

struct RemoteImageThumbnailSkeleton: View {
    let cornerRadius: CGFloat
    let baseColor: Color
    
    @State private var phase: CGFloat = -1
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(baseColor.opacity(0.4))
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width * 1.5)
                    .offset(x: width * phase)
                )
        }
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                phase = 1.5
            }
        }
    }
}

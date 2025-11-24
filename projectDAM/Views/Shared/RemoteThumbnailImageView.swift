import SwiftUI
import UIKit

final class RemoteImageCache {
    static let shared = RemoteImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    
    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    
    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

struct RemoteThumbnailImageView<Fallback: View>: View {
    let url: URL?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let baseColor: Color
    let fallback: () -> Fallback
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var didFail = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            baseColor.opacity(0.9),
                            baseColor.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            contentOverlay
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: baseColor.opacity(0.22), radius: 8, x: 0, y: 4)
        .task(id: url?.absoluteString) {
            await loadImageIfNeeded()
        }
    }
    
    @ViewBuilder
    private var contentOverlay: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .transition(.opacity.combined(with: .scale))
        } else if isLoading {
            RemoteImageThumbnailSkeleton(cornerRadius: cornerRadius, baseColor: baseColor)
        } else {
            fallback()
        }
    }
    
    private func loadImageIfNeeded() async {
        guard let url else { return }
        if image != nil { return }
        if let cached = RemoteImageCache.shared.image(for: url) {
            await MainActor.run {
                image = cached
                isLoading = false
            }
            return
        }
        await MainActor.run {
            isLoading = true
            didFail = false
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                await MainActor.run {
                    didFail = true
                    isLoading = false
                }
                return
            }
            guard let uiImage = UIImage(data: data) else {
                await MainActor.run {
                    didFail = true
                    isLoading = false
                }
                return
            }
            RemoteImageCache.shared.insert(uiImage, for: url)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.18)) {
                    image = uiImage
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                didFail = true
                isLoading = false
            }
        }
    }
}

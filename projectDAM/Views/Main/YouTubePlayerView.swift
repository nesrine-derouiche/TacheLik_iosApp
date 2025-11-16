import SwiftUI
import YouTubePlayerKit

/// Thin SwiftUI wrapper around YouTubePlayerKit that embeds a YouTube video by ID.
struct EmbeddedYouTubePlayerView: View {
    private let player: YouTubePlayer

    init(videoId: String) {
        print("[EmbeddedYouTubePlayerView] Init with videoId=\(videoId)")
        self.player = YouTubePlayer(source: .video(id: videoId))
    }

    var body: some View {
        YouTubePlayerView(player) { state in
            switch state {
            case .idle:
                ZStack {
                    Color.black
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
            case .ready:
                Color.clear
            case .error(let error):
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 28))
                    Text("YouTube Player Error")
                        .font(.system(size: 15, weight: .semibold))
                    Text(String(describing: error))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
    }
}

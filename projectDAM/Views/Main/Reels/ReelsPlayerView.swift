import SwiftUI
import AVFoundation

/// Shared AVPlayer view used across Reels-related screens.
/// Uses `AVPlayerLayer` with `.resizeAspectFill` to ensure proper centering and full-screen coverage.
struct PlayerView: UIViewRepresentable {
    var player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(player: player)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if uiView.player !== player {
            uiView.player = player
        }
        uiView.playerLayer.videoGravity = .resizeAspectFill
    }

    final class PlayerUIView: UIView {
        var player: AVPlayer? {
            get { playerLayer.player }
            set { playerLayer.player = newValue }
        }

        override class var layerClass: AnyClass { AVPlayerLayer.self }

        var playerLayer: AVPlayerLayer {
            layer as! AVPlayerLayer
        }

        init(player: AVPlayer) {
            super.init(frame: .zero)
            self.player = player
            backgroundColor = .black
            playerLayer.videoGravity = .resizeAspectFill
            clipsToBounds = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            playerLayer.frame = bounds
            CATransaction.commit()
        }
    }
}

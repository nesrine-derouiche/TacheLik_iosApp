import Foundation
import Combine

@MainActor
final class AiReelGeneratorCardViewModel: ObservableObject {

    enum UiState: Equatable {
        case idle
        case generating
        case success(reelsCount: Int)
        case error(message: String)
    }

    @Published var videoUrlText: String = ""
    @Published private(set) var uiState: UiState = .idle

    private let reelsService: ReelsServiceProtocol

    init(reelsService: ReelsServiceProtocol = DIContainer.shared.reelsService) {
        self.reelsService = reelsService
    }

    var trimmedVideoUrl: String {
        videoUrlText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValidYouTubeUrl: Bool {
        guard let url = URL(string: trimmedVideoUrl) else { return false }
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return false }
        guard let host = url.host?.lowercased() else { return false }

        // Accept common YouTube hosts
        let acceptedHosts: Set<String> = [
            "youtube.com",
            "www.youtube.com",
            "m.youtube.com",
            "youtu.be",
            "www.youtu.be"
        ]

        if acceptedHosts.contains(host) { return true }
        if host.hasSuffix(".youtube.com") { return true }

        return false
    }

    var canGenerate: Bool {
        uiState != .generating && isValidYouTubeUrl
    }

    func clearStatus() {
        if case .generating = uiState { return }
        uiState = .idle
    }

    func generate() async {
        let url = trimmedVideoUrl
        guard isValidYouTubeUrl else {
            uiState = .error(message: "Please enter a valid YouTube URL.")
            return
        }

        uiState = .generating

        do {
            let reels = try await reelsService.generateReels(videoUrl: url)
            if !reels.isEmpty {
                ReelFeedManager.shared.addGeneratedReels(reels)
            }
            uiState = .success(reelsCount: reels.count)
        } catch {
            let message = HomeErrorFormatter.message(for: error)
            uiState = .error(message: message)
        }
    }
}

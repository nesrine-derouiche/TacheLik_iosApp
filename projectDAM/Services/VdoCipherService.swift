import Foundation
import UIKit
 
protocol VdoCipherServiceProtocol {
    func playPaidVideo(videoId: String) async
    func getPlaybackUrl(videoId: String) async throws -> String
}

struct VdoPlaybackOtpResponse: Decodable {
    let success: Bool?
    let otp: VdoPlaybackOtp
}

struct VdoPlaybackOtp: Decodable {
    let otp: String
    let playbackInfo: String
}

final class VdoCipherService: VdoCipherServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
 
    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
    }

    func playPaidVideo(videoId: String) async {
        do {
            let details = try await fetchPlaybackDetails(videoId: videoId)
            try await startPlayback(videoId: videoId, details: details)
        } catch {
            if AppConfig.enableLogging {
                print("⚠️ [VdoCipherService] Failed to play VdoCipher video \(videoId): \(error)")
            }
        }
    }
    
    /// Get VdoCipher playback URL for embedding in reels
    func getPlaybackUrl(videoId: String) async throws -> String {
        let details = try await fetchPlaybackDetails(videoId: videoId)
        // Construct the VdoCipher embed URL with OTP and playbackInfo
        return "https://player.vdocipher.com/v2/?otp=\(details.otp)&playbackInfo=\(details.playbackInfo)"
    }

    private func fetchPlaybackDetails(videoId: String) async throws -> VdoPlaybackOtp {
        guard let user = authService.getCurrentUser(),
              let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }

        let encodedVideoId = videoId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? videoId
        let encodedUserId = user.id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? user.id

        let endpoint = "/video/playing-details/payed?videoId=\(encodedVideoId)&userId=\(encodedUserId)&videoOrigin=video"

        let response: VdoPlaybackOtpResponse = try await networkService.request(
            endpoint: endpoint,
            method: .GET,
            body: nil,
            headers: ["Authorization": "Bearer \(token)"]
        )

        guard response.success ?? true else {
            throw NetworkError.serverError(400, "Playback details request not successful")
        }

        return response.otp
    }

    @MainActor
    private func startPlayback(videoId: String, details: VdoPlaybackOtp) async throws {
        if AppConfig.enableLogging {
            print("[VdoCipherService] Paid video playback is currently disabled. videoId=\(videoId)")
        }

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            let alert = UIAlertController(
                title: "Playback not available",
                message: "Paid video playback is currently unavailable on this device.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            rootVC.present(alert, animated: true)
        }
    }
}

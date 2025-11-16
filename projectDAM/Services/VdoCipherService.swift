import Foundation
import UIKit
import VdoFramework

protocol VdoCipherServiceProtocol {
    func playPaidVideo(videoId: String) async
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
    private var currentAsset: VdoAsset?

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
        #if targetEnvironment(simulator)
        if AppConfig.enableLogging {
            print("[VdoCipherService] Playback not supported in simulator. Please run on a physical device.")
        }

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            let alert = UIAlertController(
                title: "Paid videos not available in Simulator",
                message: "VdoCipher playback requires a real iOS device. Please run this lesson on a physical iPhone or iPad.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            rootVC.present(alert, animated: true)
        }
        return
        #else
        VdoAsset.createAsset(videoId: videoId) { [weak self] asset, error in
            if let error {
                if AppConfig.enableLogging {
                    print("⚠️ [VdoCipherService] Asset creation failed for videoId=\(videoId): \(error)")
                }
                return
            }
            guard let self, let asset else { return }
            self.currentAsset = asset

            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
                if AppConfig.enableLogging {
                    print("⚠️ [VdoCipherService] Could not find root view controller to present player")
                }
                return
            }

            DispatchQueue.main.async {
                let vdoPlayerController: VdoPlayerViewController = VdoCipher.getVdoPlayerViewController()
                rootVC.present(vdoPlayerController, animated: true) {
                    asset.playOnline(otp: details.otp, playbackInfo: details.playbackInfo)
                }
            }
        }
        #endif
    }
}

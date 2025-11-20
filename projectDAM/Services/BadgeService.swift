import Foundation

protocol BadgeServiceProtocol {
    func fetchMyBadges() async throws -> [AwardedBadge]
}

final class BadgeService: BadgeServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
    }
    
    func fetchMyBadges() async throws -> [AwardedBadge] {
        guard let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }
        
        struct BadgesResponse: Decodable {
            let success: Bool
            let badges: [AwardedBadge]
        }
        
        if AppConfig.enableLogging {
            print("📡 [BadgeService] Requesting my badges at GET /badge/me")
        }
        
        let response: BadgesResponse = try await networkService.request(
            endpoint: "/badge/me",
            method: .GET,
            body: nil,
            headers: ["Authorization": "Bearer \(token)"]
        )
        
        if AppConfig.enableLogging {
            print("✅ [BadgeService] Received \(response.badges.count) badges for current user")
        }
        
        return response.badges
    }
}

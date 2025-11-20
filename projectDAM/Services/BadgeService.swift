import Foundation

protocol BadgeServiceProtocol {
    func fetchMyBadges() async throws -> [AwardedBadge]
    func fetchBadges(for userId: String) async throws -> [AwardedBadge]
    func fetchBadgeLeaderboard(page: Int, limit: Int) async throws -> BadgeLeaderboardPage
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

    func fetchBadges(for userId: String) async throws -> [AwardedBadge] {
        guard let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }

        struct BadgesResponse: Decodable {
            let success: Bool
            let badges: [AwardedBadge]
        }

        if AppConfig.enableLogging {
            print("📡 [BadgeService] Requesting badges for user at GET /badge/user/\(userId)")
        }

        let response: BadgesResponse = try await networkService.request(
            endpoint: "/badge/user/\(userId)",
            method: .GET,
            body: nil,
            headers: ["Authorization": "Bearer \(token)"]
        )

        if AppConfig.enableLogging {
            print("✅ [BadgeService] Received \(response.badges.count) badges for user \(userId)")
        }

        return response.badges
    }

    func fetchBadgeLeaderboard(page: Int, limit: Int) async throws -> BadgeLeaderboardPage {
        guard let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }

        if AppConfig.enableLogging {
            print("📡 [BadgeService] Requesting badge leaderboard at GET /badge/leaderboard?page=\(page)&limit=\(limit)")
        }

        let response: BadgeLeaderboardPage = try await networkService.request(
            endpoint: "/badge/leaderboard?page=\(page)&limit=\(limit)",
            method: .GET,
            body: nil,
            headers: ["Authorization": "Bearer \(token)"]
        )

        if AppConfig.enableLogging {
            print("✅ [BadgeService] Received leaderboard page=\(response.page) total=\(response.total)")
        }

        return response
    }
}

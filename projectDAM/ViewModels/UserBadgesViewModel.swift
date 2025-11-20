import Foundation
import Combine

@MainActor
final class UserBadgesViewModel: ObservableObject {
    @Published private(set) var badges: [AwardedBadge] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    let userId: String
    let username: String

    private let badgeService: BadgeServiceProtocol

    init(userId: String, username: String, badgeService: BadgeServiceProtocol) {
        self.userId = userId
        self.username = username
        self.badgeService = badgeService
    }

    func loadBadges() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await badgeService.fetchBadges(for: userId)
            badges = fetched.sorted { $0.awardedAt > $1.awardedAt }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

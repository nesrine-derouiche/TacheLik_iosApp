import Foundation
import Combine

@MainActor
final class BadgesViewModel: ObservableObject {
    @Published private(set) var badges: [AwardedBadge] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    private let badgeService: BadgeServiceProtocol
    
    init(badgeService: BadgeServiceProtocol) {
        self.badgeService = badgeService
    }
    
    func loadBadges() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let fetched = try await badgeService.fetchMyBadges()
            badges = fetched.sorted { $0.awardedAt > $1.awardedAt }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

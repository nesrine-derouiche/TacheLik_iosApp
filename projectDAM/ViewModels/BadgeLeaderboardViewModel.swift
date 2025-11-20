import Foundation
import Combine

@MainActor
final class BadgeLeaderboardViewModel: ObservableObject {
    @Published private(set) var entries: [BadgeLeaderboardEntry] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    private let badgeService: BadgeServiceProtocol
    private var currentPage: Int = 1
    private let pageSize: Int = 5
    private var totalPages: Int = 1
    private var isLoadingPage: Bool = false
    
    init(badgeService: BadgeServiceProtocol) {
        self.badgeService = badgeService
    }
    
    func loadInitial() async {
        guard !isLoadingPage else { return }
        isLoading = true
        isLoadingPage = true
        errorMessage = nil
        currentPage = 1
        entries = []
        
        do {
            let page = try await badgeService.fetchBadgeLeaderboard(page: currentPage, limit: pageSize)
            entries = page.leaderboard
            totalPages = page.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        isLoadingPage = false
    }
    
    func loadMoreIfNeeded(currentEntry: BadgeLeaderboardEntry?) async {
        guard let currentEntry else { return }
        guard !isLoadingPage, currentPage < totalPages else { return }
        
        let thresholdIndex = entries.index(entries.endIndex, offsetBy: -2, limitedBy: entries.startIndex) ?? entries.startIndex
        if let currentIndex = entries.firstIndex(where: { $0.id == currentEntry.id }), currentIndex >= thresholdIndex {
            await loadNextPage()
        }
    }
    
    private func loadNextPage() async {
        guard !isLoadingPage, currentPage < totalPages else { return }
        isLoadingPage = true
        errorMessage = nil
        
        do {
            let nextPage = currentPage + 1
            let page = try await badgeService.fetchBadgeLeaderboard(page: nextPage, limit: pageSize)
            entries.append(contentsOf: page.leaderboard)
            currentPage = page.page
            totalPages = page.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoadingPage = false
    }
}

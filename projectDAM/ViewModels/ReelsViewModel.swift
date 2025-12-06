//
//  ReelsViewModel.swift
//  projectDAM
//
//  ViewModel for Reels feature
//

import Foundation
import Combine
import SwiftUI

// MARK: - Reels View State
enum ReelsViewState {
    case idle
    case loading
    case loaded
    case error(String)
}

// MARK: - Reels ViewModel
@MainActor
final class ReelsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var reels: [Reel] = []
    @Published var currentIndex: Int = 0
    @Published var viewState: ReelsViewState = .idle
    @Published var isLoadingMore: Bool = false
    @Published var hasMorePages: Bool = true
    @Published var selectedType: ReelType? = nil
    
    // MARK: - Private Properties
    private let reelService: ReelServiceProtocol
    private var currentPage: Int = 1
    private let pageLimit: Int = 10
    private var viewedReelIds: Set<String> = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(reelService: ReelServiceProtocol) {
        self.reelService = reelService
        
        // Listen for new reels created by teacher
        NotificationCenter.default.addObserver(
            forName: .reelCreated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshReels()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Load initial reels feed
    func loadReels() async {
        guard case .idle = viewState else { return }
        
        viewState = .loading
        currentPage = 1
        
        do {
            let response = try await reelService.fetchReelsFeed(
                page: currentPage,
                limit: pageLimit,
                type: selectedType
            )
            
            reels = response.reels
            hasMorePages = currentPage < response.totalPages
            viewState = .loaded
            
            // Record view for first reel
            if let firstReel = reels.first {
                await recordViewIfNeeded(for: firstReel)
            }
            
        } catch {
            print("❌ [ReelsViewModel] Failed to load reels: \(error)")
            // Use ReelStorage which includes teacher-created reels + mock data
            reels = ReelStorage.shared.getAllReels()
            hasMorePages = false
            viewState = .loaded
            print("ℹ️ [ReelsViewModel] Using local storage as fallback (\(reels.count) reels)")
        }
    }
    
    /// Refresh reels feed
    func refreshReels() async {
        currentPage = 1
        viewedReelIds.removeAll()
        
        do {
            let response = try await reelService.fetchReelsFeed(
                page: currentPage,
                limit: pageLimit,
                type: selectedType
            )
            
            reels = response.reels
            hasMorePages = currentPage < response.totalPages
            viewState = .loaded
            
        } catch {
            print("❌ [ReelsViewModel] Failed to refresh reels: \(error)")
            // Use ReelStorage which includes teacher-created reels + mock data
            reels = ReelStorage.shared.getAllReels()
            hasMorePages = false
            viewState = .loaded
        }
    }
    
    /// Load more reels when scrolling
    func loadMoreIfNeeded(currentReel: Reel) async {
        guard hasMorePages, !isLoadingMore else { return }
        
        // Load more when reaching second-to-last reel
        let thresholdIndex = reels.count - 2
        guard let currentIndex = reels.firstIndex(where: { $0.id == currentReel.id }),
              currentIndex >= thresholdIndex else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            let response = try await reelService.fetchReelsFeed(
                page: currentPage,
                limit: pageLimit,
                type: selectedType
            )
            
            reels.append(contentsOf: response.reels)
            hasMorePages = currentPage < response.totalPages
            
        } catch {
            currentPage -= 1
            print("❌ [ReelsViewModel] Failed to load more reels: \(error)")
        }
        
        isLoadingMore = false
    }
    
    /// Record view for a reel (only once per session)
    func recordViewIfNeeded(for reel: Reel) async {
        guard !viewedReelIds.contains(reel.id) else { return }
        
        viewedReelIds.insert(reel.id)
        
        do {
            try await reelService.recordView(reelId: reel.id)
            
            // Update local count
            if let index = reels.firstIndex(where: { $0.id == reel.id }) {
                reels[index].viewsCount += 1
            }
            
        } catch {
            viewedReelIds.remove(reel.id)
            print("❌ [ReelsViewModel] Failed to record view: \(error)")
        }
    }
    
    /// Toggle like for a reel
    func toggleLike(for reel: Reel) async {
        guard let index = reels.firstIndex(where: { $0.id == reel.id }) else { return }
        
        // Optimistic update
        let wasLiked = reels[index].isLiked
        reels[index].isLiked.toggle()
        reels[index].likesCount += wasLiked ? -1 : 1
        
        do {
            let liked = try await reelService.toggleLike(reelId: reel.id)
            
            // Verify server state matches
            if liked != reels[index].isLiked {
                reels[index].isLiked = liked
                reels[index].likesCount += liked ? 1 : -1
            }
            
        } catch {
            // Revert on failure
            reels[index].isLiked = wasLiked
            reels[index].likesCount += wasLiked ? 1 : -1
            print("❌ [ReelsViewModel] Failed to toggle like: \(error)")
        }
    }
    
    /// Record share for a reel
    func recordShare(for reel: Reel) async {
        do {
            try await reelService.recordShare(reelId: reel.id)
            
            // Update local count
            if let index = reels.firstIndex(where: { $0.id == reel.id }) {
                reels[index].sharesCount += 1
            }
            
        } catch {
            print("❌ [ReelsViewModel] Failed to record share: \(error)")
        }
    }
    
    /// Filter reels by type
    func filterByType(_ type: ReelType?) {
        selectedType = type
        viewState = .idle
        Task {
            await loadReels()
        }
    }
    
    /// Handle reel change (when user swipes)
    func onReelChange(to index: Int) {
        currentIndex = index
        
        guard index >= 0, index < reels.count else { return }
        
        let reel = reels[index]
        
        // Record view
        Task {
            await recordViewIfNeeded(for: reel)
            await loadMoreIfNeeded(currentReel: reel)
        }
    }
}

// MARK: - Preview ViewModel
extension ReelsViewModel {
    static var preview: ReelsViewModel {
        let viewModel = ReelsViewModel(reelService: MockReelService())
        viewModel.reels = Reel.mockReels
        viewModel.viewState = .loaded
        return viewModel
    }
}

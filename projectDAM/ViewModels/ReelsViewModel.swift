//
//  ReelsViewModel.swift
//  projectDAM
//
//  Created by Antigravity on 12/07/2025.
//

import Foundation
import Combine
import AVFoundation
import SwiftUI


@MainActor
class ReelsViewModel: ObservableObject {
    @Published var reels: [Reel] = []
    @Published var isLoading = false
    @Published var error: String? = nil
    
    // To track seen IDs for the current session
    private var seenReelIds: [String] = []
    
    private let reelsService: ReelsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(reelsService: ReelsServiceProtocol = ReelsService()) {
        self.reelsService = reelsService
        setupPendingReelsObserver()
    }
    
    /// Observe ReelFeedManager for newly generated reels to insert at the top of the feed
    private func setupPendingReelsObserver() {
        ReelFeedManager.shared.$hasPendingReels
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasPending in
                guard hasPending else { return }
                Task { @MainActor [weak self] in
                    self?.insertPendingReels()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Insert pending reels from the manager at the top of the feed
    private func insertPendingReels() {
        let pendingReels = ReelFeedManager.shared.consumePendingReels()
        guard !pendingReels.isEmpty else { return }
        
        print("[ReelsViewModel] 📥 Inserting \(pendingReels.count) pending reels at top of feed")
        
        // Filter out any duplicates (shouldn't happen but be safe)
        let uniquePendingReels = pendingReels.filter { pending in
            !self.reels.contains(where: { $0.id == pending.id })
        }
        
        guard !uniquePendingReels.isEmpty else {
            print("[ReelsViewModel] ⚠️ All pending reels were duplicates, skipping insert")
            return
        }
        
        // Insert at the beginning of the feed (index 0)
        self.reels.insert(contentsOf: uniquePendingReels, at: 0)
        
        // Mark as seen so they don't get fetched again from the backend
        self.seenReelIds.append(contentsOf: uniquePendingReels.map { $0.id })
        
        // Preload the first inserted reel's player
        if let firstReel = uniquePendingReels.first {
            _ = getPlayer(for: firstReel)
            print("[ReelsViewModel] 🎬 Preloading player for first inserted reel: \(firstReel.id)")
        }
        
        print("[ReelsViewModel] ✅ Feed now has \(self.reels.count) reels")
    }
    
    func loadInitialReels() async {
        guard reels.isEmpty else { return }
        await fetchReels()
    }
    
    func loadMoreReels(currentItemId: String) async {
        // Simple threshold: if we are near the end, load more
        guard let index = reels.firstIndex(where: { $0.id == currentItemId }) else { return }
        let thresholdIndex = reels.count - 2
        
        if index >= thresholdIndex && !isLoading {
            await fetchReels()
        }
    }
    
    private func fetchReels() async {
        isLoading = true
        error = nil
        
        do {
            let newReels = try await reelsService.fetchReels(seenIds: seenReelIds)
            
            if newReels.isEmpty {
                 // End of feed
                 if !reels.contains(where: { $0.id == Reel.endOfFeed.id }) {
                     reels.append(Reel.endOfFeed)
                 }
            } else {
                // Filter out any duplicates just in case client/server sync is off
                let uniqueNewReels = newReels.filter { newReel in
                    !self.reels.contains(where: { $0.id == newReel.id })
                }
                
                if !uniqueNewReels.isEmpty {
                    self.reels.append(contentsOf: uniqueNewReels)
                    self.seenReelIds.append(contentsOf: uniqueNewReels.map { $0.id })
                } else if !reels.contains(where: { $0.id == Reel.endOfFeed.id }) {
                    // If we got reels but they were all duplicates, we might be at end or just unlucky.
                    // For now, let's try one more time or just assume end if it persists, 
                    // but practically it means end of content for this user session.
                    reels.append(Reel.endOfFeed)
                }
            }
        } catch let netError as NetworkError {
            self.error = netError.localizedDescription
        } catch {
            self.error = "Unable to load reels. Please check your connection."
        }
        
        isLoading = false
    }
    
    func toggleLike(reel: Reel) async {
        guard let index = reels.firstIndex(where: { $0.id == reel.id }) else { return }
        
        let isLiked = reel.isLiked ?? false
        let currentCount = reel.likesCount ?? 0
        let newLiked = !isLiked
        let newCount = newLiked ? currentCount + 1 : max(0, currentCount - 1)
        
        // Optimistic Update
        var updatedReel = reel.updatingLike(isLiked: newLiked, count: newCount)
        reels[index] = updatedReel
        
        do {
            let response = try await reelsService.toggleLike(reelId: reel.id)
            // Sync with server response
            if let reIndex = reels.firstIndex(where: { $0.id == reel.id }) {
                reels[reIndex] = reels[reIndex].updatingLike(isLiked: response.liked, count: response.likesCount)
            }
        } catch {
             // Revert on error
             if let reIndex = reels.firstIndex(where: { $0.id == reel.id }) {
                 reels[reIndex] = reels[reIndex].updatingLike(isLiked: isLiked, count: currentCount)
             }
             print("[ReelsViewModel] ❌ Failed to toggle like: \(error)")
        }
    }
    
    func toggleBookmark(reel: Reel) async {
        guard let index = reels.firstIndex(where: { $0.id == reel.id }) else { return }
        
        let isBookmarked = reel.isBookmarked ?? false
        let newBookmarked = !isBookmarked
        
        // Log action
        print("[ReelsViewModel] 🔖 Bookmark action: reelId=\(reel.id), newState=\(newBookmarked), timestamp=\(ISO8601DateFormatter().string(from: Date()))")
        
        // Optimistic Update
        reels[index] = reel.updatingBookmark(isBookmarked: newBookmarked)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        do {
            let serverBookmarked = try await reelsService.toggleBookmark(reelId: reel.id)
            // Sync with server response
            if let reIndex = reels.firstIndex(where: { $0.id == reel.id }) {
                reels[reIndex] = reels[reIndex].updatingBookmark(isBookmarked: serverBookmarked)
            }
            print("[ReelsViewModel] ✅ Bookmark synced: \(serverBookmarked)")
        } catch {
            // Revert on error
            if let reIndex = reels.firstIndex(where: { $0.id == reel.id }) {
                reels[reIndex] = reels[reIndex].updatingBookmark(isBookmarked: isBookmarked)
            }
            print("[ReelsViewModel] ❌ Failed to toggle bookmark: \(error)")
            // TODO: Show error toast to user
        }
    }
    
    // MARK: - Player Management
    // Cache for AVPlayers to enable smooth scrolling
    @Published var cachedPlayers: [String: AVPlayer] = [:]
    
    /// Returns a pre-loaded player or creates a new one
    func getPlayer(for reel: Reel) -> AVPlayer {
        if let player = cachedPlayers[reel.id] {
            return player
        }
        
        // Create new if not exists
        if let url = getStreamURL(for: reel) {
            let playerItem = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: playerItem)
            player.automaticallyWaitsToMinimizeStalling = false 
            cachedPlayers[reel.id] = player
            return player
        }
        
        return AVPlayer() // Fallback empty player
    }
    
    /// Preloads adjacent reels (current, next, next+1) and cleans up old ones
    func managePreloading(currentIndex: Int) {
        guard !reels.isEmpty else { return }
        
        let window = 2 // How many ahead to preload
        
        // 1. Determine IDs to keep
        var idsToKeep: Set<String> = []
        
        // Keep current
        if reels.indices.contains(currentIndex) {
            idsToKeep.insert(reels[currentIndex].id)
        }
        
        // Keep next few
        for i in 1...window {
            let nextIndex = currentIndex + i
            if reels.indices.contains(nextIndex) {
                idsToKeep.insert(reels[nextIndex].id)
            }
        }
        
        // Keep previous one (for smooth reverse scroll)
        if reels.indices.contains(currentIndex - 1) {
            idsToKeep.insert(reels[currentIndex - 1].id)
        }
        
        // 2. Remove players not in keep list
        for (id, player) in cachedPlayers {
            if !idsToKeep.contains(id) {
                player.pause()
                player.replaceCurrentItem(with: nil)
                cachedPlayers.removeValue(forKey: id)
            }
        }
        
        // 3. Create players for keep list if missing
        for index in (currentIndex - 1)...(currentIndex + window) {
            if index >= 0 && index < reels.count {
                let reel = reels[index]
                if cachedPlayers[reel.id] == nil {
                    _ = getPlayer(for: reel) // This implicitly creates and caches it
                }
            }
        }
    }
    
    func updateReelCommentCount(reelId: String, newCount: Int) {
        guard let index = reels.firstIndex(where: { $0.id == reelId }) else { return }
        reels[index] = reels[index].updatingCommentCount(newCount)
    }

    func getStreamURL(for reel: Reel) -> URL? {
        guard let filename = reel.filePath?.components(separatedBy: "/").last else { return nil }
        let urlString = reelsService.streamReelRawURL(filename: filename)
        return URL(string: urlString)
    }
}

//
//  BookmarksViewModel.swift
//  projectDAM
//
//  Created by Antigravity on 12/08/2025.
//

import Foundation
import Combine
import AVFoundation
import UIKit

@MainActor
class BookmarksViewModel: ObservableObject {
    @Published var bookmarkedReels: [Reel] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let reelsService: ReelsServiceProtocol
    
    // Player cache for smooth playback
    @Published var cachedPlayers: [String: AVPlayer] = [:]
    
    init(reelsService: ReelsServiceProtocol = DIContainer.shared.reelsService) {
        self.reelsService = reelsService
    }
    
    func loadBookmarks() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        print("[BookmarksViewModel] 📚 Loading bookmarked reels...")
        
        do {
            let reels = try await reelsService.getBookmarkedReels()
            // Saved Reels screen should always reflect that these items are bookmarked.
            bookmarkedReels = reels.map { $0.updatingBookmark(isBookmarked: true) }
            print("[BookmarksViewModel] ✅ Loaded \(bookmarkedReels.count) bookmarked reels")
        } catch let networkError as NetworkError {
            error = networkError.localizedDescription
            print("[BookmarksViewModel] ❌ Network error: \(networkError)")
        } catch {
            self.error = "Failed to load bookmarks. Please try again."
            print("[BookmarksViewModel] ❌ Error: \(error)")
        }
        
        isLoading = false
    }
    
    func toggleBookmark(reel: Reel) async {
        guard let index = bookmarkedReels.firstIndex(where: { $0.id == reel.id }) else { return }
        
        let isBookmarked = reel.isBookmarked ?? true
        
        // Log action
        print("[BookmarksViewModel] 🔖 Unbookmark action: reelId=\(reel.id), timestamp=\(ISO8601DateFormatter().string(from: Date()))")
        
        // Optimistic removal from list
        if let player = cachedPlayers[reel.id] {
            player.pause()
            player.isMuted = true
            player.volume = 0
            player.replaceCurrentItem(with: nil)
            cachedPlayers.removeValue(forKey: reel.id)
        }
        bookmarkedReels.remove(at: index)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        do {
            let serverBookmarked = try await reelsService.toggleBookmark(reelId: reel.id)
            
            if serverBookmarked {
                // Reel is still bookmarked (shouldn't happen but handle gracefully)
                bookmarkedReels.insert(reel.updatingBookmark(isBookmarked: true), at: min(index, bookmarkedReels.count))
            }
            print("[BookmarksViewModel] ✅ Bookmark removed")
        } catch {
            // Revert on error
            bookmarkedReels.insert(reel.updatingBookmark(isBookmarked: isBookmarked), at: min(index, bookmarkedReels.count))
            print("[BookmarksViewModel] ❌ Failed to toggle bookmark: \(error)")
        }
    }

    func toggleLike(reel: Reel) async {
        guard let index = bookmarkedReels.firstIndex(where: { $0.id == reel.id }) else { return }

        let original = bookmarkedReels[index]
        let optimisticLiked = !(original.isLiked ?? false)
        let originalCount = original.likesCount ?? 0
        let optimisticCount = max(0, originalCount + (optimisticLiked ? 1 : -1))

        bookmarkedReels[index] = original.updatingLike(isLiked: optimisticLiked, count: optimisticCount)

        do {
            let result = try await reelsService.toggleLike(reelId: reel.id)
            bookmarkedReels[index] = original.updatingLike(isLiked: result.liked, count: result.likesCount)
        } catch {
            bookmarkedReels[index] = original
            print("[BookmarksViewModel] ❌ Failed to toggle like: \(error)")
        }
    }

    func updateReelCommentCount(reelId: String, newCount: Int) {
        guard let index = bookmarkedReels.firstIndex(where: { $0.id == reelId }) else { return }
        bookmarkedReels[index] = bookmarkedReels[index].updatingCommentCount(newCount)
    }
    
    // MARK: - Player Management
    func getPlayer(for reel: Reel) -> AVPlayer {
        if let player = cachedPlayers[reel.id] {
            return player
        }
        
        if let url = getStreamURL(for: reel) {
            let playerItem = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: playerItem)
            player.automaticallyWaitsToMinimizeStalling = false
            // Ensure preloaded players never create audible overlap.
            player.isMuted = true
            player.volume = 0
            cachedPlayers[reel.id] = player
            return player
        }
        
        return AVPlayer()
    }
    
    func getStreamURL(for reel: Reel) -> URL? {
        guard let filename = reel.filePath?.components(separatedBy: "/").last else { return nil }
        let urlString = reelsService.streamReelRawURL(filename: filename)
        return URL(string: urlString)
    }
    
    func managePreloading(currentIndex: Int) {
        guard !bookmarkedReels.isEmpty else { return }
        
        let window = 2
        var idsToKeep: Set<String> = []
        
        if bookmarkedReels.indices.contains(currentIndex) {
            idsToKeep.insert(bookmarkedReels[currentIndex].id)
        }
        
        for i in 1...window {
            let nextIndex = currentIndex + i
            if bookmarkedReels.indices.contains(nextIndex) {
                idsToKeep.insert(bookmarkedReels[nextIndex].id)
            }
        }
        
        if bookmarkedReels.indices.contains(currentIndex - 1) {
            idsToKeep.insert(bookmarkedReels[currentIndex - 1].id)
        }
        
        for (id, player) in cachedPlayers {
            if !idsToKeep.contains(id) {
                player.pause()
                player.replaceCurrentItem(with: nil)
                cachedPlayers.removeValue(forKey: id)
            }
        }
        
        for index in (currentIndex - 1)...(currentIndex + window) {
            if index >= 0 && index < bookmarkedReels.count {
                let reel = bookmarkedReels[index]
                if cachedPlayers[reel.id] == nil {
                    _ = getPlayer(for: reel)
                }
            }
        }
    }

    func pauseAllPlayers(except activeReelId: String?) {
        for (id, player) in cachedPlayers {
            if id == activeReelId {
                continue
            }
            player.pause()
            player.isMuted = true
            player.volume = 0
        }
    }

    func stopAllPlayers() {
        for (_, player) in cachedPlayers {
            player.pause()
            player.isMuted = true
            player.volume = 0
        }
    }
    
    func cleanup() {
        for (_, player) in cachedPlayers {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
        cachedPlayers.removeAll()
    }
}

//
//  ReelFeedManager.swift
//  projectDAM
//
//  Created by Antigravity on 12/08/2025.
//

import Foundation
import Combine

/// Singleton manager to coordinate newly generated reels across the app.
/// Allows the generation flow to push reels to the Explore feed without manual refresh.
@MainActor
final class ReelFeedManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ReelFeedManager()
    
    // MARK: - Published Properties
    
    /// Queue of newly generated reels waiting to be inserted into the feed
    @Published private(set) var pendingReels: [Reel] = []
    
    /// Flag indicating there are pending reels to show
    @Published private(set) var hasPendingReels: Bool = false
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Add newly generated reels to the pending queue.
    /// Call this after POST /reels/generate/:id succeeds.
    /// - Parameter reels: Array of Reel objects from the generation response
    func addGeneratedReels(_ reels: [Reel]) {
        // Validate each reel has a valid filePath before adding
        let validReels = reels.filter { reel in
            guard let filePath = reel.filePath else {
                print("[ReelFeedManager] ⚠️ Skipping reel \(reel.id): missing filePath")
                return false
            }
            
            // Extract filename and validate
            guard let filename = filePath.components(separatedBy: "/").last, !filename.isEmpty else {
                print("[ReelFeedManager] ⚠️ Skipping reel \(reel.id): malformed filePath '\(filePath)'")
                return false
            }
            
            print("[ReelFeedManager] ✅ Added reel \(reel.id) with filename: \(filename)")
            return true
        }
        
        guard !validReels.isEmpty else {
            print("[ReelFeedManager] ⚠️ No valid reels to add")
            return
        }
        
        pendingReels.append(contentsOf: validReels)
        hasPendingReels = true
        
        print("[ReelFeedManager] 📥 Added \(validReels.count) reels to pending queue. Total pending: \(pendingReels.count)")
    }
    
    /// Consume all pending reels. Call this from ReelsViewModel when inserting into the feed.
    /// - Returns: Array of pending reels, clearing the queue
    func consumePendingReels() -> [Reel] {
        let reels = pendingReels
        pendingReels = []
        hasPendingReels = false
        
        print("[ReelFeedManager] 📤 Consumed \(reels.count) pending reels")
        return reels
    }
    
    /// Clear all pending reels without consuming them (e.g., on error)
    func clearPendingReels() {
        pendingReels = []
        hasPendingReels = false
        print("[ReelFeedManager] 🗑️ Cleared pending reels")
    }
}

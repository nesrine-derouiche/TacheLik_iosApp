//
//  Reel.swift
//  projectDAM
//
//  Created by Antigravity on 12/07/2025.
//

import Foundation

struct Reel: Codable, Identifiable, Equatable {
    let id: String
    let originalVideoUrl: String?
    let title: String?
    let description: String?
    let filePath: String?
    let videoId: String?
    let startTime: String?
    let endTime: String?
    let likesCount: Int?
    let commentsCount: Int?
    let isLiked: Bool?
    
    // Coding keys if needed to match JSON exactly (implicit match mostly fine)
    
    var videoURL: URL? {
        guard let filePath = filePath else { return nil }
        
        // If already a full URL, use it directly
        if filePath.hasPrefix("http") {
            return URL(string: filePath)
        }
        
        // Extract the filename from the filePath (e.g., "reels/reel_123.mp4" -> "reel_123.mp4")
        // The backend streaming endpoint is /reels/stream/{filename}
        guard let filename = filePath.components(separatedBy: "/").last else { return nil }
        
        // Construct the correct streaming URL
        return URL(string: "\(AppConfig.baseURL)/reels/stream/\(filename)")
    }
    
    // Equatable for Diffing
    static func == (lhs: Reel, rhs: Reel) -> Bool {
        return lhs.id == rhs.id
    }
    
    static var endOfFeed: Reel {
        return Reel(id: "END_OF_FEED", originalVideoUrl: nil, title: "All Caught Up", description: nil, filePath: nil, videoId: nil, startTime: nil, endTime: nil, likesCount: nil, commentsCount: nil, isLiked: nil)
    }
    
    // Helper to return a new copy with updated like status
    func updatingLike(isLiked: Bool, count: Int) -> Reel {
        return Reel(
            id: self.id,
            originalVideoUrl: self.originalVideoUrl,
            title: self.title,
            description: self.description,
            filePath: self.filePath,
            videoId: self.videoId,
            startTime: self.startTime,
            endTime: self.endTime,
            likesCount: count,
            commentsCount: self.commentsCount,
            isLiked: isLiked
        )
    }
    
    // Helper to return a new copy with updated comments count
    func updatingCommentCount(_ count: Int) -> Reel {
        return Reel(
            id: self.id,
            originalVideoUrl: self.originalVideoUrl,
            title: self.title,
            description: self.description,
            filePath: self.filePath,
            videoId: self.videoId,
            startTime: self.startTime,
            endTime: self.endTime,
            likesCount: self.likesCount,
            commentsCount: count,
            isLiked: self.isLiked
        )
    }
}

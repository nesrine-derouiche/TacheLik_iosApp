//
//  ReelsService.swift
//  projectDAM
//
//  Created by Antigravity on 12/07/2025.
//

import Foundation
import Combine

protocol ReelsServiceProtocol {
    func fetchReels(seenIds: [String]) async throws -> [Reel]
    func streamReelRawURL(filename: String) -> String
    func toggleLike(reelId: String) async throws -> (liked: Bool, likesCount: Int)
    func addComment(reelId: String, content: String) async throws -> (comment: Comment, count: Int)
    func getComments(reelId: String) async throws -> [Comment]
    func deleteComment(reelId: String, commentId: String) async throws -> Int
    func generateReels(videoId: String) async throws -> [Reel]
    func toggleBookmark(reelId: String) async throws -> Bool
    func getBookmarkedReels() async throws -> [Reel]
}

final class ReelsService: ReelsServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService(), authService: AuthServiceProtocol = DIContainer.shared.authService) {
        self.networkService = networkService
        self.authService = authService
    }
    
    private var authHeaders: [String: String]? {
        guard let token = authService.getAuthToken() else { return nil }
        return ["Authorization": "Bearer \(token)"]
    }
    
    func fetchReels(seenIds: [String]) async throws -> [Reel] {
        let body: [String: Any] = ["seenReelIds": seenIds]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        return try await networkService.request(
            endpoint: "/reels/feed",
            method: .POST,
            body: jsonData,
            headers: authHeaders
        )
    }
    
    func streamReelRawURL(filename: String) -> String {
        return "\(AppConfig.baseURL)/reels/stream/\(filename)"
    }
    
    func toggleLike(reelId: String) async throws -> (liked: Bool, likesCount: Int) {
        struct LikeResponse: Decodable {
            let message: String
            let liked: Bool
            let likesCount: Int
        }
        
        let response: LikeResponse = try await networkService.request(
            endpoint: "/reels/\(reelId)/like",
            method: .POST,
            body: nil,
            headers: authHeaders
        )
        return (response.liked, response.likesCount)
    }
    
    func addComment(reelId: String, content: String) async throws -> (comment: Comment, count: Int) {
        let body = ["content": content]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        struct AddCommentResponse: Decodable {
            let id: String
            let content: String
            let createdAt: String
            let user: Comment.CommentUser
            let commentsCount: Int
        }

        let response: AddCommentResponse = try await networkService.request(
             endpoint: "/reels/\(reelId)/comments",
             method: .POST,
             body: jsonData,
             headers: authHeaders
         )
         
         let comment = Comment(id: response.id, content: response.content, createdAt: response.createdAt, user: response.user)
         return (comment, response.commentsCount)
    }
    
    func getComments(reelId: String) async throws -> [Comment] {
        return try await networkService.request(
            endpoint: "/reels/\(reelId)/comments",
            method: .GET,
            body: nil,
            headers: authHeaders
        )
    }
    
    func deleteComment(reelId: String, commentId: String) async throws -> Int {
        struct DeleteResponse: Decodable {
            let message: String
            let commentsCount: Int
        }
        
        let response: DeleteResponse = try await networkService.request(
            endpoint: "/reels/\(reelId)/comments/\(commentId)",
            method: .DELETE,
            body: nil,
            headers: authHeaders
        )
        return response.commentsCount
    }
    
    // MARK: - Generation
    func generateReels(videoId: String) async throws -> [Reel] {
        let body = ["videoId": videoId]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        // 1. Start Generation Job
        struct GenerationResponse: Decodable {
            let message: String
            let jobId: String
        }
        
        let initialResponse: GenerationResponse = try await networkService.request(
            endpoint: "/reels/generate/id",
            method: .POST,
            body: jsonData,
            headers: authHeaders
        )
        
        let jobId = initialResponse.jobId
        print("[ReelsService] 🚀 Started reel generation job: \(jobId)")
        
        // 2. Poll for Status
        struct StatusResponse: Decodable {
            let status: String
            let reels: [Reel]?
            let error: String?
        }
        
        // Poll every 5 seconds, timeout after 5 minutes (60 attempts)
        for i in 0..<60 {
            try await Task.sleep(nanoseconds: 5 * 1_000_000_000) // 5 seconds
            
            let statusResponse: StatusResponse = try await networkService.request(
                endpoint: "/reels/generate/status/\(jobId)",
                method: .GET,
                body: nil,
                headers: authHeaders
            )
            
            print("[ReelsService] 🔄 Job \(jobId) status: \(statusResponse.status) (Attempt \(i + 1)/60)")
            
            if statusResponse.status == "completed" {
                if let reels = statusResponse.reels {
                    return reels
                } else {
                    throw NetworkError.serverError(200, "Job completed but returned no reels")
                }
            } else if statusResponse.status == "failed" {
                throw NetworkError.serverError(500, statusResponse.error ?? "Generation failed")
            }
            
            // If pending/processing, continue loop
        }
        
        throw NetworkError.serverError(408, "Generation timed out after polling")
    }
    
    // MARK: - Bookmarks
    func toggleBookmark(reelId: String) async throws -> Bool {
        struct BookmarkResponse: Decodable {
            let message: String
            let bookmarked: Bool
        }
        
        let response: BookmarkResponse = try await networkService.request(
            endpoint: "/reels/\(reelId)/bookmark",
            method: .POST,
            body: nil,
            headers: authHeaders
        )
        
        print("[ReelsService] 🔖 Bookmark toggled for reel \(reelId): \(response.bookmarked)")
        return response.bookmarked
    }
    
    func getBookmarkedReels() async throws -> [Reel] {
        let reels: [Reel] = try await networkService.request(
            endpoint: "/reels/bookmarks/all",
            method: .GET,
            body: nil,
            headers: authHeaders
        )
        
        print("[ReelsService] 📚 Fetched \(reels.count) bookmarked reels")
        return reels
    }
}

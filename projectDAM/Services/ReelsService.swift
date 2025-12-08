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
        
        // Backend returns the full comment object + commentsCount
        // We can create a custom response struct or decode Comment and handle count
        // Based on controller: res.status(201).json({ ...commentFields, commentsCount })
        
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
            headers: authHeaders // comments can be public, but send auth if available? controller says public, but we can send if we want
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
        
        struct GenerateResponse: Decodable {
            let message: String
            let reels: [Reel]
        }
        
        let response: GenerateResponse = try await networkService.request(
            endpoint: "/reels/generate/id",
            method: .POST,
            body: jsonData,
            headers: authHeaders
        )
        
        return response.reels
    }
}

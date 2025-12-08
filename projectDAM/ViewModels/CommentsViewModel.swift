//
//  CommentsViewModel.swift
//  projectDAM
//
//  Created by Antigravity on 12/07/2025.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var isPosting = false
    @Published var error: String? = nil
    
    let reelId: String
    private let reelsService: ReelsServiceProtocol
    private let authService: AuthServiceProtocol
    
    // Callback to update parent Reel's comment count
    var onCommentCountCheck: ((Int) -> Void)?
    
    var currentUserId: String? {
        return authService.getCurrentUser()?.id
    }
    
    init(reelId: String, reelsService: ReelsServiceProtocol = ReelsService(), authService: AuthServiceProtocol = DIContainer.shared.authService) {
        self.reelId = reelId
        self.reelsService = reelsService
        self.authService = authService
    }
    
    func fetchComments() async {
        isLoading = true
        error = nil
        do {
            comments = try await reelsService.getComments(reelId: reelId)
        } catch {
            self.error = "Failed to load comments"
        }
        isLoading = false
    }
    
    func addComment(content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isPosting = true
        do {
            let (newComment, newCount) = try await reelsService.addComment(reelId: reelId, content: content)
            comments.insert(newComment, at: 0) // Prepend
            onCommentCountCheck?(newCount)
        } catch {
            self.error = "Failed to post comment"
        }
        isPosting = false
    }
     
    func deleteComment(commentId: String) async {
        // Optimistic delete
        guard let index = comments.firstIndex(where: { $0.id == commentId }) else { return }
        let deletedComment = comments[index]
        
        withAnimation {
            comments.remove(at: index)
        }
        
        do {
            let newCount = try await reelsService.deleteComment(reelId: reelId, commentId: commentId)
            onCommentCountCheck?(newCount)
        } catch {
            // Revert
            withAnimation {
                comments.insert(deletedComment, at: index)
            }
             self.error = "Failed to delete comment"
        }
    }
}

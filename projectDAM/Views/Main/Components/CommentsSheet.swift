//
//  CommentsSheet.swift
//  projectDAM
//
//  Created by Antigravity on 12/07/2025.
//

import SwiftUI

struct CommentsSheet: View {
    @StateObject private var viewModel: CommentsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var newCommentText = ""
    
    init(reelId: String, onCommentCountCheck: ((Int) -> Void)? = nil) {
        let vm = CommentsViewModel(reelId: reelId)
        vm.onCommentCountCheck = onCommentCountCheck
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack {
                Capsule()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)
                
                Text("Comments")
                    .font(.headline)
                    .padding(.vertical, 10)
            }
            .background(Color(.systemBackground))
            
            Divider()
            
            // List
            if viewModel.isLoading {
                ProgressView()
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.comments.isEmpty {
                VStack {
                    Spacer()
                    Text("No comments yet. Be the first!")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.comments) { comment in
                        CommentRow(comment: comment)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .deleteDisabled(comment.user.id != viewModel.currentUserId)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let comment = viewModel.comments[index]
                            Task {
                                await viewModel.deleteComment(commentId: comment.id)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            
            Divider()
            
            // Input
            HStack(alignment: .bottom) {
                TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)
                    .lineLimit(1...5)
                
                Button {
                    Task {
                        await viewModel.addComment(content: newCommentText)
                        newCommentText = ""
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(newCommentText.isEmpty ? .gray : .blue)
                }
                .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isPosting)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .task {
            await viewModel.fetchComments()
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    // onDelete removed as we use List swipe actions now
    // In a real app we would check if current user == comment.user.id
    // For now we assume we can maybe delete our own or allow delete for all for demo if needed
    // But better to just show delete if authorized. Since we don't have current user in global state easily here without DI,
    // we will implement swipe to delete which usually implies ownership or admin.
    // Or we can just use a simple button.
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            if let imageString = comment.user.image,
               let imageData = Data(base64Encoded: imageString),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.user.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(timeAgoDisplay(date: comment.createdDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.content)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        // Context menu can remain as alternative or be removed if swipe is enough.
        // Keeping it for accessibility/alternate interaction. 
        // But contextMenu on List row sometimes conflicts or is redundant.
        // Let's keep it but maybe it's fine.
        // Actually, looking at code below, I see I removed the 'onDelete' closure from init in previous step but need to fix CommentRow signature.
        // Wait, in previous step I removed 'onDelete' from the call site BUT I did not update CommentRow definition.
        // I need to update CommentRow definition to remove 'onDelete' property if I removed it from init.
        // Checking previous call: I changed call site to `CommentRow(comment: comment)`.
        // So I MUST update CommentRow struct.
    }
    
    func timeAgoDisplay(date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

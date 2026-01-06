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
    @State private var showErrorAlert = false
    @FocusState private var isComposerFocused: Bool
    
    init(reelId: String, onCommentCountCheck: ((Int) -> Void)? = nil) {
        let vm = CommentsViewModel(reelId: reelId)
        vm.onCommentCountCheck = onCommentCountCheck
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error, !error.isEmpty, viewModel.comments.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("Couldn’t load comments")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        Button("Retry") {
                            Task { await viewModel.fetchComments() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 8)
                } else if viewModel.comments.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Text("No comments yet")
                            .font(.headline)
                        Text("Be the first to comment.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.comments) { comment in
                                CommentRow(
                                    comment: comment,
                                    canDelete: comment.user.id == viewModel.currentUserId,
                                    onDelete: {
                                        Task { await viewModel.deleteComment(commentId: comment.id) }
                                    }
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)

                                Divider()
                                    .padding(.leading, 64)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .padding(.top, 4)
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 10) {
                Capsule()
                    .fill(Color.secondary.opacity(0.35))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)

                Text("Comments")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding(.bottom, 6)

                Divider()
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Divider()

                HStack(alignment: .bottom, spacing: 10) {
                    TextField("Add a comment…", text: $newCommentText, axis: .vertical)
                        .focused($isComposerFocused)
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(false)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                        .lineLimit(1...5)

                    Button {
                        let text = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        Task {
                            await viewModel.addComment(content: text)
                            newCommentText = ""
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(
                                newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isPosting
                                    ? .secondary
                                    : Color.brandPrimary
                            )
                    }
                    .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isPosting)
                    .accessibilityLabel("Post comment")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .background(Color(.systemBackground))
        }
        .task {
            await viewModel.fetchComments()
        }
        .onChange(of: viewModel.error) { _, newValue in
            showErrorAlert = (newValue != nil)
        }
        .alert("Comments", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error ?? "Something went wrong.")
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    let canDelete: Bool
    let onDelete: () -> Void
    
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
                        .lineLimit(1)
                }
                
                Text(comment.content)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .contextMenu {
            if canDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    
    func timeAgoDisplay(date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

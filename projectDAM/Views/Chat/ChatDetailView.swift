//
//  ChatDetailView.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import SwiftUI

struct ChatDetailView: View {
    let otherUserId: String
    let otherUserName: String
    let otherUserProfileImage: String?
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""  // Local state for text field
    @FocusState private var isInputFocused: Bool
    // Need to know current user ID to determine alignment.
    // Usually stored in AppState or SessionManager.
    // For now hardcoding or assuming ViewModel handles it?
    // ViewModel doesn't know "current user" implicitly unless we check Keychain/UserDefaults.
    let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""

    init(otherUserId: String, otherUserName: String, otherUserProfileImage: String?) {
        self.otherUserId = otherUserId
        self.otherUserName = otherUserName
        self.otherUserProfileImage = otherUserProfileImage
        print("🔵 [ChatDetailView] INIT - otherUserId: \(otherUserId), otherUserName: \(otherUserName)")
    }

    var body: some View {
        print("🔵 [ChatDetailView] BODY CALLED - otherUserId: \(otherUserId)")
        return ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.appSurface)
                        .overlay(Divider(), alignment: .bottom)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.messages.isEmpty && viewModel.errorMessage == nil {
                    VStack(spacing: 10) {
                        Spacer()
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("No messages yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(
                                        message: message,
                                        isCurrentUser: message.senderId == currentUserId
                                    )
                                    .id(message.id)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: viewModel.messages) { _ in
                            if let last = viewModel.messages.last {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: isInputFocused) { _, focused in
                            guard focused, let last = viewModel.messages.last else { return }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            inputBar
        }
        .navigationTitle(otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .appForceNavigationTitle(otherUserName, displayMode: .never)
        .hideTabBar(true)  // Hide custom tab bar using PreferenceKey
        .onAppear {
            print("🟡 [ChatDetailView] ON APPEAR - otherUserId: \(otherUserId)")
            Task {
                await viewModel.fetchHistory(userId: otherUserId)
            }
        }
        .onDisappear {
            print("🔴 [ChatDetailView] ON DISAPPEAR - otherUserId: \(otherUserId)")
        }
    }

    private var inputBar: some View {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(spacing: 0) {
            Divider()
                .background(Color.appDivider)

            HStack(spacing: 10) {
                TextField("Message…", text: $messageText, axis: .vertical)
                    .focused($isInputFocused)
                    .font(.body)
                    .lineLimit(1...5)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.appChatInputFieldBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )

                Button {
                    guard !trimmed.isEmpty else { return }
                    let textToSend = trimmed
                    messageText = ""
                    viewModel.sendMessageWithText(receiverId: otherUserId, text: textToSend)
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(trimmed.isEmpty ? .secondary : Color.brandPrimary)
                        .padding(10)
                        .contentShape(Rectangle())
                }
                .disabled(trimmed.isEmpty)
                .accessibilityLabel("Send")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.appChatInputBarBackground)
        }
    }
}

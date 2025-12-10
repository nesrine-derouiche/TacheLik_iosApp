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
    // Need to know current user ID to determine alignment.
    // Usually stored in AppState or SessionManager.
    // For now hardcoding or assuming ViewModel handles it?
    // ViewModel doesn't know "current user" implicitly unless we check Keychain/UserDefaults.
    let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""

    var body: some View {
        VStack {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else if viewModel.messages.isEmpty && viewModel.errorMessage == nil {
                VStack {
                    Spacer()
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No messages yet")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(
                                    message: message,
                                    isCurrentUser: message.senderId == currentUserId
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .onChange(of: viewModel.messages) { _ in
                        if let last = viewModel.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            HStack {
                TextField("Message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)

                Button(action: {
                    guard !messageText.isEmpty else { return }
                    let textToSend = messageText
                    messageText = ""  // Clear local state
                    viewModel.sendMessageWithText(receiverId: otherUserId, text: textToSend)
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
                .disabled(messageText.isEmpty)
                .padding(.trailing, 8)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
        }
        .navigationTitle(otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar(true)  // Hide custom tab bar using PreferenceKey
        .onAppear {
            Task {
                await viewModel.fetchHistory(userId: otherUserId)
            }
        }
    }
}

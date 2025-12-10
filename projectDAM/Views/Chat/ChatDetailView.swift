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

    init(otherUserId: String, otherUserName: String, otherUserProfileImage: String?) {
        self.otherUserId = otherUserId
        self.otherUserName = otherUserName
        self.otherUserProfileImage = otherUserProfileImage
        print("🔵 [ChatDetailView] INIT - otherUserId: \(otherUserId), otherUserName: \(otherUserName)")
    }

    var body: some View {
        print("🔵 [ChatDetailView] BODY CALLED - otherUserId: \(otherUserId)")
        return VStack {
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
                    print("🟢 [ChatDetailView] SEND BUTTON TAPPED - messageText: '\(messageText)'")
                    guard !messageText.isEmpty else {
                        print("🔴 [ChatDetailView] Message is empty, not sending")
                        return
                    }
                    let textToSend = messageText
                    print("🟢 [ChatDetailView] Clearing messageText and calling sendMessageWithText")
                    messageText = ""  // Clear local state
                    viewModel.sendMessageWithText(receiverId: otherUserId, text: textToSend)
                    print("🟢 [ChatDetailView] sendMessageWithText completed")
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
            print("🟡 [ChatDetailView] ON APPEAR - otherUserId: \(otherUserId)")
            Task {
                await viewModel.fetchHistory(userId: otherUserId)
            }
        }
        .onDisappear {
            print("🔴 [ChatDetailView] ON DISAPPEAR - otherUserId: \(otherUserId)")
        }
    }
}

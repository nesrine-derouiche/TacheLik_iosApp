//
//  ChatListView.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import SwiftUI

struct ChatListView: View {
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        List(viewModel.conversations, id: \.conversationPartnerId) { message in
            let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
            let otherId = message.senderId == currentUserId ? message.receiverId : message.senderId
            
            // Use partner data if available, otherwise fallback
            let otherName = message.partner?.displayName ?? "User \(otherId.prefix(4))"
            let otherImage = message.partner?.image

            NavigationLink(
                destination: ChatDetailView(
                    otherUserId: otherId,
                    otherUserName: otherName,
                    otherUserProfileImage: otherImage
                )
            ) {
                HStack {
                    // Profile Image
                    if let base64String = otherImage,
                       let imageData = Data(base64Encoded: base64String),
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(otherName)
                            .font(.headline)
                        
                        HStack {
                            if message.senderId == currentUserId {
                                Text("You:")
                                    .fontWeight(.medium)
                            }
                            Text(message.content)
                                .lineLimit(1)
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Messages")
        .onAppear {
            Task {
                await viewModel.fetchConversations()
            }
        }
    }
}

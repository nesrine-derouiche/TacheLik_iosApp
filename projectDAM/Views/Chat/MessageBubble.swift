//
//  MessageBubble.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser {
                Spacer()
            } else {
                // Sender Avatar
                if let base64String = message.sender?.image,
                   let imageData = Data(base64Encoded: base64String),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.gray)
                }
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser, let name = message.sender?.displayName {
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                }

                Text(message.content)
                    .padding()
                    .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.15))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(16)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

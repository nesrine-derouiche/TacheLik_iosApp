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

    private static let displayTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static let editedThreshold: TimeInterval = 2

    private var sentTimeText: String {
        guard let date = message.createdAtDate else { return "—" }
        return Self.displayTimeFormatter.string(from: date)
    }

    private var editedTimeText: String? {
        guard let created = message.createdAtDate,
              let updated = message.updatedAtDate
        else {
            return nil
        }

        guard abs(updated.timeIntervalSince(created)) >= Self.editedThreshold else {
            return nil
        }

        return Self.displayTimeFormatter.string(from: updated)
    }

    private var metadataText: String {
        if let edited = editedTimeText {
            return "\(sentTimeText) · Edited \(edited)"
        }
        return sentTimeText
    }
    
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
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser, let name = message.sender?.displayName {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }

                Text(message.content)
                    .font(.body)
                    .foregroundStyle(isCurrentUser ? Color.white : Color.primary)
                    .textSelection(.enabled)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isCurrentUser ? Color.appChatOutgoingBubble : Color.appChatIncomingBubble)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.appBorder.opacity(isCurrentUser ? 0.0 : 1.0), lineWidth: 1)
                    )
                    .frame(maxWidth: 320, alignment: isCurrentUser ? .trailing : .leading)

                HStack(spacing: 6) {
                    Text(metadataText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if isCurrentUser {
                        Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark")
                            .font(.caption2)
                            .foregroundStyle(message.isRead ? Color.brandPrimary : .secondary)
                            .accessibilityLabel(message.isRead ? "Read" : "Sent")
                    }
                }
                .padding(.horizontal, 4)
                .frame(maxWidth: 320, alignment: isCurrentUser ? .trailing : .leading)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

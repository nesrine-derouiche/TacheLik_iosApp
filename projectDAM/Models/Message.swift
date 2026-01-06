//
//  Message.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import Foundation

struct Message: Codable, Identifiable, Equatable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let senderRole: SenderRole
    let isRead: Bool
    let createdAt: String  // ISO 8601 string
    let updatedAt: String?
    
    // Enriched fields
    let partner: ChatUser?
    let sender: ChatUser?
    let receiver: ChatUser?

    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case content
        case senderRole = "sender_role"
        case isRead = "is_read"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case partner
        case sender
        case receiver
    }
    
    // Memberwise initializer for creating messages locally (e.g., optimistic UI)
    init(
        id: String,
        senderId: String,
        receiverId: String,
        content: String,
        senderRole: SenderRole,
        isRead: Bool,
        createdAt: String,
        updatedAt: String?,
        partner: ChatUser?,
        sender: ChatUser?,
        receiver: ChatUser?
    ) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.content = content
        self.senderRole = senderRole
        self.isRead = isRead
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.partner = partner
        self.sender = sender
        self.receiver = receiver
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        senderId = try container.decode(String.self, forKey: .senderId)
        receiverId = try container.decode(String.self, forKey: .receiverId)
        content = try container.decode(String.self, forKey: .content)
        senderRole = try container.decode(SenderRole.self, forKey: .senderRole)

        // Handle isRead as Bool or Int
        if let boolValue = try? container.decode(Bool.self, forKey: .isRead) {
            isRead = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isRead) {
            isRead = intValue != 0
        } else {
            isRead = false
        }

        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        
        partner = try container.decodeIfPresent(ChatUser.self, forKey: .partner)
        sender = try container.decodeIfPresent(ChatUser.self, forKey: .sender)
        receiver = try container.decodeIfPresent(ChatUser.self, forKey: .receiver)
    }

    // Stable identifier for conversation list
    // Uses partner ID if available (standard for conversations endpoint), 
    // otherwise constructs a somewhat stable key from sender/receiver but partner is preferred.
    var conversationPartnerId: String {
        return partner?.id ?? (senderId < receiverId ? "\(senderId)-\(receiverId)" : "\(receiverId)-\(senderId)")
    }

    var createdAtDate: Date? {
        Self.parseServerTimestamp(createdAt)
    }

    var updatedAtDate: Date? {
        guard let updatedAt, !updatedAt.isEmpty else { return nil }
        return Self.parseServerTimestamp(updatedAt)
    }

    static func parseServerTimestamp(_ value: String?) -> Date? {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty
        else {
            return nil
        }

        // 1) ISO-8601 (with/without fractional seconds, with Z / timezone)
        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFractional.date(from: raw) {
            return date
        }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: raw) {
            return date
        }

        // 2) Server timestamps like: 2026-01-06 13:52:36.926166
        // Assume UTC if no explicit timezone is present.
        let patterns = [
            "yyyy-MM-dd HH:mm:ss.SSSSSS",
            "yyyy-MM-dd HH:mm:ss.SSS",
            "yyyy-MM-dd HH:mm:ss"
        ]

        for pattern in patterns {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = pattern
            if let date = formatter.date(from: raw) {
                return date
            }
        }

        return nil
    }
}

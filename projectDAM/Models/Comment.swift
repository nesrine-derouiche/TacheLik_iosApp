//
//  Comment.swift
//  projectDAM
//
//  Created by Antigravity on 12/07/2025.
//

import Foundation

struct Comment: Codable, Identifiable, Equatable {
    let id: String
    let content: String
    let createdAt: String // Backend sends ISO string
    let user: CommentUser
    
    struct CommentUser: Codable, Equatable {
        let id: String
        let username: String
        let image: String? // Base64 string or URL
    }
    
    // Helper to get Date
    var createdDate: Date? {
        let formatter = ISO8601DateFormatter()
        // Handle fractional seconds if present in backend (backend uses TypeORM/postgres, typically usually ISO)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: createdAt) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: createdAt)
    }
}

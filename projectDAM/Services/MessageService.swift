//
//  MessageService.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import Combine
import Foundation

protocol MessageServiceProtocol {
    func getConversations() async throws -> [Message]
    func getHistory(userId: String, page: Int, limit: Int) async throws -> [Message]
    func sendMessage(receiverId: String, content: String, role: SenderRole?) async throws -> Message
}

final class MessageService: MessageServiceProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    func getConversations() async throws -> [Message] {
        return try await networkService.request(
            endpoint: "/messages/conversations", method: .GET, body: nil, headers: getAuthHeaders())
    }

    func getHistory(userId: String, page: Int = 1, limit: Int = 50) async throws -> [Message] {
        return try await networkService.request(
            endpoint: "/messages/history/\(userId)?page=\(page)&limit=\(limit)", method: .GET,
            body: nil, headers: getAuthHeaders())
    }

    func sendMessage(receiverId: String, content: String, role: SenderRole? = nil) async throws
        -> Message
    {
        struct SendMessageBody: Encodable {
            let receiverId: String
            let content: String
            let senderRole: String?
        }

        let body = SendMessageBody(
            receiverId: receiverId, content: content, senderRole: role?.rawValue)
        let bodyData = try JSONEncoder().encode(body)

        return try await networkService.request(
            endpoint: "/messages/send", method: .POST, body: bodyData, headers: getAuthHeaders())
    }

    private func getAuthHeaders() -> [String: String]? {
        guard let token = UserDefaults.standard.string(forKey: "authToken") else { return nil }
        return ["Authorization": "Bearer \(token)"]
    }
}

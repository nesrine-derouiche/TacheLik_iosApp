//
//  ChatViewModel.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import Combine
import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [Message] = []
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var newMessageText = ""

    private let messageService: MessageServiceProtocol
    private let socketService: SocketServiceProtocol
    private var subscribers = Set<AnyCancellable>()

    init(
        messageService: MessageServiceProtocol = MessageService(),
        socketService: SocketServiceProtocol = DIContainer.shared.socketService
    ) {
        self.messageService = messageService
        self.socketService = socketService

        setupSocketListeners()

        // Ensure socket is connected and authenticated
        if !socketService.isConnected {
            socketService.connect()
        }

        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            if !socketService.isAuthenticated {
                socketService.authenticate(token: token)
            }
        } else {
            print("⚠️ [ChatViewModel] No access token found in UserDefaults")
        }
    }

    func setupSocketListeners() {
        // Listen for incoming messages
        NotificationCenter.default.publisher(for: .socketMessageReceived)
            .compactMap { $0.userInfo?["message"] as? Message }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleIncomingMessage(message)
            }
            .store(in: &subscribers)

        // Listen for sent message confirmations
        NotificationCenter.default.publisher(for: .socketMessageSent)
            .compactMap { $0.userInfo?["message"] as? Message }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleIncomingMessage(message)
            }
            .store(in: &subscribers)
    }

    func handleIncomingMessage(_ message: Message) {
        // Add to current chat history if applicable
        messages.append(message)

        // Update conversations list (move to top or add)
        if let index = conversations.firstIndex(where: {
            $0.senderId == message.senderId || $0.receiverId == message.senderId
        }) {
            conversations[index] = message
        } else {
            conversations.insert(message, at: 0)
        }
    }

    func fetchConversations() async {
        isLoading = true
        do {
            conversations = try await messageService.getConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func fetchHistory(userId: String) async {
        isLoading = true
        errorMessage = nil  // Clear previous errors
        print("🔍 [ChatViewModel] Fetching history for user: \(userId)")
        do {
            messages = try await messageService.getHistory(userId: userId, page: 1, limit: 50)
            print("✅ [ChatViewModel] Fetched \(messages.count) messages")
            if messages.isEmpty {
                print("⚠️ [ChatViewModel] Warning: Message list is empty")
            }
        } catch {
            print("❌ [ChatViewModel] Error fetching history: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func sendMessage(receiverId: String, role: SenderRole? = nil) {
        guard !newMessageText.isEmpty else { return }

        let sentMessageContent = newMessageText
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
        newMessageText = ""  // Clear input

        // Optimistic UI update - immediately add message to list
        let optimisticMessage = Message(
            id: UUID().uuidString,
            senderId: currentUserId,
            receiverId: receiverId,
            content: sentMessageContent,
            senderRole: role ?? .user,
            isRead: false,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: nil,
            partner: nil,
            sender: nil,
            receiver: nil
        )
        
        messages.append(optimisticMessage)

        // Send via socket
        socketService.sendMessage(receiverId: receiverId, content: sentMessageContent, role: role)
        
        print("✅ [ChatViewModel] Message sent optimistically and via socket to \(receiverId)")
    }
    
    // New method that accepts text directly to avoid state binding issues
    func sendMessageWithText(receiverId: String, text: String, role: SenderRole? = nil) {
        guard !text.isEmpty else { return }
        
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
        
        // Optimistic UI update - immediately add message to list
        let optimisticMessage = Message(
            id: UUID().uuidString,
            senderId: currentUserId,
            receiverId: receiverId,
            content: text,
            senderRole: role ?? .user,
            isRead: false,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: nil,
            partner: nil,
            sender: nil,
            receiver: nil
        )
        
        messages.append(optimisticMessage)

        // Send via socket
        socketService.sendMessage(receiverId: receiverId, content: text, role: role)
        
        print("✅ [ChatViewModel] Message sent optimistically and via socket to \(receiverId)")
    }
}

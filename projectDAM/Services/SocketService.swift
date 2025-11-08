//
//  SocketService.swift
//  projectDAM
//
//  Created on 11/8/2025.
//

import Foundation
import Combine
import UIKit
import SocketIO

// MARK: - Socket Service Protocol
protocol SocketServiceProtocol {
    var connectionState: Published<SocketConnectionState>.Publisher { get }
    var isConnected: Bool { get }
    var isAuthenticated: Bool { get }
    
    func connect()
    func disconnect()
    func authenticate(token: String)
    func sendHeartbeat()
    func refreshToken(_ newToken: String)
}

// MARK: - Socket Service Implementation
final class SocketService: SocketServiceProtocol {
    
    // MARK: - Properties
    private let manager: SocketManager
    private let socket: SocketIOClient
    private let configuration: SocketConfiguration
    
    @Published private(set) var connectionStateValue: SocketConnectionState = .disconnected
    var connectionState: Published<SocketConnectionState>.Publisher { $connectionStateValue }
    
    private var heartbeatTimer: Timer?
    private var authToken: String?
    private var cancellables = Set<AnyCancellable>()
    
    var isConnected: Bool {
        connectionStateValue.isConnected
    }
    
    var isAuthenticated: Bool {
        if case .authenticated = connectionStateValue {
            return true
        }
        return false
    }
    
    // MARK: - Initialization
    init(configuration: SocketConfiguration = .default) {
        self.configuration = configuration
        
        // Configure Socket.IO manager
        let config: SocketIOClientConfiguration = [
            .log(configuration.enableLogging),
            .compress,
            .reconnects(true),
            .reconnectAttempts(configuration.reconnectAttempts),
            .reconnectWait(configuration.reconnectWait),
            .forcePolling(false),
            .forceWebsockets(false), // Let it negotiate transport
            .secure(false), // HTTP not HTTPS
            .selfSigned(false)
        ]
        
        guard let url = URL(string: configuration.url) else {
            fatalError("Invalid socket URL: \(configuration.url)")
        }
        
        self.manager = SocketManager(socketURL: url, config: config)
        self.socket = manager.defaultSocket
        
        setupEventHandlers()
    }
    
    deinit {
        disconnect()
        heartbeatTimer?.invalidate()
    }
    
    // MARK: - Connection Management
    
    func connect() {
        guard !socket.status.active else {
            print("⚠️ Socket already connected")
            return
        }
        
        print("🔌 Connecting to socket server...")
        connectionStateValue = .connecting
        socket.connect()
    }
    
    func disconnect() {
        print("🔌 Disconnecting from socket server...")
        stopHeartbeat()
        authToken = nil
        socket.disconnect()
        connectionStateValue = .disconnected
    }
    
    func authenticate(token: String) {
        guard socket.status.active else {
            print("⚠️ Cannot authenticate: Socket not connected")
            connectionStateValue = .failed(SocketError.notConnected)
            return
        }
        
        print("🔐 Authenticating with token...")
        authToken = token
        
        // Get device fingerprint (simplified version)
        let fingerprint = getDeviceFingerprint()
        
        let authData: [String: Any] = [
            "token": token,
            "browserFingerprint": fingerprint
        ]
        
        socket.emit(SocketEvents.authenticate, authData)
    }
    
    func sendHeartbeat() {
        guard isAuthenticated else {
            print("⚠️ Cannot send heartbeat: Not authenticated")
            return
        }
        
        socket.emit(SocketEvents.heartbeat)
    }
    
    func refreshToken(_ newToken: String) {
        guard isAuthenticated else {
            print("⚠️ Cannot refresh token: Not authenticated")
            return
        }
        
        print("🔄 Refreshing token...")
        authToken = newToken
        socket.emit(SocketEvents.refreshToken, newToken)
    }
    
    // MARK: - Event Handlers Setup
    
    private func setupEventHandlers() {
        // Connection events
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            self?.handleConnect()
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            self?.handleDisconnect(data: data)
        }
        
        socket.on(clientEvent: .error) { [weak self] data, ack in
            self?.handleError(data: data)
        }
        
        socket.on(clientEvent: .reconnect) { [weak self] data, ack in
            self?.handleReconnect(data: data)
        }
        
        socket.on(clientEvent: .reconnectAttempt) { [weak self] data, ack in
            self?.handleReconnectAttempt(data: data)
        }
        
        // Authentication events
        socket.on(SocketEvents.authenticationSuccess) { [weak self] data, ack in
            self?.handleAuthenticationSuccess(data: data)
        }
        
        socket.on(SocketEvents.sessionTerminated) { [weak self] data, ack in
            self?.handleSessionTerminated(data: data)
        }
        
        // Token events
        socket.on(SocketEvents.tokenRefreshSuccess) { [weak self] data, ack in
            self?.handleTokenRefreshSuccess(data: data)
        }
        
        socket.on(SocketEvents.tokenExpirationWarning) { [weak self] data, ack in
            self?.handleTokenExpirationWarning(data: data)
        }
        
        // Heartbeat events
        socket.on(SocketEvents.heartbeatAck) { [weak self] data, ack in
            self?.handleHeartbeatAck(data: data)
        }
        
        socket.on(SocketEvents.pong) { [weak self] data, ack in
            self?.handlePong(data: data)
        }
        
        // User events
        socket.on(SocketEvents.userConnected) { [weak self] data, ack in
            self?.handleUserConnected(data: data)
        }
        
        socket.on(SocketEvents.userDisconnected) { [weak self] data, ack in
            self?.handleUserDisconnected(data: data)
        }
    }
    
    // MARK: - Connection Event Handlers
    
    private func handleConnect() {
        print("✅ Socket connected")
        connectionStateValue = .connected
        
        // Auto-authenticate if we have a token
        if let token = authToken {
            authenticate(token: token)
        }
    }
    
    private func handleDisconnect(data: [Any]) {
        print("❌ Socket disconnected: \(data)")
        stopHeartbeat()
        connectionStateValue = .disconnected
    }
    
    private func handleError(data: [Any]) {
        print("❌ Socket error: \(data)")
        let errorMessage = data.first as? String ?? "Unknown error"
        connectionStateValue = .failed(SocketError.connectionFailed(errorMessage))
    }
    
    private func handleReconnect(data: [Any]) {
        print("🔄 Socket reconnected")
        connectionStateValue = .connected
        
        // Re-authenticate after reconnection
        if let token = authToken {
            authenticate(token: token)
        }
    }
    
    private func handleReconnectAttempt(data: [Any]) {
        print("🔄 Socket reconnecting...")
        connectionStateValue = .reconnecting
    }
    
    // MARK: - Authentication Event Handlers
    
    private func handleAuthenticationSuccess(data: [Any]) {
        print("✅ Authentication successful")
        connectionStateValue = .authenticated
        startHeartbeat()
        
        // Parse user data if available
        if let jsonData = data.first as? [String: Any],
           let userData = try? JSONSerialization.data(withJSONObject: jsonData),
           let authSuccess = try? JSONDecoder().decode(AuthenticationSuccessData.self, from: userData) {
            print("👤 Authenticated as: \(authSuccess.user.username)")
        }
    }
    
    private func handleSessionTerminated(data: [Any]) {
        let reason = data.first as? String ?? "Unknown reason"
        print("⚠️ Session terminated: \(reason)")
        
        stopHeartbeat()
        authToken = nil
        connectionStateValue = .failed(SocketError.sessionTerminated(reason))
        
        // Post notification for UI to handle
        NotificationCenter.default.post(
            name: .socketSessionTerminated,
            object: nil,
            userInfo: ["reason": reason]
        )
    }
    
    // MARK: - Token Event Handlers
    
    private func handleTokenRefreshSuccess(data: [Any]) {
        print("✅ Token refresh successful")
        
        if let jsonData = data.first as? [String: Any],
           let userData = try? JSONSerialization.data(withJSONObject: jsonData),
           let refreshData = try? JSONDecoder().decode(TokenRefreshSuccessData.self, from: userData) {
            print("🔄 \(refreshData.message)")
        }
    }
    
    private func handleTokenExpirationWarning(data: [Any]) {
        if let jsonData = data.first as? [String: Any],
           let userData = try? JSONSerialization.data(withJSONObject: jsonData),
           let warningData = try? JSONDecoder().decode(TokenExpirationWarningData.self, from: userData) {
            print("⚠️ Token expiring in \(warningData.secondsRemaining) seconds")
            
            // Post notification for UI to handle token refresh
            NotificationCenter.default.post(
                name: .socketTokenExpiring,
                object: nil,
                userInfo: [
                    "secondsRemaining": warningData.secondsRemaining,
                    "expiresAt": warningData.expiresAt
                ]
            )
        }
    }
    
    // MARK: - Heartbeat Event Handlers
    
    private func handleHeartbeatAck(data: [Any]) {
        // Heartbeat acknowledged - connection is healthy
        if AppConfig.enableLogging {
            print("💓 Heartbeat acknowledged")
        }
    }
    
    private func handlePong(data: [Any]) {
        if AppConfig.enableLogging {
            print("🏓 Pong received")
        }
    }
    
    // MARK: - User Event Handlers
    
    private func handleUserConnected(data: [Any]) {
        if let jsonData = data.first as? [String: Any],
           let userData = try? JSONSerialization.data(withJSONObject: jsonData),
           let user = try? JSONDecoder().decode(SocketUser.self, from: userData) {
            print("👤 User connected: \(user.username)")
            
            NotificationCenter.default.post(
                name: .socketUserConnected,
                object: nil,
                userInfo: ["user": user]
            )
        }
    }
    
    private func handleUserDisconnected(data: [Any]) {
        if let userId = data.first as? String {
            print("👤 User disconnected: \(userId)")
            
            NotificationCenter.default.post(
                name: .socketUserDisconnected,
                object: nil,
                userInfo: ["userId": userId]
            )
        }
    }
    
    // MARK: - Heartbeat Management
    
    private func startHeartbeat() {
        stopHeartbeat() // Clear any existing timer
        
        heartbeatTimer = Timer.scheduledTimer(
            withTimeInterval: configuration.heartbeatInterval,
            repeats: true
        ) { [weak self] _ in
            self?.sendHeartbeat()
        }
        
        print("💓 Heartbeat started (interval: \(configuration.heartbeatInterval)s)")
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        print("💓 Heartbeat stopped")
    }
    
    // MARK: - Utility Methods
    
    private func getDeviceFingerprint() -> String {
        // Create a unique fingerprint for this device
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let model = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        
        return "\(deviceId)-\(model)-\(systemVersion)"
    }
    
    // MARK: - Custom Event Emission
    
    func emit(_ event: String, _ items: SocketData...) {
        socket.emit(event, items)
    }
    
    func emitWithAck(_ event: String, _ items: SocketData...) -> OnAckCallback {
        return socket.emitWithAck(event, items)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let socketSessionTerminated = Notification.Name("socketSessionTerminated")
    static let socketTokenExpiring = Notification.Name("socketTokenExpiring")
    static let socketUserConnected = Notification.Name("socketUserConnected")
    static let socketUserDisconnected = Notification.Name("socketUserDisconnected")
}

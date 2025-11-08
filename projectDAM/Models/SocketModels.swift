//
//  SocketModels.swift
//  projectDAM
//
//  Created on 11/8/2025.
//

import Foundation

// MARK: - Socket Events
struct SocketEvents {
    // Client to Server
    static let authenticate = "authenticate"
    static let heartbeat = "heartbeat"
    static let ping = "ping"
    static let refreshToken = "refreshToken"
    static let message = "message"
    static let updateStatus = "updateStatus"
    
    // Server to Client
    static let sessionTerminated = "sessionTerminated"
    static let userConnected = "userConnected"
    static let userDisconnected = "userDisconnected"
    static let heartbeatAck = "heartbeatAck"
    static let pong = "pong"
    static let authenticationSuccess = "authenticationSuccess"
    static let tokenRefreshSuccess = "tokenRefreshSuccess"
    static let tokenExpirationWarning = "tokenExpirationWarning"
    static let heartbeatError = "heartbeatError"
    static let heartbeatReminder = "heartbeatReminder"
    
    // System Events
    static let connection = "connection"
    static let disconnect = "disconnect"
    static let error = "error"
}

// MARK: - Socket Event Data Models

struct AuthenticationData: Codable {
    let token: String
    let browserFingerprint: String?
    
    init(token: String, browserFingerprint: String? = nil) {
        self.token = token
        self.browserFingerprint = browserFingerprint
    }
}

struct AuthenticationSuccessData: Codable {
    let user: SocketUser
    let timestamp: String
}

struct SocketUser: Codable {
    let id: String
    let username: String
    let email: String
}

struct TokenExpirationWarningData: Codable {
    let message: String
    let secondsRemaining: Int
    let expiresAt: String
    let timestamp: String
}

struct TokenRefreshSuccessData: Codable {
    let message: String
    let timestamp: String
}

struct HeartbeatAckData: Codable {
    let timestamp: String
}

struct PongData: Codable {
    let timestamp: String
}

// MARK: - Socket Connection State
enum SocketConnectionState {
    case disconnected
    case connecting
    case connected
    case authenticated
    case reconnecting
    case failed(Error)
    
    var description: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .authenticated:
            return "Authenticated"
        case .reconnecting:
            return "Reconnecting"
        case .failed(let error):
            return "Failed: \(error.localizedDescription)"
        }
    }
    
    var isConnected: Bool {
        switch self {
        case .connected, .authenticated:
            return true
        default:
            return false
        }
    }
}

// MARK: - Socket Error
enum SocketError: Error, LocalizedError {
    case notConnected
    case notAuthenticated
    case authenticationFailed(String)
    case connectionFailed(String)
    case invalidToken
    case sessionTerminated(String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Socket is not connected"
        case .notAuthenticated:
            return "Socket is not authenticated"
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .invalidToken:
            return "Invalid authentication token"
        case .sessionTerminated(let reason):
            return "Session terminated: \(reason)"
        }
    }
}

// MARK: - Socket Configuration
struct SocketConfiguration {
    let url: String
    let enableLogging: Bool
    let reconnectAttempts: Int
    let reconnectWait: Int // in seconds
    let heartbeatInterval: TimeInterval
    let connectionTimeout: TimeInterval
    
    static let `default` = SocketConfiguration(
        url: "http://127.0.0.1:3001",
        enableLogging: true,
        reconnectAttempts: 5,
        reconnectWait: 2,
        heartbeatInterval: 30,
        connectionTimeout: 10
    )
}

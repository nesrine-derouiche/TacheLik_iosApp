//
//  SessionManager.swift
//  projectDAM
//
//  Created on 11/8/2025.
//

import Foundation
import SwiftUI
import Combine

/// Manages user session state and socket reconnection
@MainActor
final class SessionManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var showSessionAlert = false
    @Published var sessionTerminationReason = ""
    @Published var isSessionTerminated = false
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let socketService: SocketServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        authService: AuthServiceProtocol = DIContainer.shared.authService,
        socketService: SocketServiceProtocol = DIContainer.shared.socketService
    ) {
        self.authService = authService
        self.socketService = socketService
        
        setupSocketStateObserver()
    }
    
    // MARK: - Public Methods
    
    /// Reconnect socket if user is logged in and didn't manually logout
    func reconnectIfNeeded() {
        // Check if user should auto-login
        guard authService.shouldAutoLogin() else {
            print("⚠️ User manually logged out or no valid session, skipping auto-reconnect")
            return
        }
        
        Task {
            do {
                // Refresh user data from API to get latest info
                print("🔄 Refreshing user data from API...")
                try await authService.refreshUserData()
                
                // Check if socket is already connected
                guard !socketService.isConnected else {
                    print("✅ Socket already connected")
                    return
                }
                
                // Get auth token
                guard let token = authService.getAuthToken() else {
                    print("⚠️ No auth token available for reconnection")
                    return
                }
                
                print("🔄 Auto-reconnecting socket...")
                socketService.connect()
                
                // Wait for connection, then authenticate
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                if socketService.isConnected {
                    socketService.authenticate(token: token)
                    print("✅ Socket auto-reconnected and authenticated")
                } else {
                    print("⚠️ Socket connection failed during auto-reconnect")
                }
            } catch {
                print("❌ Failed to refresh user data: \(error.localizedDescription)")
                // Continue with cached user data
            }
        }
    }
    
    /// Handle session termination from socket
    func terminateSession(reason: String) {
        Task { @MainActor in
            print("🚨 Session terminated: \(reason)")
            self.sessionTerminationReason = reason
            self.isSessionTerminated = true
            self.showSessionAlert = true
            
            // Disconnect socket
            self.socketService.disconnect()
            
            print("✅ Alert should be shown now")
        }
    }
    
    /// Handle session termination confirmation
    func handleSessionTermination() {
        Task {
            do {
                // Logout user
                try await authService.logout()
                
                // Disconnect socket
                socketService.disconnect()
                
                // Reset state
                isSessionTerminated = false
                sessionTerminationReason = ""
                
                print("✅ User logged out after session termination")
            } catch {
                print("❌ Error during logout: \(error.localizedDescription)")
            }
        }
    }
    
    /// Logout user and disconnect socket
    func logout() {
        Task {
            do {
                // Logout from auth service
                try await authService.logout()
                
                // Disconnect socket
                socketService.disconnect()
                
                print("✅ User logged out successfully")
            } catch {
                print("❌ Error during logout: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSocketStateObserver() {
        // Monitor socket connection state
        socketService.connectionState
            .sink { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .authenticated:
                    print("✅ Socket authenticated")
                    self.isSessionTerminated = false
                    
                case .failed(let error):
                    print("❌ Socket failed: \(error.localizedDescription)")
                    
                case .disconnected:
                    print("🔌 Socket disconnected")
                    
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
}

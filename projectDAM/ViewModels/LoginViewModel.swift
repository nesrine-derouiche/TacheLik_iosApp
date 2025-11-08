//
//  LoginViewModel.swift
//  projectDAM
//
//  Created on 11/7/2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Login View Model
/// Handles authentication logic and state for LoginView
@MainActor
final class LoginViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showPassword: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let socketService: SocketServiceProtocol
    
    // MARK: - Initialization
    init(authService: AuthServiceProtocol, socketService: SocketServiceProtocol = DIContainer.shared.socketService) {
        self.authService = authService
        self.socketService = socketService
    }
    
    // MARK: - Public Methods
    
    /// Validates email format
    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validates password (minimum 6 characters)
    var isPasswordValid: Bool {
        return password.count >= 6
    }
    
    /// Checks if form is valid
    var isFormValid: Bool {
        return isEmailValid && isPasswordValid
    }
    
    /// Login user
    func login() async {
        guard isFormValid else {
            errorMessage = "Please enter valid email and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.login(email: email, password: password)
            isLoggedIn = true
            print("✅ Login successful: \(user.name)")
            
            // Connect to socket and authenticate
            connectSocket()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Login failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Connect to socket server
    private func connectSocket() {
        guard let token = authService.getAuthToken() else {
            print("⚠️ No auth token available for socket connection")
            return
        }
        
        print("🔌 Connecting to socket server...")
        socketService.connect()
        
        // Wait for connection, then authenticate
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Only authenticate if connected
            if socketService.isConnected {
                socketService.authenticate(token: token)
                print("✅ Socket authenticated after login")
            }
        }
    }
    
    /// Register new user
    func register(username: String) async {
        guard isFormValid else {
            errorMessage = "Please enter valid email and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.register(username: username, email: email, password: password)
            isLoggedIn = true
            print("✅ Registration successful: \(user.username)")
            
            // Connect to socket and authenticate
            connectSocket()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Registration failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Toggle password visibility
    func togglePasswordVisibility() {
        showPassword.toggle()
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}

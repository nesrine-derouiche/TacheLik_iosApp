//
//  RegisterViewModel.swift
//  projectDAM
//
//  Created on 11/8/2025.
//

import Foundation
import Combine

@MainActor
final class RegisterViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var inviteCode = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var registrationSuccess = false
    @Published var isCheckingInviteLink = false
    @Published var inviteLinkValid = false
    @Published var inviteLinkSpecial = false
    @Published var inviteLinkMessage = ""
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let socketService: SocketServiceProtocol
    
    // MARK: - Initialization
    init(
        authService: AuthServiceProtocol = DIContainer.shared.authService,
        socketService: SocketServiceProtocol = DIContainer.shared.socketService
    ) {
        self.authService = authService
        self.socketService = socketService
    }
    
    // MARK: - Validation
    
    var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        isValidEmail(email) &&
        password.count >= 6
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Public Methods
    
    func checkInviteLink() async {
        guard !inviteCode.isEmpty else {
            inviteLinkValid = false
            inviteLinkSpecial = false
            inviteLinkMessage = ""
            return
        }
        
        guard inviteCode.count == 6 else {
            return // Wait until 6 characters
        }
        
        isCheckingInviteLink = true
        inviteLinkMessage = ""
        
        do {
            let response = try await authService.checkInviteLink(inviteCode)
            
            if response.exists && response.isSpecialInvitation {
                inviteLinkValid = true
                inviteLinkSpecial = true
                inviteLinkMessage = "✓ Special invite! Get a reduction on your first purchase"
            } else if response.exists {
                inviteLinkValid = false
                inviteLinkSpecial = false
                inviteLinkMessage = "This invite code is not special. Only special invites give a reduction."
            } else {
                inviteLinkValid = false
                inviteLinkSpecial = false
                inviteLinkMessage = "Invalid invite code"
            }
        } catch {
            inviteLinkValid = false
            inviteLinkSpecial = false
            inviteLinkMessage = "Could not verify invite code"
            print("❌ Failed to check invite link: \(error.localizedDescription)")
        }
        
        isCheckingInviteLink = false
    }
    
    func register() async {
        // Validate form
        guard isFormValid else {
            if username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
                errorMessage = "Please fill in all fields"
            } else if !isValidEmail(email) {
                errorMessage = "Invalid email address"
            } else if password.count < 6 {
                errorMessage = "Password must be at least 6 characters"
            } else if password != confirmPassword {
                errorMessage = "Passwords do not match"
            }
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Register user
            let inviteCodeToSend = inviteCode.isEmpty ? nil : inviteCode
            let user = try await authService.register(
                username: username,
                email: email,
                password: password,
                inviteCode: inviteCodeToSend
            )
            
            print("✅ Registration successful: \(user.username)")
            
            // Connect and authenticate socket
            connectSocket()
            
            // Mark registration as successful
            registrationSuccess = true
            
        } catch let error as NetworkError {
            handleNetworkError(error)
        } catch {
            errorMessage = "Registration failed: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func handleNetworkError(_ error: NetworkError) {
        switch error {
        case .invalidURL:
            errorMessage = "Invalid server URL"
        case .noData:
            errorMessage = "No response from server"
        case .decodingError:
            errorMessage = "Invalid response from server"
        case .serverError(let code, let message):
            // Handle specific error messages from backend
            if let message = message {
                if message.contains("Email already exists") {
                    errorMessage = "This email is already registered"
                } else if message.contains("Invalid email") {
                    errorMessage = "Invalid email address"
                } else {
                    errorMessage = message
                }
            } else {
                errorMessage = "Server error (\(code))"
            }
        case .unauthorized:
            errorMessage = "Unauthorized"
        case .invalidResponse:
            errorMessage = "Invalid response from server"
        }
        showError = true
    }
    
    private func connectSocket() {
        guard let token = authService.getAuthToken() else {
            print("⚠️ No auth token available for socket connection")
            return
        }
        
        print("🔌 Connecting socket after registration...")
        socketService.connect()
        
        // Wait for connection, then authenticate
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Only authenticate if connected
            if socketService.isConnected {
                socketService.authenticate(token: token)
                print("✅ Socket authenticated after registration")
            }
        }
    }
}

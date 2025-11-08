//
//  AuthService.swift
//  projectDAM
//
//  Created on 11/7/2025.
//

import Foundation
import Combine

// MARK: - Auth Service Protocol
protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func register(username: String, email: String, password: String, inviteCode: String?) async throws -> User
    func logout() async throws
    func getCurrentUser() -> User?
    func isAuthenticated() -> Bool
    func getAuthToken() -> String?
    func didUserLogout() -> Bool
    func shouldAutoLogin() -> Bool
    func refreshUserData() async throws
    func requestEmailVerification() async throws
    func checkInviteLink(_ link: String) async throws -> InviteLinkCheckResponse
    func setUserInvitedByLink(userId: String, link: String) async throws
}

// MARK: - Auth Response Models
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let username: String
    let email: String
    let password: String
}

struct AuthResponse: Decodable {
    let message: String
    let token: String
    let success: Bool
}

struct UserResponse: Decodable {
    let user: User
    let success: Bool
}

struct EmailVerificationRequest: Encodable {
    let email: String
    let serverUrl: String
}

struct EmailVerificationResponse: Decodable {
    let message: String
    let success: Bool
}

struct InviteLinkCheckResponse: Decodable {
    let exists: Bool
    let success: Bool
    let isSpecialInvitation: Bool
}

struct SetInvitedByRequest: Encodable {
    let userId: String
    let link: String
}

struct SetInvitedByResponse: Decodable {
    let success: Bool?
    let message: String?
}

// MARK: - JWT Payload
struct JWTPayload: Decodable {
    let id: String
    let email: String
    let role: String
    let iat: Int
    let exp: Int
}

// MARK: - Auth Service Implementation
final class AuthService: AuthServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    private let networkService: NetworkServiceProtocol
    private let tokenKey = "authToken"
    private let logoutFlagKey = "userDidLogout"
    
    @Published private(set) var currentUser: User?
    
    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
        self.loadCurrentUser()
    }
    
    // MARK: - Public Methods
    
    /// Login user
    func login(email: String, password: String) async throws -> User {
        let request = LoginRequest(email: email, password: password)
        let requestData = try JSONEncoder().encode(request)
        
        let response: AuthResponse = try await networkService.request(
            endpoint: "/auth/login",
            method: .POST,
            body: requestData,
            headers: nil
        )
        
        // Decode JWT token to extract user ID
        guard let tokenData = decodeJWTPayload(token: response.token) else {
            throw NetworkError.decodingError
        }
        
        // Fetch full user data from API
        let userResponse: UserResponse = try await networkService.request(
            endpoint: "/user?userId=\(tokenData.id)",
            method: .GET,
            body: nil,
            headers: ["Authorization": "Bearer \(response.token)"]
        )
        
        saveUser(userResponse.user, token: response.token)
        UserDefaults.standard.set(false, forKey: logoutFlagKey) // Clear logout flag on login
        currentUser = userResponse.user
        return userResponse.user
    }
    
    /// Register new user
    func register(username: String, email: String, password: String, inviteCode: String? = nil) async throws -> User {
        // Save invite code locally to use after verification
        if let inviteCode = inviteCode, !inviteCode.isEmpty {
            UserDefaults.standard.set(inviteCode, forKey: "pendingInviteCode")
        }
        
        let request = RegisterRequest(
            username: username,
            email: email,
            password: password
        )
        let requestData = try JSONEncoder().encode(request)
        
        let response: AuthResponse = try await networkService.request(
            endpoint: "/auth/signup",
            method: .POST,
            body: requestData,
            headers: nil
        )
        
        // Decode JWT token to extract user ID
        guard let tokenData = decodeJWTPayload(token: response.token) else {
            throw NetworkError.decodingError
        }
        
        // Fetch full user data from API
        let userResponse: UserResponse = try await networkService.request(
            endpoint: "/user?userId=\(tokenData.id)",
            method: .GET,
            body: nil,
            headers: ["Authorization": "Bearer \(response.token)"]
        )
        
        saveUser(userResponse.user, token: response.token)
        UserDefaults.standard.set(false, forKey: logoutFlagKey) // Clear logout flag on registration
        currentUser = userResponse.user
        return userResponse.user
    }
    
    /// Logout current user
    func logout() async throws {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.set(true, forKey: logoutFlagKey) // Mark that user manually logged out
        currentUser = nil
    }
    
    /// Get current authenticated user
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    /// Check if user is authenticated
    func isAuthenticated() -> Bool {
        return currentUser != nil && getAuthToken() != nil
    }
    
    /// Get authentication token
    func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    /// Check if user manually logged out
    func didUserLogout() -> Bool {
        return UserDefaults.standard.bool(forKey: logoutFlagKey)
    }
    
    /// Check if user should auto-login (has token and didn't manually logout)
    func shouldAutoLogin() -> Bool {
        return !didUserLogout() && getAuthToken() != nil
    }
    
    /// Refresh user data from API
    func refreshUserData() async throws {
        guard let token = getAuthToken() else {
            throw NetworkError.unauthorized
        }
        
        // Decode JWT to get user ID
        guard let tokenData = decodeJWTPayload(token: token) else {
            throw NetworkError.decodingError
        }
        
        // Fetch fresh user data from API
        let userResponse: UserResponse = try await networkService.request(
            endpoint: "/user?userId=\(tokenData.id)",
            method: .GET,
            body: nil,
            headers: ["Authorization": "Bearer \(token)"]
        )
        
        // Update stored user data
        saveUser(userResponse.user, token: token)
        currentUser = userResponse.user
        
        print("✅ User data refreshed: \(userResponse.user.username)")
    }
    
    /// Request email verification
    func requestEmailVerification() async throws {
        guard let user = getCurrentUser() else {
            throw NetworkError.unauthorized
        }
        
        guard let token = getAuthToken() else {
            throw NetworkError.unauthorized
        }
        
        let request = EmailVerificationRequest(
            email: user.email,
            serverUrl: AppConfig.serverURL
        )
        let requestData = try JSONEncoder().encode(request)
        
        let response: EmailVerificationResponse = try await networkService.request(
            endpoint: "/user/request-email-verification",
            method: .POST,
            body: requestData,
            headers: ["Authorization": "Bearer \(token)"]
        )
        
        print("✅ Verification email sent: \(response.message)")
    }
    
    /// Check if invite link is valid and special
    func checkInviteLink(_ link: String) async throws -> InviteLinkCheckResponse {
        let response: InviteLinkCheckResponse = try await networkService.request(
            endpoint: "/user/check-invite-link-special/\(link)",
            method: .GET,
            body: nil,
            headers: nil
        )
        
        print("✅ Invite link checked: exists=\(response.exists), special=\(response.isSpecialInvitation)")
        return response
    }
    
    /// Set user's invited by link after verification
    func setUserInvitedByLink(userId: String, link: String) async throws {
        guard let token = getAuthToken() else {
            throw NetworkError.unauthorized
        }
        
        let request = SetInvitedByRequest(userId: userId, link: link)
        let requestData = try JSONEncoder().encode(request)
        
        do {
            // Try to decode as SetInvitedByResponse
            let response: SetInvitedByResponse = try await networkService.request(
                endpoint: "/user/set-user-invited-by-link",
                method: .PUT,
                body: requestData,
                headers: ["Authorization": "Bearer \(token)"]
            )
            
            print("✅ User invited by link set successfully: \(response.message ?? "success")")
        } catch NetworkError.decodingError {
            // If decoding fails, the request might have succeeded but returned unexpected format
            // Consider it successful if we got here without other errors
            print("⚠️ Invite link set but response format unexpected")
        }
        
        // Clear pending invite code after successful set
        UserDefaults.standard.removeObject(forKey: "pendingInviteCode")
    }
    
    // MARK: - Private Methods
    
    private func saveUser(_ user: User, token: String) {
        // Only save token, not user data
        // User data will always be fetched fresh from API
        UserDefaults.standard.set(token, forKey: tokenKey)
        currentUser = user
    }
    
    private func loadCurrentUser() {
        // Don't load user from UserDefaults
        // User data will be fetched fresh from API on app launch
        currentUser = nil
    }
    
    /// Decode JWT token to extract payload
    private func decodeJWTPayload(token: String) -> JWTPayload? {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }
        
        let payloadSegment = segments[1]
        var base64 = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: base64) else { return nil }
        
        do {
            let payload = try JSONDecoder().decode(JWTPayload.self, from: data)
            return payload
        } catch {
            print("Failed to decode JWT payload: \(error)")
            return nil
        }
    }
}

// MARK: - Mock Auth Service (for testing/development)
final class MockAuthService: AuthServiceProtocol {
    
    private(set) var currentUser: User?
    
    func login(email: String, password: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let user = User(
            id: UUID().uuidString,
            username: "Demo User",
            email: email,
            phone: nil,
            phoneNbVerified: false,
            role: .student,
            creationDate: nil,
            image: nil,
            verified: true,
            banned: false,
            credit: 0,
            isTeacher: false,
            inviteLink: nil,
            invitedBy: nil,
            inviteLinkType: nil,
            haveReduction: false,
            warningTimes: 0,
            lastLoginDate: nil
        )
        currentUser = user
        return user
    }
    
    func register(username: String, email: String, password: String, inviteCode: String? = nil) async throws -> User {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let user = User(
            id: UUID().uuidString,
            username: username,
            email: email,
            phone: nil,
            phoneNbVerified: false,
            role: .student,
            creationDate: nil,
            image: nil,
            verified: true,
            banned: false,
            credit: 0,
            isTeacher: false,
            inviteLink: nil,
            invitedBy: nil,
            inviteLinkType: nil,
            haveReduction: false,
            warningTimes: 0,
            lastLoginDate: nil
        )
        currentUser = user
        return user
    }
    
    func logout() async throws {
        currentUser = nil
    }
    
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    func isAuthenticated() -> Bool {
        return currentUser != nil
    }
    
    func getAuthToken() -> String? {
        return nil
    }
    
    func didUserLogout() -> Bool {
        return false
    }
    
    func shouldAutoLogin() -> Bool {
        return false
    }
    
    func refreshUserData() async throws {
        // Mock implementation - do nothing
        print("🔄 Mock: User data refresh (no-op)")
    }
    
    func requestEmailVerification() async throws {
        // Mock implementation - simulate delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("📧 Mock: Verification email sent")
    }
    
    func checkInviteLink(_ link: String) async throws -> InviteLinkCheckResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        return InviteLinkCheckResponse(exists: true, success: true, isSpecialInvitation: true)
    }
    
    func setUserInvitedByLink(userId: String, link: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        print("📧 Mock: User invited by link set")
    }
}

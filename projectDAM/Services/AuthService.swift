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
    func register(email: String, password: String, name: String) async throws -> User
    func logout() async throws
    func getCurrentUser() -> User?
    func isAuthenticated() -> Bool
    func getAuthToken() -> String?
}

// MARK: - Auth Response Models
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let name: String
}

struct AuthResponse: Decodable {
    let message: String
    let token: String
    let success: Bool
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
final class AuthService: AuthServiceProtocol {
    
    // MARK: - Properties
    private let networkService: NetworkServiceProtocol
    private let userDefaultsKey = "currentUser"
    private let tokenKey = "authToken"
    
    @Published private(set) var currentUser: User?
    
    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
        self.loadCurrentUser()
    }
    
    // MARK: - Public Methods
    
    /// Login user with email and password
    func login(email: String, password: String) async throws -> User {
        let request = LoginRequest(email: email, password: password)
        let requestData = try JSONEncoder().encode(request)
        
        let response: AuthResponse = try await networkService.request(
            endpoint: "/auth/login",
            method: .POST,
            body: requestData,
            headers: nil
        )
        
        // Decode JWT token to extract user information
        guard let user = decodeJWT(token: response.token) else {
            throw NetworkError.decodingError
        }
        
        saveUser(user, token: response.token)
        currentUser = user
        return user
    }
    
    /// Register new user
    func register(email: String, password: String, name: String) async throws -> User {
        let request = RegisterRequest(email: email, password: password, name: name)
        let requestData = try JSONEncoder().encode(request)
        
        let response: AuthResponse = try await networkService.request(
            endpoint: "/auth/register",
            method: .POST,
            body: requestData,
            headers: nil
        )
        
        // Decode JWT token to extract user information
        guard let user = decodeJWT(token: response.token) else {
            throw NetworkError.decodingError
        }
        
        saveUser(user, token: response.token)
        currentUser = user
        return user
    }
    
    /// Logout current user
    func logout() async throws {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: tokenKey)
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
    
    // MARK: - Private Methods
    
    private func saveUser(_ user: User, token: String) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    private func loadCurrentUser() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
        }
    }
    
    /// Decode JWT token to extract user information
    private func decodeJWT(token: String) -> User? {
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
            
            // Map role string to UserRole enum
            let userRole: User.UserRole
            switch payload.role.lowercased() {
            case "admin":
                userRole = .admin
            case "mentor":
                userRole = .mentor
            default:
                userRole = .student
            }
            
            // Create User object from JWT payload
            return User(
                id: payload.id,
                email: payload.email,
                name: payload.email.components(separatedBy: "@").first ?? "User",
                avatar: nil,
                role: userRole
            )
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
            email: email,
            name: "Demo User",
            avatar: nil,
            role: .student
        )
        currentUser = user
        return user
    }
    
    func register(email: String, password: String, name: String) async throws -> User {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let user = User(
            id: UUID().uuidString,
            email: email,
            name: name,
            avatar: nil,
            role: .student
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
}

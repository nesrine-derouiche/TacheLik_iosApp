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
    let user: User
    let token: String
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
        
        saveUser(response.user, token: response.token)
        currentUser = response.user
        return response.user
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
        
        saveUser(response.user, token: response.token)
        currentUser = response.user
        return response.user
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

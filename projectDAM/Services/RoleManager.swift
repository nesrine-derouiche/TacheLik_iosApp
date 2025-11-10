//
//  RoleManager.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import Foundation
import Combine

// MARK: - Role Manager Protocol
protocol RoleManagerProtocol {
    var currentRole: User.UserRole? { get }
    var isStudent: Bool { get }
    var isAdmin: Bool { get }
    var isTeacher: Bool { get }
    var roleDidChange: AnyPublisher<User.UserRole?, Never> { get }
    func updateRole(from user: User)
}

// MARK: - Role Manager Implementation
@MainActor
final class RoleManager: RoleManagerProtocol, ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var currentRole: User.UserRole?
    private let roleDidChangeSubject = PassthroughSubject<User.UserRole?, Never>()
    
    var roleDidChange: AnyPublisher<User.UserRole?, Never> {
        roleDidChangeSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Computed Properties
    var isStudent: Bool {
        currentRole == .student
    }
    
    var isAdmin: Bool {
        currentRole == .admin
    }
    
    var isTeacher: Bool {
        currentRole == .mentor
    }
    
    // MARK: - Initialization
    init() {
        self.currentRole = nil
    }
    
    // MARK: - Public Methods
    
    /// Update the current role based on user data
    func updateRole(from user: User) {
        let previousRole = currentRole
        currentRole = user.role
        
        // Only send notification if role actually changed
        if previousRole != user.role {
            print("👤 Role changed: \(previousRole?.rawValue ?? "nil") → \(user.role.rawValue)")
            roleDidChangeSubject.send(user.role)
        }
    }
}

// MARK: - Mock Role Manager (for testing/development)
final class MockRoleManager: RoleManagerProtocol {
    
    private(set) var currentRole: User.UserRole?
    private let roleDidChangeSubject = PassthroughSubject<User.UserRole?, Never>()
    
    var roleDidChange: AnyPublisher<User.UserRole?, Never> {
        roleDidChangeSubject.eraseToAnyPublisher()
    }
    
    var isStudent: Bool {
        currentRole == .student
    }
    
    var isAdmin: Bool {
        currentRole == .admin
    }
    
    var isTeacher: Bool {
        currentRole == .mentor
    }
    
    init(role: User.UserRole = .student) {
        self.currentRole = role
    }
    
    func updateRole(from user: User) {
        let previousRole = currentRole
        currentRole = user.role
        
        if previousRole != user.role {
            roleDidChangeSubject.send(user.role)
        }
    }
}
